import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Widget que exibe o status atual do DNS (ativo/inativo)
/// 
/// Mostra:
/// - Estado do DNS (Ativo/Desativado)
/// - Toggle para ativar/desativar
/// - Hostname do servidor quando ativo
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.isEnabled,
    required this.hostname,
    required this.isToggling,
    required this.onToggle,
  });

  /// Se o DNS está ativo
  final bool isEnabled;
  
  /// Hostname do servidor DNS atual (null se desativado)
  final String? hostname;
  
  /// Se está processando toggle
  final bool isToggling;
  
  /// Callback quando o toggle é acionado
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
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
                  color: AppColors.primary.withOpacity(0.3),
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
                      color: isEnabled 
                          ? Colors.white70 
                          : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
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
                  onChanged: isToggling ? null : onToggle,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white24,
                  inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
            ],
          ),
          
          if (isEnabled && hostname != null) ...[
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
                        hostname!,
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
}

/// Widget de loading do StatusCard
class StatusCardLoading extends StatelessWidget {
  const StatusCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    
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
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

/// Widget de erro do StatusCard
class StatusCardError extends StatelessWidget {
  const StatusCardError({
    super.key,
    required this.error,
  });

  final String error;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
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
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
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
}
