import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dns_provider.dart';

/// Tela com múltiplas opções para conceder a permissão WRITE_SECURE_SETTINGS
/// 
/// Oferece diferentes métodos para o usuário escolher:
/// 1. USB + ADB (método padrão)
/// 2. Shizuku (app externo)
/// 3. Wireless Debugging (Android 11+)
class PermissionOptionsScreen extends ConsumerStatefulWidget {
  const PermissionOptionsScreen({super.key});

  @override
  ConsumerState<PermissionOptionsScreen> createState() => _PermissionOptionsScreenState();
}

class _PermissionOptionsScreenState extends ConsumerState<PermissionOptionsScreen> {
  bool _isCheckingPermission = false;

  static const String adbCommand = 
      'adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header com gradiente
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Configurar Permissão',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 15),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: Icon(
                      Icons.security_rounded,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          
          // Conteúdo
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Explicação
                _buildExplanationCard(),
                const SizedBox(height: 24),
                
                // Título da seção de métodos
                Text(
                  'Escolha um método:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Método 1: USB + ADB (Recomendado)
                _buildMethodCard(
                  icon: Icons.usb_rounded,
                  iconColor: Colors.blue,
                  title: 'USB + ADB',
                  subtitle: 'Método recomendado',
                  description: 'Conecte ao PC via cabo USB e execute um comando no terminal.',
                  isRecommended: true,
                  onTap: () => _showUsbMethod(context),
                ),
                const SizedBox(height: 12),
                
                // Método 2: Shizuku
                _buildMethodCard(
                  icon: Icons.apps_rounded,
                  iconColor: Colors.purple,
                  title: 'App Shizuku',
                  subtitle: 'Sem necessidade de PC',
                  description: 'Use o app Shizuku para conceder a permissão sem computador.',
                  onTap: () => _showShizukuMethod(context),
                ),
                const SizedBox(height: 12),
                
                // Método 3: LADB (Android 11+)
                _buildMethodCard(
                  icon: Icons.wifi_tethering_rounded,
                  iconColor: Colors.teal,
                  title: 'LADB (Wireless)',
                  subtitle: 'Android 11+ • Sem PC',
                  description: 'Use o app LADB para executar comandos ADB pelo próprio celular.',
                  onTap: () => _showLabdMethod(context),
                ),
                
                const SizedBox(height: 32),
                
                // Botão verificar permissão
                _buildCheckPermissionButton(),
                
                const SizedBox(height: 16),
                
                // Link para ajuda
                Center(
                  child: TextButton.icon(
                    onPressed: _showHelpDialog,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Precisa de ajuda?'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Por que essa permissão?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A permissão WRITE_SECURE_SETTINGS é necessária para alterar as configurações de DNS do sistema. '
            'Por segurança, o Android não permite que apps concedam essa permissão sozinhos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return Card(
      elevation: isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended 
            ? BorderSide(color: iconColor.withValues(alpha:0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'RECOMENDADO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Seta
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckPermissionButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isCheckingPermission ? null : _checkPermission,
        icon: _isCheckingPermission 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.verified_user_outlined),
        label: Text(_isCheckingPermission ? 'Verificando...' : 'Verificar Permissão'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ========== MÉTODO USB ==========
  void _showUsbMethod(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.usb_rounded, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Método USB + ADB',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Método mais confiável',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Passos
                _buildStepItem(
                  number: 1,
                  title: 'Ative a Depuração USB',
                  description: 'Vá em Configurações > Sobre o telefone > toque 7x no "Número da versão" para ativar o Modo Desenvolvedor. '
                      'Depois vá em Opções do desenvolvedor e ative "Depuração USB".',
                  icon: Icons.developer_mode,
                ),
                _buildStepItem(
                  number: 2,
                  title: 'Baixe o ADB',
                  description: 'Baixe o Android SDK Platform Tools para seu sistema:',
                  icon: Icons.download,
                  child: Column(
                    children: [
                      _buildLinkButton(
                        'Windows',
                        'https://dl.google.com/android/repository/platform-tools-latest-windows.zip',
                      ),
                      _buildLinkButton(
                        'macOS',
                        'https://dl.google.com/android/repository/platform-tools-latest-darwin.zip',
                      ),
                      _buildLinkButton(
                        'Linux',
                        'https://dl.google.com/android/repository/platform-tools-latest-linux.zip',
                      ),
                    ],
                  ),
                ),
                _buildStepItem(
                  number: 3,
                  title: 'Conecte o celular',
                  description: 'Conecte seu celular ao computador via cabo USB. '
                      'Quando aparecer o popup "Permitir depuração USB?", marque "Sempre permitir" e toque em OK.',
                  icon: Icons.cable,
                ),
                _buildStepItem(
                  number: 4,
                  title: 'Execute o comando',
                  description: 'Abra o terminal/prompt de comando na pasta do ADB e execute:',
                  icon: Icons.terminal,
                  child: _buildCommandBox(adbCommand),
                ),
                _buildStepItem(
                  number: 5,
                  title: 'Verifique',
                  description: 'Volte ao app e toque em "Verificar Permissão" para confirmar.',
                  icon: Icons.check_circle,
                  isLast: true,
                ),
                
                const SizedBox(height: 24),
                
                // Aviso sobre tutoriais da internet
                _buildTutorialWarningCard(),
                
                // Vídeo tutorial (link)
                _buildVideoTutorialCard(
                  videoUrl: 'https://www.youtube.com/watch?v=H10wJVhrrEI',
                  title: 'Vídeo Tutorial USB + ADB',
                  description: 'Assista um tutorial completo de como usar o ADB via USB',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== MÉTODO SHIZUKU ==========
  void _showShizukuMethod(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apps_rounded, color: Colors.purple, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Método Shizuku',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Requer configuração inicial com PC',
                            style: TextStyle(color: Colors.purple),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Aviso
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'O Shizuku precisa de um PC na primeira configuração, mas depois funciona sem cabo.',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.orange[300]
                                : Colors.orange[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Passos
                _buildStepItem(
                  number: 1,
                  title: 'Instale o Shizuku',
                  description: 'Baixe o app Shizuku na Play Store:',
                  icon: Icons.download,
                  child: _buildAppButton(
                    'Shizuku',
                    'https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api',
                    Icons.shop,
                  ),
                ),
                _buildStepItem(
                  number: 2,
                  title: 'Inicie o Shizuku',
                  description: 'Siga as instruções dentro do app Shizuku para iniciar o serviço. '
                      'Na primeira vez, você precisará conectar ao PC via ADB.',
                  icon: Icons.play_circle,
                ),
                _buildStepItem(
                  number: 3,
                  title: 'Instale o Rish',
                  description: 'Baixe o app Rish (shell para Shizuku) para executar comandos:',
                  icon: Icons.terminal,
                  child: _buildAppButton(
                    'Rish',
                    'https://github.com/nickcao/rish/releases',
                    Icons.download,
                  ),
                ),
                _buildStepItem(
                  number: 4,
                  title: 'Execute o comando',
                  description: 'Com o Shizuku rodando, abra o Rish e execute:',
                  icon: Icons.code,
                  child: _buildCommandBox(
                    'pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS',
                  ),
                ),
                _buildStepItem(
                  number: 5,
                  title: 'Verifique',
                  description: 'Volte ao DNS Manager e toque em "Verificar Permissão".',
                  icon: Icons.check_circle,
                  isLast: true,
                ),
                
                const SizedBox(height: 24),
                
                // Aviso sobre tutoriais da internet
                _buildTutorialWarningCard(),
                
                // Vídeo tutorial
                _buildVideoTutorialCard(
                  videoUrl: 'https://www.youtube.com/watch?v=mT1x3CSNk9I',
                  title: 'Vídeo Tutorial Shizuku',
                  description: 'Assista um tutorial completo de como configurar o Shizuku',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== MÉTODO LADB ==========
  void _showLabdMethod(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi_tethering_rounded, color: Colors.teal, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Método LADB',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '100% pelo celular • Android 11+',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Aviso
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.teal, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este método não precisa de computador! Funciona 100% no celular.',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.teal[300]
                                : Colors.teal[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Passos
                _buildStepItem(
                  number: 1,
                  title: 'Instale o LADB',
                  description: 'Baixe o app LADB (Local ADB Shell):',
                  icon: Icons.download,
                  child: Column(
                    children: [
                      _buildAppButton(
                        'LADB (Play Store)',
                        'https://play.google.com/store/apps/details?id=com.draco.ladb',
                        Icons.shop,
                      ),
                      const SizedBox(height: 8),
                      _buildAppButton(
                        'LADB (GitHub - Grátis)',
                        'https://github.com/tytydraco/LADB/releases',
                        Icons.download,
                      ),
                    ],
                  ),
                ),
                _buildStepItem(
                  number: 2,
                  title: 'Ative a Depuração Wireless',
                  description: 'Vá em Configurações > Opções do desenvolvedor > ative "Depuração wireless" (ou "Wireless debugging").',
                  icon: Icons.wifi_tethering,
                ),
                _buildStepItem(
                  number: 3,
                  title: 'Emparelhe no LADB',
                  description: 'Abra o LADB e toque em "Pair". Nas configurações de Depuração Wireless, '
                      'toque em "Emparelhar dispositivo com código" e copie o código de 6 dígitos e a porta para o LADB.',
                  icon: Icons.link,
                ),
                _buildStepItem(
                  number: 4,
                  title: 'Execute o comando',
                  description: 'Com o LADB conectado, digite o comando:',
                  icon: Icons.terminal,
                  child: _buildCommandBox(
                    'pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS',
                  ),
                ),
                _buildStepItem(
                  number: 5,
                  title: 'Verifique',
                  description: 'Volte ao DNS Manager e toque em "Verificar Permissão".',
                  icon: Icons.check_circle,
                  isLast: true,
                ),
                
                const SizedBox(height: 24),
                
                // Aviso sobre tutoriais da internet
                _buildTutorialWarningCard(),
                
                // Vídeo tutorial
                _buildVideoTutorialCard(
                  videoUrl: 'https://www.youtube.com/watch?v=Rq894y5RvP0',
                  title: 'Vídeo Tutorial LADB',
                  description: 'Assista um tutorial completo de como usar o LADB',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== WIDGETS AUXILIARES ==========

  Widget _buildStepItem({
    required int number,
    required String title,
    required String description,
    required IconData icon,
    Widget? child,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Número e linha
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 80 + (child != null ? 60.0 : 0.0),
                color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Conteúdo
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                  ),
                ),
                if (child != null) ...[
                  const SizedBox(height: 12),
                  child,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommandBox(String command) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              command,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isDark ? Colors.greenAccent : const Color(0xFF00796B),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Comando copiado!'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Copiar comando',
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: () => _openUrl(url),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  Widget _buildAppButton(String label, String url, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () => _openUrl(url),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
      ),
    );
  }

  /// Widget de aviso contextual sobre os vídeos tutoriais da internet
  Widget _buildTutorialWarningCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha:0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber[700],
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Atenção: Os vídeos abaixo são tutoriais da internet. Siga as instruções gerais para configurar o ADB/Shizuku/LADB, mas lembre-se de executar o comando específico mostrado acima nesta tela.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber[300]
                    : Colors.amber[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTutorialCard({
    required String videoUrl,
    String title = 'Vídeo Tutorial',
    String description = 'Assista um tutorial completo passo a passo',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha:0.1),
            Colors.red.withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openUrl(videoUrl),
            child: const Text('Assistir'),
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copiar link se não conseguir abrir
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.link, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Não foi possível abrir. Link copiado:\n$url', 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Em caso de erro, copiar o link
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir link. Copiado: $url'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkPermission() async {
    setState(() => _isCheckingPermission = true);

    try {
      ref.invalidate(hasPermissionProvider);
      final hasPermission = await ref.read(hasPermissionProvider.future);
      
      if (hasPermission) {
        final storageService = ref.read(storageServiceProvider);
        await storageService.setHasSeenSetup(true);
        
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Permissão ainda não concedida. Siga um dos métodos acima.'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingPermission = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permissão Concedida!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agora você pode usar todas as funcionalidades do DNS Manager.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha dialog
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('Começar a usar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('Ajuda'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'O que é ADB?',
                'ADB (Android Debug Bridge) é uma ferramenta oficial do Google para comunicação com dispositivos Android via computador.',
              ),
              _buildHelpItem(
                'É seguro?',
                'Sim! Você está apenas concedendo uma permissão de sistema para o app. Não é necessário root ou modificações no sistema.',
              ),
              _buildHelpItem(
                'Preciso fazer isso toda vez?',
                'Não! Após conceder a permissão uma vez, ela permanece mesmo após reiniciar o celular. Só é necessário repetir se você reinstalar o app.',
              ),
              _buildHelpItem(
                'Qual método escolher?',
                '• USB + ADB: Mais fácil se você tem PC\n'
                '• LADB: Melhor se não tem PC (Android 11+)\n'
                '• Shizuku: Útil se já usa o Shizuku',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
