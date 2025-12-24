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
/// - description: descrição detalhada do servidor (opcional)
/// - websiteUrl: URL do site oficial (opcional)
/// - benefits: lista de benefícios/recursos (opcional)
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
  final String? description;
  final String? websiteUrl;
  final List<String>? benefits;

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
    this.description,
    this.websiteUrl,
    this.benefits,
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
    String? description,
    bool clearDescription = false,
    String? websiteUrl,
    bool clearWebsiteUrl = false,
    List<String>? benefits,
    bool clearBenefits = false,
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
      description: clearDescription ? null : (description ?? this.description),
      websiteUrl: clearWebsiteUrl ? null : (websiteUrl ?? this.websiteUrl),
      benefits: clearBenefits ? null : (benefits ?? this.benefits),
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
      'description': description,
      'websiteUrl': websiteUrl,
      'benefits': benefits,
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
      description: json['description'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      benefits: (json['benefits'] as List<dynamic>?)?.cast<String>(),
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
      description: 'O Cloudflare DNS (1.1.1.1) é um resolvedor DNS público focado em velocidade e privacidade. Não registra seu endereço IP e promete deletar logs em 24 horas. É considerado um dos DNS mais rápidos do mundo.',
      websiteUrl: 'https://1.1.1.1',
      benefits: [
        'Um dos DNS mais rápidos do mundo',
        'Não vende seus dados para anunciantes',
        'Suporte completo a DNS over HTTPS/TLS',
        'Opção com bloqueio de malware (1.1.1.2)',
        'Auditado por terceiros para garantir privacidade',
      ],
    ),
    DnsServer(
      id: 'google',
      name: 'Google',
      hostname: 'dns.google',
      isCustom: false,
      logoAsset: 'assets/logos/google.svg',
      colorValue: 0xFF4285F4, // Blue
      order: 1,
      description: 'O Google Public DNS é um serviço gratuito oferecido pelo Google desde 2009. É conhecido por sua alta confiabilidade, ampla cobertura global e tempos de resposta consistentes.',
      websiteUrl: 'https://developers.google.com/speed/public-dns',
      benefits: [
        'Alta disponibilidade e confiabilidade',
        'Cobertura global com servidores em todo mundo',
        'Proteção contra ataques DNS',
        'Suporte a DNSSEC para validação',
        'Documentação técnica completa',
      ],
    ),
    DnsServer(
      id: 'quad9',
      name: 'Quad9',
      hostname: 'dns.quad9.net',
      isCustom: false,
      logoAsset: 'assets/logos/quad9.svg',
      colorValue: 0xFF2196F3, // Light Blue
      order: 2,
      description: 'O Quad9 é um DNS público sem fins lucrativos que bloqueia automaticamente domínios maliciosos. Utiliza inteligência de ameaças de mais de 20 parceiros de segurança para proteger sua navegação.',
      websiteUrl: 'https://quad9.net',
      benefits: [
        'Bloqueio automático de malware e phishing',
        'Organização sem fins lucrativos',
        'Não coleta nem vende dados pessoais',
        'Sediado na Suíça (leis rígidas de privacidade)',
        'Atualização constante da lista de ameaças',
      ],
    ),
    DnsServer(
      id: 'adguard',
      name: 'AdGuard',
      hostname: 'dns.adguard.com',
      isCustom: false,
      logoAsset: 'assets/logos/adguard.svg',
      colorValue: 0xFF68BC71, // Green
      order: 3,
      description: 'O AdGuard DNS é especializado em bloqueio de anúncios e rastreadores a nível de DNS. Além de acelerar sua navegação removendo ads, também protege contra sites maliciosos.',
      websiteUrl: 'https://adguard-dns.io',
      benefits: [
        'Bloqueio de anúncios em todos os apps',
        'Proteção contra rastreadores',
        'Bloqueio de sites maliciosos e phishing',
        'Navegação mais rápida sem carregar ads',
        'Modo família com filtro de conteúdo adulto',
      ],
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
