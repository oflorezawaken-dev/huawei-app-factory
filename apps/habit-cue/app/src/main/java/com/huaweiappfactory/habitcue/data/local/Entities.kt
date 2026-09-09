package com.huaweiappfactory.habitcue.data.local

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(tableName = "habits")
data class HabitEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    /** Hex colour string, e.g. "#5B4FCF", chosen from a fixed palette -- never a photo. */
    val colour: String,
    /** ScheduleType.name */
    val scheduleType: String,
    /** Bitmask of DayOfWeek (bit 0 = Monday .. bit 6 = Sunday); used when SPECIFIC_WEEKDAYS. */
    val scheduleWeekdaysMask: Int = 0,
    /** Used when TIMES_PER_WEEK. */
    val scheduleTimesPerWeek: Int = 0,
    val createdAtEpochDay: Long
)

@Entity(
    tableName = "habit_completions",
    foreignKeys = [ForeignKey(
        entity = HabitEntity::class,
        parentColumns = ["id"],
        childColumns = ["habitId"],
        onDelete = ForeignKey.CASCADE
    )],
    indices = [Index("habitId"), Index("epochDay"), Index(value = ["habitId", "epochDay"], unique = true)]
)
data class HabitCompletionEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val habitId: Long,
    /** The calendar date the habit was completed FOR, not necessarily the tap timestamp's date. */
    val epochDay: Long,
    val completedAtMillis: Long
)
