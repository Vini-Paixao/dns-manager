import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dns_server.dart';
import '../providers/dns_provider.dart';
import '../providers/history_provider.dart';
import '../services/dns_service.dart';
import '../theme/app_colors.dart';
import '../widgets/server_card.dart';
import '../widgets/server_form_dialog.dart';
import '../widgets/server_info_dialog.dart';
import '../widgets/server_options_sheet.dart';
import '../widgets/status_card.dart';
import 'settings_screen.dart';

/// Tela principal do aplicativo DNS Manager
/// 
/// Exibe:
/// - Status atual do DNS (ativo/inativo)
/// - Toggle para ativar/desativar
/// - Lista de servidores DNS com drag-and-drop
/// - Opção para adicionar servidor customizado
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isToggling = false;
  bool _isReorderMode = false;
  bool _isTestingLatency = false;

  @override
  void initState() {
    super.initState();
    // Testa latências ao iniciar (com delay para não bloquear UI)
    Future.delayed(const Duration(milliseconds: 500), _testAllLatencies);
  }

  /// Testa a latência de todos os servidores
  Future<void> _testAllLatencies() async {
    if (_isTestingLatency) return;
    
    setState(() => _isTestingLatency = true);
    
    final servers = ref.read(serversProvider);
    final hostnames = servers.map((s) => s.hostname).toList();
    
    await ref.read(latencyProvider.notifier).testAllServers(hostnames);
    
    if (mounted) {
      setState(() => _isTestingLatency = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dnsStatusAsync = ref.watch(dnsStatusAutoRefreshProvider);
    // Modo reordenação mostra todos os servidores, modo normal mostra só visíveis
    final servers = _isReorderMode 
        ? ref.watch(serversProvider) 
        : ref.watch(visibleServersProvider);
    final allServers = ref.watch(serversProvider);
    final hiddenCount = allServers.where((s) => s.isHidden).length;
    final selectedServer = ref.watch(selectedServerProvider);
    final latencies = ref.watch(latencyProvider);
    
    // Cores adaptadas ao tema
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshStatus,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header e Status Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(cardColor),
                      const SizedBox(height: 24),
                      dnsStatusAsync.when(
                        data: (status) => _buildStatusCard(status, selectedServer),
                        loading: () => _buildStatusCardLoading(),
                        error: (e, _) => _buildStatusCardError(e.toString()),
                      ),
                      const SizedBox(height: 28),
                      _buildServersHeader(servers.length, hiddenCount, cardColor, isDarkMode),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Lista de servidores com drag-and-drop
              _buildServerGrid(servers, selectedServer, dnsStatusAsync, latencies),

              // Espaço final
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      
      // FAB para adicionar servidor
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServerDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo DNS'),
      ),
    );
  }

  Widget _buildHeader(Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DNS Manager',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Gerencie seu DNS privado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Botão de testar latência
            IconButton(
              onPressed: _isTestingLatency ? null : _testAllLatencies,
              icon: _isTestingLatency
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[400],
                      ),
                    )
                  : const Icon(Icons.speed_rounded),
              tooltip: 'Testar latência',
              style: IconButton.styleFrom(
                backgroundColor: cardColor,
              ),
            ),
            const SizedBox(width: 8),
            // Botão de reordenar
            IconButton(
              onPressed: () {
                setState(() => _isReorderMode = !_isReorderMode);
                if (_isReorderMode) {
                  HapticFeedback.mediumImpact();
                  _showSnackBar('Arraste para reordenar', isSuccess: true);
                }
              },
              icon: Icon(
                _isReorderMode ? Icons.done_rounded : Icons.swap_vert_rounded,
                color: _isReorderMode ? AppColors.secondary : null,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _isReorderMode 
                    ? AppColors.secondary.withOpacity(0.2)
                    : cardColor,
              ),
            ),
            const SizedBox(width: 8),
            // Botão de configurações
            IconButton(
              onPressed: _showSettings,
              icon: const Icon(Icons.settings_outlined),
              style: IconButton.styleFrom(
                backgroundColor: cardColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(DnsStatus status, DnsServer? selectedServer) {
    return StatusCard(
      isEnabled: status.enabled,
      hostname: status.hostname,
      isToggling: _isToggling,
      onToggle: (value) => _toggleDns(value, selectedServer),
    );
  }

  Widget _buildStatusCardLoading() {
    return const StatusCardLoading();
  }

  Widget _buildStatusCardError(String error) {
    return StatusCardError(error: error);
  }

  Widget _buildServersHeader(int count, int hiddenCount, Color cardColor, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Servidores DNS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (hiddenCount > 0 && !_isReorderMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off_rounded,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$hiddenCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isReorderMode 
                    ? '$count servidores (toque no 👁 para ocultar)'
                    : '$count servidores disponíveis${hiddenCount > 0 ? ' • $hiddenCount ocultos' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        if (_isReorderMode)
          TextButton.icon(
            onPressed: () {
              setState(() => _isReorderMode = false);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Concluir'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
            ),
          ),
      ],
    );
  }

  Widget _buildServerGrid(
    List<DnsServer> servers,
    DnsServer? selectedServer,
    AsyncValue<DnsStatus> dnsStatusAsync,
    Map<String, int?> latencies,
  ) {
    final currentHostname = dnsStatusAsync.valueOrNull?.hostname;
    final isEnabled = dnsStatusAsync.valueOrNull?.enabled ?? false;

    if (_isReorderMode) {
      // Modo reordenação com drag-and-drop (layout compacto horizontal)
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverReorderableList(
          itemCount: servers.length,
          itemBuilder: (context, index) {
            final server = servers[index];
            final isActive = isEnabled && server.hostname == currentHostname;
            final isSelected = selectedServer?.id == server.id;

            return ReorderableDragStartListener(
              key: ValueKey(server.id),
              index: index,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: server.isHidden ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ServerCard(
                    server: server,
                    isSelected: isSelected,
                    isActive: isActive,
                    latency: latencies[server.hostname],
                    isTestingLatency: _isTestingLatency,
                    showFavoriteButton: false,
                    showHideButton: true, // Mostrar botão de ocultar
                    isDragging: false,
                    isCompact: true, // Layout horizontal compacto
                    onTap: null,
                    onHideToggle: () {
                      HapticFeedback.lightImpact();
                      ref.read(serversProvider.notifier).toggleHidden(server.id);
                      _showSnackBar(
                        server.isHidden 
                            ? '${server.name} visível na dashboard' 
                            : '${server.name} oculto da dashboard',
                        isSuccess: true,
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            HapticFeedback.mediumImpact();
            ref.read(serversProvider.notifier).reorderServers(oldIndex, newIndex);
          },
        ),
      );
    }

    // Modo normal com Grid adaptativo
    // 1 coluna para 1-2 servidores, 2 colunas para 3+
    final crossAxisCount = servers.length <= 2 ? 1 : 2;
    // Ajusta aspect ratio baseado no layout
    final childAspectRatio = crossAxisCount == 1 ? 2.5 : 1.1;
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final server = servers[index];
            final isActive = isEnabled && server.hostname == currentHostname;
            final isSelected = selectedServer?.id == server.id;

            return ServerCard(
              server: server,
              isSelected: isSelected,
              isActive: isActive,
              latency: latencies[server.hostname],
              isTestingLatency: _isTestingLatency,
              // Usa layout horizontal elegante quando é grid de 1 coluna
              isHorizontal: crossAxisCount == 1,
              onTap: () => _selectServer(server),
              onLongPress: () => _showServerOptions(server),
              onFavoriteToggle: () => _toggleFavorite(server),
              onInfoTap: () => ServerInfoDialog.show(
                context: context,
                server: server,
              ),
            );
          },
          childCount: servers.length,
        ),
      ),
    );
  }

  Future<void> _refreshStatus() async {
    ref.read(dnsStatusRefreshProvider.notifier).state++;
    await ref.read(dnsStatusAutoRefreshProvider.future);
  }

  Future<void> _toggleDns(bool enable, DnsServer? selectedServer) async {
    if (_isToggling) return;
    
    setState(() => _isToggling = true);
    HapticFeedback.mediumImpact();

    try {
      final dnsService = ref.read(dnsServiceProvider);
      
      if (enable) {
        final server = selectedServer ?? ref.read(serversProvider).first;
        
        // Testa latência antes de ativar
        final latency = await dnsService.testLatency(server.hostname);
        
        final success = await dnsService.setDns(server.hostname);
        
        if (success) {
          ref.read(selectedServerProvider.notifier).selectServer(server);
          _showSnackBar('DNS ativado: ${server.name}', isSuccess: true);
          
          // Registra ativação no histórico
          ref.read(historyProvider.notifier).recordActivation(
            serverId: server.id,
            serverName: server.name,
            hostname: server.hostname,
            latencyMs: latency,
          );
        } else {
          _showSnackBar('Erro ao ativar DNS. Verifique a permissão.', isSuccess: false);
          
          // Registra falha no histórico
          ref.read(historyProvider.notifier).recordFailure(
            serverId: server.id,
            serverName: server.name,
            hostname: server.hostname,
            failureReason: 'Falha ao ativar DNS - permissão negada',
          );
        }
      } else {
        // Registra desativação antes de desativar
        ref.read(historyProvider.notifier).recordDeactivation();
        
        final success = await dnsService.disableDns();
        
        if (success) {
          _showSnackBar('DNS desativado', isSuccess: true);
        } else {
          _showSnackBar('Erro ao desativar DNS', isSuccess: false);
        }
      }
      
      ref.read(dnsStatusRefreshProvider.notifier).state++;
    } finally {
      setState(() => _isToggling = false);
    }
  }

  void _selectServer(DnsServer server) async {
    final dnsStatus = ref.read(dnsStatusAutoRefreshProvider).valueOrNull;
    final wasEnabled = dnsStatus?.enabled ?? false;
    
    HapticFeedback.selectionClick();
    ref.read(selectedServerProvider.notifier).selectServer(server);
    
    if (wasEnabled) {
      setState(() => _isToggling = true);
      
      try {
        final dnsService = ref.read(dnsServiceProvider);
        
        // Registra desativação do servidor anterior
        ref.read(historyProvider.notifier).recordDeactivation();
        
        // Testa latência antes de ativar
        final latency = await dnsService.testLatency(server.hostname);
        
        final success = await dnsService.setDns(server.hostname);
        
        if (success) {
          _showSnackBar('Alterado para ${server.name}', isSuccess: true);
          
          // Registra ativação do novo servidor no histórico
          ref.read(historyProvider.notifier).recordActivation(
            serverId: server.id,
            serverName: server.name,
            hostname: server.hostname,
            latencyMs: latency,
          );
        } else {
          _showSnackBar('Erro ao alterar servidor', isSuccess: false);
          
          // Registra falha no histórico
          ref.read(historyProvider.notifier).recordFailure(
            serverId: server.id,
            serverName: server.name,
            hostname: server.hostname,
            failureReason: 'Falha ao trocar de servidor',
          );
        }
        
        ref.read(dnsStatusRefreshProvider.notifier).state++;
      } finally {
        setState(() => _isToggling = false);
      }
    } else {
      _showSnackBar('${server.name} selecionado', isSuccess: true);
    }
  }

  void _toggleFavorite(DnsServer server) {
    HapticFeedback.lightImpact();
    ref.read(serversProvider.notifier).toggleFavorite(server.id);
    
    final message = server.isFavorite 
        ? '${server.name} removido dos favoritos'
        : '${server.name} adicionado aos favoritos';
    _showSnackBar(message, isSuccess: true);
  }

  void _toggleHidden(DnsServer server) {
    HapticFeedback.lightImpact();
    ref.read(serversProvider.notifier).toggleHidden(server.id);
    
    final message = server.isHidden 
        ? '${server.name} agora está visível'
        : '${server.name} foi ocultado';
    _showSnackBar(message, isSuccess: true);
  }

  void _showServerOptions(DnsServer server) {
    HapticFeedback.mediumImpact();
    
    ServerOptionsSheet.show(
      context: context,
      server: server,
      onFavoriteToggle: () => _toggleFavorite(server),
      onHideToggle: () => _toggleHidden(server),
      onEdit: server.isCustom ? () => _showEditServerDialog(server) : null,
      onDelete: server.isCustom ? () => _confirmDeleteServer(server) : null,
    );
  }

  void _showAddServerDialog() {
    ServerFormDialog.show(
      context: context,
      onSave: (server) async {
        final success = await ref.read(serversProvider.notifier).addServer(server);
        if (mounted) {
          if (success) {
            _showSnackBar('${server.name} adicionado!', isSuccess: true);
          } else {
            _showSnackBar('Este servidor já existe', isSuccess: false);
          }
        }
        return success;
      },
    );
  }

  void _showEditServerDialog(DnsServer server) {
    ServerFormDialog.show(
      context: context,
      server: server,
      onSave: (updatedServer) async {
        await ref.read(serversProvider.notifier).updateServer(updatedServer);
        if (mounted) {
          _showSnackBar('Servidor atualizado!', isSuccess: true);
        }
        return true;
      },
    );
  }

  void _confirmDeleteServer(DnsServer server) {
    DeleteServerDialog.show(
      context: context,
      server: server,
      onConfirm: () async {
        await ref.read(serversProvider.notifier).removeServer(server.id);
        if (mounted) {
          _showSnackBar('${server.name} removido', isSuccess: true);
        }
      },
    );
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? AppColors.success : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
