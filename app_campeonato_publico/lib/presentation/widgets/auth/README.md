# Widgets de Autenticação

Widgets reutilizáveis para as telas de autenticação (Login, Reset Password, etc).

## Widgets Disponíveis

### AuthHeader
Cabeçalho padronizado com logo e título da aplicação.

**Propriedades:**
- `isSmall` (bool): Define se deve usar o layout compacto para telas pequenas

**Exemplo:**
```dart
AuthHeader(isSmall: isSmallScreen)
```

---

### AuthInputLabel
Label padronizado para campos de entrada.

**Propriedades:**
- `label` (String): Texto do label

**Exemplo:**
```dart
AuthInputLabel(label: 'Seu e-mail:')
```

---

### AuthInputField
Campo de entrada padronizado com ícone SVG opcional.

**Propriedades:**
- `controller` (TextEditingController): Controlador do campo
- `placeholder` (String): Texto placeholder
- `svgAsset` (String?): Caminho do ícone SVG (opcional)
- `obscureText` (bool): Define se o texto deve ser obscurecido (senha)
- `keyboardType` (TextInputType?): Tipo de teclado
- `isSmall` (bool): Define tamanho compacto

**Exemplo:**
```dart
AuthInputField(
  controller: _emailController,
  placeholder: 'exemplo@email.com',
  svgAsset: 'assets/images/envelope.svg',
  keyboardType: TextInputType.emailAddress,
  isSmall: isSmallScreen,
)
```

---

### AuthButton
Botão padronizado com suporte a estado de loading.

**Propriedades:**
- `text` (String): Texto do botão
- `onPressed` (VoidCallback?): Callback ao pressionar
- `isLoading` (bool): Define se está em loading
- `isSmall` (bool): Define tamanho compacto

**Exemplo:**
```dart
AuthButton(
  text: 'Entrar',
  onPressed: _login,
  isLoading: _loading,
  isSmall: isSmallScreen,
)
```

---

### AuthFeedbackMessage
Widget para exibir mensagens de erro ou sucesso.

**Propriedades:**
- `errorMessage` (String?): Mensagem de erro
- `successMessage` (String?): Mensagem de sucesso

**Exemplo:**
```dart
AuthFeedbackMessage(
  errorMessage: _error,
  successMessage: _success,
)
```

## Importação Simplificada

Para importar todos os widgets de uma vez:

```dart
import '../../widgets/auth/auth_widgets.dart';
```

## Padrão de Cores

- Cor principal: `#F85C39`
- Background dos inputs: `#F3F3F3`
- Texto: `Colors.black` / `Colors.black87`
