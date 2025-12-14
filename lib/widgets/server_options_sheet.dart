import 'package:flutter/material.dart';
import '../models/dns_server.dart';
import '../theme/app_colors.dart';

/// BottomSheet com opções para um servidor DNS
/// 
/// Opções disponíveis:
/// - Favoritar/Desfavoritar
/// - Ocultar/Mostrar
/// - Editar (apenas servidores customizados)
/// - Remover (apenas servidores customizados)
class ServerOptionsSheet extends StatelessWidget {
  const ServerOptionsSheet({
    super.key,
    required this.server,
    required this.onFavoriteToggle,
    required this.onHideToggle,
    this.onEdit,
    this.onDelete,
  });

  final DnsServer server;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onHideToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Mostra o BottomSheet de opções
  static void show({
    required BuildContext context,
    required DnsServer server,
    required VoidCallback onFavoriteToggle,
    required VoidCallback onHideToggle,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ServerOptionsSheet(
        server: server,
        onFavoriteToggle: () {
          Navigator.pop(context);
          onFavoriteToggle();
        },
        onHideToggle: () {
          Navigator.pop(context);
          onHideToggle();
        },
        onEdit: onEdit != null
            ? () {
                Navigator.pop(context);
                onEdit();
              }
            : null,
        onDelete: onDelete != null
            ? () {
                Navigator.pop(context);
                onDelete();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            _OptionTile(
              icon: server.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              label: server.isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
              color: Colors.amber,
              onTap: onFavoriteToggle,
            ),
            
            const SizedBox(height: 8),
            _OptionTile(
              icon: server.isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              label: server.isHidden ? 'Mostrar servidor' : 'Ocultar servidor',
              color: server.isHidden ? AppColors.success : Colors.orange,
              onTap: onHideToggle,
            ),
            
            if (server.isCustom && onEdit != null) ...[
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.edit_rounded,
                label: 'Editar servidor',
                color: AppColors.primary,
                onTap: onEdit!,
              ),
            ],
            
            if (server.isCustom && onDelete != null) ...[
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.delete_rounded,
                label: 'Remover servidor',
                color: AppColors.error,
                onTap: onDelete!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
}

/// Dialog de confirmação para deletar servidor
class DeleteServerDialog extends StatelessWidget {
  const DeleteServerDialog({
    super.key,
    required this.server,
    required this.onConfirm,
  });

  final DnsServer server;
  final VoidCallback onConfirm;

  /// Mostra o dialog de confirmação
  static Future<void> show({
    required BuildContext context,
    required DnsServer server,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DeleteServerDialog(
        server: server,
        onConfirm: () {
          Navigator.pop(context);
          onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    
    return AlertDialog(
      backgroundColor: dialogBg,
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
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Remover'),
        ),
      ],
    );
  }
}
