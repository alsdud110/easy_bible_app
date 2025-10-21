package easy.bible.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.os.Bundle

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= 35) {
            window.decorView.setOnApplyWindowInsetsListener(null)
        }
    }
}