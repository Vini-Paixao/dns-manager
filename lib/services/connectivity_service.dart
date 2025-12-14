import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Resultado de um teste de conectividade
class ConnectivityResult {
  final bool success;
  final String testName;
  final String? errorMessage;
  final int? latencyMs;
  final DateTime timestamp;

  ConnectivityResult({
    required this.success,
    required this.testName,
    this.errorMessage,
    this.latencyMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    if (success) {
      return '$testName: OK (${latencyMs}ms)';
    }
    return '$testName: FALHA - $errorMessage';
  }
}

/// Resultado completo da verificação de conectividade
class FullConnectivityCheck {
  final ConnectivityResult tcpTest;
  final ConnectivityResult dnsTest;
  final bool overallSuccess;
  final DateTime timestamp;

  FullConnectivityCheck({
    required this.tcpTest,
    required this.dnsTest,
    DateTime? timestamp,
  }) : overallSuccess = tcpTest.success && dnsTest.success,
       timestamp = timestamp ?? DateTime.now();

  String get statusMessage {
    if (overallSuccess) {
      return 'DNS funcionando corretamente';
    }
    
    if (!tcpTest.success) {
      return 'Servidor DNS não está respondendo';
    }
    
    if (!dnsTest.success) {
      return 'DNS não está resolvendo domínios';
    }
    
    return 'Verificação incompleta';
  }

  int? get averageLatency {
    final latencies = [tcpTest.latencyMs, dnsTest.latencyMs]
        .where((l) => l != null)
        .cast<int>()
        .toList();
    
    if (latencies.isEmpty) return null;
    return latencies.reduce((a, b) => a + b) ~/ latencies.length;
  }
}

/// Serviço para verificar conectividade DNS
/// 
/// Realiza testes em múltiplos níveis para garantir que o DNS está funcionando
class ConnectivityService {
  
  /// Timeout padrão para testes
  static const Duration defaultTimeout = Duration(seconds: 5);
  
  /// Domínios para testar resolução DNS
  static const List<String> testDomains = [
    'google.com',
    'cloudflare.com',
    'microsoft.com',
  ];

  /// Realiza verificação completa de conectividade do DNS
  /// 
  /// [hostname] é o servidor DNS a ser testado
  /// [delayBeforeTest] é o tempo de espera antes do teste (para propagação)
  static Future<FullConnectivityCheck> performFullCheck({
    required String hostname,
    Duration delayBeforeTest = const Duration(seconds: 2),
  }) async {
    // Aguarda propagação do DNS
    if (delayBeforeTest.inMilliseconds > 0) {
      await Future.delayed(delayBeforeTest);
    }

    // Teste 1: Conexão TCP na porta 853 (DoT)
    final tcpResult = await testTcpConnection(hostname);
    
    // Teste 2: Resolução DNS
    final dnsResult = await testDnsResolution();

    return FullConnectivityCheck(
      tcpTest: tcpResult,
      dnsTest: dnsResult,
    );
  }

  /// Testa conexão TCP com servidor DNS na porta 853 (DoT)
  static Future<ConnectivityResult> testTcpConnection(
    String hostname, {
    Duration timeout = defaultTimeout,
  }) async {
    const port = 853; // Porta DoT
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final socket = await Socket.connect(
        hostname,
        port,
        timeout: timeout,
      );
      
      stopwatch.stop();
      await socket.close();
      
      return ConnectivityResult(
        success: true,
        testName: 'Conexão TCP',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on SocketException catch (e) {
      return ConnectivityResult(
        success: false,
        testName: 'Conexão TCP',
        errorMessage: 'Servidor não respondeu: ${e.message}',
      );
    } on TimeoutException {
      return ConnectivityResult(
        success: false,
        testName: 'Conexão TCP',
        errorMessage: 'Timeout - servidor muito lento',
      );
    } catch (e) {
      return ConnectivityResult(
        success: false,
        testName: 'Conexão TCP',
        errorMessage: 'Erro: $e',
      );
    }
  }

  /// Testa resolução de DNS usando domínios conhecidos
  static Future<ConnectivityResult> testDnsResolution({
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Tenta resolver múltiplos domínios
      for (final domain in testDomains) {
        try {
          final addresses = await InternetAddress.lookup(domain)
              .timeout(timeout);
          
          if (addresses.isNotEmpty) {
            stopwatch.stop();
            return ConnectivityResult(
              success: true,
              testName: 'Resolução DNS',
              latencyMs: stopwatch.elapsedMilliseconds,
            );
          }
        } catch (e) {
          // Tenta o próximo domínio
          debugPrint('Falha ao resolver $domain: $e');
        }
      }
      
      // Todos os domínios falharam
      return ConnectivityResult(
        success: false,
        testName: 'Resolução DNS',
        errorMessage: 'Não foi possível resolver nenhum domínio',
      );
    } on TimeoutException {
      return ConnectivityResult(
        success: false,
        testName: 'Resolução DNS',
        errorMessage: 'Timeout na resolução DNS',
      );
    } catch (e) {
      return ConnectivityResult(
        success: false,
        testName: 'Resolução DNS',
        errorMessage: 'Erro: $e',
      );
    }
  }

  /// Verifica rapidamente se há conectividade com a internet
  static Future<bool> hasInternetConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Testa latência contínua de um servidor DNS
  /// 
  /// Retorna um Stream de resultados de latência
  static Stream<int?> monitorLatency(
    String hostname, {
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (true) {
      final result = await testTcpConnection(hostname);
      yield result.latencyMs;
      await Future.delayed(interval);
    }
  }

  /// Verifica se o DNS está funcionando corretamente após ativação
  /// 
  /// Retorna true se o DNS está funcionando, false caso contrário
  /// [onProgress] callback para feedback de progresso
  static Future<bool> verifyDnsAfterActivation({
    required String hostname,
    Duration delayBeforeTest = const Duration(seconds: 2),
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Aguardando propagação...');
    await Future.delayed(delayBeforeTest);
    
    onProgress?.call('Testando conexão com servidor...');
    final tcpResult = await testTcpConnection(hostname);
    
    if (!tcpResult.success) {
      onProgress?.call('Falha na conexão TCP');
      return false;
    }
    
    onProgress?.call('Testando resolução de DNS...');
    final dnsResult = await testDnsResolution();
    
    if (!dnsResult.success) {
      onProgress?.call('Falha na resolução DNS');
      return false;
    }
    
    onProgress?.call('DNS funcionando corretamente!');
    return true;
  }
}
