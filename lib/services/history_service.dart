import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usage_record.dart';

/// Serviço para gerenciar histórico de uso dos servidores DNS
/// 
/// Usa SharedPreferences para persistência local com limpeza automática
class HistoryService {
  static const String _historyKey = 'dns_usage_history';
  static const String _activeRecordKey = 'dns_active_record';
  
  /// Limite máximo de registros no histórico
  static const int maxRecords = 500;
  
  /// Dias para manter no histórico antes da limpeza automática
  static const int retentionDays = 30;

  SharedPreferences? _prefs;

  /// Inicializa o serviço
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Garante que o serviço está inicializado
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  /// Registra ativação de um servidor DNS
  /// 
  /// Cria um novo registro com timestamp de ativação
  Future<UsageRecord> recordActivation({
    required String serverId,
    required String serverName,
    required String hostname,
    int? latencyMs,
  }) async {
    final prefs = await _preferences;
    
    // Finaliza registro anterior se existir
    await finalizeActiveRecord();
    
    // Cria novo registro
    final record = UsageRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serverId: serverId,
      serverName: serverName,
      hostname: hostname,
      activatedAt: DateTime.now(),
      latencyMs: latencyMs,
    );
    
    // Salva como registro ativo
    await prefs.setString(_activeRecordKey, jsonEncode(record.toJson()));
    
    // Adiciona ao histórico
    await _addToHistory(record);
    
    return record;
  }

  /// Registra desativação do servidor atual
  Future<UsageRecord?> recordDeactivation() async {
    return await finalizeActiveRecord();
  }

  /// Registra falha de conexão
  Future<void> recordFailure({
    required String serverId,
    required String serverName,
    required String hostname,
    required String failureReason,
  }) async {
    final record = UsageRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serverId: serverId,
      serverName: serverName,
      hostname: hostname,
      activatedAt: DateTime.now(),
      deactivatedAt: DateTime.now(),
      wasSuccessful: false,
      failureReason: failureReason,
    );
    
    await _addToHistory(record);
  }

  /// Finaliza o registro ativo (quando DNS é desativado)
  Future<UsageRecord?> finalizeActiveRecord() async {
    final prefs = await _preferences;
    final activeJson = prefs.getString(_activeRecordKey);
    
    if (activeJson == null) return null;
    
    try {
      final activeRecord = UsageRecord.fromJson(jsonDecode(activeJson));
      final finalized = activeRecord.copyWith(
        deactivatedAt: DateTime.now(),
      );
      
      // Atualiza no histórico
      await _updateInHistory(finalized);
      
      // Remove registro ativo
      await prefs.remove(_activeRecordKey);
      
      return finalized;
    } catch (e) {
      debugPrint('Erro ao finalizar registro ativo: $e');
      await prefs.remove(_activeRecordKey);
      return null;
    }
  }

  /// Obtém o registro ativo atual (se houver)
  Future<UsageRecord?> getActiveRecord() async {
    final prefs = await _preferences;
    final activeJson = prefs.getString(_activeRecordKey);
    
    if (activeJson == null) return null;
    
    try {
      return UsageRecord.fromJson(jsonDecode(activeJson));
    } catch (e) {
      debugPrint('Erro ao ler registro ativo: $e');
      return null;
    }
  }

  /// Carrega todo o histórico
  Future<List<UsageRecord>> loadHistory() async {
    final prefs = await _preferences;
    final historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      final records = decoded
          .map((json) => UsageRecord.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Ordena por data mais recente primeiro
      records.sort((a, b) => b.activatedAt.compareTo(a.activatedAt));
      
      return records;
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
      return [];
    }
  }

  /// Carrega histórico filtrado por período
  Future<List<UsageRecord>> loadHistoryByPeriod({
    required DateTime start,
    DateTime? end,
  }) async {
    final history = await loadHistory();
    final endDate = end ?? DateTime.now();
    
    return history.where((record) {
      return record.activatedAt.isAfter(start) && 
             record.activatedAt.isBefore(endDate);
    }).toList();
  }

  /// Carrega histórico dos últimos N dias
  Future<List<UsageRecord>> loadRecentHistory({int days = 7}) async {
    final start = DateTime.now().subtract(Duration(days: days));
    return loadHistoryByPeriod(start: start);
  }

  /// Calcula estatísticas de uso
  Future<UsageStatistics> calculateStatistics() async {
    final history = await loadHistory();
    return UsageStatistics.fromRecords(history);
  }

  /// Calcula estatísticas por período
  Future<UsageStatistics> calculateStatisticsByPeriod({
    required DateTime start,
    DateTime? end,
  }) async {
    final history = await loadHistoryByPeriod(start: start, end: end);
    return UsageStatistics.fromRecords(history);
  }

  /// Limpa histórico antigo (limpeza automática)
  Future<int> cleanupOldRecords() async {
    final history = await loadHistory();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    final filtered = history.where((record) {
      return record.activatedAt.isAfter(cutoffDate);
    }).toList();
    
    final removedCount = history.length - filtered.length;
    
    if (removedCount > 0) {
      await _saveHistory(filtered);
      debugPrint('Limpeza automática: $removedCount registros removidos');
    }
    
    return removedCount;
  }

  /// Limpa todo o histórico
  Future<void> clearHistory() async {
    final prefs = await _preferences;
    await prefs.remove(_historyKey);
    await prefs.remove(_activeRecordKey);
  }

  /// Exporta histórico como JSON
  Future<String> exportHistory() async {
    final history = await loadHistory();
    return jsonEncode(history.map((r) => r.toJson()).toList());
  }

  /// Importa histórico de JSON
  Future<bool> importHistory(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final records = decoded
          .map((json) => UsageRecord.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Mescla com histórico existente
      final currentHistory = await loadHistory();
      final existingIds = currentHistory.map((r) => r.id).toSet();
      
      final newRecords = records.where((r) => !existingIds.contains(r.id)).toList();
      final merged = [...currentHistory, ...newRecords];
      
      await _saveHistory(merged);
      return true;
    } catch (e) {
      debugPrint('Erro ao importar histórico: $e');
      return false;
    }
  }

  /// Adiciona registro ao histórico
  Future<void> _addToHistory(UsageRecord record) async {
    final history = await loadHistory();
    history.insert(0, record);
    
    // Limita tamanho do histórico
    final limited = history.take(maxRecords).toList();
    
    await _saveHistory(limited);
    
    // Executa limpeza automática periodicamente
    if (history.length % 50 == 0) {
      await cleanupOldRecords();
    }
  }

  /// Atualiza registro existente no histórico
  Future<void> _updateInHistory(UsageRecord record) async {
    final history = await loadHistory();
    final index = history.indexWhere((r) => r.id == record.id);
    
    if (index >= 0) {
      history[index] = record;
      await _saveHistory(history);
    }
  }

  /// Salva histórico no SharedPreferences
  Future<void> _saveHistory(List<UsageRecord> history) async {
    final prefs = await _preferences;
    final json = jsonEncode(history.map((r) => r.toJson()).toList());
    await prefs.setString(_historyKey, json);
  }

  /// Obtém contagem de registros no histórico
  Future<int> getHistoryCount() async {
    final history = await loadHistory();
    return history.length;
  }

  /// Obtém registros de um servidor específico
  Future<List<UsageRecord>> getHistoryByServer(String serverId) async {
    final history = await loadHistory();
    return history.where((r) => r.serverId == serverId).toList();
  }
}
