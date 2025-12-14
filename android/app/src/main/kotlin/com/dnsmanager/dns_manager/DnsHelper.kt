package com.dnsmanager.dns_manager

import android.content.Context
import android.content.pm.PackageManager
import android.provider.Settings
import android.Manifest

/**
 * Helper class para gerenciar configurações de DNS Privado no Android.
 * 
 * O DNS Privado (DNS over TLS - DoT) foi introduzido no Android 9 (API 28).
 * Esta classe manipula as configurações via Settings.Global.
 * 
 * IMPORTANTE: Requer permissão WRITE_SECURE_SETTINGS que deve ser concedida via ADB:
 * adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS
 */
object DnsHelper {
    
    // Constantes para Settings.Global (DNS privado está em Global, não Secure)
    private const val PRIVATE_DNS_MODE = "private_dns_mode"
    private const val PRIVATE_DNS_SPECIFIER = "private_dns_specifier"
    
    // Modos de DNS Privado
    private const val DNS_MODE_OFF = "off"
    private const val DNS_MODE_OPPORTUNISTIC = "opportunistic"
    private const val DNS_MODE_HOSTNAME = "hostname"
    
    /**
     * Verifica se o app tem permissão WRITE_SECURE_SETTINGS
     */
    fun hasPermission(context: Context): Boolean {
        return context.checkCallingOrSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) == 
            PackageManager.PERMISSION_GRANTED
    }
    
    /**
     * Obtém o modo atual de DNS Privado
     * @return "off", "opportunistic" ou "hostname"
     */
    fun getPrivateDnsMode(context: Context): String {
        return try {
            Settings.Global.getString(context.contentResolver, PRIVATE_DNS_MODE) ?: DNS_MODE_OFF
        } catch (e: Exception) {
            DNS_MODE_OFF
        }
    }
    
    /**
     * Obtém o hostname DNS configurado (quando modo é "hostname")
     */
    fun getPrivateDnsHostname(context: Context): String? {
        return try {
            Settings.Global.getString(context.contentResolver, PRIVATE_DNS_SPECIFIER)
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Verifica se o DNS Privado está ativo com hostname específico
     * Considera ativo apenas quando o modo é "hostname" (servidor específico configurado)
     */
    fun isDnsEnabled(context: Context): Boolean {
        val mode = getPrivateDnsMode(context)
        return mode == DNS_MODE_HOSTNAME
    }
    
    /**
     * Obtém o status completo do DNS Privado
     * @return Map com "enabled" (Boolean), "mode" (String) e "hostname" (String?)
     */
    fun getDnsStatus(context: Context): Map<String, Any?> {
        val mode = getPrivateDnsMode(context)
        val hostname = getPrivateDnsHostname(context)
        // Considera ativo apenas quando tem hostname específico configurado
        val enabled = mode == DNS_MODE_HOSTNAME
        
        return mapOf(
            "enabled" to enabled,
            "mode" to mode,
            "hostname" to hostname
        )
    }
    
    /**
     * Configura o DNS Privado com um hostname específico
     * @param hostname O endereço DoT do servidor DNS (ex: "dns.google")
     * @return true se configurado com sucesso
     */
    fun setPrivateDns(context: Context, hostname: String): Boolean {
        return try {
            if (!hasPermission(context)) {
                android.util.Log.e("DnsHelper", "Sem permissão WRITE_SECURE_SETTINGS")
                return false
            }
            
            // Primeiro define o hostname
            val hostnameResult = Settings.Global.putString(
                context.contentResolver,
                PRIVATE_DNS_SPECIFIER,
                hostname
            )
            android.util.Log.d("DnsHelper", "setPrivateDns hostname=$hostname, result=$hostnameResult")
            
            // Depois ativa o modo hostname
            val modeResult = Settings.Global.putString(
                context.contentResolver,
                PRIVATE_DNS_MODE,
                DNS_MODE_HOSTNAME
            )
            android.util.Log.d("DnsHelper", "setPrivateDns mode=hostname, result=$modeResult")
            
            hostnameResult && modeResult
        } catch (e: Exception) {
            android.util.Log.e("DnsHelper", "Erro ao configurar DNS", e)
            e.printStackTrace()
            false
        }
    }
    
    /**
     * Desativa o DNS Privado
     * @return true se desativado com sucesso
     */
    fun disablePrivateDns(context: Context): Boolean {
        return try {
            if (!hasPermission(context)) {
                android.util.Log.e("DnsHelper", "Sem permissão WRITE_SECURE_SETTINGS")
                return false
            }
            
            val result = Settings.Global.putString(
                context.contentResolver,
                PRIVATE_DNS_MODE,
                DNS_MODE_OFF
            )
            android.util.Log.d("DnsHelper", "disablePrivateDns result=$result")
            
            result
        } catch (e: Exception) {
            android.util.Log.e("DnsHelper", "Erro ao desativar DNS", e)
            e.printStackTrace()
            false
        }
    }
    
    /**
     * Ativa o modo automático/oportunístico de DNS Privado
     * O sistema tentará usar DoT automaticamente se disponível
     * @return true se configurado com sucesso
     */
    fun setOpportunisticDns(context: Context): Boolean {
        return try {
            if (!hasPermission(context)) {
                android.util.Log.e("DnsHelper", "Sem permissão WRITE_SECURE_SETTINGS")
                return false
            }
            
            val result = Settings.Global.putString(
                context.contentResolver,
                PRIVATE_DNS_MODE,
                DNS_MODE_OPPORTUNISTIC
            )
            android.util.Log.d("DnsHelper", "setOpportunisticDns result=$result")
            
            result
        } catch (e: Exception) {
            android.util.Log.e("DnsHelper", "Erro ao configurar DNS oportunístico", e)
            e.printStackTrace()
            false
        }
    }
}
