import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dns_provider.dart';
import '../theme/app_theme.dart';

/// Tela de setup inicial com instruções para conceder permissão via ADB
/// 
/// Esta tela é exibida na primeira vez que o usuário abre o app
/// ou quando a permissão WRITE_SECURE_SETTINGS não foi concedida
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool _isCheckingPermission = false;
  int _currentStep = 0;

  // Comando ADB para conceder permissão
  static const String adbCommand = 
      'adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header com ícone e título
              _buildHeader(),
              
              const SizedBox(height: 32),
              
              // Card de explicação
              _buildExplanationCard(),
              
              const SizedBox(height: 24),
              
              // Passos do setup
              _buildSetupSteps(),
              
              const SizedBox(height: 32),
              
              // Card com comando ADB
              _buildCommandCard(),
              
              const SizedBox(height: 32),
              
              // Botões de ação
              _buildActionButtons(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone animado
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.dns_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Configuração Inicial',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Precisamos de uma permissão especial para gerenciar o DNS do seu dispositivo.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF7C4DFF),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'A permissão WRITE_SECURE_SETTINGS não pode ser concedida diretamente pelo Android. '
              'É necessário usar o ADB (Android Debug Bridge) conectado ao computador.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupSteps() {
    final steps = [
      {
        'icon': Icons.usb_rounded,
        'title': 'Conecte via USB',
        'description': 'Conecte seu dispositivo ao computador com cabo USB e ative a Depuração USB nas Opções de Desenvolvedor.',
      },
      {
        'icon': Icons.download_rounded,
        'title': 'Instale o ADB',
        'description': 'Baixe e instale o Android SDK Platform Tools no seu computador.',
      },
      {
        'icon': Icons.terminal_rounded,
        'title': 'Execute o comando',
        'description': 'Abra o terminal/prompt de comando e execute o comando abaixo.',
      },
      {
        'icon': Icons.verified_rounded,
        'title': 'Verifique',
        'description': 'Clique em "Verificar Permissão" para confirmar que foi concedida.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passos para configuração',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return GestureDetector(
            onTap: () => setState(() => _currentStep = index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive 
                    ? const Color(0xFF7C4DFF).withOpacity(0.15)
                    : const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive 
                      ? const Color(0xFF7C4DFF)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Número/Check do passo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF00BFA5)
                          : isActive
                              ? const Color(0xFF7C4DFF)
                              : Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Conteúdo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step['description'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Ícone
                  Icon(
                    step['icon'] as IconData,
                    color: isActive ? const Color(0xFF7C4DFF) : Colors.grey[600],
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCommandCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comando ADB',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
            ),
          ),
          child: Column(
            children: [
              // Comando
              Row(
                children: [
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF00BFA5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      adbCommand,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF00BFA5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Botão copiar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyCommand,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar comando'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00BFA5),
                    side: const BorderSide(color: Color(0xFF00BFA5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botão verificar permissão
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isCheckingPermission ? null : _checkPermission,
            icon: _isCheckingPermission
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user_rounded),
            label: Text(
              _isCheckingPermission ? 'Verificando...' : 'Verificar Permissão',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Link para ajuda
        TextButton.icon(
          onPressed: _showHelpDialog,
          icon: const Icon(Icons.help_outline, size: 18),
          label: const Text('Precisa de ajuda?'),
        ),
      ],
    );
  }

  void _copyCommand() {
    Clipboard.setData(const ClipboardData(text: adbCommand));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00BFA5)),
            const SizedBox(width: 12),
            const Text('Comando copiado!'),
          ],
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _checkPermission() async {
    setState(() => _isCheckingPermission = true);

    try {
      // Invalida o cache e verifica novamente
      ref.invalidate(hasPermissionProvider);
      
      final hasPermission = await ref.read(hasPermissionProvider.future);
      
      if (hasPermission) {
        // Permissão concedida! Marca como visto e navega
        final storageService = ref.read(storageServiceProvider);
        await storageService.setHasSeenSetup(true);
        
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        // Permissão ainda não concedida
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Permissão não encontrada. Execute o comando ADB e tente novamente.',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2D2D2D),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00BFA5),
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
              'Agora você pode gerenciar o DNS privado do seu dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
              ),
              child: const Text('Começar'),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajuda'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'Como ativar a Depuração USB?',
                '1. Vá em Configurações > Sobre o telefone\n'
                '2. Toque 7 vezes em "Número da versão"\n'
                '3. Volte e acesse "Opções do desenvolvedor"\n'
                '4. Ative "Depuração USB"',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'Onde baixar o ADB?',
                'Pesquise por "Android SDK Platform Tools" no Google '
                'e baixe do site oficial do Android Developers.',
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                'O comando não funciona?',
                'Certifique-se que:\n'
                '• O dispositivo está conectado via USB\n'
                '• Depuração USB está ativa\n'
                '• Você autorizou o computador no popup do celular\n'
                '• O ADB está no PATH do sistema',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C4DFF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
