import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Status atual do DNS Privado
class DnsStatus {
  final bool enabled;
  final String mode;
  final String? hostname;

  DnsStatus({
    required this.enabled,
    required this.mode,
    this.hostname,
  });

  factory DnsStatus.fromMap(Map<dynamic, dynamic> map) {
    return DnsStatus(
      enabled: map['enabled'] as bool? ?? false,
      mode: map['mode'] as String? ?? 'off',
      hostname: map['hostname'] as String?,
    );
  }

  @override
  String toString() {
    return 'DnsStatus(enabled: $enabled, mode: $mode, hostname: $hostname)';
  }
}

/// Serviço para comunicação com código nativo Android via Platform Channel
/// 
/// Este serviço faz a ponte entre Flutter e as APIs nativas de DNS
/// do Android através do MethodChannel configurado em MainActivity.kt
class DnsService {
  // Canal de comunicação com código nativo
  static const MethodChannel _channel = MethodChannel('com.dnsmanager/dns');

  /// Verifica se o app tem a permissão WRITE_SECURE_SETTINGS
  /// 
  /// Esta permissão é necessária para modificar configurações de DNS
  /// e deve ser concedida via ADB:
  /// `adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS`
  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Erro ao verificar permissão: ${e.message}');
      return false;
    }
  }

  /// Obtém o status atual do DNS Privado
  /// 
  /// Retorna um [DnsStatus] com:
  /// - enabled: se o DNS privado está ativo
  /// - mode: modo atual (off, opportunistic, hostname)
  /// - hostname: hostname configurado (quando mode == hostname)
  Future<DnsStatus> getDnsStatus() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDnsStatus');
      if (result != null) {
        return DnsStatus.fromMap(result);
      }
      return DnsStatus(enabled: false, mode: 'off');
    } on PlatformException catch (e) {
      print('Erro ao obter status DNS: ${e.message}');
      return DnsStatus(enabled: false, mode: 'off');
    }
  }

  /// Configura o DNS Privado com um hostname específico
  /// 
  /// [hostname] deve ser um endereço DoT válido, como:
  /// - dns.google
  /// - 1dot1dot1dot1.cloudflare-dns.com
  /// - dns.quad9.net
  /// 
  /// Retorna true se configurado com sucesso
  Future<bool> setDns(String hostname) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setDns',
        {'hostname': hostname},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Erro ao configurar DNS: ${e.message}');
      return false;
    }
  }

  /// Desativa o DNS Privado
  /// 
  /// Retorna true se desativado com sucesso
  Future<bool> disableDns() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableDns');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Erro ao desativar DNS: ${e.message}');
      return false;
    }
  }

  /// Obtém o último hostname DNS utilizado
  /// 
  /// Útil para restaurar a configuração anterior
  Future<String> getLastHostname() async {
    try {
      final result = await _channel.invokeMethod<String>('getLastHostname');
      return result ?? 'dns.google';
    } on PlatformException catch (e) {
      print('Erro ao obter último hostname: ${e.message}');
      return 'dns.google';
    }
  }

  /// Salva um hostname como último utilizado
  /// 
  /// Persiste a escolha para uso futuro
  Future<bool> saveLastHostname(String hostname) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'saveLastHostname',
        {'hostname': hostname},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Erro ao salvar hostname: ${e.message}');
      return false;
    }
  }

  /// Testa a latência de conexão com um servidor DNS
  /// 
  /// [hostname] é o endereço do servidor DNS (ex: dns.google)
  /// Retorna a latência em milissegundos ou null se não conseguir conectar
  /// 
  /// O teste é feito via conexão TCP na porta 853 (DoT - DNS over TLS)
  Future<int?> testLatency(String hostname) async {
    const port = 853; // Porta padrão para DNS over TLS
    const timeout = Duration(seconds: 5);
    
    try {
      final stopwatch = Stopwatch()..start();
      
      // Tenta conectar na porta 853 (DoT)
      final socket = await Socket.connect(
        hostname,
        port,
        timeout: timeout,
      );
      
      stopwatch.stop();
      await socket.close();
      
      return stopwatch.elapsedMilliseconds;
    } on SocketException {
      // Servidor não respondeu ou não está disponível
      return null;
    } on TimeoutException {
      // Timeout - servidor muito lento
      return null;
    } catch (e) {
      print('Erro ao testar latência de $hostname: $e');
      return null;
    }
  }

  /// Testa a latência de múltiplos servidores em paralelo
  /// 
  /// [hostnames] lista de endereços para testar
  /// Retorna um Map com hostname -> latência (null se falhou)
  Future<Map<String, int?>> testMultipleLatencies(List<String> hostnames) async {
    final futures = hostnames.map((hostname) async {
      final latency = await testLatency(hostname);
      return MapEntry(hostname, latency);
    });
    
    final results = await Future.wait(futures);
    return Map.fromEntries(results);
  }
}
