# Context7 MCP - Documentação de Bibliotecas

Este projeto tem acesso ao **Context7 MCP** para consultar documentação atualizada de bibliotecas Flutter, Dart e outras tecnologias utilizadas.

---

## Como Usar

### 1. Resolver ID da Biblioteca

Antes de consultar a documentação, é necessário obter o ID compatível com Context7:

```
mcp_context7_resolve-library-id
  libraryName: "flutter" | "dart" | "riverpod" | etc.
```

**Exemplo de resposta:**
- Flutter: `/flutter/flutter`
- Dart: `/dart-lang/sdk`
- Riverpod: `/rrousselGit/riverpod`

### 2. Buscar Documentação

Com o ID da biblioteca, consulte a documentação:

```
mcp_context7_get-library-docs
  context7CompatibleLibraryID: "/flutter/flutter"
  topic: "widgets" | "state management" | "networking" | etc.
  mode: "code" | "info"
  page: 1 (opcional, para paginação)
```

**Parâmetros:**
- `context7CompatibleLibraryID`: ID obtido no passo anterior
- `topic`: Tópico específico para focar a busca
- `mode`: 
  - `code` (padrão): Retorna referências de API e exemplos de código
  - `info`: Retorna guias conceituais e informações arquiteturais
- `page`: Número da página (1-10) para paginação de resultados

---

## Bibliotecas do Projeto

| Biblioteca | ID Context7 | Uso no Projeto |
|------------|-------------|----------------|
| Flutter | `/flutter/flutter` | Framework principal |
| Dart | `/dart-lang/sdk` | Linguagem base |
| Riverpod | `/rrousselGit/riverpod` | Gerenciamento de estado |
| SharedPreferences | `/flutter/packages` | Persistência local |
| Flutter SVG | `/nicholasSvg/flutter_svg` | Logos dos provedores |

---

## Exemplos de Uso

### Consultar Widgets Flutter
```
1. resolve-library-id: "flutter"
2. get-library-docs:
   - context7CompatibleLibraryID: "/flutter/flutter"
   - topic: "CustomScrollView SliverGrid"
   - mode: "code"
```

### Consultar Riverpod StateNotifier
```
1. resolve-library-id: "riverpod"
2. get-library-docs:
   - context7CompatibleLibraryID: "/rrousselGit/riverpod"
   - topic: "StateNotifier provider"
   - mode: "code"
```

### Consultar Conceitos Dart
```
1. resolve-library-id: "dart"
2. get-library-docs:
   - context7CompatibleLibraryID: "/dart-lang/sdk"
   - topic: "async await Future"
   - mode: "info"
```

---

## Quando Usar

✅ **Use o Context7 MCP quando:**
- Precisar de sintaxe atualizada de uma API
- Buscar exemplos de código específicos
- Verificar parâmetros de widgets/classes
- Entender padrões recomendados
- Resolver dúvidas sobre funcionalidades

❌ **Não é necessário usar quando:**
- O código já está funcionando corretamente
- É uma tarefa simples e conhecida
- A documentação inline do código é suficiente

---

## Notas

- O Context7 sempre retorna documentação atualizada
- Se o contexto não for suficiente, tente `page=2`, `page=3`, etc.
- Prefira `mode="code"` para implementações e `mode="info"` para conceitos
- O ID da biblioteca pode ser fornecido diretamente se conhecido (formato `/org/project`)
