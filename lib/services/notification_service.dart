import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Intervalos disponíveis para polling de latência (em segundos)
class LatencyInterval {
  final int seconds;
  final String label;
  final String description;

  const LatencyInterval({
    required this.seconds,
    required this.label,
    required this.description,
  });

  static const List<LatencyInterval> available = [
    LatencyInterval(seconds: 10, label: '10s', description: 'Alto consumo de bateria'),
    LatencyInterval(seconds: 30, label: '30s', description: 'Consumo moderado'),
    LatencyInterval(seconds: 60, label: '1min', description: 'Recomendado'),
    LatencyInterval(seconds: 120, label: '2min', description: 'Baixo consumo'),
    LatencyInterval(seconds: 300, label: '5min', description: 'Mínimo consumo'),
  ];

  static LatencyInterval fromSeconds(int seconds) {
    return available.firstWhere(
      (i) => i.seconds == seconds,
      orElse: () => available[2], // 60s como padrão
    );
  }
}

/// Configurações da notificação persistente
class NotificationSettings {
  final bool enabled;
  final int intervalSeconds;
  final String? serverName;
  final String? hostname;

  const NotificationSettings({
    this.enabled = false,
    this.intervalSeconds = 60,
    this.serverName,
    this.hostname,
  });

  NotificationSettings copyWith({
    bool? enabled,
    int? intervalSeconds,
    String? serverName,
    String? hostname,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      serverName: serverName ?? this.serverName,
      hostname: hostname ?? this.hostname,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'intervalSeconds': intervalSeconds,
    'serverName': serverName,
    'hostname': hostname,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? false,
      intervalSeconds: json['intervalSeconds'] as int? ?? 60,
      serverName: json['serverName'] as String?,
      hostname: json['hostname'] as String?,
    );
  }
}

/// Serviço para gerenciar notificações persistentes
/// 
/// Comunica com o DnsNotificationService nativo via Platform Channel
class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.dnsmanager/dns');
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  
  /// Log condicional (apenas em modo debug)
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Inicializa o serviço de notificações
  static Future<void> initialize() async {
    if (_initialized) return;
    
    _log('📱 NotificationService: Inicializando...');
    
    const androidSettings = AndroidInitializationSettings('@drawable/ic_dns_tile');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    _initialized = true;
    _log('✅ NotificationService: Inicializado com sucesso');
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Callback quando usuário toca na notificação
    _log('Notificação tocada: ${response.payload}');
  }

  /// Solicita permissão de notificação (obrigatório no Android 13+)
  static Future<bool> requestNotificationPermission() async {
    _log('🔐 NotificationService: Verificando permissão de notificação...');
    
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      _log('📋 NotificationService: Status atual: $status');
      
      if (status.isGranted) {
        _log('✅ NotificationService: Permissão já concedida');
        return true;
      }
      
      if (status.isDenied) {
        _log('🔔 NotificationService: Solicitando permissão...');
        final result = await Permission.notification.request();
        _log('📋 NotificationService: Resultado: $result');
        return result.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        _log('⚠️ NotificationService: Permissão negada permanentemente, abrindo configurações...');
        await openAppSettings();
        return false;
      }
    }
    return true;
  }

  /// Verifica se tem permissão de notificação
  static Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  /// Inicia a notificação persistente com status do DNS
  static Future<bool> startPersistentNotification({
    required String serverName,
    required String hostname,
    int intervalSeconds = 60,
  }) async {
    _log('🚀 NotificationService: Iniciando notificação persistente...');
    _log('📌 Server: $serverName, Hostname: $hostname, Interval: ${intervalSeconds}s');
    
    try {
      // Solicita permissão de notificação primeiro
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        _log('❌ NotificationService: Permissão de notificação negada');
        return false;
      }
      
      _log('📡 NotificationService: Chamando Platform Channel...');
      final result = await _channel.invokeMethod<bool>('startNotificationService', {
        'serverName': serverName,
        'hostname': hostname,
        'interval': intervalSeconds,
      });
      _log('✅ NotificationService: Resultado do Platform Channel: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _log('❌ NotificationService: Erro ao iniciar notificação: ${e.message}');
      _log('❌ Stack: ${e.stacktrace}');
      return false;
    }
  }

  /// Para a notificação persistente
  static Future<bool> stopPersistentNotification() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopNotificationService');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Erro ao parar notificação: ${e.message}');
      return false;
    }
  }

  /// Atualiza o conteúdo da notificação persistente
  static Future<bool> updatePersistentNotification({
    required String serverName,
    required String hostname,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateNotificationHostname', {
        'hostname': hostname,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Erro ao atualizar notificação: ${e.message}');
      return false;
    }
  }

  /// Verifica se a notificação persistente está ativa
  static Future<bool> isNotificationActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNotificationActive');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Erro ao verificar notificação: ${e.message}');
      return false;
    }
  }

  /// Verifica se notificações estão habilitadas nas preferências
  static Future<bool> isNotificationEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNotificationEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Erro ao verificar preferência: ${e.message}');
      return false;
    }
  }

  /// Define o intervalo de polling da latência
  static Future<bool> setNotificationInterval(int intervalSeconds) async {
    try {
      final result = await _channel.invokeMethod<bool>('setNotificationInterval', {
        'interval': intervalSeconds,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Erro ao definir intervalo: ${e.message}');
      return false;
    }
  }

  /// Obtém o intervalo de polling atual
  static Future<int> getNotificationInterval() async {
    try {
      final result = await _channel.invokeMethod<int>('getNotificationInterval');
      return result ?? 60;
    } on PlatformException catch (e) {
      debugPrint('Erro ao obter intervalo: ${e.message}');
      return 60;
    }
  }

  /// Envia notificação de falha de conexão DNS
  static Future<void> showDnsFailureNotification({
    required String serverName,
    required String hostname,
  }) async {
    await initialize();
    
    const androidDetails = AndroidNotificationDetails(
      'dns_failure_channel',
      'Alertas de DNS',
      channelDescription: 'Notificações sobre falhas de conexão DNS',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_dns_tile',
      playSound: true,
      enableVibration: true,
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      2001, // ID diferente da notificação persistente
      '⚠️ Falha na conexão DNS',
      'O servidor $serverName ($hostname) não está respondendo. Considere trocar o servidor DNS.',
      details,
      payload: 'dns_failure',
    );
  }

  /// Envia notificação de DNS desativado externamente
  static Future<void> showDnsDisabledNotification() async {
    await initialize();
    
    const androidDetails = AndroidNotificationDetails(
      'dns_status_channel',
      'Status do DNS',
      channelDescription: 'Notificações sobre mudanças no status do DNS',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_dns_tile',
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      2002,
      'DNS Privado desativado',
      'O DNS privado foi desativado. Toque para reativar.',
      details,
      payload: 'dns_disabled',
    );
  }

  /// Cancela todas as notificações de alerta (não a persistente)
  static Future<void> cancelAlertNotifications() async {
    await _localNotifications.cancel(2001);
    await _localNotifications.cancel(2002);
  }
}
