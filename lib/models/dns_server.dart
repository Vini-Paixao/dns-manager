import 'package:flutter/material.dart';

/// Modelo que representa um servidor DNS
/// 
/// Cada servidor tem:
/// - id: identificador único
/// - name: nome amigável para exibição
/// - hostname: endereço DoT do servidor
/// - isCustom: se foi adicionado pelo usuário
/// - logoAsset: caminho do logo nos assets (para servidores padrão)
/// - customLogoPath: caminho do logo personalizado (para servidores custom)
/// - colorValue: cor do card em formato int (0xFFRRGGBB)
/// - isFavorite: se é favorito (aparece primeiro)
/// - isHidden: se está oculto da dashboard principal
/// - order: ordem personalizada para drag-and-drop
/// - createdAt: timestamp de criação
class DnsServer {
  final String id;
  final String name;
  final String hostname;
  final bool isCustom;
  final String? logoAsset;
  final String? customLogoPath;
  final int? colorValue;
  final bool isFavorite;
  final bool isHidden;
  final int order;
  final int createdAt;

  const DnsServer({
    required this.id,
    required this.name,
    required this.hostname,
    this.isCustom = false,
    this.logoAsset,
    this.customLogoPath,
    this.colorValue,
    this.isFavorite = false,
    this.isHidden = false,
    this.order = 0,
    this.createdAt = 0,
  });

  /// Retorna a cor como Color do Flutter
  Color? get color => colorValue != null ? Color(colorValue!) : null;

  /// Verifica se tem logo (asset ou customizado)
  bool get hasLogo => logoAsset != null || customLogoPath != null;

  /// Cria uma cópia com valores alterados
  /// Use [clearCustomLogoPath] = true para remover o logo customizado
  DnsServer copyWith({
    String? id,
    String? name,
    String? hostname,
    bool? isCustom,
    String? logoAsset,
    String? customLogoPath,
    bool clearCustomLogoPath = false,
    int? colorValue,
    bool? isFavorite,
    bool? isHidden,
    int? order,
    int? createdAt,
  }) {
    return DnsServer(
      id: id ?? this.id,
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      isCustom: isCustom ?? this.isCustom,
      logoAsset: logoAsset ?? this.logoAsset,
      customLogoPath: clearCustomLogoPath ? null : (customLogoPath ?? this.customLogoPath),
      colorValue: colorValue ?? this.colorValue,
      isFavorite: isFavorite ?? this.isFavorite,
      isHidden: isHidden ?? this.isHidden,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converte para Map para persistência
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostname': hostname,
      'isCustom': isCustom,
      'logoAsset': logoAsset,
      'customLogoPath': customLogoPath,
      'colorValue': colorValue,
      'isFavorite': isFavorite,
      'isHidden': isHidden,
      'order': order,
      'createdAt': createdAt,
    };
  }

  /// Cria instância a partir de Map
  factory DnsServer.fromJson(Map<String, dynamic> json) {
    return DnsServer(
      id: json['id'] as String,
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
      logoAsset: json['logoAsset'] as String?,
      customLogoPath: json['customLogoPath'] as String?,
      colorValue: json['colorValue'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DnsServer &&
        other.id == id &&
        other.name == name &&
        other.hostname == hostname &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, hostname, isCustom);
  }

  @override
  String toString() {
    return 'DnsServer(id: $id, name: $name, hostname: $hostname, isCustom: $isCustom, isFavorite: $isFavorite, order: $order)';
  }
}

/// Lista de servidores DNS pré-configurados
/// 
/// Estes são os servidores DNS populares que vêm
/// configurados por padrão no aplicativo
class DefaultDnsServers {
  static const List<DnsServer> servers = [
    DnsServer(
      id: 'cloudflare',
      name: 'Cloudflare',
      hostname: '1dot1dot1dot1.cloudflare-dns.com',
      isCustom: false,
      logoAsset: 'assets/logos/cloudflare.svg',
      colorValue: 0xFFF38020, // Orange
      order: 0,
    ),
    DnsServer(
      id: 'google',
      name: 'Google',
      hostname: 'dns.google',
      isCustom: false,
      logoAsset: 'assets/logos/google.svg',
      colorValue: 0xFF4285F4, // Blue
      order: 1,
    ),
    DnsServer(
      id: 'quad9',
      name: 'Quad9',
      hostname: 'dns.quad9.net',
      isCustom: false,
      logoAsset: 'assets/logos/quad9.svg',
      colorValue: 0xFF2196F3, // Light Blue
      order: 2,
    ),
    DnsServer(
      id: 'adguard',
      name: 'AdGuard',
      hostname: 'dns.adguard.com',
      isCustom: false,
      logoAsset: 'assets/logos/adguard.svg',
      colorValue: 0xFF68BC71, // Green
      order: 3,
    ),
    DnsServer(
      id: 'opendns',
      name: 'OpenDNS',
      hostname: 'doh.opendns.com',
      isCustom: false,
      logoAsset: 'assets/logos/opendns.svg',
      colorValue: 0xFF049FD9, // Cyan
      order: 4,
    ),
    DnsServer(
      id: 'nextdns',
      name: 'NextDNS',
      hostname: 'dns.nextdns.io',
      isCustom: false,
      logoAsset: 'assets/logos/nextdns.svg',
      colorValue: 0xFF007AFF, // Blue
      order: 5,
    ),
  ];

  /// Obtém um servidor pelo ID
  static DnsServer? getById(String id) {
    try {
      return servers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtém um servidor pelo hostname
  static DnsServer? getByHostname(String hostname) {
    try {
      return servers.firstWhere((s) => s.hostname == hostname);
    } catch (e) {
      return null;
    }
  }
}
