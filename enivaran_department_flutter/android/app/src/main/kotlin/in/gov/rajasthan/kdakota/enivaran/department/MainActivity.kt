package `in`.gov.rajasthan.kdakota.enivaran.department

import android.content.Context
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "in.gov.rajasthan.kdakota.enivaran/print"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "printHtml") {
                val html = call.argument<String>("html")
                val title = call.argument<String>("title") ?: "Complaint"
                if (html != null) {
                    runOnUiThread {
                        val printWebView = WebView(this)
                        printWebView.settings.javaScriptEnabled = true
                        printWebView.settings.domStorageEnabled = true
                        printWebView.loadDataWithBaseURL("https://kdakota.rajasthan.gov.in/enivaran/", html, "text/html", "UTF-8", null)
                        printWebView.webViewClient = object : WebViewClient() {
                            override fun onPageFinished(view: WebView?, url: String?) {
                                super.onPageFinished(view, url)
                                try {
                                    val printManager = getSystemService(Context.PRINT_SERVICE) as PrintManager
                                    val printAdapter = printWebView.createPrintDocumentAdapter(title)
                                    val builder = PrintAttributes.Builder()
                                    builder.setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                                    printManager.print(title, printAdapter, builder.build())
                                    result.success(true)
                                } catch (e: Exception) {
                                    result.error("PRINT_FAILED", e.message, null)
                                }
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGS", "HTML content is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
