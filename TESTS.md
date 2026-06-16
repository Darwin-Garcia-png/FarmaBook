# Pruebas — FarmaBook Frontend

## Stack de testing

| Herramienta | Versión | Propósito |
|---|---|---|
| `flutter_test` | SDK | Framework base de testing (widget tests, unit tests) |
| `integration_test` | SDK | Tests de integración (app completa en Windows) |
| `mocktail` | ^1.0.4 | Mocking de dependencias (HTTP client, servicios) |

## CI/CD — GitHub Actions

El workflow `.github/workflows/ci.yml` ejecuta automáticamente en cada push/PR a `master`:

```yaml
jobs:
  test:
    runs-on: windows-latest
    steps:
      - flutter pub get
      - flutter analyze
      - flutter test
```

## Estructura de tests

```
test/
├── controllers/
│   └── login_controller_test.dart    # Unit + widget tests (7)
├── services/
│   └── api_service_test.dart         # Unit tests con HTTP mockeado (7)
└── widgets/
    ├── error_display_test.dart        # Unit + widget tests (12)
    └── login_screen_test.dart         # Widget tests (5)

integration_test/
└── app_test.dart                     # Smoke test de la app completa (2)
```

## Cómo ejecutar

```powershell
# Tests unitarios y de widgets
flutter test

# Tests de integración (requiere app corriendo o build)
flutter test integration_test/app_test.dart

# Un archivo específico
flutter test test\services\api_service_test.dart
flutter test test\widgets\error_display_test.dart
flutter test test\widgets\login_screen_test.dart
flutter test test\controllers\login_controller_test.dart
```

## Resumen de tests

### Unit + Widget tests (36 en total)

#### 1. `api_service_test.dart` — ApiService (7 tests)

Categoría: **Unit tests** con mock del HTTP client.

**Qué se testea:**
- `checkResponse()` lanza `ApiException` con el mensaje correcto para códigos 400+ (incluyendo mensajes anidados en `error.message`)
- `checkResponse()` NO lanza excepción para 200/201
- `createUser()` envía POST a `/users` con los datos correctos y parsea la respuesta
- `createUser()` lanza `ApiException` cuando el servidor responde con error (ej: 409 email duplicado)
- `getUsers()` envía GET a `/users` y parsea la lista de resultados

**Mocking:** `http.Client` se mockea con `MockClient` de mocktail. Se inyecta via `ApiService.testClient`.

**Casos borde cubiertos:**
- Error con mensaje plano (`{"message": "..."}`)
- Error con mensaje anidado (`{"error": {"message": "..."}}`)
- Códigos de éxito (200, 201)

---

#### 2. `error_display_test.dart` — ErrorDisplay (12 tests)

Categoría: **Unit tests** (hintFromMessage) + **Widget tests** (fullScreen, inline, snackBar).

**`hintFromMessage()` — 10 tests de lógica pura:**
- Cada tipo de error HTTP devuelve el hint en español correspondiente
- Sensibilidad a mayúsculas/minúsculas (case insensitive)
- Mensajes compuestos (ej: "Error 401: Invalid credentials")
- Errores desconocidos devuelven `null`

**Widget tests — 2 tests:**
- `fullScreen()` renderiza mensaje + hint + botón "Reintentar" cuando hay `onRetry`
- `fullScreen()` NO renderiza el botón si `onRetry` es `null`
- `inline()` renderiza mensaje y hint
- `snackBar()` muestra el SnackBar de error correctamente
- `successSnackBar()` muestra el SnackBar de éxito correctamente

---

#### 3. `login_controller_test.dart` — LoginController (7 tests)

Categoría: **Unit tests** (estado) + **Widget tests** (login con forms mockeados).

**Tests de estado:**
- Estado inicial correcto (`isLoading: false`, `obscurePassword: true`, campos vacíos)
- `togglePasswordVisibility()` cambia correctamente `obscurePassword`
- `togglePasswordVisibility()` dispara `notifyListeners()`

**Tests de login con widget tree:**
- Formulario vacío: `login()` retorna `false` (validación falla)
- Con credenciales válidas: llama a `AuthService.login()` con los valores correctos
- Error 401 del API: `login()` retorna `false`
- Token faltante tras 200: `login()` retorna `false` y muestra error

**Mocking:** `AuthService` se mockea con `MockAuthService`. Se inyecta via constructor (`LoginController(authService: mockAuth)`).

---

#### 4. `login_screen_test.dart` — LoginScreen (5 tests)

Categoría: **Widget tests** con Provider mockeado.

**Qué se testea:**
- Renderiza el formulario de login (fields de email/password)
- Muestra el enlace "Registrarse" (texto separado: "¿No tienes cuenta? " + "Registrarse")
- Al tocar "Registrarse": se abre el diálogo "Crear Cuenta"
- El diálogo contiene: Usuario *, Email *, Contraseña *, ROL
- El botón "CANCELAR" cierra el diálogo

**Mocking:** `AlmacenController` y `LotesController` se mockean (requeridos por `LoginScreen`). No se mockea `LoginController` — se usa el real.

---

### Integration tests (2 tests)

#### `app_test.dart` — Smoke test

Categoría: **Integration test** sobre la app real.

**Qué se testea:**
- La app arranca y muestra la pantalla de login
- Los campos Email y Contraseña están presentes
- Al tocar "Iniciar Sesión" sin credenciales aparece la validación

**Ejecución:** Requiere la app compilada o un dispositivo Windows. Se ejecuta con:
```powershell
flutter test integration_test/app_test.dart
```

---

## Modificaciones a producción para testing

Se hicieron cambios mínimos en archivos de producción para facilitar el testing:

| Archivo | Cambio |
|---|---|
| `lib/services/api_service.dart` | Se agregó `testClient` setter con `@visibleForTesting` para inyectar mock de HTTP client |
| `lib/services/api_service.dart` | Se agregó `testCachedToken` setter con `@visibleForTesting` para evitar dependencia de FlutterSecureStorage en tests |
| `lib/controllers/login_controller.dart` | Constructor acepta `AuthService? authService` opcional (por defecto crea uno real) |

Estos cambios no afectan el comportamiento en producción: los setters solo se usan en tests, y el constructor sigue siendo compatible hacia atrás.

## Nota sobre Patrol

El usuario preguntó por **Patrol** (framework de testing E2E). Patrol está orientado a mobile (Android/iOS) para interactuar con elementos nativos como diálogos de permisos, notificaciones, WebViews, etc. Para una app de **Windows desktop**, el soporte de Patrol es limitado. Se recomienda usar `integration_test` (built-in de Flutter SDK) que funciona nativamente en Windows.

Si en el futuro la app se expande a mobile, Patrol es la opción recomendada para integration testing en Android/iOS.

## Resultados actuales

**36 tests, 0 failures.** Todos los tests pasan en Windows.

```
flutter test
00:07 +36: All tests passed!
```
