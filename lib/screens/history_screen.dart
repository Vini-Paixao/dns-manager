import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usage_record.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Uso'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cleanup',
                child: ListTile(
                  leading: Icon(Icons.cleaning_services),
                  title: Text('Limpar antigos'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_forever),
                  title: Text('Limpar tudo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Exportar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Histórico', icon: Icon(Icons.history)),
            Tab(text: 'Estatísticas', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: historyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(historyState, theme),
                _buildStatisticsTab(historyState.statistics, theme),
              ],
            ),
    );
  }

  Widget _buildHistoryTab(HistoryState historyState, ThemeData theme) {
    if (historyState.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum registro encontrado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O histórico de uso será exibido aqui',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtro de período
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Período: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('7 dias'),
                selected: _selectedDays == 7,
                onSelected: (selected) => setState(() => _selectedDays = 7),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('30 dias'),
                selected: _selectedDays == 30,
                onSelected: (selected) => setState(() => _selectedDays = 30),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Todos'),
                selected: _selectedDays == 0,
                onSelected: (selected) => setState(() => _selectedDays = 0),
              ),
            ],
          ),
        ),
        
        // Lista de registros
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(historyProvider.notifier).loadHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredRecords(historyState.records).length,
              itemBuilder: (context, index) {
                final record = _filteredRecords(historyState.records)[index];
                return _buildRecordCard(record, theme);
              },
            ),
          ),
        ),
      ],
    );
  }

  List<UsageRecord> _filteredRecords(List<UsageRecord> records) {
    if (_selectedDays == 0) return records;
    
    final cutoff = DateTime.now().subtract(Duration(days: _selectedDays));
    return records.where((r) => r.activatedAt.isAfter(cutoff)).toList();
  }

  Widget _buildRecordCard(UsageRecord record, ThemeData theme) {
    final isActive = record.deactivatedAt == null;
    final statusColor = record.wasSuccessful
        ? Colors.green
        : record.failureReason != null
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.serverName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ATIVO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.hostname,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(record.activatedAt),
                  style: theme.textTheme.bodySmall,
                ),
                if (record.duration != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.formattedDuration,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (record.latencyMs != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${record.latencyMs}ms',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getLatencyColor(record.latencyMs!),
                    ),
                  ),
                ],
              ],
            ),
            if (record.failureReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.failureReason!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(UsageStatistics? statistics, ThemeData theme) {
    if (statistics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma estatística disponível',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de estatísticas principais
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                  title: 'Total de Ativações',
                  value: statistics.totalActivations.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: Icons.timer,
                  iconColor: theme.colorScheme.primary,
                  title: 'Tempo Total',
                  value: _formatDuration(statistics.totalUsageTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: Icons.speed,
                  iconColor: Colors.blue,
                  title: 'Latência Média',
                  value: statistics.averageLatencyMs != null
                      ? '${statistics.averageLatencyMs!.toStringAsFixed(0)}ms'
                      : 'N/A',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  theme,
                  icon: statistics.successRate >= 90
                      ? Icons.sentiment_very_satisfied
                      : statistics.successRate >= 70
                          ? Icons.sentiment_satisfied
                          : Icons.sentiment_dissatisfied,
                  iconColor: _getSuccessRateColor(statistics.successRate),
                  title: 'Taxa de Sucesso',
                  value: '${statistics.successRate.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Servidores mais usados
          Text(
            'Servidores Mais Usados',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (statistics.serverUsageCount.isEmpty)
            Text(
              'Nenhum servidor utilizado ainda',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          else
            ...statistics.serverUsageCount.entries.map((entry) {
              final percentage = (entry.value / statistics.totalActivations * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          '${entry.value}x (${percentage.toStringAsFixed(0)}%)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          
          const SizedBox(height: 24),
          
          // Informações adicionais
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    theme,
                    'Ativações com sucesso',
                    statistics.successfulActivations.toString(),
                  ),
                  _buildInfoRow(
                    theme,
                    'Falhas de conexão',
                    statistics.failedActivations.toString(),
                  ),
                  if (statistics.firstActivation != null)
                    _buildInfoRow(
                      theme,
                      'Primeira ativação',
                      _formatDateTime(statistics.firstActivation!),
                    ),
                  if (statistics.lastActivation != null)
                    _buildInfoRow(
                      theme,
                      'Última ativação',
                      _formatDateTime(statistics.lastActivation!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }

  Color _getLatencyColor(int latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.lightGreen;
    if (latency < 200) return Colors.orange;
    return Colors.red;
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'cleanup':
        _showCleanupDialog();
        break;
      case 'clear':
        _showClearDialog();
        break;
      case 'export':
        _exportHistory();
        break;
    }
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar registros antigos'),
        content: const Text(
          'Isso irá remover registros com mais de 30 dias. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(this.context);
              final count = await ref.read(historyProvider.notifier).cleanupOldRecords();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('$count registros removidos')),
                );
              }
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todo o histórico'),
        content: const Text(
          'Isso irá remover todos os registros de uso. Esta ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(this.context);
              await ref.read(historyProvider.notifier).clearHistory();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Histórico limpo')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );
  }

  void _exportHistory() async {
    try {
      final json = await ref.read(historyProvider.notifier).exportHistory();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exportar Histórico'),
            content: SingleChildScrollView(
              child: SelectableText(
                json,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }
}
