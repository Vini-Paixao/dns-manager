import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dns_server.dart';

/// Serviço de persistência de dados usando SharedPreferences
/// 
/// Gerencia o armazenamento local de:
/// - Lista de servidores DNS salvos
/// - Servidor selecionado atualmente
/// - Preferências do usuário
class StorageService {
  static const String _keyServers = 'dns_servers';
  static const String _keySelectedId = 'selected_server_id';
  static const String _keyHasSeenSetup = 'has_seen_setup';

  late SharedPreferences _prefs;

  /// Inicializa o serviço de armazenamento
  /// 
  /// Deve ser chamado antes de usar qualquer outro método
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Salva a lista de servidores DNS
  Future<bool> saveServers(List<DnsServer> servers) async {
    try {
      final jsonList = servers.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      return await _prefs.setString(_keyServers, jsonString);
    } catch (e) {
      print('Erro ao salvar servidores: $e');
      return false;
    }
  }

  /// Carrega a lista de servidores DNS salvos
  /// 
  /// Retorna lista vazia se não houver dados salvos
  List<DnsServer> loadServers() {
    try {
      final jsonString = _prefs.getString(_keyServers);
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => DnsServer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao carregar servidores: $e');
      return [];
    }
  }

  /// Salva o ID do servidor selecionado
  Future<bool> saveSelectedServerId(String? id) async {
    if (id == null) {
      return await _prefs.remove(_keySelectedId);
    }
    return await _prefs.setString(_keySelectedId, id);
  }

  /// Obtém o ID do servidor selecionado
  String? getSelectedServerId() {
    return _prefs.getString(_keySelectedId);
  }

  /// Verifica se o usuário já viu a tela de setup
  bool hasSeenSetup() {
    return _prefs.getBool(_keyHasSeenSetup) ?? false;
  }

  /// Marca que o usuário já viu a tela de setup
  Future<bool> setHasSeenSetup(bool value) async {
    return await _prefs.setBool(_keyHasSeenSetup, value);
  }

  /// Adiciona um servidor à lista existente
  Future<bool> addServer(DnsServer server) async {
    final servers = loadServers();
    
    // Verifica se já existe servidor com mesmo hostname
    final exists = servers.any((s) => s.hostname == server.hostname);
    if (exists) return false;
    
    servers.add(server);
    return await saveServers(servers);
  }

  /// Remove um servidor da lista pelo ID
  Future<bool> removeServer(String id) async {
    final servers = loadServers();
    servers.removeWhere((s) => s.id == id);
    return await saveServers(servers);
  }

  /// Atualiza um servidor existente
  Future<bool> updateServer(DnsServer server) async {
    final servers = loadServers();
    final index = servers.indexWhere((s) => s.id == server.id);
    
    if (index == -1) return false;
    
    servers[index] = server;
    return await saveServers(servers);
  }

  /// Limpa todos os dados salvos
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
