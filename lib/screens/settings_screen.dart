import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dns_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

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
              _showComingSoon(context, 'Exportar configurações');
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
              _showComingSoon(context, 'Importar configurações');
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature: em breve!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
