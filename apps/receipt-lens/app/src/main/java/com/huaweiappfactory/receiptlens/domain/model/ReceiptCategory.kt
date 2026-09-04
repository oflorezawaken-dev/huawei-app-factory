package com.huaweiappfactory.receiptlens.domain.model

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Fastfood
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.Store
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.example.R

enum class ReceiptCategory(
    val id: String,
    @StringRes val titleRes: Int,
    val icon: ImageVector,
    val color: Color
) {
    FOOD(
        id = "Food",
        titleRes = R.string.category_food,
        icon = Icons.Default.Fastfood,
        color = Color(0xFFF97316) // Orange
    ),
    GROCERIES(
        id = "Groceries",
        titleRes = R.string.category_groceries,
        icon = Icons.Default.ShoppingCart,
        color = Color(0xFF10B981) // Emerald
    ),
    TRANSPORT(
        id = "Transport",
        titleRes = R.string.category_transport,
        icon = Icons.Default.DirectionsCar,
        color = Color(0xFF0EA5E9) // Sky Blue
    ),
    SHOPPING(
        id = "Shopping",
        titleRes = R.string.category_shopping,
        icon = Icons.Default.Store,
        color = Color(0xFF8B5CF6) // Purple
    ),
    BILLS(
        id = "Bills",
        titleRes = R.string.category_bills,
        icon = Icons.Default.Receipt,
        color = Color(0xFFEF4444) // Red
    ),
    HEALTH(
        id = "Health",
        titleRes = R.string.category_health,
        icon = Icons.Default.LocalHospital,
        color = Color(0xFFEC4899) // Pink
    ),
    ENTERTAINMENT(
        id = "Entertainment",
        titleRes = R.string.category_entertainment,
        icon = Icons.Default.Movie,
        color = Color(0xFFF59E0B) // Amber
    ),
    TRAVEL(
        id = "Travel",
        titleRes = R.string.category_travel,
        icon = Icons.Default.Flight,
        color = Color(0xFF06B6D4) // Cyan
    ),
    WORK(
        id = "Work",
        titleRes = R.string.category_work,
        icon = Icons.Default.Business,
        color = Color(0xFF64748B) // Slate
    ),
    OTHER(
        id = "Other",
        titleRes = R.string.category_other,
        icon = Icons.Default.Category,
        color = Color(0xFF94A3B8) // Gray
    );

    companion object {
        fun fromId(id: String): ReceiptCategory {
            return entries.find { it.id.equals(id, ignoreCase = true) } ?: OTHER
        }
    }
}
