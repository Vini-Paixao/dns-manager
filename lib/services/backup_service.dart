import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dns_server.dart';

/// Modelo de backup completo das configurações do app
class BackupData {
  final int version;
  final String appVersion;
  final DateTime createdAt;
  final List<DnsServer> servers;
  final String? selectedServerId;
  final String? themeMode;

  BackupData({
    required this.version,
    required this.appVersion,
    required this.createdAt,
    required this.servers,
    this.selectedServerId,
    this.themeMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'servers': servers.map((s) => s.toJson()).toList(),
      'selectedServerId': selectedServerId,
      'themeMode': themeMode,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int? ?? 1,
      appVersion: json['appVersion'] as String? ?? '1',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      servers: (json['servers'] as List<dynamic>?)
              ?.map((s) => DnsServer.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      selectedServerId: json['selectedServerId'] as String?,
      themeMode: json['themeMode'] as String?,
    );
  }
}

/// Resultado da operação de backup
class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final BackupData? data;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.data,
  });
}

/// Serviço de backup e restauração de configurações
/// 
/// Permite:
/// - Exportar todas as configurações para um arquivo JSON
/// - Importar configurações de um arquivo JSON
/// - Validar dados de backup
class BackupService {
  static const int currentVersion = 1;
  static const String appVersion = '1.0.1';
  static const String backupFileName = 'dns_manager_backup';

  /// Exporta as configurações para um arquivo JSON
  /// 
  /// Retorna o caminho do arquivo criado ou null em caso de erro
  Future<BackupResult> exportToFile({
    required List<DnsServer> servers,
    String? selectedServerId,
    String? themeMode,
  }) async {
    try {
      final backup = BackupData(
        version: currentVersion,
        appVersion: appVersion,
        createdAt: DateTime.now(),
        servers: servers,
        selectedServerId: selectedServerId,
        themeMode: themeMode,
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup.toJson());
      
      // Obter diretório de downloads ou documentos
      final directory = await _getExportDirectory();
      if (directory == null) {
        return BackupResult(
          success: false,
          message: 'Não foi possível acessar o diretório de exportação',
        );
      }

      // Criar nome de arquivo com timestamp
      final timestamp = DateTime.now().toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final fileName = '${backupFileName}_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      return BackupResult(
        success: true,
        message: 'Backup exportado com sucesso',
        filePath: file.path,
        data: backup,
      );
    } catch (e) {
      debugPrint('Erro ao exportar backup: $e');
      return BackupResult(
        success: false,
        message: 'Erro ao exportar: ${e.toString()}',
      );
    }
  }

  /// Importa as configurações de um arquivo JSON
  Future<BackupResult> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return BackupResult(
          success: false,
          message: 'Arquivo não encontrado',
        );
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validar versão do backup
      final version = json['version'] as int? ?? 0;
      if (version > currentVersion) {
        return BackupResult(
          success: false,
          message: 'Versão do backup não suportada. Atualize o app.',
        );
      }

      final backup = BackupData.fromJson(json);
      
      // Validar dados do backup
      if (backup.servers.isEmpty) {
        return BackupResult(
          success: false,
          message: 'O backup não contém servidores',
        );
      }

      return BackupResult(
        success: true,
        message: 'Backup importado com sucesso (${backup.servers.length} servidores)',
        data: backup,
      );
    } on FormatException {
      return BackupResult(
        success: false,
        message: 'Arquivo inválido: não é um JSON válido',
      );
    } catch (e) {
      debugPrint('Erro ao importar backup: $e');
      return BackupResult(
        success: false,
        message: 'Erro ao importar: ${e.toString()}',
      );
    }
  }

  /// Importa de uma string JSON diretamente
  Future<BackupResult> importFromString(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final version = json['version'] as int? ?? 0;
      if (version > currentVersion) {
        return BackupResult(
          success: false,
          message: 'Versão do backup não suportada',
        );
      }

      final backup = BackupData.fromJson(json);
      
      if (backup.servers.isEmpty) {
        return BackupResult(
          success: false,
          message: 'O backup não contém servidores',
        );
      }

      return BackupResult(
        success: true,
        message: 'Backup válido (${backup.servers.length} servidores)',
        data: backup,
      );
    } on FormatException {
      return BackupResult(
        success: false,
        message: 'JSON inválido',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Erro: ${e.toString()}',
      );
    }
  }

  /// Gera uma string JSON do backup para compartilhamento
  String generateBackupString({
    required List<DnsServer> servers,
    String? selectedServerId,
    String? themeMode,
  }) {
    final backup = BackupData(
      version: currentVersion,
      appVersion: appVersion,
      createdAt: DateTime.now(),
      servers: servers,
      selectedServerId: selectedServerId,
      themeMode: themeMode,
    );

    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  /// Obtém o diretório para exportação
  Future<Directory?> _getExportDirectory() async {
    try {
      // Tentar usar o diretório de downloads externo primeiro
      if (Platform.isAndroid) {
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          // Navegar para a pasta Downloads
          final basePath = externalDirs.first.path.split('/Android')[0];
          final downloadsDir = Directory('$basePath/Download');
          if (await downloadsDir.exists()) {
            return downloadsDir;
          }
        }
      }
      
      // Fallback para diretório de documentos do app
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('Erro ao obter diretório: $e');
      return null;
    }
  }

  /// Lista backups disponíveis no diretório de documentos do app
  Future<List<File>> listAvailableBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') && 
                        f.path.contains(backupFileName))
          .toList();
      
      // Ordenar por data de modificação (mais recentes primeiro)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      debugPrint('Erro ao listar backups: $e');
      return [];
    }
  }
}
