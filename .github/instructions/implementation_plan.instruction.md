# DNS Manager App - Plano de Implementação

Aplicativo Android em Flutter para gerenciar configurações de DNS privado (DNS over TLS) com Quick Settings Tile.

## User Review Required

> [!IMPORTANT]
> **Permissão WRITE_SECURE_SETTINGS**: O app requer permissão especial que só pode ser concedida via ADB ou Root. Isso é uma limitação do Android, não do app.

> [!CAUTION]
> **Instalação Flutter**: Confirme se deseja prosseguir com a instalação do Flutter SDK (~3GB de espaço).

---

## Estrutura do Projeto

```
dns_manager/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # MaterialApp config
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 theme
│   ├── models/
│   │   └── dns_server.dart          # Modelo de servidor DNS
│   ├── providers/
│   │   └── dns_provider.dart        # Estado com Riverpod
│   ├── services/
│   │   ├── dns_service.dart         # Platform Channel bridge
│   │   └── storage_service.dart     # SharedPreferences
│   └── screens/
│       ├── home_screen.dart         # Tela principal
│       └── setup_screen.dart        # Instruções ADB
│
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml      # Permissões + TileService
│       └── kotlin/.../
│           ├── MainActivity.kt       # Platform Channel handler
│           ├── DnsHelper.kt          # Configuração DNS nativa
│           └── DnsTileService.kt     # Quick Settings Tile
│
└── pubspec.yaml                      # Dependências Flutter
```

---

## Proposed Changes

### Fase 1: Setup Inicial

#### [NEW] Instalação Flutter SDK
Instruções para Windows:
1. Download Flutter SDK
2. Configurar PATH
3. Instalar Android Studio + SDK
4. Verificar com `flutter doctor`

#### [NEW] dns_manager/ (Projeto Flutter)
```bash
flutter create --org com.dnsmanager --project-name dns_manager dns_manager
```

#### [MODIFY] android/app/src/main/AndroidManifest.xml
Adicionar permissões e declarar TileService:
```xml
<uses-permission android:name="android.permission.WRITE_SECURE_SETTINGS"/>
<uses-permission android:name="android.permission.INTERNET"/>

<service android:name=".DnsTileService"
    android:exported="true"
    android:permission="android.permission.BIND_QUICK_SETTINGS_TILE">
    <intent-filter>
        <action android:name="android.service.quicksettings.action.QS_TILE"/>
    </intent-filter>
</service>
```

---

### Fase 2: Código Nativo Android

#### [NEW] DnsHelper.kt
Classe para manipular DNS via Settings.Secure:
- `getPrivateDnsMode()`: Obtém modo atual (off/hostname/opportunistic)
- `getPrivateDnsHostname()`: Obtém hostname configurado
- `setPrivateDns(hostname)`: Configura DNS com hostname
- `disablePrivateDns()`: Desativa DNS privado
- `hasPermission()`: Verifica WRITE_SECURE_SETTINGS

#### [NEW] DnsTileService.kt
Implementa TileService:
- Toggle on/off ao clicar
- Atualiza ícone/label baseado no estado
- Comunica com SharedPreferences

#### [MODIFY] MainActivity.kt
Configura MethodChannel com métodos:
- `getDnsStatus` → `Map{enabled, hostname}`
- `setDns(hostname)` → `bool`
- `disableDns` → `bool`
- `hasPermission` → `bool`

---

### Fase 3: UI Flutter

#### [NEW] lib/theme/app_theme.dart
Tema Material 3 com:
- Cores vibrantes (deep purple/teal gradient)
- Dark mode por padrão
- Tipografia moderna (Google Fonts - Outfit)

#### [NEW] lib/models/dns_server.dart
```dart
class DnsServer {
  final String id;
  final String name;
  final String hostname;
  final bool isCustom;
}
```

#### [NEW] lib/providers/dns_provider.dart
Riverpod providers:
- `dnsStatusProvider`: Estado atual (ativo/inativo + hostname)
- `savedServersProvider`: Lista de servidores salvos
- `selectedServerProvider`: Servidor selecionado

#### [NEW] lib/screens/home_screen.dart
- Card superior com status atual e toggle
- Lista de servidores pré-configurados
- Botão para adicionar servidor customizado
- Animações suaves de transição

#### [NEW] lib/screens/setup_screen.dart
- Instruções claras para conceder permissão via ADB
- Comando copiável
- Botão para verificar permissão

---

### Fase 4: Integração

#### [NEW] lib/services/dns_service.dart
Bridge Flutter ↔ Nativo:
```dart
class DnsService {
  static const _channel = MethodChannel('com.dnsmanager/dns');
  
  Future<DnsStatus> getStatus();
  Future<bool> setDns(String hostname);
  Future<bool> disableDns();
  Future<bool> hasPermission();
}
```

#### [NEW] lib/services/storage_service.dart
Persistência com SharedPreferences:
- Lista de servidores salvos
- Último servidor usado
- Preferências do usuário

---

## Servidores DNS Pré-configurados

| Nome | Hostname |
|------|----------|
| Cloudflare | `1dot1dot1dot1.cloudflare-dns.com` |
| Google | `dns.google` |
| Quad9 | `dns.quad9.net` |
| AdGuard | `dns.adguard.com` |

---

## Verification Plan

### Testes Manuais

1. **Verificar instalação Flutter**
   ```bash
   flutter doctor -v
   ```
   Deve mostrar todas as verificações passando.

2. **Build do app**
   ```bash
   cd dns_manager
   flutter build apk --debug
   ```
   Deve compilar sem erros.

3. **Teste funcional no dispositivo**
   - Instalar APK em dispositivo Android 9+
   - Conceder permissão via ADB:
     ```bash
     adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS
     ```
   - Testar toggle de DNS
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
