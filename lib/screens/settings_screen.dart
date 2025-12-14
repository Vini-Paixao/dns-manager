import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/dns_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../services/backup_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';

/// Tela de configurações do aplicativo
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção de Aparência
          _buildSectionTitle('Aparência', isDarkMode),
          const SizedBox(height: 8),
          _buildThemeCard(context, ref, currentTheme, isDarkMode),
          
          const SizedBox(height: 24),
          
          // Seção de Servidores
          _buildSectionTitle('Servidores DNS', isDarkMode),
          const SizedBox(height: 8),
          _buildServersSection(context, ref, isDarkMode),
          
          const SizedBox(height: 24),
          
          // Seção de Notificação
          _buildSectionTitle('Notificação', isDarkMode),
          const SizedBox(height: 8),
          _buildNotificationSection(context, ref, isDarkMode),
          
          const SizedBox(height: 24),
          
          // Seção de Histórico
          _buildSectionTitle('Histórico', isDarkMode),
          const SizedBox(height: 8),
          _buildHistorySection(context, isDarkMode),
          
          const SizedBox(height: 24),
          
          // Seção de Dados
          _buildSectionTitle('Dados', isDarkMode),
          const SizedBox(height: 8),
          _buildDataSection(context, ref, isDarkMode),
          
          const SizedBox(height: 24),
          
          // Seção Sobre
          _buildSectionTitle('Sobre', isDarkMode),
          const SizedBox(height: 8),
          _buildAboutSection(context, isDarkMode),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, ThemeModeOption currentTheme, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context: context,
            ref: ref,
            icon: Icons.brightness_auto_rounded,
            title: 'Automático',
            subtitle: 'Segue as configurações do sistema',
            value: ThemeModeOption.system,
            currentValue: currentTheme,
            isDarkMode: isDarkMode,
            isFirst: true,
          ),
          _buildDivider(isDarkMode),
          _buildThemeOption(
            context: context,
            ref: ref,
            icon: Icons.light_mode_rounded,
            title: 'Claro',
            subtitle: 'Sempre usar tema claro',
            value: ThemeModeOption.light,
            currentValue: currentTheme,
            isDarkMode: isDarkMode,
          ),
          _buildDivider(isDarkMode),
          _buildThemeOption(
            context: context,
            ref: ref,
            icon: Icons.dark_mode_rounded,
            title: 'Escuro',
            subtitle: 'Sempre usar tema escuro',
            value: ThemeModeOption.dark,
            currentValue: currentTheme,
            isDarkMode: isDarkMode,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeModeOption value,
    required ThemeModeOption currentValue,
    required bool isDarkMode,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = value == currentValue;
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(themeModeProvider.notifier).setThemeMode(value);
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF7C4DFF).withOpacity(0.15)
                    : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF7C4DFF) : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF7C4DFF),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServersSection(BuildContext context, WidgetRef ref, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.refresh_rounded,
            iconColor: const Color(0xFF7C4DFF),
            title: 'Restaurar servidores padrão',
            subtitle: 'Remove customizações e volta ao original',
            isDarkMode: isDarkMode,
            isFirst: true,
            onTap: () => _showResetConfirmation(context, ref),
          ),
          _buildDivider(isDarkMode),
          _buildSettingsTile(
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF00BFA5),
            title: 'Testar todos os servidores',
            subtitle: 'Mede a latência de conexão',
            isDarkMode: isDarkMode,
            isLast: true,
            onTap: () {
              HapticFeedback.lightImpact();
              _testLatency(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, WidgetRef ref, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    final notificationState = ref.watch(notificationProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle de notificação persistente
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificação persistente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mostra status e latência em tempo real',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: notificationState.isEnabled,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    if (value) {
                      ref.read(notificationProvider.notifier).enableNotification();
                    } else {
                      ref.read(notificationProvider.notifier).disableNotification();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Seletor de intervalo (apenas se notificação ativada)
          if (notificationState.isEnabled) ...[
            _buildDivider(isDarkMode),
            _buildIntervalSelector(context, ref, isDarkMode, notificationState),
          ],
          
          // Aviso sobre bateria
          if (notificationState.isEnabled) ...[
            _buildDivider(isDarkMode),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.battery_alert_rounded,
                    color: Colors.orange[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Intervalos menores consomem mais bateria. Recomendamos 60s para uso normal.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntervalSelector(BuildContext context, WidgetRef ref, bool isDarkMode, NotificationState state) {
    final intervals = [
      (10, '10s', 'Alto consumo'),
      (30, '30s', 'Moderado'),
      (60, '60s', 'Recomendado'),
      (120, '2min', 'Baixo'),
      (300, '5min', 'Mínimo'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intervalo de atualização',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: intervals.map((interval) {
              final isSelected = state.intervalSeconds == interval.$1;
              return ChoiceChip(
                label: Text(interval.$2),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    HapticFeedback.lightImpact();
                    ref.read(notificationProvider.notifier).setInterval(interval.$1);
                  }
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                tooltip: interval.$3,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF2196F3),
            title: 'Ver histórico de uso',
            subtitle: 'Estatísticas e registros de ativação',
            isDarkMode: isDarkMode,
            isFirst: true,
            isLast: true,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, WidgetRef ref, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.upload_rounded,
            iconColor: Colors.blue,
            title: 'Exportar configurações',
            subtitle: 'Salva servidores e preferências',
            isDarkMode: isDarkMode,
            isFirst: true,
            onTap: () {
              HapticFeedback.lightImpact();
              _showExportDialog(context, ref, isDarkMode);
            },
          ),
          _buildDivider(isDarkMode),
          _buildSettingsTile(
            icon: Icons.download_rounded,
            iconColor: Colors.green,
            title: 'Importar configurações',
            subtitle: 'Restaura de um arquivo',
            isDarkMode: isDarkMode,
            isLast: true,
            onTap: () {
              HapticFeedback.lightImpact();
              _showImportDialog(context, ref, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.blue,
            title: 'Sobre o app',
            subtitle: 'Versão e informações',
            isDarkMode: isDarkMode,
            isFirst: true,
            onTap: () => _showAboutDialog(context),
          ),
          _buildDivider(isDarkMode),
          _buildSettingsTile(
            icon: Icons.code_rounded,
            iconColor: Colors.purple,
            title: 'Código fonte',
            subtitle: 'github.com/Vini-Paixao/dns-manager',
            isDarkMode: isDarkMode,
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(const ClipboardData(
                text: 'https://github.com/Vini-Paixao/dns-manager',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Link copiado!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          _buildDivider(isDarkMode),
          _buildSettingsTile(
            icon: Icons.gavel_rounded,
            iconColor: Colors.orange,
            title: 'Licença',
            subtitle: 'Source Available - Uso não comercial',
            isDarkMode: isDarkMode,
            isLast: true,
            onTap: () => _showLicenseInfo(context, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar servidores?'),
        content: const Text(
          'Isso vai remover todos os servidores customizados e restaurar os padrões. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(serversProvider.notifier).resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Servidores restaurados'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _testLatency(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Testando latência...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    final servers = ref.read(serversProvider);
    final hostnames = servers.map((s) => s.hostname).toList();
    
    await ref.read(latencyProvider.notifier).testAllServers(hostnames);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Teste de latência concluído!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showExportDialog(BuildContext context, WidgetRef ref, bool isDarkMode) {
    final servers = ref.read(serversProvider);
    final selectedId = ref.read(selectedServerProvider)?.id;
    final themeMode = ref.read(themeModeProvider).name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_rounded, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Exportar Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O backup incluirá:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildBackupInfoRow(Icons.dns_rounded, '${servers.length} servidores DNS', isDarkMode),
            _buildBackupInfoRow(Icons.palette_rounded, 'Tema: $themeMode', isDarkMode),
            if (selectedId != null)
              _buildBackupInfoRow(Icons.check_circle_rounded, 'Servidor selecionado', isDarkMode),
            const SizedBox(height: 16),
            Text(
              'Escolha como exportar:',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportToClipboard(context, servers, selectedId, themeMode);
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _exportAndShare(context, servers, selectedId, themeMode);
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupInfoRow(IconData icon, String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToClipboard(
    BuildContext context,
    List servers,
    String? selectedId,
    String themeMode,
  ) async {
    final backupService = BackupService();
    final jsonString = backupService.generateBackupString(
      servers: servers.cast(),
      selectedServerId: selectedId,
      themeMode: themeMode,
    );
    
    await Clipboard.setData(ClipboardData(text: jsonString));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Backup copiado para a área de transferência'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _exportAndShare(
    BuildContext context,
    List servers,
    String? selectedId,
    String themeMode,
  ) async {
    final backupService = BackupService();
    final result = await backupService.exportToFile(
      servers: servers.cast(),
      selectedServerId: selectedId,
      themeMode: themeMode,
    );
    
    if (result.success && result.filePath != null) {
      await Share.shareXFiles(
        [XFile(result.filePath!)],
        subject: 'DNS Manager Backup',
        text: 'Backup das configurações do DNS Manager',
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(child: Text(result.message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showImportDialog(BuildContext context, WidgetRef ref, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download_rounded, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Importar Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha a origem do backup:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '⚠️ Atenção: A importação substituirá todas as suas configurações atuais.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.orange[300] : Colors.orange[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _importFromClipboard(context, ref, isDarkMode);
            },
            icon: const Icon(Icons.paste_rounded, size: 18),
            label: const Text('Da Área de Transferência'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _importFromFile(context, ref, isDarkMode);
            },
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('De Arquivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard(BuildContext context, WidgetRef ref, bool isDarkMode) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    
    if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Text('Área de transferência vazia'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final backupService = BackupService();
    final result = await backupService.importFromString(clipboardData.text!);
    
    if (result.success && result.data != null) {
      if (context.mounted) {
        _confirmImport(context, ref, result.data!, isDarkMode);
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(child: Text(result.message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _importFromFile(BuildContext context, WidgetRef ref, bool isDarkMode) async {
    // Solicita permissão antes de acessar arquivos (necessário em Android < 13)
    final hasPermission = await PermissionService.requestStoragePermission(context);
    
    if (!hasPermission && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange),
              SizedBox(width: 12),
              Text('Permissão de armazenamento necessária'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) return;
      
      final filePath = result.files.first.path;
      if (filePath == null) return;

      final backupService = BackupService();
      final importResult = await backupService.importFromFile(filePath);
      
      if (importResult.success && importResult.data != null) {
        if (context.mounted) {
          _confirmImport(context, ref, importResult.data!, isDarkMode);
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text(importResult.message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao selecionar arquivo: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _confirmImport(BuildContext context, WidgetRef ref, BackupData backup, bool isDarkMode) {
    final customServers = backup.servers.where((s) => s.isCustom).length;
    final defaultServers = backup.servers.length - customServers;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Importação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup de ${backup.createdAt.day}/${backup.createdAt.month}/${backup.createdAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildBackupInfoRow(Icons.dns_rounded, '$defaultServers servidores padrão', isDarkMode),
            _buildBackupInfoRow(Icons.add_circle_rounded, '$customServers servidores customizados', isDarkMode),
            if (backup.themeMode != null)
              _buildBackupInfoRow(Icons.palette_rounded, 'Tema: ${backup.themeMode}', isDarkMode),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suas configurações atuais serão substituídas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _applyImport(context, ref, backup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyImport(BuildContext context, WidgetRef ref, BackupData backup) async {
    // Importar servidores
    await ref.read(serversProvider.notifier).importServers(backup.servers);
    
    // Importar tema se existir
    if (backup.themeMode != null) {
      final themeOption = ThemeModeOption.values.firstWhere(
        (e) => e.name == backup.themeMode,
        orElse: () => ThemeModeOption.system,
      );
      ref.read(themeModeProvider.notifier).setThemeMode(themeOption);
    }
    
    // Importar servidor selecionado se existir
    if (backup.selectedServerId != null) {
      final server = backup.servers.where((s) => s.id == backup.selectedServerId).firstOrNull;
      if (server != null) {
        await ref.read(selectedServerProvider.notifier).selectServer(server);
      }
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text('Backup importado! ${backup.servers.length} servidores restaurados'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'DNS Manager',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.dns_rounded, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'Gerencie seu DNS privado (DNS over TLS) de forma simples e rápida.',
        ),
        const SizedBox(height: 16),
        Text(
          'Desenvolvido por Vinícius Paixão',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          'Requer permissão WRITE_SECURE_SETTINGS via ADB.',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  void _showLicenseInfo(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Licença'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DNS Manager - Source Available License v1.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'PERMITIDO:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[400],
                ),
              ),
              const Text('• Uso pessoal e não comercial'),
              const Text('• Estudo e aprendizado'),
              const Text('• Contribuições ao projeto'),
              const SizedBox(height: 12),
              Text(
                'PROIBIDO:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[400],
                ),
              ),
              const Text('• Uso comercial sem autorização'),
              const Text('• Redistribuição de versões modificadas'),
              const Text('• Publicação em lojas de apps'),
              const SizedBox(height: 16),
              Text(
                'Para licenciamento comercial, entre em contato.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
