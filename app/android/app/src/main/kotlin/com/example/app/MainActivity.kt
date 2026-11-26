package com.example.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val canalAlertas = "alertas_colmena"
    private var canalFlutter: MethodChannel? = null
    private var aperturaPendiente: Map<String, String>? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        registrarApertura(intent)
    }

    private fun registrarApertura(intent: Intent?) {
        val colmena = intent?.getStringExtra("beecare_colmena") ?: return
        val alerta = intent.getStringExtra("beecare_alerta") ?: return
        intent.removeExtra("beecare_colmena")
        intent.removeExtra("beecare_alerta")
        val datos = mapOf("idColmena" to colmena, "idAlerta" to alerta)
        aperturaPendiente = datos
        canalFlutter?.invokeMethod("abrir", datos, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (aperturaPendiente === datos) aperturaPendiente = null
            }
            override fun error(code: String, message: String?, details: Any?) {}
            override fun notImplemented() {}
        })
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val administrador = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            administrador.createNotificationChannel(NotificationChannel(
                canalAlertas, "Alertas de la colmena", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Alertas ambientales y energeticas de BeeCare" })
        }
        val canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beecare/notificaciones")
        canalFlutter = canal
        registrarApertura(intent)
        canal.setMethodCallHandler { llamada, resultado ->
                if (llamada.method == "aperturaInicial") {
                    val apertura = aperturaPendiente
                    aperturaPendiente = null
                    resultado.success(apertura)
                    return@setMethodCallHandler
                }
                if (llamada.method != "mostrar") {
                    resultado.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val etiqueta = llamada.argument<String>("etiqueta")
                    val apertura = Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra("beecare_colmena", llamada.argument<String>("idColmena"))
                        putExtra("beecare_alerta", llamada.argument<String>("idAlerta"))
                    }
                    val pendiente = PendingIntent.getActivity(this, etiqueta?.hashCode() ?: 0, apertura,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                    val constructor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        Notification.Builder(this, canalAlertas) else Notification.Builder(this)
                    val titulo = llamada.argument<String>("titulo") ?: "BeeCare"
                    val descripcion = llamada.argument<String>("descripcion") ?: ""
                    val aviso = constructor.setSmallIcon(R.drawable.ic_notificacion)
                        .setColor(0xFFF2B51D.toInt())
                        .setContentTitle(titulo).setContentText(descripcion)
                        .setStyle(Notification.BigTextStyle().bigText(descripcion))
                        .setContentIntent(pendiente).setAutoCancel(true)
                        .setPriority(Notification.PRIORITY_HIGH).build()
                    if (etiqueta != null) administrador.notify(etiqueta, 0, aviso)
                    else administrador.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), aviso)
                    resultado.success(null)
                } catch (error: SecurityException) {
                    resultado.error("permiso_notificaciones", "Permite las notificaciones de BeeCare en Android.", null)
                }
            }
    }
}
