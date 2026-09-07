package com.huaweiappfactory.plantcue.ui.screens

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.plantcue.data.repository.PlantRepository
import com.huaweiappfactory.plantcue.data.repository.ScheduleInput
import com.huaweiappfactory.plantcue.data.repository.UserPreferencesRepository
import com.huaweiappfactory.plantcue.domain.CareType
import com.huaweiappfactory.plantcue.util.ImageStorageManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File

data class PlantEditUiState(
    val isNew: Boolean = true,
    val loading: Boolean = true,
    val name: String = "",
    val room: String = "",
    val notes: String = "",
    val photoPath: String? = null,
    val waterEveryDays: Int = CareType.WATER.defaultIntervalDays,
    val fertiliseEnabled: Boolean = false,
    val fertiliseEveryDays: Int = CareType.FERTILISE.defaultIntervalDays,
    val mistEnabled: Boolean = false,
    val mistEveryDays: Int = CareType.MIST.defaultIntervalDays,
    val roomSuggestions: List<String> = emptyList(),
    val nameError: Boolean = false,
    val photoError: Boolean = false,
    val saving: Boolean = false,
    val savedId: Long? = null,
    /** Ask for POST_NOTIFICATIONS right after the first plant is saved (once). */
    val askNotificationPermission: Boolean = false
)

class PlantEditViewModel(
    private val repo: PlantRepository,
    private val prefs: UserPreferencesRepository,
    private val plantId: Long
) : ViewModel() {

    private val _ui = MutableStateFlow(PlantEditUiState(isNew = plantId == 0L))
    val uiState: StateFlow<PlantEditUiState> = _ui.asStateFlow()

    /** Photo saved during this edit session but not yet attached to a saved plant. */
    private var pendingPhotoPath: String? = null

    init {
        viewModelScope.launch {
            val rooms = repo.observeRooms().first()
            if (plantId != 0L) {
                val plant = repo.getPlant(plantId)
                val schedules = repo.getSchedules(plantId).associateBy { CareType.valueOf(it.careType) }
                if (plant != null) {
                    _ui.update {
                        it.copy(
                            loading = false, isNew = false,
                            name = plant.name, room = plant.room, notes = plant.notes, photoPath = plant.photoPath,
                            waterEveryDays = schedules[CareType.WATER]?.intervalDays ?: CareType.WATER.defaultIntervalDays,
                            fertiliseEnabled = schedules.containsKey(CareType.FERTILISE),
                            fertiliseEveryDays = schedules[CareType.FERTILISE]?.intervalDays ?: CareType.FERTILISE.defaultIntervalDays,
                            mistEnabled = schedules.containsKey(CareType.MIST),
                            mistEveryDays = schedules[CareType.MIST]?.intervalDays ?: CareType.MIST.defaultIntervalDays,
                            roomSuggestions = rooms
                        )
                    }
                    return@launch
                }
            }
            _ui.update { it.copy(loading = false, roomSuggestions = rooms) }
        }
    }

    fun onName(v: String) = _ui.update { it.copy(name = v, nameError = false) }
    fun onRoom(v: String) = _ui.update { it.copy(room = v) }
    fun onNotes(v: String) = _ui.update { it.copy(notes = v) }
    fun onWaterDays(v: Int) = _ui.update { it.copy(waterEveryDays = v.coerceIn(1, 365)) }
    fun onFertiliseEnabled(v: Boolean) = _ui.update { it.copy(fertiliseEnabled = v) }
    fun onFertiliseDays(v: Int) = _ui.update { it.copy(fertiliseEveryDays = v.coerceIn(1, 365)) }
    fun onMistEnabled(v: Boolean) = _ui.update { it.copy(mistEnabled = v) }
    fun onMistDays(v: Int) = _ui.update { it.copy(mistEveryDays = v.coerceIn(1, 365)) }

    fun onPhotoPicked(context: Context, uri: Uri) = viewModelScope.launch {
        ImageStorageManager.saveImageFromUri(context, uri)
            .onSuccess { setPendingPhoto(it) }
            .onFailure { _ui.update { s -> s.copy(photoError = true) } }
    }

    fun onPhotoCaptured(context: Context, file: File) = viewModelScope.launch {
        ImageStorageManager.saveImageFromFile(context, file)
            .onSuccess { setPendingPhoto(it) }
            .onFailure { _ui.update { s -> s.copy(photoError = true) } }
    }

    private suspend fun setPendingPhoto(path: String) {
        pendingPhotoPath?.let { ImageStorageManager.deleteImageFile(it) }
        pendingPhotoPath = path
        _ui.update { it.copy(photoPath = path, photoError = false) }
    }

    fun removePhoto() = viewModelScope.launch {
        pendingPhotoPath?.let { ImageStorageManager.deleteImageFile(it) }
        pendingPhotoPath = null
        _ui.update { it.copy(photoPath = null) }
    }

    fun dismissPhotoError() = _ui.update { it.copy(photoError = false) }

    fun save() {
        val s = _ui.value
        if (s.name.isBlank()) { _ui.update { it.copy(nameError = true) }; return }
        if (s.saving) return
        _ui.update { it.copy(saving = true) }
        viewModelScope.launch {
            val schedules = buildList {
                add(ScheduleInput(CareType.WATER, s.waterEveryDays))
                if (s.fertiliseEnabled) add(ScheduleInput(CareType.FERTILISE, s.fertiliseEveryDays))
                if (s.mistEnabled) add(ScheduleInput(CareType.MIST, s.mistEveryDays))
            }
            val id = repo.savePlant(plantId, s.name, s.room, s.notes, s.photoPath, schedules)
            pendingPhotoPath = null
            val ask = !prefs.isNotificationIntroSeen()
            if (ask) prefs.setNotificationIntroSeen()
            _ui.update { it.copy(saving = false, savedId = id, askNotificationPermission = ask) }
        }
    }

    fun notificationPromptHandled() = _ui.update { it.copy(askNotificationPermission = false) }

    override fun onCleared() {
        // Discard a photo that was picked but never saved with a plant.
        val orphan = pendingPhotoPath
        if (orphan != null && _ui.value.savedId == null) {
            kotlinx.coroutines.runBlocking { ImageStorageManager.deleteImageFile(orphan) }
        }
    }

    companion object {
        fun factory(repo: PlantRepository, prefs: UserPreferencesRepository, plantId: Long): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T = PlantEditViewModel(repo, prefs, plantId) as T
            }
    }
}
