package dev.plotsklapps.gymply

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "dev.plotsklapps.gymply/app_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "changeIcon") {
                val iconName = call.argument<String>("iconName")
                if (iconName != null) {
                    changeAppIcon(iconName)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Icon name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun changeAppIcon(iconName: String) {
        val packageManager = context.packageManager
        val packageName = context.packageName

        val aliases = listOf(
            "MainActivityPink",
            "MainActivityPurple",
            "MainActivityOrange"
        )

        if (iconName == "MainActivity") {
            // Re-enable the base MainActivity
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, "$packageName.MainActivity"),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            // Disable all custom aliases
            for (alias in aliases) {
                packageManager.setComponentEnabledSetting(
                    ComponentName(packageName, "$packageName.$alias"),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        } else {
            // Enable the chosen custom alias
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, "$packageName.$iconName"),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            // Disable the base MainActivity
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, "$packageName.MainActivity"),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            // Disable all other custom aliases
            for (alias in aliases) {
                if (alias != iconName) {
                    packageManager.setComponentEnabledSetting(
                        ComponentName(packageName, "$packageName.$alias"),
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP
                    )
                }
            }
        }
    }
}
