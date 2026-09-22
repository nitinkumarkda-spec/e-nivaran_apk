package `in`.gov.rajasthan.kdakota.enivaran.department

import android.content.Context
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "in.gov.rajasthan.kdakota.enivaran/print"
    private var activePrintWebView: WebView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "printHtml") {
                val html = call.argument<String>("html")
                val baseUrl = call.argument<String>("baseUrl") ?: "https://kdakota.rajasthan.gov.in/enivaran/"
                val title = call.argument<String>("title") ?: "KDA-Complaint-Print"

                if (html != null) {
                    printHtmlContent(html, baseUrl, title)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "HTML content is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun printHtmlContent(html: String, baseUrl: String, title: String) {
        runOnUiThread {
            val printWebView = WebView(this)
            activePrintWebView = printWebView

            val cookieManager = CookieManager.getInstance()
            cookieManager.setAcceptCookie(true)
            cookieManager.setAcceptThirdPartyCookies(printWebView, true)

            printWebView.settings.javaScriptEnabled = true
            printWebView.settings.domStorageEnabled = true
            printWebView.settings.loadWithOverviewMode = true
            printWebView.settings.useWideViewPort = true

            printWebView.webViewClient = object : WebViewClient() {
                private var hasPrinted = false
                override fun onPageFinished(view: WebView, url: String) {
                    if (!hasPrinted) {
                        hasPrinted = true
                        view.postDelayed({
                            val printManager = getSystemService(Context.PRINT_SERVICE) as? PrintManager
                            if (printManager != null) {
                                val printAdapter = view.createPrintDocumentAdapter(title)
                                val printAttributes = PrintAttributes.Builder()
                                    .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
                                    .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                                    .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                                    .build()
                                printManager.print(title, printAdapter, printAttributes)
                            }
                        }, 500)
                    }
                }
            }

            printWebView.loadDataWithBaseURL(baseUrl, html, "text/html", "UTF-8", null)
        }
    }
}
