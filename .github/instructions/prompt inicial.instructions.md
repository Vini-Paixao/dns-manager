---
applyTo: '**'
---
# DNS Manager - Aplicativo Gerenciador de DNS Privado (Android/Flutter)

**Versão:** 1.0.0 | **Repositório:** https://github.com/Vini-Paixao/dns-manager  
**Status:** ✅ MVP Completo | **Última Atualização:** Janeiro 2025

---

## Visão Geral do Projeto

Aplicativo Android desenvolvido em Flutter para gerenciar configurações de DNS privado (DNS over TLS - DoT) de forma simples e intuitiva. Permite ativar/desativar facilmente o DNS privado e trocar entre diferentes servidores DNS, com acesso rápido via Quick Settings Tile.

---

## Requisitos Implementados vs Planejados

### 1. Interface Principal (UI) ✅ COMPLETO

| Requisito Original | Status | Implementação |
|-------------------|--------|---------------|
| Tela simples e limpa | ✅ | HomeScreen com Material 3 dark theme |
| Campo para adicionar/editar DNS | ✅ | Dialogs com validação em tempo real |
| Switch para ativar/desativar | ✅ | Toggle no StatusCard + toque no servidor |
| Lista de servidores salvos | ✅ | Grid com cards visuais e logos SVG |
| Indicador visual do status | ✅ | StatusCard com animações e cores |

**Extras implementados:**
- ✅ Sistema de favoritos com estrela
- ✅ Drag-and-drop para reordenar servidores
- ✅ Upload de logos personalizados (image picker)
- ✅ Cores personalizadas por servidor
- ✅ Modo compacto para reordenação
- ✅ Sistema de ocultar servidores (backend completo)

### 2. Gerenciamento de DNS ✅ COMPLETO

| Requisito Original | Status | Implementação |
|-------------------|--------|---------------|
| Configurar DNS DoT programaticamente | ✅ | DnsHelper.kt via Settings.Secure |
| Salvar múltiplos servidores | ✅ | StorageService + SharedPreferences |
| Alternar com um toque | ✅ | Toque no card ativa imediatamente |
| Ativar/desativar mantendo configs | ✅ | Estado persistido independentemente |

### 3. Quick Settings Tile ✅ COMPLETO

| Requisito Original | Status | Implementação |
|-------------------|--------|---------------|
| Tile na central de acesso rápido | ✅ | DnsTileService.kt |
| Switch liga/desliga | ✅ | Toggle com último servidor usado |
| Atualização visual automática | ✅ | Ícone e label dinâmicos |
| Sincronização com app | ✅ | Via SharedPreferences |

---

## Stack Técnica Implementada

### Framework e Linguagens
- **Flutter SDK:** ^3.6.0
- **Dart:** Linguagem principal
- **Kotlin:** Código nativo Android
- **Min SDK:** API 28 (Android 9.0 Pie)

### Dependências Flutter
```yaml
flutter_riverpod: ^2.4.9     # Gerenciamento de estado
shared_preferences: ^2.2.2   # Persistência local
google_fonts: ^6.1.0         # Tipografia (Outfit)
flutter_svg: ^2.2.0          # Logos dos provedores
image_picker: ^1.0.7         # Upload de imagens
path_provider: ^2.1.2        # Armazenamento de arquivos
```

### Arquitetura
- **UI:** Flutter com Riverpod para estado
- **Nativo:** Kotlin com TileService e Settings.Secure
- **Comunicação:** Platform Channels (MethodChannel)
- **Persistência:** SharedPreferences (Dart e Kotlin)

---

## Estrutura de Arquivos Atual

```
dns_manager/
├── lib/
│   ├── main.dart                 # Entry point com ProviderScope
│   ├── app.dart                  # MaterialApp + navegação
│   ├── theme/app_theme.dart      # Material 3 dark theme
│   ├── models/dns_server.dart    # Modelo com 12 campos
│   ├── providers/dns_provider.dart  # 8 providers Riverpod
│   ├── services/
│   │   ├── dns_service.dart      # Bridge para código nativo
│   │   └── storage_service.dart  # SharedPreferences wrapper
│   ├── screens/
│   │   ├── home_screen.dart      # Tela principal (~1350 linhas)
│   │   └── setup_screen.dart     # Instruções ADB
│   └── widgets/
│       └── server_card.dart      # Card full + compact mode
│
├── android/app/src/main/
│   ├── kotlin/com/dnsmanager/dns_manager/
│   │   ├── MainActivity.kt       # MethodChannel handler
│   │   ├── DnsHelper.kt          # DNS via Settings.Secure
│   │   └── DnsTileService.kt     # Quick Settings Tile
│   └── res/drawable/
│       ├── ic_dns_tile.xml       # Ícone do tile
│       └── ic_launcher_gradient_background.xml
│
├── assets/
│   ├── icon/                     # Ícones do app
│   └── logos/                    # SVGs (cloudflare, google, etc.)
│
├── pubspec.yaml
├── README.md
└── LICENSE (MIT)
```

---

## Servidores DNS Pré-configurados

| Provedor | Hostname | Cor | Logo |
|----------|----------|-----|------|
| Cloudflare | `1dot1dot1dot1.cloudflare-dns.com` | #F38020 | cloudflare.svg |
| Google | `dns.google` | #4285F4 | google.svg |
| Quad9 | `dns.quad9.net` | #ED1944 | quad9.svg |
| AdGuard | `dns.adguard.com` | #68BC71 | adguard.svg |
| NextDNS | `dns.nextdns.io` | #007BFF | nextdns.svg |
| OpenDNS | `doh.opendns.com` | #FF6600 | opendns.svg |

---

## Configuração e Permissões

### Package Name
`com.dnsmanager.dns_manager`

### Permissão Obrigatória (via ADB)
```bash
adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS
```

> ⚠️ **Importante:** Esta permissão deve ser concedida novamente após cada reinstalação do app.

---

## Comandos de Desenvolvimento

```bash
# Executar em modo debug
flutter run

# Build APK release
flutter build apk --release

# Gerar ícones do app
dart run flutter_launcher_icons

# Verificar ambiente Flutter
flutter doctor -v

# Limpar e reconstruir
flutter clean && flutter pub get
```

---

## Roadmap Futuro

### Próximas Features (v1.1.0)
- [ ] Layout adaptivo (1 coluna para poucos servidores)
- [ ] Botão de ocultar servidores na UI (backend já implementado)
- [ ] Exportar/importar configurações

### Melhorias Planejadas
- [ ] Testes unitários e de integração
- [ ] Screenshots no README
- [ ] Animações de transição aprimoradas
- [ ] Suporte a temas claros

### Publicação
- [ ] Preparar assets para Play Store
- [ ] Descrição e screenshots
- [ ] Política de privacidade

---

## Contexto para IA

Este documento serve como contexto principal para desenvolvimento contínuo. Ao trabalhar neste projeto:

1. **Consulte** [implementation_plan.instructions.md](implementation_plan.instructions.md) para detalhes técnicos
2. **Mantenha** a arquitetura Riverpod existente
3. **Siga** o padrão Material 3 dark theme já estabelecido
4. **Preserve** a estrutura de pastas atual
5. **Documente** novas funcionalidades neste arquivo

### Arquivos Principais para Referência
- `lib/models/dns_server.dart` - Estrutura de dados
- `lib/providers/dns_provider.dart` - Estado da aplicação
- `lib/screens/home_screen.dart` - Lógica da UI principal
- `lib/widgets/server_card.dart` - Componente de card reutilizável