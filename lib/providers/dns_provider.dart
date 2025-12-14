import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dns_server.dart';
import '../services/dns_service.dart';
import '../services/storage_service.dart';

// ============================================
// PROVIDERS DE SERVIÇOS
// ============================================

/// Provider para o serviço de DNS
final dnsServiceProvider = Provider<DnsService>((ref) {
  return DnsService();
});

/// Provider para o serviço de armazenamento
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// ============================================
// PROVIDERS DE ESTADO
// ============================================

/// Estado de verificação de permissão
final hasPermissionProvider = FutureProvider<bool>((ref) async {
  final dnsService = ref.read(dnsServiceProvider);
  return await dnsService.hasPermission();
});

/// Estado atual do DNS (enabled, mode, hostname)
final dnsStatusProvider = FutureProvider<DnsStatus>((ref) async {
  final dnsService = ref.read(dnsServiceProvider);
  return await dnsService.getDnsStatus();
});

/// Provider para forçar atualização do status
final dnsStatusRefreshProvider = StateProvider<int>((ref) => 0);

/// Status do DNS com refresh automático
final dnsStatusAutoRefreshProvider = FutureProvider<DnsStatus>((ref) async {
  // Observa o contador de refresh para invalidar quando necessário
  ref.watch(dnsStatusRefreshProvider);
  
  final dnsService = ref.read(dnsServiceProvider);
  return await dnsService.getDnsStatus();
});

// ============================================
// ESTADO DOS SERVIDORES SALVOS
// ============================================

/// Notifier para gerenciar lista de servidores salvos
class ServersNotifier extends StateNotifier<List<DnsServer>> {
  final StorageService _storageService;

  ServersNotifier(this._storageService) : super([]) {
    _loadServers();
  }

  /// Carrega servidores do storage
  void _loadServers() {
    final saved = _storageService.loadServers();
    if (saved.isEmpty) {
      // Se não há servidores salvos, usa os padrões com ordem inicial
      final defaultServers = DefaultDnsServers.servers.asMap().entries.map((e) {
        return e.value.copyWith(order: e.key);
      }).toList();
      state = defaultServers;
      _storageService.saveServers(state);
    } else {
      state = _sortServers(saved);
    }
  }

  /// Ordena servidores: favoritos primeiro, depois por ordem personalizada
  List<DnsServer> _sortServers(List<DnsServer> servers) {
    final sorted = List<DnsServer>.from(servers);
    sorted.sort((a, b) {
      // Favoritos primeiro
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      // Depois por ordem personalizada
      return a.order.compareTo(b.order);
    });
    return sorted;
  }

  /// Adiciona um novo servidor (no início da lista)
  Future<bool> addServer(DnsServer server) async {
    // Verifica se já existe
    if (state.any((s) => s.hostname == server.hostname)) {
      return false;
    }

    // Novo servidor vai para o topo (ordem -1 para ficar antes dos outros)
    final minOrder = state.isEmpty ? 0 : state.map((s) => s.order).reduce((a, b) => a < b ? a : b);
    final newServer = server.copyWith(
      order: minOrder - 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = _sortServers([newServer, ...state]);
    return await _storageService.saveServers(state);
  }

  /// Remove um servidor pelo ID
  Future<bool> removeServer(String id) async {
    // Não permite remover servidores padrão
    final server = state.firstWhere((s) => s.id == id, orElse: () => state.first);
    if (!server.isCustom) {
      return false;
    }

    state = state.where((s) => s.id != id).toList();
    return await _storageService.saveServers(state);
  }

  /// Atualiza um servidor existente
  Future<bool> updateServer(DnsServer server) async {
    final index = state.indexWhere((s) => s.id == server.id);
    if (index == -1) return false;

    final updated = [
      ...state.sublist(0, index),
      server,
      ...state.sublist(index + 1),
    ];
    state = _sortServers(updated);
    return await _storageService.saveServers(state);
  }

  /// Toggle favorito de um servidor
  Future<bool> toggleFavorite(String id) async {
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return false;

    final server = state[index];
    final updated = server.copyWith(isFavorite: !server.isFavorite);
    
    final newList = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
    state = _sortServers(newList);
    return await _storageService.saveServers(state);
  }

  /// Toggle visibilidade de um servidor (ocultar/mostrar)
  Future<bool> toggleHidden(String id) async {
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return false;

    final server = state[index];
    final updated = server.copyWith(isHidden: !server.isHidden);
    
    final newList = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
    state = _sortServers(newList);
    return await _storageService.saveServers(state);
  }

  /// Reordena servidores (drag-and-drop)
  Future<bool> reorderServers(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.length) return false;
    if (newIndex < 0 || newIndex > state.length) return false;

    final items = List<DnsServer>.from(state);
    final item = items.removeAt(oldIndex);
    
    // Ajusta índice se movendo para baixo
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    items.insert(adjustedNewIndex, item);

    // Atualiza a ordem de todos os itens
    final reordered = items.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();

    state = reordered;
    return await _storageService.saveServers(state);
  }

  /// Reseta para os servidores padrão
  Future<void> resetToDefaults() async {
    final defaultServers = DefaultDnsServers.servers.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();
    state = defaultServers;
    await _storageService.saveServers(state);
  }

  /// Importa servidores de um backup
  /// 
  /// Substitui completamente a lista atual de servidores
  Future<bool> importServers(List<DnsServer> servers) async {
    if (servers.isEmpty) return false;
    
    // Reordena os servidores importados
    final imported = servers.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();
    
    state = _sortServers(imported);
    return await _storageService.saveServers(state);
  }
}

/// Provider da lista de servidores (todos)
final serversProvider = StateNotifierProvider<ServersNotifier, List<DnsServer>>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return ServersNotifier(storageService);
});

/// Provider para servidores visíveis (não ocultos)
final visibleServersProvider = Provider<List<DnsServer>>((ref) {
  final servers = ref.watch(serversProvider);
  return servers.where((s) => !s.isHidden).toList();
});

/// Provider para servidores ocultos
final hiddenServersProvider = Provider<List<DnsServer>>((ref) {
  final servers = ref.watch(serversProvider);
  return servers.where((s) => s.isHidden).toList();
});

// ============================================
// SERVIDOR SELECIONADO
// ============================================

/// Notifier para o servidor selecionado
class SelectedServerNotifier extends StateNotifier<DnsServer?> {
  final StorageService _storageService;
  final List<DnsServer> _servers;

  SelectedServerNotifier(this._storageService, this._servers) : super(null) {
    _loadSelected();
  }

  void _loadSelected() {
    final savedId = _storageService.getSelectedServerId();
    if (savedId != null) {
      try {
        state = _servers.firstWhere((s) => s.id == savedId);
      } catch (e) {
        // Se o servidor salvo não existe mais, usa o primeiro da lista
        state = _servers.isNotEmpty ? _servers.first : null;
      }
    } else {
      // Nenhum selecionado, usa o primeiro
      state = _servers.isNotEmpty ? _servers.first : null;
    }
  }

  Future<void> selectServer(DnsServer server) async {
    state = server;
    await _storageService.saveSelectedServerId(server.id);
  }

  void clearSelection() {
    state = null;
    _storageService.saveSelectedServerId(null);
  }
}

/// Provider do servidor selecionado
final selectedServerProvider = StateNotifierProvider<SelectedServerNotifier, DnsServer?>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final servers = ref.watch(serversProvider);
  return SelectedServerNotifier(storageService, servers);
});

// ============================================
// PROVIDER DE SETUP
// ============================================

/// Verifica se o usuário já viu a tela de setup
final hasSeenSetupProvider = StateProvider<bool>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return storageService.hasSeenSetup();
});

// ============================================
// ACTIONS / MÉTODOS
// ============================================

/// Provider para ativar DNS com um servidor específico
final activateDnsProvider = FutureProvider.family<bool, DnsServer>((ref, server) async {
  final dnsService = ref.read(dnsServiceProvider);
  
  final success = await dnsService.setDns(server.hostname);
  
  if (success) {
    // Atualiza o servidor selecionado
    ref.read(selectedServerProvider.notifier).selectServer(server);
    // Força refresh do status
    ref.read(dnsStatusRefreshProvider.notifier).state++;
  }
  
  return success;
});

/// Provider para desativar DNS
final deactivateDnsProvider = FutureProvider<bool>((ref) async {
  final dnsService = ref.read(dnsServiceProvider);
  
  final success = await dnsService.disableDns();
  
  if (success) {
    // Força refresh do status
    ref.read(dnsStatusRefreshProvider.notifier).state++;
  }
  
  return success;
});

// ============================================
// LATÊNCIA DOS SERVIDORES
// ============================================

/// Notifier para gerenciar dados de latência dos servidores
class LatencyNotifier extends StateNotifier<Map<String, int?>> {
  final DnsService _dnsService;
  bool _isLoading = false;

  LatencyNotifier(this._dnsService) : super({});

  bool get isLoading => _isLoading;

  /// Testa a latência de um servidor específico
  Future<int?> testServer(String hostname) async {
    _isLoading = true;
    final latency = await _dnsService.testLatency(hostname);
    state = {...state, hostname: latency};
    _isLoading = false;
    return latency;
  }

  /// Testa a latência de todos os servidores da lista
  Future<void> testAllServers(List<String> hostnames) async {
    _isLoading = true;
    
    // Testa em paralelo
    final results = await _dnsService.testMultipleLatencies(hostnames);
    state = {...state, ...results};
    
    _isLoading = false;
  }

  /// Limpa os dados de latência
  void clearLatencies() {
    state = {};
  }

  /// Obtém a latência de um servidor (ou null se não testado)
  int? getLatency(String hostname) => state[hostname];
}

/// Provider para dados de latência
final latencyProvider = StateNotifierProvider<LatencyNotifier, Map<String, int?>>((ref) {
  final dnsService = ref.read(dnsServiceProvider);
  return LatencyNotifier(dnsService);
});

/// Provider para verificar se está carregando latências
final isTestingLatencyProvider = Provider<bool>((ref) {
  final notifier = ref.watch(latencyProvider.notifier);
  return notifier.isLoading;
});
