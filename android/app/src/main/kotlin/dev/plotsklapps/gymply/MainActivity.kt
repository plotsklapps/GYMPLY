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

        // List of all aliases we defined in AndroidManifest.xml
        val aliases = listOf(
            "MainActivity",
            "MainActivityPink",
            "MainActivityPurple",
            "MainActivityOrange"
        )

        // Enable the new icon first
        val newComponent = ComponentName(packageName, "$packageName.$iconName")
        packageManager.setComponentEnabledSetting(
            newComponent,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )

        // Then disable the others
        for (alias in aliases) {
            if (alias != iconName) {
                val componentName = ComponentName(packageName, "$packageName.$alias")
                packageManager.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP 
                )
            }
        }
    }
}
