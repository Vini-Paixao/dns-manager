import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/dns_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'theme/app_theme.dart';

/// Widget raiz do aplicativo DNS Manager
/// 
/// Configura:
/// - Tema Material 3 com suporte a claro/escuro/sistema
/// - Rotas de navegação
/// - Verificação inicial de permissão
class DnsManagerApp extends ConsumerStatefulWidget {
  const DnsManagerApp({super.key});

  @override
  ConsumerState<DnsManagerApp> createState() => _DnsManagerAppState();
}

class _DnsManagerAppState extends ConsumerState<DnsManagerApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Inicializa o serviço de armazenamento
    final storageService = ref.read(storageServiceProvider);
    await storageService.init();
  }

  @override
  Widget build(BuildContext context) {
    // Observa o modo de tema atual
    final themeMode = ref.watch(flutterThemeModeProvider);
    
    return MaterialApp(
      title: 'DNS Manager',
      debugShowCheckedModeBanner: false,
      
      // Temas com suporte a claro/escuro
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Tela inicial com verificação de permissão
      home: const _InitialScreen(),
      
      // Rotas nomeadas
      routes: {
        '/home': (context) => const HomeScreen(),
        '/setup': (context) => const SetupScreen(),
      },
    );
  }
}

/// Tela inicial que decide para onde navegar
/// 
/// Verifica:
/// 1. Se tem permissão WRITE_SECURE_SETTINGS
/// 2. Se o usuário já viu a tela de setup
/// 
/// Baseado nisso, redireciona para Home ou Setup
class _InitialScreen extends ConsumerWidget {
  const _InitialScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermissionAsync = ref.watch(hasPermissionProvider);
    
    return hasPermissionAsync.when(
      data: (hasPermission) {
        // Se tem permissão, vai para home
        if (hasPermission) {
          return const HomeScreen();
        }
        
        // Se não tem permissão, mostra setup
        // independente de já ter visto antes
        return const SetupScreen();
      },
      loading: () => const _SplashScreen(),
      error: (error, stack) => _ErrorScreen(error: error.toString()),
    );
  }
}

/// Tela de splash enquanto carrega
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone com gradiente
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dns_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'DNS Manager',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 48),
            
            const CircularProgressIndicator(
              color: Color(0xFF7C4DFF),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela de erro
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Erro ao inicializar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Reinicia o app
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
