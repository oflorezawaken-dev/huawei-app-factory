package com.huaweiappfactory.plantcue.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface PlantDao {

    @Transaction
    @Query("SELECT * FROM plants ORDER BY name COLLATE NOCASE")
    fun observePlantsWithSchedules(): Flow<List<PlantWithSchedules>>

    @Transaction
    @Query("SELECT * FROM plants WHERE id = :id")
    fun observePlantWithSchedules(id: Long): Flow<PlantWithSchedules?>

    @Transaction
    @Query("SELECT * FROM plants")
    suspend fun getPlantsWithSchedulesOnce(): List<PlantWithSchedules>

    @Query("SELECT * FROM plants WHERE id = :id")
    suspend fun getPlant(id: Long): PlantEntity?

    @Query("SELECT COUNT(*) FROM plants")
    fun observePlantCount(): Flow<Int>

    @Query("SELECT DISTINCT room FROM plants WHERE room != '' ORDER BY room COLLATE NOCASE")
    fun observeRooms(): Flow<List<String>>

    @Insert
    suspend fun insertPlant(plant: PlantEntity): Long

    @Update
    suspend fun updatePlant(plant: PlantEntity)

    @Delete
    suspend fun deletePlant(plant: PlantEntity)

    @Query("SELECT * FROM care_schedules WHERE id = :id")
    suspend fun getSchedule(id: Long): CareScheduleEntity?

    @Query("SELECT * FROM care_schedules WHERE plantId = :plantId")
    suspend fun getSchedulesForPlant(plantId: Long): List<CareScheduleEntity>

    @Query("SELECT * FROM care_schedules WHERE nextDueEpochDay <= :epochDay")
    suspend fun getSchedulesDueOnOrBefore(epochDay: Long): List<CareScheduleEntity>

    @Insert
    suspend fun insertSchedule(schedule: CareScheduleEntity): Long

    @Update
    suspend fun updateSchedule(schedule: CareScheduleEntity)

    @Query("DELETE FROM care_schedules WHERE id = :id")
    suspend fun deleteSchedule(id: Long)

    @Insert
    suspend fun insertEvent(event: CareEventEntity)

    @Query("SELECT * FROM care_events WHERE plantId = :plantId ORDER BY atMillis DESC")
    fun observeEventsForPlant(plantId: Long): Flow<List<CareEventEntity>>

    @Query("SELECT * FROM care_events ORDER BY atMillis DESC")
    fun observeAllEvents(): Flow<List<CareEventEntity>>
}
