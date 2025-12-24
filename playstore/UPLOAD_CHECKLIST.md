# Checklist para Upload na Play Store

## 1. Arquivos Necessários

### App Bundle (obrigatório)
- [x] **Arquivo:** `build/app/outputs/bundle/release/app-release.aab`
- [x] **Tamanho:** 24.2 MB
- [x] **Assinado:** Sim (upload-keystore.jks)

### Ícone do App (obrigatório)
- [x] **Arquivo:** `assets/icon/app_icon.png`
- [x] **Resolução:** 512 x 512 px
- [x] **Formato:** PNG 32-bit

### Screenshots (obrigatório - mínimo 2)
- [x] Capturar screenshots do app
- [x] Salvar em `playstore/screenshots/`
- [x] Resolução: 1080 x 1920 px (ou 1920 x 1080 para paisagem)

### Feature Graphic (recomendado)
- [ ] Criar banner 1024 x 500 px
- [ ] Salvar em `playstore/feature_graphic.png`

---

## 2. Informações do App

### Detalhes do App
- [x] **Nome:** DNS Manager
- [x] **Descrição curta:** 80 caracteres
- [x] **Descrição completa:** 4000 caracteres
- [x] **Categoria:** Ferramentas

### Gráficos
- [x] Ícone 512x512
- [ ] Feature Graphic 1024x500
- [x] Screenshots (2-8)

---

## 3. Classificação de Conteúdo

Preencher questionário no Google Play Console:
- [x] Violência: Nenhuma
- [x] Conteúdo sexual: Nenhum
- [x] Linguagem: Inofensiva
- [x] Drogas: Nenhuma referência
- [x] IARC: Classificação esperada "Livre"

---

## 4. Configurações de Lançamento

### Preço e Distribuição
- [x] **Preço:** Gratuito
- [x] **Países:** Todos selecionados
- [x] **Contém anúncios:** Não

### Política de Privacidade
- [x] **Arquivo:** PRIVACY_POLICY.md
- [x] **URL publicada:** https://raw.githubusercontent.com/Vini-Paixao/dns-manager/main/PRIVACY_POLICY.md

### Declaração de Dados (Data Safety)
- [x] Coleta de dados: Não
- [x] Compartilhamento de dados: Não
- [x] Dados criptografados: N/A
- [x] Exclusão de dados: N/A

---

## 5. Declaração de Permissões Sensíveis

O Google pode solicitar justificativa para:

### WRITE_SECURE_SETTINGS
**Justificativa a enviar:**
```
Esta permissão é necessária para a funcionalidade principal do aplicativo: 
configurar o DNS Privado (DNS over TLS) nas configurações do sistema Android.
A permissão não é concedida automaticamente pelo Android e requer que o 
usuário a conceda manualmente via ADB (Android Debug Bridge), garantindo 
que apenas usuários avançados que entendem as implicações podem usá-la.
O aplicativo exibe instruções claras sobre como conceder esta permissão.
```

### FOREGROUND_SERVICE
**Justificativa a enviar:**
```
O serviço em primeiro plano é usado para exibir uma notificação persistente 
OPCIONAL que mostra o status do DNS e a latência em tempo real. O usuário 
pode ativar/desativar esta funcionalidade nas configurações do app. O serviço 
não realiza nenhuma coleta de dados.
```

---

## 6. Passos para Upload

1. **Acessar Google Play Console**
   - https://play.google.com/console

2. **Selecionar o app "DNS Manager"**
   - Já criado pelo usuário

3. **Ir em "Release" > "Production"**
   - Ou "Internal testing" para teste inicial

4. **Criar nova release**
   - Upload do arquivo .aab
   - Adicionar release notes

5. **Preencher Store Listing**
   - Copiar textos do PLAY_STORE_LISTING.md
   - Upload de screenshots e ícone

6. **Preencher Content Rating**
   - Responder questionário

7. **Configurar Pricing & Distribution**
   - Gratuito, todos os países

8. **Preencher Data Safety**
   - Nenhuma coleta de dados

9. **Revisar e publicar**
   - Aguardar aprovação (1-7 dias)

---

## 7. Release Notes (Notas da Versão)

### Versão 1.0.2 (Atual)
```
🎬 Novidades nesta versão:

• Links agora abrem diretamente no navegador/app
• Tutoriais em vídeo do YouTube para configuração
• Instruções melhoradas para cada método de permissão
• Melhorias de usabilidade na tela de configuração
• Correções de bugs menores
```

### Versão 1.0.1
```
🚀 Lançamento oficial do DNS Manager!

✨ Recursos principais:
• Configure DNS Privado (DNS over TLS) facilmente
• Quick Settings Tile para acesso rápido
• Widget na tela inicial com status em tempo real
• Notificação persistente com latência e tempo de conexão
• 6 servidores DNS pré-configurados
• Adicione servidores personalizados com logo e cores
• Backup e restauração de configurações
• Histórico de uso com estatísticas detalhadas
• Interface moderna com Material Design 3
• Temas claro e escuro

🛡️ Servidores incluídos:
Cloudflare • Google • Quad9 • AdGuard • NextDNS • OpenDNS

🆓 Gratuito e sem anúncios!
```

---

## 8. Arquivos de Backup (Manter Seguros!)

⚠️ **NUNCA compartilhar ou commitar no Git:**

- `android/key.properties` - Credenciais do keystore
- `android/app/upload-keystore.jks` - Arquivo de assinatura

**Fazer backup em local seguro!** Se perder o keystore, não poderá atualizar o app.

---

## 9. Após Publicação

- [ ] Testar download da Play Store
- [ ] Verificar funcionamento em dispositivo real
- [ ] Responder reviews
- [ ] Monitorar crash reports no Console
- [ ] Planejar próximas atualizações
- [ ] Criar Release no GitHub com APK
