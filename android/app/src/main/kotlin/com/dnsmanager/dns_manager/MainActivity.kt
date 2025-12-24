package com.dnsmanager.dns_manager

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity com Platform Channel para comunicação Flutter ↔ Nativo
 * 
 * Expõe métodos nativos de DNS para o Flutter via MethodChannel
 */
class MainActivity : FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "com.dnsmanager/dns"
        private const val PREFS_NAME = "dns_manager_prefs"
        private const val KEY_LAST_HOSTNAME = "last_hostname"
        private const val KEY_NOTIFICATION_ENABLED = "notification_enabled"
        private const val KEY_NOTIFICATION_INTERVAL = "notification_interval"
    }
    
    private val prefs: SharedPreferences by lazy {
        applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Verifica se tem permissão WRITE_SECURE_SETTINGS
                "hasPermission" -> {
                    val hasPermission = DnsHelper.hasPermission(applicationContext)
                    result.success(hasPermission)
                }
                
                // Obtém status completo do DNS
                "getDnsStatus" -> {
                    val status = DnsHelper.getDnsStatus(applicationContext)
                    result.success(status)
                }
                
                // Configura DNS com hostname específico
                "setDns" -> {
                    val hostname = call.argument<String>("hostname")
                    if (hostname.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "Hostname é obrigatório", null)
                        return@setMethodCallHandler
                    }
                    
                    val success = DnsHelper.setPrivateDns(applicationContext, hostname)
                    if (success) {
                        // Salva o hostname como último usado
                        prefs.edit().putString(KEY_LAST_HOSTNAME, hostname).apply()
                        // Atualiza widgets
                        DnsWidgetProvider.updateAllWidgets(applicationContext)
                        // Atualiza notificação se estiver ativa
                        if (DnsNotificationService.isRunning) {
                            DnsNotificationService.updateNotification(applicationContext, hostname)
                        }
                    }
                    result.success(success)
                }
                
                // Desativa DNS privado
                "disableDns" -> {
                    val success = DnsHelper.disablePrivateDns(applicationContext)
                    if (success) {
                        // Atualiza widgets
                        DnsWidgetProvider.updateAllWidgets(applicationContext)
                        // Para a notificação se estiver ativa
                        stopNotificationService()
                    }
                    result.success(success)
                }
                
                // Obtém último hostname usado
                "getLastHostname" -> {
                    val hostname = prefs.getString(KEY_LAST_HOSTNAME, "dns.google")
                    result.success(hostname)
                }
                
                // Salva hostname como último usado
                "saveLastHostname" -> {
                    val hostname = call.argument<String>("hostname")
                    if (hostname != null) {
                        prefs.edit().putString(KEY_LAST_HOSTNAME, hostname).apply()
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Hostname é obrigatório", null)
                    }
                }
                
                // ========== Métodos de Notificação ==========
                
                // Inicia serviço de notificação persistente
                "startNotificationService" -> {
                    val hostname = call.argument<String>("hostname") ?: prefs.getString(KEY_LAST_HOSTNAME, "dns.google")
                    val serverName = call.argument<String>("serverName") ?: "DNS Privado"
                    val interval = call.argument<Int>("interval") ?: 60
                    
                    try {
                        startNotificationService(hostname!!, serverName, interval)
                        prefs.edit()
                            .putBoolean(KEY_NOTIFICATION_ENABLED, true)
                            .putInt(KEY_NOTIFICATION_INTERVAL, interval)
                            .apply()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Erro ao iniciar serviço: ${e.message}", null)
                    }
                }
                
                // Para serviço de notificação
                "stopNotificationService" -> {
                    try {
                        stopNotificationService()
                        prefs.edit().putBoolean(KEY_NOTIFICATION_ENABLED, false).apply()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Erro ao parar serviço: ${e.message}", null)
                    }
                }
                
                // Verifica se notificação está ativa
                "isNotificationActive" -> {
                    result.success(DnsNotificationService.isRunning)
                }
                
                // Atualiza intervalo de polling
                "setNotificationInterval" -> {
                    val interval = call.argument<Int>("interval")
                    if (interval == null || interval < 10) {
                        result.error("INVALID_ARGUMENT", "Intervalo inválido (mínimo 10s)", null)
                        return@setMethodCallHandler
                    }
                    
                    prefs.edit().putInt(KEY_NOTIFICATION_INTERVAL, interval).apply()
                    
                    if (DnsNotificationService.isRunning) {
                        DnsNotificationService.setPollingInterval(applicationContext, interval)
                    }
                    result.success(true)
                }
                
                // Obtém intervalo de polling atual
                "getNotificationInterval" -> {
                    val interval = prefs.getInt(KEY_NOTIFICATION_INTERVAL, 60)
                    result.success(interval)
                }
                
                // Verifica se notificações estão habilitadas nas preferências
                "isNotificationEnabled" -> {
                    val enabled = prefs.getBoolean(KEY_NOTIFICATION_ENABLED, false)
                    result.success(enabled)
                }
                
                // Atualiza hostname na notificação
                "updateNotificationHostname" -> {
                    val hostname = call.argument<String>("hostname")
                    if (hostname.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "Hostname é obrigatório", null)
                        return@setMethodCallHandler
                    }
                    
                    if (DnsNotificationService.isRunning) {
                        DnsNotificationService.updateNotification(applicationContext, hostname)
                    }
                    result.success(true)
                }
                
                // Testa latência do DNS
                "testDnsLatency" -> {
                    val hostname = call.argument<String>("hostname")
                    if (hostname.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "Hostname é obrigatório", null)
                        return@setMethodCallHandler
                    }
                    
                    Thread {
                        val latency = DnsNotificationService.testLatency(hostname)
                        runOnUiThread {
                            result.success(latency)
                        }
                    }.start()
                }
                
                // Obtém versão do Android (útil para verificações de compatibilidade)
                "getAndroidSdkVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                
                // Abre configurações de desenvolvedor
                "openDeveloperSettings" -> {
                    try {
                        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        applicationContext.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", "Não foi possível abrir configurações: ${e.message}", null)
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Inicia o serviço de notificação persistente
     */
    private fun startNotificationService(hostname: String, serverName: String, interval: Int) {
        val serviceIntent = Intent(applicationContext, DnsNotificationService::class.java).apply {
            action = DnsNotificationService.ACTION_START
            putExtra(DnsNotificationService.EXTRA_HOSTNAME, hostname)
            putExtra(DnsNotificationService.EXTRA_SERVER_NAME, serverName)
            putExtra(DnsNotificationService.EXTRA_INTERVAL, interval)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(serviceIntent)
        } else {
            applicationContext.startService(serviceIntent)
        }
    }
    
    /**
     * Para o serviço de notificação
     */
    private fun stopNotificationService() {
        val serviceIntent = Intent(applicationContext, DnsNotificationService::class.java).apply {
            action = DnsNotificationService.ACTION_STOP
        }
        applicationContext.startService(serviceIntent)
    }
}
