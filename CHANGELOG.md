# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.0.2] - 2024-12-24

### Adicionado
- 🎬 Tutoriais em vídeo do YouTube para cada método de permissão
  - USB + ADB: Tutorial completo de configuração
  - Shizuku: Tutorial de instalação e uso
  - LADB: Tutorial para Android 11+ sem PC
- ⚠️ Aviso contextual nos tutoriais lembrando de executar o comando específico do DNS Manager
- 🔗 Links agora abrem diretamente no navegador ou app correspondente

### Melhorado
- 📱 Experiência de configuração de permissão mais intuitiva
- 🔄 Método `_openUrl` agora usa `url_launcher` para abrir links externamente
- 📝 Documentação atualizada com novas funcionalidades

### Corrigido
- 🐛 Links que apenas copiavam para área de transferência agora abrem corretamente

---

## [1.0.1] - 2024-12-20

### Adicionado
- 📱 Widget na tela inicial com status do DNS em tempo real
- 🔔 Notificação persistente com latência e tempo de conexão
- 📊 Histórico de uso com estatísticas detalhadas
- 💾 Backup e restauração de configurações (JSON)
- 🎨 Suporte a temas claro e escuro
- 📋 Três métodos para conceder permissão:
  - USB + ADB (recomendado)
  - App Shizuku
  - App LADB (Android 11+)

### Melhorado
- 🎯 Interface de configuração de permissão redesenhada
- ⚡ Performance geral do aplicativo

---

## [1.0.0] - 2024-12-15

### Lançamento Inicial 🚀

#### Funcionalidades Principais
- 🔒 Configuração de DNS Privado (DNS over TLS - DoT)
- ⚡ Quick Settings Tile para acesso rápido
- 📦 4 servidores DNS pré-configurados:
  - Cloudflare (1.1.1.1)
  - Google DNS
  - Quad9
  - AdGuard DNS
- ➕ Suporte a servidores personalizados com logo e cores
- ⭐ Sistema de favoritos
- 🔀 Reordenação de servidores via drag-and-drop
- 🎨 Interface moderna com Material Design 3

#### Requisitos
- Android 9.0 (Pie) ou superior
- Permissão WRITE_SECURE_SETTINGS via ADB

---

## Links

- [Repositório GitHub](https://github.com/Vini-Paixao/dns-manager)
- [Play Store](https://play.google.com/store/apps/details?id=com.dnsmanager.dns_manager)
- [Política de Privacidade](https://raw.githubusercontent.com/Vini-Paixao/dns-manager/main/PRIVACY_POLICY.md)
