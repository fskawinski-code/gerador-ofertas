package com.example.gerador_ofertas  // 👈 use o SEU package original

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.share/link"
    private var channel: MethodChannel? = null
    private var linkPendente: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tratarIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        tratarIntent(intent)
    }

    private fun tratarIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("text") == true) {
            val texto = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (texto != null) {
                // Se o canal já existe, envia direto. Senão, guarda pra depois.
                if (channel != null) {
                    channel?.invokeMethod("linkRecebido", texto)
                } else {
                    linkPendente = texto
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Flutter também pode pedir o link inicial (fallback)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getSharedLink") {
                result.success(linkPendente)
                linkPendente = null
            } else {
                result.notImplemented()
            }
        }

        // Se já tinha link guardado ao iniciar, envia agora
        linkPendente?.let {
            channel?.invokeMethod("linkRecebido", it)
            linkPendente = null
        }
    }
}
