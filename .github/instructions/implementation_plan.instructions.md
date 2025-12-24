# DNS Manager App - Plano de Implementação

**Versão Atual: 1.0.1** | **Repositório:** https://github.com/Vini-Paixao/dns-manager  
**Status:** Produção (Play Store) | **Última Atualização:** Dezembro 2025

Aplicativo Android em Flutter para gerenciar configurações de DNS privado (DNS over TLS) com Quick Settings Tile, Widget e Notificação Persistente.

---

## Status do Desenvolvimento

### ✅ Funcionalidades Completas

| Funcionalidade | Descrição | Status |
|----------------|-----------|--------|
| Projeto Flutter | Estrutura base, pubspec.yaml, configurações | ✅ Completo |
| Código Nativo Android | DnsHelper, DnsTileService, DnsWidgetProvider, DnsNotificationService | ✅ Completo |
| Platform Channels | Comunicação Flutter ↔ Kotlin | ✅ Completo |
| UI Material 3 | Temas claro e escuro, tipografia Outfit, cores do logo | ✅ Completo |
| Status Card | Exibe estado atual do DNS com animações | ✅ Completo |
| Grid de Servidores | Cards com logos SVG e cores personalizadas | ✅ Completo |
| Sistema de Favoritos | Marcar servidores como favoritos | ✅ Completo |
| Drag-and-Drop | Reordenar servidores com modo de edição | ✅ Completo |
| Servidores Customizados | Adicionar/editar servidores com image picker | ✅ Completo |
| Quick Settings Tile | Toggle rápido na central de notificações | ✅ Completo |
| Widget Home Screen | Widget 2x1 com status e controle rápido | ✅ Completo |
| Notificação Persistente | Latência e tempo de conexão em tempo real | ✅ Completo |
| Histórico de Uso | Registros de ativação com estatísticas | ✅ Completo |
| Backup/Restauração | Exportar/importar configurações JSON | ✅ Completo |
| Múltiplas Opções Permissão | ADB via PC, Shizuku, ADB Wi-Fi | ✅ Completo |
| Ícone do App | Ícone personalizado com gradiente radial | ✅ Completo |
| Tela de Setup | Instruções detalhadas para permissão | ✅ Completo |
| Persistência | SharedPreferences para salvar configurações | ✅ Completo |
| GitHub | Repositório publicado com README e LICENSE | ✅ Completo |
| Play Store | App publicado na Google Play Store | ✅ Completo |

---

## Estrutura Atual do Projeto

```
dns_manager/
├── lib/
│   ├── main.dart                    # Entry point com ProviderScope
│   ├── app.dart                     # MaterialApp + rotas
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 dark theme (Outfit font)
│   ├── models/
│   │   └── dns_server.dart          # Modelo completo com 12 campos
│   ├── providers/
│   │   └── dns_provider.dart        # Riverpod (servers, status, selected)
│   ├── services/
│   │   ├── dns_service.dart         # Platform Channel bridge
│   │   └── storage_service.dart     # SharedPreferences
│   ├── screens/
│   │   ├── home_screen.dart         # Tela principal (~1350 linhas)
│   │   └── setup_screen.dart        # Instruções ADB
│   └── widgets/
│       └── server_card.dart         # Card reutilizável (full + compact)
│
├── android/app/src/main/
│   ├── AndroidManifest.xml          # Permissões + TileService
│   ├── kotlin/com/dnsmanager/dns_manager/
│   │   ├── MainActivity.kt          # Platform Channel handler
│   │   ├── DnsHelper.kt             # Configuração DNS nativa
│   │   └── DnsTileService.kt        # Quick Settings Tile
│   └── res/
│       ├── drawable/
│       │   ├── ic_dns_tile.xml      # Ícone do tile (server icon)
│       │   └── ic_launcher_gradient_background.xml  # Gradiente radial
│       └── mipmap-*/                # Ícones do app gerados
│
├── assets/
│   ├── icon/
│   │   ├── app_icon.png             # Ícone completo 1024x1024
│   │   └── app_icon_foreground.png  # Foreground para adaptive icon
│   └── logos/                       # SVGs dos provedores DNS
│       ├── cloudflare.svg
│       ├── google.svg
│       ├── quad9.svg
│       ├── adguard.svg
│       ├── nextdns.svg
│       └── opendns.svg
│
├── pubspec.yaml                     # Dependências + flutter_launcher_icons
├── README.md                        # Documentação completa
└── LICENSE                          # MIT License
```

---

## Modelo de Dados (DnsServer)

```dart
class DnsServer {
  final String id;              // UUID único
  final String name;            // Nome amigável
  final String hostname;        // Endereço DoT
  final bool isCustom;          // Se foi criado pelo usuário
  final String? logoAsset;      // Caminho do SVG nos assets
  final String? customLogoPath; // Caminho de imagem customizada
  final int? colorValue;        // Cor do card (0xFFRRGGBB)
  final bool isFavorite;        // Se é favorito
  final bool isHidden;          // Se está oculto da dashboard
  final int order;              // Ordem para drag-and-drop
  final int createdAt;          // Timestamp de criação
}
```

---

## Providers Riverpod

| Provider | Tipo | Descrição |
|----------|------|-----------|
| `dnsServiceProvider` | Provider | Instância do DnsService |
| `storageServiceProvider` | Provider | Instância do StorageService |
| `hasPermissionProvider` | FutureProvider | Verifica permissão ADB |
| `dnsStatusAutoRefreshProvider` | FutureProvider | Status atual do DNS |
| `serversProvider` | StateNotifierProvider | Lista completa de servidores |
| `visibleServersProvider` | Provider | Servidores não ocultos |
| `hiddenServersProvider` | Provider | Servidores ocultos |
| `selectedServerProvider` | StateNotifierProvider | Servidor selecionado |

### Métodos do ServersNotifier
- `addServer()` - Adiciona servidor customizado
- `removeServer()` - Remove servidor (só custom)
- `updateServer()` - Atualiza servidor existente
- `toggleFavorite()` - Alterna favorito
- `toggleHidden()` - Alterna visibilidade
- `reorderServers()` - Reordena via drag-and-drop
- `resetToDefaults()` - Reseta para servidores padrão

---

## Dependências (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.4.9     # Estado
  shared_preferences: ^2.2.2   # Persistência
  google_fonts: ^6.1.0         # Tipografia
  flutter_svg: ^2.2.0          # Logos SVG
  image_picker: ^1.0.7         # Upload de logos
  path_provider: ^2.1.2        # Armazenamento de arquivos

dev_dependencies:
  flutter_launcher_icons: ^0.14.3  # Geração de ícones
```

---

## Configuração Android

- **Package Name:** `com.dnsmanager.dns_manager`
- **Min SDK:** API 28 (Android 9.0 Pie)
- **Target SDK:** API 34 (Android 14)
- **App Name:** DNS Manager
- **Ícone:** Adaptive icon com gradiente radial (#5de0e6 → #004aad)

### Permissão Especial
```bash
adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS
```

---

## Servidores DNS Pré-configurados

| Nome | Hostname | Logo | Cor |
|------|----------|------|-----|
| Cloudflare | `1dot1dot1dot1.cloudflare-dns.com` | cloudflare.svg | #F38020 |
| Google | `dns.google` | google.svg | #4285F4 |
| Quad9 | `dns.quad9.net` | quad9.svg | #ED1944 |
| AdGuard | `dns.adguard.com` | adguard.svg | #68BC71 |
| NextDNS | `dns.nextdns.io` | nextdns.svg | #007BFF |
| OpenDNS | `doh.opendns.com` | opendns.svg | #FF6600 |

---

## Comandos de Desenvolvimento

```bash
# Executar em debug
flutter run

# Build APK de release
flutter build apk --release

# Gerar ícones do app
dart run flutter_launcher_icons

# Verificar ambiente
flutter doctor -v
```

---

## Próximos Passos

1. **Layout Adaptivo:** Implementar grid responsivo baseado na quantidade de servidores
2. **Screenshots:** Capturar telas do app para o README
3. **Testes:** Adicionar testes unitários e de integração
4. **Play Store:** Preparar assets e descrição para publicação
   - Verificar Quick Settings Tile
   - Verificar persistência após fechar app

4. **Verificação visual**
   - Tema escuro aplicado corretamente
   - Animações suaves
   - Feedback visual claro de estados

---

## Próximos Passos

1. **Confirmar instalação do Flutter** - Preciso saber se você já tem ambiente de desenvolvimento Android configurado
2. **Criar projeto base** - Estrutura inicial do Flutter
3. **Implementar código nativo** - Kotlin para DNS e TileService
4. **Desenvolver UI** - Telas em Flutter com Material 3
