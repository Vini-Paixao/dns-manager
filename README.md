# DNS Manager

<p align="center">
  <img src="assets/icon/app_icon.png" width="128" alt="DNS Manager Logo">
</p>

<p align="center">
  <strong>🛡️ Gerenciador de DNS Privado (DNS over TLS) para Android</strong>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.dnsmanager.dns_manager">
    <img src="https://img.shields.io/badge/Google%20Play-Download-green?logo=google-play" alt="Google Play">
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.6+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Android-9.0+-brightgreen?logo=android" alt="Android">
  <img src="https://img.shields.io/badge/Version-1.0.1-orange" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

---

## 📱 Sobre o App

O **DNS Manager** é o aplicativo definitivo para gerenciar configurações de DNS Privado (DNS over TLS - DoT) no seu dispositivo Android. Com uma interface intuitiva e recursos avançados, você tem controle total sobre sua conexão de internet.

### ✨ Funcionalidades Principais

- 🔒 **DNS Privado Seguro** - Configure DNS over TLS (DoT) facilmente
- ⚡ **Quick Settings Tile** - Controle rápido na central de notificações  
- 📱 **Widget na Tela Inicial** - Status do DNS sempre visível
- 📊 **Notificação Persistente** - Latência e tempo de conexão em tempo real
- 📋 **4 Servidores Pré-configurados** - Cloudflare, Google, Quad9, AdGuard
- ➕ **Servidores Personalizados** - Adicione seus próprios servidores com logo e cor
- ⭐ **Sistema de Favoritos** - Acesso rápido aos seus servidores preferidos
- 🔀 **Drag-and-Drop** - Reordene servidores como preferir
- 📈 **Histórico de Uso** - Estatísticas detalhadas de conexão
- 💾 **Backup e Restauração** - Exporte/importe suas configurações
- 🎨 **Interface Moderna** - Material Design 3 com temas claro e escuro

---

## 🚀 Instalação

### Via Google Play (Recomendado)

<a href="https://play.google.com/store/apps/details?id=com.dnsmanager.dns_manager">
  <img src="https://play.google.com/intl/en_us/badges/static/images/badges/pt-br_badge_web_generic.png" width="200" alt="Disponível no Google Play">
</a>

### Via APK

1. Baixe o APK da [página de releases](../../releases)
2. Instale o APK no seu dispositivo
3. Conceda a permissão especial (veja abaixo)

### Requisitos

- Android 9.0 (Pie) ou superior
- Computador com ADB para conceder permissão (apenas uma vez)

### ⚠️ Permissão Necessária

O Android requer uma permissão especial para que apps configurem o DNS Privado. Você precisa conceder **uma única vez** via ADB:

```bash
adb shell pm grant com.dnsmanager.dns_manager android.permission.WRITE_SECURE_SETTINGS
```

> 💡 **Dica:** O app inclui instruções detalhadas e múltiplas opções para conceder a permissão (PC, Shizuku, ADB Wi-Fi).

**Nota:** Esta permissão precisa ser concedida novamente apenas se você reinstalar o app.

---

## 🛠️ Desenvolvimento

### Pré-requisitos

- Flutter SDK 3.6+
- Android SDK
- VS Code ou Android Studio

### Configuração

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/dns-manager.git

# Entre no diretório
cd dns-manager

# Instale as dependências
flutter pub get

# Execute o app
flutter run
```

### Estrutura do Projeto

```
lib/
├── main.dart                 # Entry point
├── models/
│   └── dns_server.dart       # Modelo de servidor DNS
├── providers/
│   └── dns_provider.dart     # State management (Riverpod)
├── screens/
│   └── home_screen.dart      # Tela principal
├── services/
│   └── dns_service.dart      # Serviço de configuração DNS
├── theme/
│   └── app_theme.dart        # Tema do app
└── widgets/
    └── server_card.dart      # Widget de card do servidor

android/
├── app/src/main/
│   ├── kotlin/.../
│   │   ├── MainActivity.kt   # Activity principal
│   │   └── DnsTileService.kt # Quick Settings Tile
│   └── res/
│       └── drawable/         # Ícones e recursos
```

---

## 📦 Tecnologias Utilizadas

- **Flutter** - Framework de UI
- **Riverpod** - Gerenciamento de estado
- **SharedPreferences** - Persistência de dados
- **Flutter SVG** - Renderização de logos SVG
- **Image Picker** - Seleção de imagens customizadas

---

## 🌐 Servidores DNS Pré-configurados

| Provedor | Hostname | Descrição |
|----------|----------|-----------|
| Cloudflare | `1dot1dot1dot1.cloudflare-dns.com` | Rápido e focado em privacidade |
| Google | `dns.google` | Confiável e estável |
| Quad9 | `dns.quad9.net` | Bloqueio de malware |
| AdGuard | `dns.adguard.com` | Bloqueio de anúncios |

---

## 🔒 Privacidade

- **Sem coleta de dados** - Tudo funciona localmente no seu dispositivo
- **Sem anúncios** - Experiência limpa e sem interrupções
- **Código aberto** - Transparência total

Veja nossa [Política de Privacidade](PRIVACY_POLICY.md) completa.

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para:

- 🐛 Reportar bugs via [Issues](../../issues)
- 💡 Sugerir novas funcionalidades
- 🔧 Enviar Pull Requests

---

## ⭐ Apoie o Projeto

Se o DNS Manager foi útil para você:

- ⭐ Deixe uma estrela no repositório
- 📝 Avalie o app na Play Store
- 📢 Compartilhe com amigos

---

<p align="center">
  Desenvolvido com ❤️ usando Flutter e Kotlin
</p>

<p align="center">
  <a href="https://github.com/Vini-Paixao">@Vini-Paixao</a>
</p>
