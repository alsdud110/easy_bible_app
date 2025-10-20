package easy.bible.app.easy_bible_app

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
package easy.bible.app.easy_bible_app

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.os.Bundle

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Android 15 대응
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            enableEdgeToEdge()
        }
    }
    
    private fun enableEdgeToEdge() {
        window.decorView.setOnApplyWindowInsetsListener(null)
    }
}