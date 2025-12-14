package com.dnsmanager.dns_manager

import android.content.Context
import android.content.SharedPreferences
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
                    }
                    result.success(success)
                }
                
                // Desativa DNS privado
                "disableDns" -> {
                    val success = DnsHelper.disablePrivateDns(applicationContext)
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
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
