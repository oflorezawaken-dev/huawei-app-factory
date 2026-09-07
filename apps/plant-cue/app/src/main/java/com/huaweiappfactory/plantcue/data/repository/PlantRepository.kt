package com.huaweiappfactory.plantcue.data.repository

import android.content.Context
import com.huaweiappfactory.plantcue.data.local.CareEventEntity
import com.huaweiappfactory.plantcue.data.local.CareScheduleEntity
import com.huaweiappfactory.plantcue.data.local.PlantDao
import com.huaweiappfactory.plantcue.data.local.PlantEntity
import com.huaweiappfactory.plantcue.data.local.PlantWithSchedules
import com.huaweiappfactory.plantcue.domain.CareAction
import com.huaweiappfactory.plantcue.domain.CareRecord
import com.huaweiappfactory.plantcue.domain.CareType
import com.huaweiappfactory.plantcue.domain.Scheduler
import com.huaweiappfactory.plantcue.util.ImageStorageManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate

/** Schedule as entered on the Add/Edit screen. */
data class ScheduleInput(val type: CareType, val intervalDays: Int)

/** A due item for Today and the daily notification. */
data class DueItem(
    val plant: PlantEntity,
    val schedule: CareScheduleEntity,
    val type: CareType,
    val daysLate: Long
)

class PlantRepository(private val dao: PlantDao, private val appContext: Context) {

    fun observePlants(): Flow<List<PlantWithSchedules>> = dao.observePlantsWithSchedules()
    fun observePlant(id: Long): Flow<PlantWithSchedules?> = dao.observePlantWithSchedules(id)
    fun observePlantCount(): Flow<Int> = dao.observePlantCount()
    fun observeRooms(): Flow<List<String>> = dao.observeRooms()
    fun observeEventsForPlant(plantId: Long): Flow<List<CareEventEntity>> = dao.observeEventsForPlant(plantId)

    fun observeCareRecords(): Flow<List<CareRecord>> = dao.observeAllEvents().map { events ->
        events.map {
            CareRecord(
                plantId = it.plantId,
                type = CareType.valueOf(it.careType),
                action = CareAction.valueOf(it.action),
                on = LocalDate.ofEpochDay(it.atEpochDay),
                dueOn = LocalDate.ofEpochDay(it.dueEpochDay)
            )
        }
    }

    suspend fun getPlant(id: Long): PlantEntity? = dao.getPlant(id)
    suspend fun getSchedules(plantId: Long): List<CareScheduleEntity> = dao.getSchedulesForPlant(plantId)

    /** Creates or updates a plant and reconciles its schedules with the given inputs. */
    suspend fun savePlant(
        id: Long,
        name: String,
        room: String,
        notes: String,
        photoPath: String?,
        schedules: List<ScheduleInput>,
        today: LocalDate = LocalDate.now()
    ): Long {
        val now = System.currentTimeMillis()
        val plantId: Long
        if (id == 0L) {
            plantId = dao.insertPlant(PlantEntity(name = name.trim(), room = room.trim(), notes = notes.trim(), photoPath = photoPath, createdAt = now, updatedAt = now))
        } else {
            val existing = dao.getPlant(id) ?: return 0L
            if (existing.photoPath != null && existing.photoPath != photoPath) {
                ImageStorageManager.deleteImageFile(existing.photoPath)
            }
            dao.updatePlant(existing.copy(name = name.trim(), room = room.trim(), notes = notes.trim(), photoPath = photoPath, updatedAt = now))
            plantId = id
        }

        val current = dao.getSchedulesForPlant(plantId).associateBy { it.careType }
        val wanted = schedules.associateBy { it.type.name }
        for ((type, existing) in current) {
            val input = wanted[type]
            if (input == null) {
                dao.deleteSchedule(existing.id)
            } else if (input.intervalDays != existing.intervalDays) {
                val anchor = existing.lastDoneEpochDay?.let { LocalDate.ofEpochDay(it) } ?: today
                dao.updateSchedule(existing.copy(
                    intervalDays = input.intervalDays,
                    nextDueEpochDay = Scheduler.nextDueAfterDone(anchor, input.intervalDays).toEpochDay()
                ))
            }
        }
        for ((type, input) in wanted) {
            if (type !in current) {
                dao.insertSchedule(CareScheduleEntity(
                    plantId = plantId,
                    careType = type,
                    intervalDays = input.intervalDays,
                    lastDoneEpochDay = null,
                    nextDueEpochDay = Scheduler.initialNextDue(today, input.intervalDays).toEpochDay()
                ))
            }
        }
        return plantId
    }

    suspend fun deletePlant(id: Long) {
        val plant = dao.getPlant(id) ?: return
        ImageStorageManager.deleteImageFile(plant.photoPath)
        dao.deletePlant(plant) // schedules and events cascade
    }

    suspend fun markDone(scheduleId: Long, today: LocalDate = LocalDate.now()) {
        val s = dao.getSchedule(scheduleId) ?: return
        dao.updateSchedule(s.copy(
            lastDoneEpochDay = today.toEpochDay(),
            nextDueEpochDay = Scheduler.nextDueAfterDone(today, s.intervalDays).toEpochDay()
        ))
        dao.insertEvent(event(s, CareAction.DONE, today))
    }

    suspend fun snooze(scheduleId: Long, today: LocalDate = LocalDate.now()) {
        val s = dao.getSchedule(scheduleId) ?: return
        dao.updateSchedule(s.copy(
            nextDueEpochDay = Scheduler.snooze(LocalDate.ofEpochDay(s.nextDueEpochDay), today).toEpochDay()
        ))
        dao.insertEvent(event(s, CareAction.SNOOZED, today))
    }

    /** Everything due today or overdue, most overdue first. */
    suspend fun dueItems(today: LocalDate = LocalDate.now()): List<DueItem> {
        val due = dao.getSchedulesDueOnOrBefore(today.toEpochDay())
        if (due.isEmpty()) return emptyList()
        val plants = dao.getPlantsWithSchedulesOnce().associateBy { it.plant.id }
        return due.mapNotNull { s ->
            plants[s.plantId]?.plant?.let { p ->
                DueItem(p, s, CareType.valueOf(s.careType), Scheduler.daysLate(LocalDate.ofEpochDay(s.nextDueEpochDay), today))
            }
        }.sortedByDescending { it.daysLate }
    }

    suspend fun markAllDueDone(today: LocalDate = LocalDate.now()) {
        dueItems(today).forEach { markDone(it.schedule.id, today) }
    }

    suspend fun snoozeAllDue(today: LocalDate = LocalDate.now()) {
        dueItems(today).forEach { snooze(it.schedule.id, today) }
    }

    private fun event(s: CareScheduleEntity, action: CareAction, today: LocalDate) = CareEventEntity(
        plantId = s.plantId,
        careType = s.careType,
        action = action.name,
        atEpochDay = today.toEpochDay(),
        dueEpochDay = s.nextDueEpochDay,
        atMillis = System.currentTimeMillis()
    )
}
