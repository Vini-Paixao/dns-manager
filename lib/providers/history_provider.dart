import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usage_record.dart';
import '../services/history_service.dart';

/// Provider para o serviço de histórico
final historyServiceProvider = Provider<HistoryService>((ref) {
  final service = HistoryService();
  service.init();
  return service;
});

/// Estado do histórico de uso
class HistoryState {
  final List<UsageRecord> records;
  final UsageStatistics? statistics;
  final bool isLoading;
  final String? error;
  final UsageRecord? activeRecord;

  const HistoryState({
    this.records = const [],
    this.statistics,
    this.isLoading = false,
    this.error,
    this.activeRecord,
  });

  HistoryState copyWith({
    List<UsageRecord>? records,
    UsageStatistics? statistics,
    bool? isLoading,
    String? error,
    UsageRecord? activeRecord,
  }) {
    return HistoryState(
      records: records ?? this.records,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeRecord: activeRecord ?? this.activeRecord,
    );
  }
}

/// Notifier para gerenciar histórico de uso
class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryService _historyService;

  HistoryNotifier(this._historyService) : super(const HistoryState()) {
    loadHistory();
  }

  /// Carrega histórico completo
  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final records = await _historyService.loadHistory();
      final statistics = await _historyService.calculateStatistics();
      final activeRecord = await _historyService.getActiveRecord();
      
      state = state.copyWith(
        records: records,
        statistics: statistics,
        activeRecord: activeRecord,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar histórico: $e',
      );
    }
  }

  /// Carrega histórico recente (últimos N dias)
  Future<void> loadRecentHistory({int days = 7}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final records = await _historyService.loadRecentHistory(days: days);
      final statistics = UsageStatistics.fromRecords(records);
      
      state = state.copyWith(
        records: records,
        statistics: statistics,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar histórico: $e',
      );
    }
  }

  /// Registra ativação de servidor
  Future<UsageRecord?> recordActivation({
    required String serverId,
    required String serverName,
    required String hostname,
    int? latencyMs,
  }) async {
    try {
      final record = await _historyService.recordActivation(
        serverId: serverId,
        serverName: serverName,
        hostname: hostname,
        latencyMs: latencyMs,
      );
      
      await loadHistory();
      return record;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao registrar ativação: $e');
      return null;
    }
  }

  /// Registra desativação
  Future<UsageRecord?> recordDeactivation() async {
    try {
      final record = await _historyService.recordDeactivation();
      await loadHistory();
      return record;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao registrar desativação: $e');
      return null;
    }
  }

  /// Registra falha de conexão
  Future<void> recordFailure({
    required String serverId,
    required String serverName,
    required String hostname,
    required String failureReason,
  }) async {
    try {
      await _historyService.recordFailure(
        serverId: serverId,
        serverName: serverName,
        hostname: hostname,
        failureReason: failureReason,
      );
      await loadHistory();
    } catch (e) {
      state = state.copyWith(error: 'Erro ao registrar falha: $e');
    }
  }

  /// Limpa histórico antigo
  Future<int> cleanupOldRecords() async {
    final count = await _historyService.cleanupOldRecords();
    await loadHistory();
    return count;
  }

  /// Limpa todo o histórico
  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    state = const HistoryState();
  }

  /// Exporta histórico
  Future<String> exportHistory() async {
    return await _historyService.exportHistory();
  }

  /// Importa histórico
  Future<bool> importHistory(String jsonString) async {
    final success = await _historyService.importHistory(jsonString);
    if (success) {
      await loadHistory();
    }
    return success;
  }

  /// Obtém histórico de um servidor específico
  Future<List<UsageRecord>> getServerHistory(String serverId) async {
    return await _historyService.getHistoryByServer(serverId);
  }
}

/// Provider para o histórico de uso
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final historyService = ref.read(historyServiceProvider);
  return HistoryNotifier(historyService);
});

/// Provider para estatísticas de uso
final usageStatisticsProvider = Provider<UsageStatistics?>((ref) {
  return ref.watch(historyProvider).statistics;
});

/// Provider para registro ativo
final activeRecordProvider = Provider<UsageRecord?>((ref) {
  return ref.watch(historyProvider).activeRecord;
});

/// Provider para histórico recente (últimos 7 dias)
final recentHistoryProvider = Provider<List<UsageRecord>>((ref) {
  final history = ref.watch(historyProvider).records;
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  return history.where((r) => r.activatedAt.isAfter(weekAgo)).toList();
});

/// Provider para histórico filtrado por servidor
final serverHistoryProvider = FutureProvider.family<List<UsageRecord>, String>((ref, serverId) async {
  final historyService = ref.read(historyServiceProvider);
  return await historyService.getHistoryByServer(serverId);
});
