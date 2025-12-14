import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// Chaves para persistência das configurações
const String _keyNotificationEnabled = 'notification_enabled';
const String _keyLatencyInterval = 'latency_interval';
const String _keyServerName = 'notification_server_name';
const String _keyHostname = 'notification_hostname';

/// Estado das configurações de notificação
class NotificationState {
  final bool isEnabled;
  final int intervalSeconds;
  final bool isLoading;
  final String? activeServerName;
  final String? activeHostname;

  const NotificationState({
    this.isEnabled = false,
    this.intervalSeconds = 60,
    this.isLoading = false,
    this.activeServerName,
    this.activeHostname,
  });

  NotificationState copyWith({
    bool? isEnabled,
    int? intervalSeconds,
    bool? isLoading,
    String? activeServerName,
    String? activeHostname,
  }) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      isLoading: isLoading ?? this.isLoading,
      activeServerName: activeServerName ?? this.activeServerName,
      activeHostname: activeHostname ?? this.activeHostname,
    );
  }
}

/// Notifier para gerenciar estado das notificações
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    _loadSettings();
  }

  /// Carrega configurações salvas
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyNotificationEnabled) ?? false;
      final interval = prefs.getInt(_keyLatencyInterval) ?? 60;
      final serverName = prefs.getString(_keyServerName);
      final hostname = prefs.getString(_keyHostname);
      
      // Verifica se o serviço nativo está realmente ativo
      final isActive = await NotificationService.isNotificationActive();
      
      state = state.copyWith(
        isEnabled: enabled && isActive,
        intervalSeconds: interval,
        activeServerName: serverName,
        activeHostname: hostname,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Salva configurações
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationEnabled, state.isEnabled);
    await prefs.setInt(_keyLatencyInterval, state.intervalSeconds);
    if (state.activeServerName != null) {
      await prefs.setString(_keyServerName, state.activeServerName!);
    }
    if (state.activeHostname != null) {
      await prefs.setString(_keyHostname, state.activeHostname!);
    }
  }

  /// Log condicional (apenas em modo debug)
  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Ativa notificação persistente
  /// 
  /// Se [serverName] e [hostname] não forem fornecidos, usa os valores salvos
  /// ou valores padrão
  Future<bool> enableNotification({
    String? serverName,
    String? hostname,
  }) async {
    final name = serverName ?? state.activeServerName ?? 'DNS Privado';
    final host = hostname ?? state.activeHostname ?? 'dns.google';
    
    _log('🔔 NotificationNotifier: enableNotification chamado');
    _log('📌 Server: $name, Host: $host, Interval: ${state.intervalSeconds}s');
    
    state = state.copyWith(isLoading: true);
    
    final success = await NotificationService.startPersistentNotification(
      serverName: name,
      hostname: host,
      intervalSeconds: state.intervalSeconds,
    );
    
    _log('📋 NotificationNotifier: Resultado = $success');
    
    if (success) {
      state = state.copyWith(
        isEnabled: true,
        activeServerName: name,
        activeHostname: host,
        isLoading: false,
      );
      await _saveSettings();
      _log('✅ NotificationNotifier: Notificação ativada com sucesso');
    } else {
      state = state.copyWith(isLoading: false);
      _log('❌ NotificationNotifier: Falha ao ativar notificação');
    }
    
    return success;
  }

  /// Desativa notificação persistente
  Future<bool> disableNotification() async {
    state = state.copyWith(isLoading: true);
    
    final success = await NotificationService.stopPersistentNotification();
    
    state = state.copyWith(
      isEnabled: false,
      isLoading: false,
    );
    
    await _saveSettings();
    
    return success;
  }

  /// Atualiza intervalo de polling
  Future<void> setInterval(int seconds) async {
    state = state.copyWith(intervalSeconds: seconds);
    await _saveSettings();
    
    // Se notificação está ativa, atualiza o intervalo no serviço
    if (state.isEnabled) {
      await NotificationService.setNotificationInterval(seconds);
    }
  }

  /// Atualiza informações do servidor na notificação
  Future<void> updateServerInfo({
    required String serverName,
    required String hostname,
  }) async {
    if (!state.isEnabled) return;
    
    state = state.copyWith(
      activeServerName: serverName,
      activeHostname: hostname,
    );
    
    await NotificationService.updatePersistentNotification(
      serverName: serverName,
      hostname: hostname,
    );
    
    await _saveSettings();
  }

  /// Envia notificação de falha de DNS
  Future<void> notifyDnsFailure({
    required String serverName,
    required String hostname,
  }) async {
    await NotificationService.showDnsFailureNotification(
      serverName: serverName,
      hostname: hostname,
    );
  }

  /// Envia notificação de DNS desativado
  Future<void> notifyDnsDisabled() async {
    await NotificationService.showDnsDisabledNotification();
  }
}

/// Provider para estado das notificações
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

/// Provider para intervalo selecionado
final selectedIntervalProvider = Provider<LatencyInterval>((ref) {
  final state = ref.watch(notificationProvider);
  return LatencyInterval.fromSeconds(state.intervalSeconds);
});

/// Provider para verificar permissão de notificação
final hasNotificationPermissionProvider = FutureProvider<bool>((ref) async {
  return await NotificationService.hasNotificationPermission();
});
