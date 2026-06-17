package `in`.femflow.app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15 (SDK 35) compliance
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
