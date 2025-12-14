---
applyTo: '**'
---
# Prompt para Desenvolvimento: Aplicativo Gerenciador de DNS Privado (Android/Flutter)

## Contexto do Projeto
Preciso desenvolver um aplicativo Android em Flutter para gerenciar configurações de DNS privado (DNS over TLS - DoT) de forma simples e intuitiva. O app deve permitir ativar/desativar facilmente o DNS privado e trocar entre diferentes servidores DNS.

## Funcionalidades Principais

### 1. Interface Principal (UI)
- Tela simples e limpa para configuração de DNS
- Campo de entrada para adicionar/editar servidor DNS DoT (hostname)
- Switch/Toggle visível para ativar/desativar DNS privado
- Lista de servidores DNS salvos para troca rápida
- Indicador visual claro do status atual (ativo/inativo)

### 2. Gerenciamento de DNS
- Configurar servidor DNS privado (DoT) programaticamente no Android
- Salvar múltiplos servidores DNS para acesso rápido
- Alternar entre servidores salvos com um toque
- Ativar/desativar DNS privado mantendo as configurações salvas

### 3. Quick Settings Tile (Acesso Rápido)
- Adicionar um tile customizado na central de acesso rápido do Android
- O tile deve funcionar como um switch liga/desliga para o DNS privado
- Atualização automática do estado visual do tile
- Sincronização bidirecional entre o tile e o app principal

## Requisitos Técnicos

### Plataforma e Framework
- **Framework:** Flutter (SDK mais recente estável)
- **Linguagem:** Dart
- **Plataforma alvo:** Android (mínimo API 28 - Android 9.0 Pie, pois DoT foi introduzido nessa versão)

### Funcionalidades Android Nativas Necessárias
1. **Configuração de DNS Privado:**
   - Usar `ConnectivityManager.setPrivateDnsConfiguration()` ou APIs equivalentes
   - Verificar e solicitar permissões necessárias (`WRITE_SECURE_SETTINGS` via ADB ou root)

2. **Quick Settings Tile:**
   - Implementar `TileService` nativo em Kotlin/Java
   - Bridge entre Flutter e código nativo usando Platform Channels

3. **Persistência de Dados:**
   - Usar SharedPreferences ou similar para salvar configurações
   - Armazenar lista de servidores DNS e estado atual

### Arquitetura Sugerida
- Separação entre UI (Flutter) e código nativo Android (Kotlin/Java)
- Platform Channels para comunicação Flutter ↔ Native
- Provider ou Riverpod para gerenciamento de estado no Flutter
- Repository pattern para persistência de dados

## Fluxo de Desenvolvimento Esperado

### Fase 1: Setup Inicial
- Criar projeto Flutter com suporte Android
- Configurar permissões necessárias no AndroidManifest.xml
- Setup básico de Platform Channels

### Fase 2: Código Nativo Android
- Implementar método para configurar DNS privado
- Implementar TileService para Quick Settings
- Criar métodos para verificar status atual do DNS

### Fase 3: UI Flutter
- Criar tela principal com formulário de DNS
- Implementar sistema de listagem e seleção de servidores
- Adicionar toggle de ativação/desativação
- Feedback visual de estado

### Fase 4: Integração e Persistência
- Conectar UI Flutter com código nativo via Platform Channels
- Implementar salvamento e carregamento de configurações
- Sincronização de estados entre app e tile

### Fase 5: Polimento
- Tratamento de erros e edge cases
- Validação de hostnames DNS
- Mensagens de feedback ao usuário
- Testes de funcionalidade

## Considerações Importantes

### Permissões e Limitações
- A configuração de DNS privado no Android requer `WRITE_SECURE_SETTINGS`
- Esta permissão não pode ser concedida pela Play Store, requer:
  - ADB: `adb shell pm grant <package_name> android.permission.WRITE_SECURE_SETTINGS`
  - Root: acesso root no dispositivo
- O app deve informar claramente o usuário sobre essa limitação
- Incluir instruções de como conceder a permissão via ADB

### UX/UI
- Design Material Design 3 para consistência com Android
- Feedback imediato de ações (loading, sucesso, erro)
- Validação de entrada de DNS em tempo real
- Confirmação visual clara do estado atual

### Servidores DNS Sugeridos (pré-configurados)
- Cloudflare: `1dot1dot1dot1.cloudflare-dns.com`
- Google: `dns.google`
- Quad9: `dns.quad9.net`
- AdGuard: `dns.adguard.com`

## Instruções para a IA

Por favor, me ajude a desenvolver este aplicativo passo a passo:

1. **Comece explicando** a estrutura de pastas e arquivos que precisaremos criar
2. **Forneça o código** para cada componente de forma incremental
3. **Explique cada seção** do código para que eu entenda o que está acontecendo
4. **Inclua comentários** detalhados no código
5. **Antecipe problemas** comuns e sugira soluções
6. **Valide comigo** antes de avançar para etapas mais complexas

Vamos começar pelo setup inicial do Flutter (não tenho instalado), do projeto Flutter e a configuração básica das permissões Android. Aguardo suas instruções!