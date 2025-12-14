import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dns_server.dart';
import '../providers/dns_provider.dart';
import '../services/dns_service.dart';
import '../theme/app_theme.dart';
import '../widgets/server_card.dart';
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
          color: const Color(0xFF7C4DFF),
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
                        data: (status) => _buildStatusCard(status, selectedServer, cardColor, isDarkMode),
                        loading: () => _buildStatusCardLoading(cardColor, isDarkMode),
                        error: (e, _) => _buildStatusCardError(e.toString(), cardColor, isDarkMode),
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
        backgroundColor: const Color(0xFF7C4DFF),
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
                color: _isReorderMode ? const Color(0xFF00BFA5) : null,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _isReorderMode 
                    ? const Color(0xFF00BFA5).withOpacity(0.2)
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

  Widget _buildStatusCard(DnsStatus status, DnsServer? selectedServer, Color cardColor, bool isDarkMode) {
    final isEnabled = status.enabled;
    final textColor = isDarkMode ? Colors.white : (isEnabled ? Colors.white : Colors.black87);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isEnabled ? AppTheme.primaryGradient : null,
        color: isEnabled ? null : cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : (isDarkMode ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DNS Privado',
                    style: TextStyle(
                      fontSize: 14,
                      color: isEnabled ? Colors.white70 : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEnabled ? 'Ativo' : 'Desativado',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              
              // Toggle switch
              Transform.scale(
                scale: 1.3,
                child: Switch(
                  value: isEnabled,
                  onChanged: _isToggling ? null : (value) => _toggleDns(value, selectedServer),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white24,
                  inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
            ],
          ),
          
          if (isEnabled && status.hostname != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dns_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servidor atual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      Text(
                        status.hostname!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCardLoading(Color cardColor, bool isDarkMode) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      ),
    );
  }

  Widget _buildStatusCardError(String error, Color cardColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
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
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Erro ao obter status',
            style: TextStyle(color: Colors.red[300]),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
              foregroundColor: const Color(0xFF00BFA5),
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
        final success = await dnsService.setDns(server.hostname);
        
        if (success) {
          ref.read(selectedServerProvider.notifier).selectServer(server);
          _showSnackBar('DNS ativado: ${server.name}', isSuccess: true);
        } else {
          _showSnackBar('Erro ao ativar DNS. Verifique a permissão.', isSuccess: false);
        }
      } else {
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
        final success = await dnsService.setDns(server.hostname);
        
        if (success) {
          _showSnackBar('Alterado para ${server.name}', isSuccess: true);
        } else {
          _showSnackBar('Erro ao alterar servidor', isSuccess: false);
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
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              Text(
                server.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                server.hostname,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              
              // Opções
              _buildOptionTile(
                icon: server.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                label: server.isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                color: Colors.amber,
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite(server);
                },
              ),
              
              const SizedBox(height: 8),
              _buildOptionTile(
                icon: server.isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                label: server.isHidden ? 'Mostrar servidor' : 'Ocultar servidor',
                color: server.isHidden ? Colors.green : Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _toggleHidden(server);
                },
              ),
              
              if (server.isCustom) ...[
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.edit_rounded,
                  label: 'Editar servidor',
                  color: const Color(0xFF7C4DFF),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditServerDialog(server);
                  },
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.delete_rounded,
                  label: 'Remover servidor',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteServer(server);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showAddServerDialog() {
    final nameController = TextEditingController();
    final hostnameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int? selectedColor;
    File? selectedImage;

    final availableColors = [
      0xFF7C4DFF, // Purple
      0xFF00BFA5, // Teal
      0xFFF38020, // Orange
      0xFF4285F4, // Blue
      0xFF68BC71, // Green
      0xFFE91E63, // Pink
      0xFFFF5722, // Deep Orange
      0xFF009688, // Teal Dark
    ];

    Future<void> pickImage(StateSetter setDialogState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setDialogState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Novo Servidor DNS'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seletor de Logo Personalizado
                  const Text(
                    'Logo (opcional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => pickImage(setDialogState),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedImage != null 
                                ? const Color(0xFF00BFA5) 
                                : Colors.grey[700]!,
                            width: 2,
                          ),
                        ),
                        child: selectedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      selectedImage!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setDialogState(() => selectedImage = null);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.grey[500],
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Escolher',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Ex: Meu DNS',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite um nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: hostnameController,
                    decoration: const InputDecoration(
                      labelText: 'Hostname (DoT)',
                      hintText: 'Ex: dns.example.com',
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o hostname';
                      }
                      final regex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?$');
                      if (!regex.hasMatch(value)) {
                        return 'Hostname inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Seletor de cor
                  const Text(
                    'Cor do card',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableColors.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedColor = color);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(color),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Color(color).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ] : null,
                          ),
                          child: isSelected 
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  String? savedLogoPath;
                  
                  // Salva a imagem personalizada no diretório do app
                  if (selectedImage != null) {
                    try {
                      final appDir = await getApplicationDocumentsDirectory();
                      final logosDir = Directory('${appDir.path}/logos');
                      if (!await logosDir.exists()) {
                        await logosDir.create(recursive: true);
                      }
                      
                      final timestamp = DateTime.now().millisecondsSinceEpoch;
                      final extension = selectedImage!.path.split('.').last;
                      final newPath = '${logosDir.path}/custom_$timestamp.$extension';
                      
                      await selectedImage!.copy(newPath);
                      savedLogoPath = newPath;
                    } catch (e) {
                      debugPrint('Erro ao salvar logo: $e');
                    }
                  }
                  
                  final newServer = DnsServer(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    hostname: hostnameController.text.trim(),
                    isCustom: true,
                    colorValue: selectedColor,
                    customLogoPath: savedLogoPath,
                  );

                  final success = await ref.read(serversProvider.notifier).addServer(newServer);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      _showSnackBar('${newServer.name} adicionado!', isSuccess: true);
                    } else {
                      _showSnackBar('Este servidor já existe', isSuccess: false);
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServerDialog(DnsServer server) {
    final nameController = TextEditingController(text: server.name);
    final hostnameController = TextEditingController(text: server.hostname);
    final formKey = GlobalKey<FormState>();
    int? selectedColor = server.colorValue;
    String? currentLogoPath = server.customLogoPath;
    File? newSelectedImage;
    bool removeCurrentLogo = false;

    final availableColors = [
      0xFF7C4DFF, 0xFF00BFA5, 0xFFF38020, 0xFF4285F4,
      0xFF68BC71, 0xFFE91E63, 0xFFFF5722, 0xFF009688,
    ];

    Future<void> pickImage(StateSetter setDialogState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setDialogState(() {
          newSelectedImage = File(pickedFile.path);
          removeCurrentLogo = false;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Determinar o que mostrar no preview
          Widget logoPreview;
          
          if (newSelectedImage != null) {
            // Nova imagem selecionada
            logoPreview = Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    newSelectedImage!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        newSelectedImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          } else if (currentLogoPath != null && !removeCurrentLogo && File(currentLogoPath).existsSync()) {
            // Logo atual existente
            logoPreview = Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(currentLogoPath),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        removeCurrentLogo = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Sem logo
            logoPreview = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[500], size: 32),
                const SizedBox(height: 4),
                Text('Escolher', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            );
          }
          
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Editar Servidor'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seletor de Logo
                    const Text(
                      'Logo (opcional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () => pickImage(setDialogState),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (newSelectedImage != null || (currentLogoPath != null && !removeCurrentLogo))
                                  ? const Color(0xFF00BFA5) 
                                  : Colors.grey[700]!,
                              width: 2,
                            ),
                          ),
                          child: logoPreview,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite um nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: hostnameController,
                      decoration: const InputDecoration(
                        labelText: 'Hostname (DoT)',
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite o hostname';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cor do card',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableColors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(color),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    String? finalLogoPath = currentLogoPath;
                    
                    // Se removeu o logo atual
                    if (removeCurrentLogo) {
                      finalLogoPath = null;
                    }
                    
                    // Se selecionou uma nova imagem
                    if (newSelectedImage != null) {
                      try {
                        final appDir = await getApplicationDocumentsDirectory();
                        final logosDir = Directory('${appDir.path}/logos');
                        if (!await logosDir.exists()) {
                          await logosDir.create(recursive: true);
                        }
                        
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final extension = newSelectedImage!.path.split('.').last;
                        final newPath = '${logosDir.path}/custom_$timestamp.$extension';
                        
                        await newSelectedImage!.copy(newPath);
                        finalLogoPath = newPath;
                      } catch (e) {
                        debugPrint('Erro ao salvar logo: $e');
                      }
                    }
                    
                    final updatedServer = server.copyWith(
                      name: nameController.text.trim(),
                      hostname: hostnameController.text.trim(),
                      colorValue: selectedColor,
                      customLogoPath: finalLogoPath,
                      clearCustomLogoPath: removeCurrentLogo && newSelectedImage == null,
                    );

                    await ref.read(serversProvider.notifier).updateServer(updatedServer);
                    
                    if (mounted) {
                      Navigator.pop(context);
                      _showSnackBar('Servidor atualizado!', isSuccess: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteServer(DnsServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remover servidor?'),
        content: Text(
          'O servidor "${server.name}" será removido permanentemente.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(serversProvider.notifier).removeServer(server.id);
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('${server.name} removido', isSuccess: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
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
              color: isSuccess ? const Color(0xFF00BFA5) : Colors.red,
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
