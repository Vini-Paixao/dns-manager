package com.dnsmanager.dns_manager

import android.content.Context
import android.content.SharedPreferences
import android.graphics.drawable.Icon
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * TileService para Quick Settings do Android.
 * 
 * Permite ao usuário ativar/desativar DNS Privado diretamente
 * pela central de notificações sem abrir o app.
 * 
 * O tile é adicionado automaticamente ao painel de tiles
 * quando o app é instalado. O usuário precisa adicionar
 * manualmente à área de acesso rápido.
 */
class DnsTileService : TileService() {
    
    companion object {
        private const val PREFS_NAME = "dns_manager_prefs"
        private const val KEY_LAST_HOSTNAME = "last_hostname"
        private const val DEFAULT_HOSTNAME = "dns.google"
    }
    
    private val prefs: SharedPreferences by lazy {
        applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    /**
     * Chamado quando o tile se torna visível
     */
    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }
    
    /**
     * Chamado quando o usuário clica no tile
     */
    override fun onClick() {
        super.onClick()
        
        // Verifica permissão antes de fazer qualquer alteração
        if (!DnsHelper.hasPermission(applicationContext)) {
            // Se não tem permissão, apenas atualiza o tile para mostrar erro
            qsTile?.let { tile ->
                tile.state = Tile.STATE_UNAVAILABLE
                tile.subtitle = "Permissão negada"
                tile.updateTile()
            }
            return
        }
        
        // Toggle: se está ativo, desativa; se está inativo, ativa
        val isCurrentlyEnabled = DnsHelper.isDnsEnabled(applicationContext)
        
        if (isCurrentlyEnabled) {
            // Desativa DNS privado
            DnsHelper.disablePrivateDns(applicationContext)
        } else {
            // Ativa DNS privado com o último hostname usado
            val hostname = getLastUsedHostname()
            DnsHelper.setPrivateDns(applicationContext, hostname)
        }
        
        // Atualiza o estado visual do tile
        updateTileState()
    }
    
    /**
     * Atualiza o estado visual do tile baseado no status atual do DNS
     */
    private fun updateTileState() {
        qsTile?.let { tile ->
            val status = DnsHelper.getDnsStatus(applicationContext)
            val enabled = status["enabled"] as? Boolean ?: false
            val hostname = status["hostname"] as? String
            
            // Usa o logo do app como ícone
            tile.icon = Icon.createWithResource(this, R.drawable.ic_app_logo)
            
            if (enabled) {
                tile.state = Tile.STATE_ACTIVE
                tile.label = "DNS Privado"
                tile.subtitle = hostname ?: "Ativo"
            } else {
                tile.state = Tile.STATE_INACTIVE
                tile.label = "DNS Privado"
                tile.subtitle = "Desativado"
            }
            
            tile.updateTile()
        }
    }
    
    /**
     * Obtém o último hostname DNS usado ou o padrão
     */
    private fun getLastUsedHostname(): String {
        return prefs.getString(KEY_LAST_HOSTNAME, DEFAULT_HOSTNAME) ?: DEFAULT_HOSTNAME
    }
    
    /**
     * Salva o hostname como último usado
     */
    fun saveLastUsedHostname(hostname: String) {
        prefs.edit().putString(KEY_LAST_HOSTNAME, hostname).apply()
    }
}
