import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço para gerenciar permissões do aplicativo
/// 
/// Centraliza a lógica de solicitação e verificação de permissões
/// para galeria de fotos e armazenamento.
class PermissionService {
  /// Solicita permissão para acessar fotos da galeria
  /// 
  /// No Android 13+ (API 33), usa READ_MEDIA_IMAGES
  /// Em versões anteriores, usa READ_EXTERNAL_STORAGE
  /// 
  /// Retorna true se a permissão foi concedida
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    Permission permission;
    
    // Android 13+ usa permissão específica de mídia
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        permission = Permission.photos;
      } else {
        permission = Permission.storage;
      }
    } else {
      permission = Permission.photos;
    }
    
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await permission.request();
      if (result.isGranted) {
        return true;
      }
      
      // Se foi negada, mostra diálogo explicando
      if (context.mounted) {
        return await _showPermissionDeniedDialog(
          context,
          'Permissão de Fotos',
          'Para adicionar uma logo personalizada ao servidor DNS, precisamos de acesso à sua galeria de fotos.',
        );
      }
    }
    
    if (status.isPermanentlyDenied) {
      // Usuário marcou "Não perguntar novamente"
      if (context.mounted) {
        return await _showOpenSettingsDialog(
          context,
          'Permissão de Fotos Bloqueada',
          'Você bloqueou o acesso às fotos. Para usar logos personalizados, habilite a permissão nas configurações do app.',
        );
      }
    }
    
    return false;
  }

  /// Solicita permissão para acessar arquivos (para importar backup)
  /// 
  /// No Android 13+, file_picker já gerencia as permissões necessárias
  /// Em versões anteriores, pode precisar de READ_EXTERNAL_STORAGE
  /// 
  /// Retorna true se a permissão foi concedida
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // Android 13+ não precisa de permissão para file_picker usar SAF
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 33) {
        // Android 13+ usa Storage Access Framework, não precisa de permissão
        return true;
      }
    }
    
    final status = await Permission.storage.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      }
      
      if (context.mounted) {
        return await _showPermissionDeniedDialog(
          context,
          'Permissão de Armazenamento',
          'Para importar configurações de backup, precisamos de acesso ao armazenamento do dispositivo.',
        );
      }
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        return await _showOpenSettingsDialog(
          context,
          'Permissão de Armazenamento Bloqueada',
          'Você bloqueou o acesso ao armazenamento. Para importar backups, habilite a permissão nas configurações do app.',
        );
      }
    }
    
    return false;
  }

  /// Obtém a versão do Android SDK
  static Future<int> _getAndroidVersion() async {
    // Retorna 33 como fallback seguro (Android 13)
    // Em produção, o plugin permission_handler já detecta corretamente
    try {
      if (Platform.isAndroid) {
        final version = Platform.operatingSystemVersion;
        // Tenta extrair o SDK level da string
        final match = RegExp(r'SDK (\d+)').firstMatch(version);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter versão do Android: $e');
    }
    return 33; // Fallback para Android 13
  }

  /// Mostra diálogo quando permissão é negada
  static Future<bool> _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[400], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seus dados estão seguros. Não acessamos nem compartilhamos suas fotos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
    
    if (result == true && context.mounted) {
      // Tenta solicitar novamente
      return await requestPhotosPermission(context);
    }
    
    return false;
  }

  /// Mostra diálogo para abrir configurações do app
  static Future<bool> _showOpenSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.block_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Configurações > Apps > DNS Manager > Permissões',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context, true);
              await openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('Abrir Configurações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Verifica se tem permissão de fotos sem solicitar
  static Future<bool> hasPhotosPermission() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 33) {
        return await Permission.photos.isGranted;
      }
      return await Permission.storage.isGranted;
    }
    return await Permission.photos.isGranted;
  }

  /// Verifica se tem permissão de armazenamento sem solicitar
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 33) {
        return true; // Android 13+ usa SAF
      }
    }
    return await Permission.storage.isGranted;
  }
}
