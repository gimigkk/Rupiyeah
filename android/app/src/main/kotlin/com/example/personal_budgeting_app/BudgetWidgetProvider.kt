package com.example.personal_budgeting_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.os.Bundle
import android.widget.RemoteViews
import android.util.Log

class BudgetWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d("BudgetWidget", "onUpdate called for ${appWidgetIds.size} widgets")
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        Log.d("BudgetWidget", "onAppWidgetOptionsChanged called")
        updateWidget(context, appWidgetManager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d("BudgetWidget", "🔔 onReceive called with action: ${intent?.action}")
        
        when (intent?.action) {
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                Log.d("BudgetWidget", "📢 ACTION_APPWIDGET_UPDATE received")
                context?.let {
                    val appWidgetManager = AppWidgetManager.getInstance(it)
                    val ids = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                    if (ids != null && ids.isNotEmpty()) {
                        Log.d("BudgetWidget", "Updating ${ids.size} widgets")
                        onUpdate(it, appWidgetManager, ids)
                    } else {
                        Log.d("BudgetWidget", "No widget IDs in intent, getting all widgets")
                        val widgetIds = appWidgetManager.getAppWidgetIds(
                            android.content.ComponentName(it, BudgetWidgetProvider::class.java)
                        )
                        onUpdate(it, appWidgetManager, widgetIds)
                    }
                }
            }
            "com.example.personal_budgeting_app.UPDATE_WIDGET" -> {
                Log.d("BudgetWidget", "📢 Custom UPDATE_WIDGET broadcast received")
                context?.let {
                    val appWidgetManager = AppWidgetManager.getInstance(it)
                    val widgetIds = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(it, BudgetWidgetProvider::class.java)
                    )
                    onUpdate(it, appWidgetManager, widgetIds)
                }
            }
            else -> {
                super.onReceive(context, intent)
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Read theme settings
            val themeId = prefs.getString("flutter.theme_id", "purple") ?: "purple"
            // Widget always uses light mode for better visibility on home screen
            val isDarkMode = false
            
            Log.d("BudgetWidget", "Theme: $themeId (widget always uses light mode)")
            
            // Get theme with light mode (widget is always light)
            val theme = WidgetThemeHelper.getTheme(themeId, isDarkMode)
            
            val remainingBudget = prefs.getString("flutter.remaining_budget", "Rp 0") ?: "Rp 0"
            val spentToday = prefs.getString("flutter.spent_today", "Rp 0") ?: "Rp 0"
            val progress = prefs.getString("flutter.progress", "0")?.toIntOrNull() ?: 0
            
            Log.d("BudgetWidget", "Budget: $remainingBudget, Spent: $spentToday, Progress: $progress%")
            
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            
            val layout = if (minHeight < 70) R.layout.widget_small else R.layout.widget_medium
            
            // Create NEW RemoteViews instance to avoid caching
            val views = RemoteViews(context.packageName, layout)
            
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                widgetId * 1000,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val addTransactionIntent = Intent(context, MainActivity::class.java).apply {
                action = "ADD_TRANSACTION"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            
            val addTransactionPendingIntent = PendingIntent.getActivity(
                context,
                widgetId * 1000 + 1,
                addTransactionIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            views.setInt(R.id.widget_root, "setBackgroundColor", theme.primary)
            
            val whiteColor = 0xFFFFFFFF.toInt()
            
            if (layout == R.layout.widget_small) {
                updateSmallWidget(
                    views, 
                    remainingBudget, 
                    progress, 
                    theme, 
                    openAppPendingIntent,
                    addTransactionPendingIntent, 
                    whiteColor
                )
            } else {
                updateMediumWidget(
                    views, 
                    remainingBudget, 
                    spentToday, 
                    progress, 
                    theme, 
                    openAppPendingIntent,
                    addTransactionPendingIntent, 
                    whiteColor
                )
            }
            
            // Force update the widget
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d("BudgetWidget", "Widget $widgetId updated successfully")
            
        } catch (e: Exception) {
            Log.e("BudgetWidget", "Error updating widget", e)
            e.printStackTrace()
        }
    }
    
    private fun updateSmallWidget(
        views: RemoteViews,
        remainingBudget: String,
        progress: Int,
        theme: WidgetTheme,
        openAppPendingIntent: PendingIntent,
        addTransactionPendingIntent: PendingIntent,
        whiteColor: Int
    ) {
        views.setTextViewText(R.id.remaining_budget, remainingBudget)
        views.setTextViewText(R.id.progress_text, "$progress%")
        
        views.setTextColor(R.id.remaining_budget, whiteColor)
        views.setTextColor(R.id.budget_label, whiteColor)
        views.setTextColor(R.id.progress_text, whiteColor)
        views.setTextColor(R.id.spent_label, whiteColor)
        
        views.setInt(R.id.add_button_icon_small, "setTextColor", theme.primary)
        
        views.setOnClickPendingIntent(R.id.widget_body_small, openAppPendingIntent)
        views.setOnClickPendingIntent(R.id.add_button_small, addTransactionPendingIntent)
    }
    
    private fun updateMediumWidget(
        views: RemoteViews,
        remainingBudget: String,
        spentToday: String,
        progress: Int,
        theme: WidgetTheme,
        openAppPendingIntent: PendingIntent,
        addTransactionPendingIntent: PendingIntent,
        whiteColor: Int
    ) {
        views.setTextViewText(R.id.remaining_budget_medium, remainingBudget)
        views.setTextViewText(R.id.spent_today_medium, spentToday)
        views.setTextViewText(R.id.progress_text_medium, "$progress%")
        
        views.setTextColor(R.id.title_medium, whiteColor)
        views.setTextColor(R.id.remaining_budget_medium, whiteColor)
        views.setTextColor(R.id.budget_label_medium, whiteColor)
        views.setTextColor(R.id.spent_label_medium, whiteColor)
        views.setTextColor(R.id.spent_today_medium, whiteColor)
        views.setTextColor(R.id.progress_text_medium, whiteColor)
        views.setTextColor(R.id.progress_label_medium, whiteColor)
        
        views.setInt(R.id.add_button_icon_medium, "setTextColor", theme.primary)
        
        views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)
        views.setOnClickPendingIntent(R.id.add_button_medium, addTransactionPendingIntent)
    }
    
    companion object {
        fun updateAllWidgets(context: Context) {
            val intent = Intent(context, BudgetWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(
                android.content.ComponentName(context, BudgetWidgetProvider::class.java)
            )
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            context.sendBroadcast(intent)
        }
    }
}