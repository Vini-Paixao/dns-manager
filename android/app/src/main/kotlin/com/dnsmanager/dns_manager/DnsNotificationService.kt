package com.dnsmanager.dns_manager

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import java.net.InetSocketAddress
import java.net.Socket

/**
 * Foreground Service para manter notificação persistente com status do DNS
 * 
 * Exibe uma notificação fixa mostrando o servidor DNS ativo e a latência em tempo real
 */
class DnsNotificationService : Service() {
    
    companion object {
        const val CHANNEL_ID = "dns_notification_channel"
        const val NOTIFICATION_ID = 1001
        const val PREFS_NAME = "dns_notification_prefs"
        
        const val KEY_ENABLED = "notification_enabled"
        const val KEY_INTERVAL = "latency_interval"
        const val KEY_SERVER_NAME = "server_name"
        const val KEY_HOSTNAME = "hostname"
        const val KEY_CONNECTION_START_TIME = "connection_start_time"
        
        const val ACTION_START = "com.dnsmanager.START_NOTIFICATION"
        const val ACTION_STOP = "com.dnsmanager.STOP_NOTIFICATION"
        const val ACTION_UPDATE = "com.dnsmanager.UPDATE_NOTIFICATION"
        const val ACTION_SET_INTERVAL = "com.dnsmanager.SET_INTERVAL"
        
        const val EXTRA_SERVER_NAME = "server_name"
        const val EXTRA_HOSTNAME = "hostname"
        const val EXTRA_INTERVAL = "interval"
        
        // Intervalos disponíveis (em segundos)
        val INTERVALS = listOf(10, 30, 60, 120, 300)
        const val DEFAULT_INTERVAL = 30
        
        @Volatile
        var isRunning = false
            private set
        
        fun isServiceRunning(): Boolean = isRunning
        
        fun startService(context: Context, serverName: String, hostname: String, intervalSeconds: Int = DEFAULT_INTERVAL) {
            val intent = Intent(context, DnsNotificationService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_SERVER_NAME, serverName)
                putExtra(EXTRA_HOSTNAME, hostname)
                putExtra(EXTRA_INTERVAL, intervalSeconds)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, DnsNotificationService::class.java).apply {
                action = ACTION_STOP
            }
            context.stopService(intent)
        }
        
        fun updateNotification(context: Context, hostname: String) {
            if (!isRunning) return
            
            val intent = Intent(context, DnsNotificationService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_HOSTNAME, hostname)
            }
            context.startService(intent)
        }
        
        fun updateNotification(context: Context, serverName: String, hostname: String) {
            if (!isRunning) return
            
            val intent = Intent(context, DnsNotificationService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_SERVER_NAME, serverName)
                putExtra(EXTRA_HOSTNAME, hostname)
            }
            context.startService(intent)
        }
        
        fun setPollingInterval(context: Context, intervalSeconds: Int) {
            if (!isRunning) return
            
            val intent = Intent(context, DnsNotificationService::class.java).apply {
                action = ACTION_SET_INTERVAL
                putExtra(EXTRA_INTERVAL, intervalSeconds)
            }
            context.startService(intent)
        }
        
        /**
         * Testa latência para um hostname DNS (porta 853 - DoT)
         * @return latência em ms ou -1 se falhou
         */
        fun testLatency(hostname: String): Int {
            if (hostname.isEmpty()) return -1
            
            return try {
                val socket = Socket()
                val startTime = System.currentTimeMillis()
                
                socket.connect(InetSocketAddress(hostname, 853), 5000)
                socket.close()
                
                (System.currentTimeMillis() - startTime).toInt()
            } catch (e: Exception) {
                -1
            }
        }
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var latencyRunnable: Runnable? = null
    
    private var currentServerName = ""
    private var currentHostname = ""
    private var currentLatency: Int? = null
    private var intervalSeconds = DEFAULT_INTERVAL
    private var connectionStartTime: Long = 0L
    
    private val prefs: SharedPreferences by lazy {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        
        // Recupera dados salvos (para caso de reinício do serviço)
        currentServerName = prefs.getString(KEY_SERVER_NAME, "DNS") ?: "DNS"
        currentHostname = prefs.getString(KEY_HOSTNAME, "") ?: ""
        intervalSeconds = prefs.getInt(KEY_INTERVAL, DEFAULT_INTERVAL)
        connectionStartTime = prefs.getLong(KEY_CONNECTION_START_TIME, System.currentTimeMillis())
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                currentServerName = intent.getStringExtra(EXTRA_SERVER_NAME) ?: "DNS"
                currentHostname = intent.getStringExtra(EXTRA_HOSTNAME) ?: ""
                intervalSeconds = intent.getIntExtra(EXTRA_INTERVAL, DEFAULT_INTERVAL)
                connectionStartTime = System.currentTimeMillis()
                
                // Salva configurações
                prefs.edit().apply {
                    putBoolean(KEY_ENABLED, true)
                    putString(KEY_SERVER_NAME, currentServerName)
                    putString(KEY_HOSTNAME, currentHostname)
                    putInt(KEY_INTERVAL, intervalSeconds)
                    putLong(KEY_CONNECTION_START_TIME, connectionStartTime)
                    apply()
                }
                
                startForegroundNotification()
                startLatencyPolling()
                isRunning = true
            }
            
            ACTION_STOP -> {
                stopLatencyPolling()
                prefs.edit().putBoolean(KEY_ENABLED, false).apply()
                isRunning = false
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            
            ACTION_UPDATE -> {
                val newServerName = intent.getStringExtra(EXTRA_SERVER_NAME)
                val newHostname = intent.getStringExtra(EXTRA_HOSTNAME)
                
                // Se trocou de servidor, reinicia o contador de tempo
                val serverChanged = newServerName != null && newServerName != currentServerName
                
                if (newServerName != null) currentServerName = newServerName
                if (newHostname != null) currentHostname = newHostname
                
                // Se trocou de servidor, reinicia o tempo de conexão
                if (serverChanged) {
                    connectionStartTime = System.currentTimeMillis()
                }
                
                // Atualiza configurações
                prefs.edit().apply {
                    putString(KEY_SERVER_NAME, currentServerName)
                    putString(KEY_HOSTNAME, currentHostname)
                    if (serverChanged) {
                        putLong(KEY_CONNECTION_START_TIME, connectionStartTime)
                    }
                    apply()
                }
                
                // Testa latência imediatamente e atualiza notificação
                Thread {
                    currentLatency = Companion.testLatency(currentHostname)
                    handler.post { updateNotificationContent() }
                }.start()
            }
            
            ACTION_SET_INTERVAL -> {
                val newInterval = intent.getIntExtra(EXTRA_INTERVAL, DEFAULT_INTERVAL)
                if (newInterval != intervalSeconds) {
                    intervalSeconds = newInterval
                    prefs.edit().putInt(KEY_INTERVAL, intervalSeconds).apply()
                    
                    // Reinicia polling com novo intervalo
                    startLatencyPolling()
                }
            }
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        stopLatencyPolling()
        isRunning = false
        super.onDestroy()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Status do DNS",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Mostra o status atual do DNS privado e a latência"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun startForegroundNotification() {
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
    }
    
    private fun buildNotification(): Notification {
        // Intent para abrir o app ao tocar na notificação
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Intent para desativar DNS
        val disableIntent = Intent(this, DnsNotificationService::class.java).apply {
            action = ACTION_STOP
        }
        val disablePendingIntent = PendingIntent.getService(
            this, 1, disableIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val latencyText = when {
            currentLatency == null -> "Testando..."
            currentLatency!! < 0 -> "Sem conexão"
            else -> "${currentLatency}ms"
        }
        
        // Calcula tempo de conexão
        val connectionDuration = formatDuration(System.currentTimeMillis() - connectionStartTime)
        
        val contentText = if (currentHostname.isNotEmpty()) {
            "$latencyText • $connectionDuration"
        } else {
            latencyText
        }
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_dns_tile)
            .setContentTitle("🛡️ $currentServerName ativo")
            .setContentText(contentText)
            .setSubText(currentHostname)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Desativar",
                disablePendingIntent
            )
            .build()
    }
    
    /**
     * Formata duração em formato legível (ex: "2h 15min" ou "45min" ou "30s")
     */
    private fun formatDuration(durationMs: Long): String {
        val totalSeconds = durationMs / 1000
        val days = totalSeconds / 86400
        val hours = (totalSeconds % 86400) / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        
        return when {
            days > 0 -> "${days}d ${hours}h"
            hours > 0 -> "${hours}h ${minutes}min"
            minutes > 0 -> "${minutes}min"
            else -> "${seconds}s"
        }
    }
    
    private fun updateNotificationContent() {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification())
    }
    
    private fun startLatencyPolling() {
        stopLatencyPolling()
        
        latencyRunnable = object : Runnable {
            override fun run() {
                // Testa latência em background
                Thread {
                    currentLatency = Companion.testLatency(currentHostname)
                    handler.post { 
                        updateNotificationContent()
                        
                        // Verifica se DNS ainda está ativo
                        if (!DnsHelper.isDnsEnabled(applicationContext)) {
                            // DNS foi desativado externamente
                            sendDnsDisabledBroadcast()
                        }
                    }
                }.start()
                
                // Agenda próximo teste
                handler.postDelayed(this, intervalSeconds * 1000L)
            }
        }
        
        // Testa imediatamente
        handler.post(latencyRunnable!!)
    }
    
    private fun stopLatencyPolling() {
        latencyRunnable?.let { handler.removeCallbacks(it) }
        latencyRunnable = null
    }
    
    private fun sendDnsDisabledBroadcast() {
        // Envia broadcast para o Flutter saber que DNS foi desativado
        val intent = Intent("com.dnsmanager.DNS_STATUS_CHANGED")
        sendBroadcast(intent)
    }
}
