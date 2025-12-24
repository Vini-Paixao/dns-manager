/// Registro de uso de um servidor DNS
/// 
/// Armazena informações sobre quando um servidor foi ativado/desativado
class UsageRecord {
  final String id;
  final String serverId;
  final String serverName;
  final String hostname;
  final DateTime activatedAt;
  final DateTime? deactivatedAt;
  final int? latencyMs;
  final bool wasSuccessful;
  final String? failureReason;

  UsageRecord({
    required this.id,
    required this.serverId,
    required this.serverName,
    required this.hostname,
    required this.activatedAt,
    this.deactivatedAt,
    this.latencyMs,
    this.wasSuccessful = true,
    this.failureReason,
  });

  /// Duração de uso do servidor (null se ainda ativo)
  Duration? get duration {
    if (deactivatedAt == null) return null;
    return deactivatedAt!.difference(activatedAt);
  }
  
  /// Duração de uso incluindo tempo atual (para registros ativos)
  Duration get currentDuration {
    final endTime = deactivatedAt ?? DateTime.now();
    return endTime.difference(activatedAt);
  }

  /// Verifica se ainda está ativo (sem data de desativação)
  bool get isActive => deactivatedAt == null;

  /// Formata a duração para exibição
  String get formattedDuration {
    final d = duration;
    if (d == null) return 'Ativo';
    
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}min';
    }
    return '${d.inSeconds}s';
  }

  /// Cria cópia com campos atualizados
  UsageRecord copyWith({
    String? id,
    String? serverId,
    String? serverName,
    String? hostname,
    DateTime? activatedAt,
    DateTime? deactivatedAt,
    int? latencyMs,
    bool? wasSuccessful,
    String? failureReason,
  }) {
    return UsageRecord(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      hostname: hostname ?? this.hostname,
      activatedAt: activatedAt ?? this.activatedAt,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      latencyMs: latencyMs ?? this.latencyMs,
      wasSuccessful: wasSuccessful ?? this.wasSuccessful,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'serverId': serverId,
    'serverName': serverName,
    'hostname': hostname,
    'activatedAt': activatedAt.toIso8601String(),
    'deactivatedAt': deactivatedAt?.toIso8601String(),
    'latencyMs': latencyMs,
    'wasSuccessful': wasSuccessful,
    'failureReason': failureReason,
  };

  /// Cria a partir de JSON
  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    return UsageRecord(
      id: json['id'] as String,
      serverId: json['serverId'] as String,
      serverName: json['serverName'] as String,
      hostname: json['hostname'] as String,
      activatedAt: DateTime.parse(json['activatedAt'] as String),
      deactivatedAt: json['deactivatedAt'] != null 
          ? DateTime.parse(json['deactivatedAt'] as String) 
          : null,
      latencyMs: json['latencyMs'] as int?,
      wasSuccessful: json['wasSuccessful'] as bool? ?? true,
      failureReason: json['failureReason'] as String?,
    );
  }

  @override
  String toString() {
    return 'UsageRecord(server: $serverName, activated: $activatedAt, duration: $formattedDuration)';
  }
}

/// Estatísticas de uso dos servidores DNS
class UsageStatistics {
  final int totalActivations;
  final int successfulActivations;
  final int failedActivations;
  final Duration totalUsageTime;
  final Map<String, int> activationsByServer;
  final Map<String, Duration> usageTimeByServer;
  final Map<String, int> serverUsageCount; // Nome do servidor -> contagem
  final String? mostUsedServerId;
  final double? averageLatencyMs;
  final DateTime? firstActivation;
  final DateTime? lastActivation;

  UsageStatistics({
    required this.totalActivations,
    required this.successfulActivations,
    required this.failedActivations,
    required this.totalUsageTime,
    required this.activationsByServer,
    required this.usageTimeByServer,
    required this.serverUsageCount,
    this.mostUsedServerId,
    this.averageLatencyMs,
    this.firstActivation,
    this.lastActivation,
  });

  /// Taxa de sucesso em porcentagem
  double get successRate {
    if (totalActivations == 0) return 0;
    return (successfulActivations / totalActivations) * 100;
  }

  /// Calcula estatísticas a partir de uma lista de registros
  factory UsageStatistics.fromRecords(List<UsageRecord> records) {
    if (records.isEmpty) {
      return UsageStatistics(
        totalActivations: 0,
        successfulActivations: 0,
        failedActivations: 0,
        totalUsageTime: Duration.zero,
        activationsByServer: {},
        usageTimeByServer: {},
        serverUsageCount: {},
      );
    }

    final activationsByServer = <String, int>{};
    final usageTimeByServer = <String, Duration>{};
    final serverUsageCount = <String, int>{};
    var totalUsageTime = Duration.zero;
    var totalLatency = 0;
    var latencyCount = 0;
    DateTime? firstActivation;
    DateTime? lastActivation;

    for (final record in records) {
      // Contagem por servidor (usando ID)
      activationsByServer[record.serverId] = 
          (activationsByServer[record.serverId] ?? 0) + 1;
      
      // Contagem por servidor (usando nome para exibição)
      serverUsageCount[record.serverName] = 
          (serverUsageCount[record.serverName] ?? 0) + 1;
      
      // Tempo de uso (usa currentDuration para incluir tempo de registros ativos)
      final duration = record.currentDuration;
      totalUsageTime += duration;
      usageTimeByServer[record.serverId] = 
          (usageTimeByServer[record.serverId] ?? Duration.zero) + duration;
      
      // Latência média
      if (record.latencyMs != null) {
        totalLatency += record.latencyMs!;
        latencyCount++;
      }
      
      // Primeira e última ativação
      if (firstActivation == null || record.activatedAt.isBefore(firstActivation)) {
        firstActivation = record.activatedAt;
      }
      if (lastActivation == null || record.activatedAt.isAfter(lastActivation)) {
        lastActivation = record.activatedAt;
      }
    }

    // Encontra servidor mais usado
    String? mostUsedServerId;
    var maxActivations = 0;
    for (final entry in activationsByServer.entries) {
      if (entry.value > maxActivations) {
        maxActivations = entry.value;
        mostUsedServerId = entry.key;
      }
    }

    return UsageStatistics(
      totalActivations: records.length,
      successfulActivations: records.where((r) => r.wasSuccessful).length,
      failedActivations: records.where((r) => !r.wasSuccessful).length,
      totalUsageTime: totalUsageTime,
      activationsByServer: activationsByServer,
      usageTimeByServer: usageTimeByServer,
      serverUsageCount: serverUsageCount,
      mostUsedServerId: mostUsedServerId,
      averageLatencyMs: latencyCount > 0 ? totalLatency / latencyCount : null,
      firstActivation: firstActivation,
      lastActivation: lastActivation,
    );
  }

  /// Formata o tempo total de uso
  String get formattedTotalUsageTime {
    if (totalUsageTime.inDays > 0) {
      return '${totalUsageTime.inDays}d ${totalUsageTime.inHours.remainder(24)}h';
    }
    if (totalUsageTime.inHours > 0) {
      return '${totalUsageTime.inHours}h ${totalUsageTime.inMinutes.remainder(60)}min';
    }
    return '${totalUsageTime.inMinutes}min';
  }
}
