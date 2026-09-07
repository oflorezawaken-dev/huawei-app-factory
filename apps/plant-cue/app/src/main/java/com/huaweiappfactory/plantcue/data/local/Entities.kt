package com.huaweiappfactory.plantcue.data.local

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation

@Entity(tableName = "plants")
data class PlantEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val room: String = "",
    val notes: String = "",
    val photoPath: String? = null,
    val createdAt: Long,
    val updatedAt: Long
)

@Entity(
    tableName = "care_schedules",
    foreignKeys = [ForeignKey(
        entity = PlantEntity::class,
        parentColumns = ["id"],
        childColumns = ["plantId"],
        onDelete = ForeignKey.CASCADE
    )],
    indices = [Index("plantId"), Index("nextDueEpochDay")]
)
data class CareScheduleEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val plantId: Long,
    /** CareType.name */
    val careType: String,
    val intervalDays: Int,
    val lastDoneEpochDay: Long? = null,
    val nextDueEpochDay: Long
)

@Entity(
    tableName = "care_events",
    foreignKeys = [ForeignKey(
        entity = PlantEntity::class,
        parentColumns = ["id"],
        childColumns = ["plantId"],
        onDelete = ForeignKey.CASCADE
    )],
    indices = [Index("plantId"), Index("atEpochDay")]
)
data class CareEventEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val plantId: Long,
    val careType: String,
    /** CareAction.name */
    val action: String,
    val atEpochDay: Long,
    val dueEpochDay: Long,
    val atMillis: Long
)

data class PlantWithSchedules(
    @Embedded val plant: PlantEntity,
    @Relation(parentColumn = "id", entityColumn = "plantId")
    val schedules: List<CareScheduleEntity>
)
