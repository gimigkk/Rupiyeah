package com.example.personal_budgeting_app

import android.graphics.Color

data class WidgetTheme(
    val primary: Int,
    val secondary: Int,
    val background: Int,
    val cardBackground: Int,
    val textPrimary: Int,
    val textSecondary: Int,
    val success: Int,
    val danger: Int,
    val warning: Int
)

object WidgetThemeHelper {
    
    fun getTheme(themeId: String, isDarkMode: Boolean): WidgetTheme {
        val lightTheme = when (themeId) {
            "purple" -> WidgetTheme(
                primary = Color.parseColor("#6C63FF"),
                secondary = Color.parseColor("#5A52E0"),
                background = Color.parseColor("#F5F7FA"),
                cardBackground = Color.parseColor("#FFFFFF"),
                textPrimary = Color.parseColor("#212121"),
                textSecondary = Color.parseColor("#757575"),
                success = Color.parseColor("#4CAF50"),
                danger = Color.parseColor("#FF5252"),
                warning = Color.parseColor("#FF9066")
            )
            "ocean" -> WidgetTheme(
                primary = Color.parseColor("#0891B2"),
                secondary = Color.parseColor("#0E7490"),
                background = Color.parseColor("#F0F9FF"),
                cardBackground = Color.parseColor("#FFFFFF"),
                textPrimary = Color.parseColor("#212121"),
                textSecondary = Color.parseColor("#757575"),
                success = Color.parseColor("#10B981"),
                danger = Color.parseColor("#EF4444"),
                warning = Color.parseColor("#F59E0B")
            )
            "sunset" -> WidgetTheme(
                primary = Color.parseColor("#EA580C"),
                secondary = Color.parseColor("#C2410C"),
                background = Color.parseColor("#FFF7ED"),
                cardBackground = Color.parseColor("#FFFFFF"),
                textPrimary = Color.parseColor("#212121"),
                textSecondary = Color.parseColor("#757575"),
                success = Color.parseColor("#22C55E"),
                danger = Color.parseColor("#DC2626"),
                warning = Color.parseColor("#FBBF24")
            )
            "forest" -> WidgetTheme(
                primary = Color.parseColor("#059669"),
                secondary = Color.parseColor("#047857"),
                background = Color.parseColor("#F0FDF4"),
                cardBackground = Color.parseColor("#FFFFFF"),
                textPrimary = Color.parseColor("#212121"),
                textSecondary = Color.parseColor("#757575"),
                success = Color.parseColor("#10B981"),
                danger = Color.parseColor("#F87171"),
                warning = Color.parseColor("#FBBF24")
            )
            "rose" -> WidgetTheme(
                primary = Color.parseColor("#E11D48"),
                secondary = Color.parseColor("#BE123C"),
                background = Color.parseColor("#FFF1F2"),
                cardBackground = Color.parseColor("#FFFFFF"),
                textPrimary = Color.parseColor("#212121"),
                textSecondary = Color.parseColor("#757575"),
                success = Color.parseColor("#10B981"),
                danger = Color.parseColor("#DC2626"),
                warning = Color.parseColor("#F59E0B")
            )
            "midnight" -> WidgetTheme(
                primary = Color.parseColor("#1E3A8A"),
                secondary = Color.parseColor("#1E40AF"),
                background = Color.parseColor("#EFF6FF"),
                cardBackground = Color.parseColor("#FFFFFF"),
                textPrimary = Color.parseColor("#212121"),
                textSecondary = Color.parseColor("#757575"),
                success = Color.parseColor("#22C55E"),
                danger = Color.parseColor("#EF4444"),
                warning = Color.parseColor("#F59E0B")
            )
            else -> getTheme("purple", false)
        }
        
        return if (isDarkMode) {
            lightTheme.copy(
                background = Color.parseColor("#121212"),
                cardBackground = Color.parseColor("#1E1E1E"),
                textPrimary = Color.parseColor("#FFFFFF"),
                textSecondary = Color.parseColor("#B0B0B0")
            )
        } else {
            lightTheme
        }
    }
}