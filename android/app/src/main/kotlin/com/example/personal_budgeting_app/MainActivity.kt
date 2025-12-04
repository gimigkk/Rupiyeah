package com.example.personal_budgeting_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.personal_budgeting_app/widget"
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "updateWidget") {
                try {
                    //Log.d("MainActivity", "Updating widget from Flutter")
                    val updateIntent = Intent(this, BudgetWidgetProvider::class.java)
                    updateIntent.action = "android.appwidget.action.APPWIDGET_UPDATE"
                    sendBroadcast(updateIntent)
                    result.success("Widget updated")
                } catch (e: Exception) {
                    //Log.e("MainActivity", "Error updating widget: ${e.message}")
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
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
        //Log.d("MainActivity", "handleIntent called with action: ${intent?.action}")
        
        if (intent?.action == "ADD_TRANSACTION") {
            //Log.d("MainActivity", "ADD_TRANSACTION action detected")
            
            // Wait a bit for Flutter to be ready, then send the command
            android.os.Handler(mainLooper).postDelayed({
                methodChannel?.invokeMethod("openAddTransaction", null, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        //Log.d("MainActivity", "Successfully opened add transaction")
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        //Log.e("MainActivity", "Error opening add transaction: $errorMessage")
                    }
                    
                    override fun notImplemented() {
                        //Log.e("MainActivity", "openAddTransaction not implemented in Flutter")
                    }
                })
            }, 500)
        }
    }
}