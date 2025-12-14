package com.dnsmanager.dns_manager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import androidx.core.content.ContextCompat

/**
 * Widget Provider para exibir e controlar o status do DNS na home screen.
 * 
 * Funcionalidades:
 * - Exibe o status atual do DNS (ativo/inativo)
 * - Mostra o servidor DNS ativo
 * - Permite toggle rápido do DNS
 */
class DnsWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val ACTION_TOGGLE_DNS = "com.dnsmanager.dns_manager.ACTION_TOGGLE_DNS"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_LAST_HOSTNAME = "flutter.last_active_hostname"
        private const val KEY_LAST_SERVER_NAME = "flutter.last_active_server_name"

        /**
         * Força atualização de todos os widgets
         */
        fun updateAllWidgets(context: Context) {
            val intent = Intent(context, DnsWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val widgetManager = AppWidgetManager.getInstance(context)
            val widgetComponent = ComponentName(context, DnsWidgetProvider::class.java)
            val widgetIds = widgetManager.getAppWidgetIds(widgetComponent)
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == ACTION_TOGGLE_DNS) {
            toggleDns(context)
            // Atualiza todos os widgets após toggle
            updateAllWidgets(context)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.dns_widget)
        
        // Obtém status atual
        val dnsStatus = DnsHelper.getDnsStatus(context)
        val isEnabled = dnsStatus["enabled"] as Boolean
        val hostname = dnsStatus["hostname"] as? String
        
        // Obtém nome amigável do servidor das SharedPreferences
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val serverName = if (isEnabled && hostname != null) {
            getServerDisplayName(prefs, hostname)
        } else {
            "Desativado"
        }
        
        // Configura textos
        views.setTextViewText(R.id.widget_status_text, if (isEnabled) "DNS Ativo" else "DNS Inativo")
        views.setTextViewText(R.id.widget_server_name, serverName)
        
        // Configura cores baseado no status (usando recursos de cor que respeitam o tema do sistema)
        val statusColor = if (isEnabled) {
            ContextCompat.getColor(context, R.color.widget_status_active)
        } else {
            ContextCompat.getColor(context, R.color.widget_status_inactive)
        }
        views.setTextColor(R.id.widget_status_text, statusColor)
        
        // Configura cor do nome do servidor (respeita o tema do sistema)
        val serverNameColor = ContextCompat.getColor(context, R.color.widget_text_secondary)
        views.setTextColor(R.id.widget_server_name, serverNameColor)
        
        // Configura ícone
        views.setImageViewResource(
            R.id.widget_icon,
            if (isEnabled) R.drawable.ic_dns_active else R.drawable.ic_dns_inactive
        )
        
        // Intent para toggle
        val toggleIntent = Intent(context, DnsWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_DNS
        }
        val togglePendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_toggle_button, togglePendingIntent)
        
        // Intent para abrir o app
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            1,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)
        
        // Atualiza widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getServerDisplayName(prefs: SharedPreferences, hostname: String): String {
        // Tenta obter o nome salvo
        val savedName = prefs.getString(KEY_LAST_SERVER_NAME, null)
        val savedHostname = prefs.getString(KEY_LAST_HOSTNAME, null)
        
        if (savedName != null && savedHostname == hostname) {
            return savedName
        }
        
        // Fallback: mapeia hostnames conhecidos para nomes amigáveis
        return when {
            hostname.contains("cloudflare") -> "Cloudflare"
            hostname.contains("google") -> "Google"
            hostname.contains("quad9") -> "Quad9"
            hostname.contains("adguard") -> "AdGuard"
            hostname.contains("nextdns") -> "NextDNS"
            hostname.contains("opendns") -> "OpenDNS"
            else -> hostname.take(20)
        }
    }

    private fun toggleDns(context: Context) {
        val isEnabled = DnsHelper.isDnsEnabled(context)
        
        if (isEnabled) {
            // Desativa DNS
            DnsHelper.disablePrivateDns(context)
        } else {
            // Ativa DNS com último servidor usado
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val lastHostname = prefs.getString(KEY_LAST_HOSTNAME, "dns.google")
            DnsHelper.setPrivateDns(context, lastHostname ?: "dns.google")
        }
    }
}
