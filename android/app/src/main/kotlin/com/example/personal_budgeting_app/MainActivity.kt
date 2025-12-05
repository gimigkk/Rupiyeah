package com.example.personal_budgeting_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.appwidget.AppWidgetManager
import android.content.ComponentName

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.personal_budgeting_app/widget"
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    try {
                        Log.d("MainActivity", "📱 Updating widget from Flutter")
                        
                        // Get all widget IDs
                        val appWidgetManager = AppWidgetManager.getInstance(this)
                        val widgetIds = appWidgetManager.getAppWidgetIds(
                            ComponentName(this, BudgetWidgetProvider::class.java)
                        )
                        
                        Log.d("MainActivity", "Found ${widgetIds.size} widgets to update")
                        
                        if (widgetIds.isNotEmpty()) {
                            // Send broadcast to update all widgets
                            val updateIntent = Intent(this, BudgetWidgetProvider::class.java)
                            updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                            updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                            sendBroadcast(updateIntent)
                            
                            Log.d("MainActivity", "✅ Widget update broadcast sent")
                            result.success("Widget updated")
                        } else {
                            Log.d("MainActivity", "⚠️ No widgets found")
                            result.success("No widgets to update")
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "❌ Error updating widget: ${e.message}")
                        e.printStackTrace()
                        result.error("ERROR", e.message, null)
                    }
                }
                "forceWidgetRefresh" -> {
                    try {
                        Log.d("MainActivity", "🔄 Force refreshing widget")
                        
                        // Alternative method: directly call the provider
                        val appWidgetManager = AppWidgetManager.getInstance(this)
                        val widgetIds = appWidgetManager.getAppWidgetIds(
                            ComponentName(this, BudgetWidgetProvider::class.java)
                        )
                        
                        val provider = BudgetWidgetProvider()
                        provider.onUpdate(this, appWidgetManager, widgetIds)
                        
                        Log.d("MainActivity", "✅ Widget force refresh complete")
                        result.success("Widget force refreshed")
                    } catch (e: Exception) {
                        Log.e("MainActivity", "❌ Error force refreshing: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        Log.d("MainActivity", "handleIntent called with action: ${intent?.action}")
        
        if (intent?.action == "ADD_TRANSACTION") {
            Log.d("MainActivity", "ADD_TRANSACTION action detected")
            
            // Wait a bit for Flutter to be ready, then send the command
            android.os.Handler(mainLooper).postDelayed({
                methodChannel?.invokeMethod("openAddTransaction", null, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        Log.d("MainActivity", "Successfully opened add transaction")
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        Log.e("MainActivity", "Error opening add transaction: $errorMessage")
                    }
                    
                    override fun notImplemented() {
                        Log.e("MainActivity", "openAddTransaction not implemented in Flutter")
                    }
                })
            }, 500)
        }
    }
}