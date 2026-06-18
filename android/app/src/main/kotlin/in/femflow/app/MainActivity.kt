package `in`.femflow.app

import android.os.Bundle
import android.os.Build
import android.view.WindowManager
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable native edge-to-edge display for Android 15 (SDK 35) compliance
        enableEdgeToEdge()
        
        // Handle Display Cutout (Notch) for immersive experience
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode = 
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        }

        super.onCreate(savedInstanceState)
    }
}
