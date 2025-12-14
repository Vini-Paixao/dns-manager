import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/notification_service.dart';

/// Ponto de entrada do aplicativo DNS Manager
/// 
/// Configura:
/// - WidgetsFlutterBinding para garantir inicialização
/// - Orientação fixa em portrait
/// - Estilo da status bar
/// - ProviderScope para Riverpod
void main() async {
  // Garante que os widgets estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configura orientação apenas portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configura estilo da status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializa o serviço de notificações
  await NotificationService.initialize();

  // Inicia o app com Riverpod
  runApp(
    const ProviderScope(
      child: DnsManagerApp(),
    ),
  );
}
