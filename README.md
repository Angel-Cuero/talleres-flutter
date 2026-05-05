# 📱 Electiva 2026 — Flutter Educativo

Aplicación Flutter didáctica que demuestra conceptos clave de programación asíncrona, timers, isolates e integración con Firebase en Dart/Flutter.

> **Versión actual:** `1.0.1+2` · **SDK mínimo:** Flutter ≥ 3.x · **Plataforma:** Android

---

## 🗂️ Pantallas de la aplicación

| Ruta | Pantalla | Concepto principal |
|------|----------|-------------------:|
| `/` | Inicio | Navegación general con Drawer |
| `/paso_parametros` | Paso de Parámetros | Navegación y parámetros en rutas |
| `/ciclo_vida` | Ciclo de Vida | `initState`, `dispose`, lifecycle |
| `/future` | Future / async-await | Asincronía, estados de carga |
| `/timer` | Cronómetro | `Timer.periodic`, limpieza de recursos |
| `/isolate` | Isolate | Cómputo pesado fuera del hilo principal |

---

## ⚡ 1. Future / async / await

### ¿Cuándo usarlo?

Usa `Future` + `async/await` cuando necesitas esperar el resultado de una operación **asíncrona** (I/O, red, base de datos) **sin bloquear la UI**.

```dart
// ✅ Correcto: espera sin bloquear
Future<List<String>> cargarDatos() async {
  await Future.delayed(const Duration(seconds: 2)); // simula red
  return ['item1', 'item2'];
}

void _consultar() async {
  print('① Antes de la consulta');
  final datos = await cargarDatos();   // espera el Future
  print('③ Después — datos: $datos');
}
```

### Estados en pantalla

La vista `FutureView` muestra cuatro estados claramente diferenciados:

```
Inicial  →  [Botón "Consultar datos"]
   ↓
Cargando → CircularProgressIndicator + mensaje
   ↓
Éxito    → GridView con los datos recibidos
   ↓
Error    → Icono + mensaje + botón "Reintentar"
```

### Flujo de ejecución (orden en consola)

```
[Future] ① Antes — llamando a ProductoService.consultarProductos()
[Future] ② Durante la espera — el delay terminó (2 s)
[Future] ③ Después — datos recibidos exitosamente (6 ítems)
```

---

## ⏱️ 2. Timer — Cronómetro

### ¿Cuándo usarlo?

Usa `Timer` cuando necesitas ejecutar código **periódicamente** o **después de un retraso** mientras la UI sigue respondiendo. A diferencia de `Future.delayed`, un `Timer.periodic` se repite indefinidamente hasta que lo cancelas.

```dart
Timer? _timer;

void iniciar() {
  _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    setState(() => _elapsed += const Duration(milliseconds: 100));
  });
}

void pausar() {
  _timer?.cancel(); // ← SIEMPRE cancelar para evitar memory leaks
  _timer = null;
}

@override
void dispose() {
  _timer?.cancel(); // ← limpieza al destruir el widget
  super.dispose();
}
```

### Flujo del cronómetro

```
Estado: Listo
   │
   ▼  [Iniciar]
Estado: Corriendo  ──→  Timer.periodic(100 ms) incrementa _elapsed
   │
   ▼  [Pausar]
Estado: Pausado   ──→  timer.cancel() + guarda lap
   │
   ├─ [Reanudar] ──→ Estado: Corriendo
   │
   └─ [Reiniciar] ──→ timer.cancel() + elapsed = 0 + borra laps
```

### Botones y sus efectos

| Botón | Visible cuando | Acción |
|-------|---------------|--------|
| Iniciar | Listo | Crea `Timer.periodic` |
| Pausar | Corriendo | `timer.cancel()` + guarda lap |
| Reanudar | Pausado | Crea nuevo `Timer.periodic` |
| Reiniciar | Iniciado | `timer.cancel()` + reset completo |

---

## 🔀 3. Isolate — Tarea Pesada

### ¿Cuándo usarlo?

Usa `Isolate` cuando tienes una tarea **CPU-bound** (cálculos pesados, parsing, compresión) que bloquearía el hilo principal y congelaría la UI. Los Isolates tienen su propia memoria y se comunican mediante `SendPort` / `ReceivePort`.

```dart
// Función top-level (no puede acceder al estado del widget)
void _sumaEnIsolate(_IsolateParams params) {
  int suma = 0;
  for (int i = 1; i <= params.n; i++) suma += i;
  params.replyPort.send(suma); // devuelve el resultado
}

Future<void> lanzar() async {
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _sumaEnIsolate,
    _IsolateParams(receivePort.sendPort, 10000000),
  );

  final resultado = await receivePort.first; // espera sin bloquear
  print('Resultado: $resultado');
}
```

### Flujo de comunicación

```
Main Isolate                     Worker Isolate
     │                                │
     │── Isolate.spawn(fn, params) ──▶│
     │                                │ ejecuta fn(params)
     │◀── sendPort.send(resultado) ───│
     │                                │
  UI actualiza                   Isolate termina
```

### Comparación: Isolate vs Main Thread

| Criterio | Isolate | Main Thread |
|----------|---------|-------------|
| Bloquea UI | ❌ No | ✅ Sí |
| Memoria compartida | ❌ No | ✅ Sí |
| Comunicación | `SendPort` / mensajes | Directa |
| Ideal para | Cómputo pesado | Operaciones ligeras |

La vista permite ejecutar la misma tarea en ambos modos para comparar el comportamiento.

---

## 📐 Diagrama general de pantallas

```
┌─────────────────────────────────┐
│         HomeScreen (/)          │
│   Drawer con navegación lateral │
└──────────────┬──────────────────┘
               │
    ┌──────────┼────────────────┐
    │          │                │
    ▼          ▼                ▼
FutureView  TimerView      IsolateView
(/future)   (/timer)       (/isolate)
    │          │                │
 Estados    Timer.periodic  Isolate.spawn
 Cargando   100 ms          CPU-bound
 Éxito      Iniciar/Pausar  Main vs Isolate
 Error      Laps            Slider N
```

---

## 🚀 Cómo ejecutar

```bash
flutter pub get
flutter run
```

### Requisitos

- Flutter ≥ 3.x
- Dart ≥ 3.x
- Dependencias: `go_router`, `firebase_core`

---

## 📚 Regla de decisión rápida

```
¿La operación espera I/O (red, disco, BD)?  → Future + async/await
¿Necesito repetir algo cada N ms/s?         → Timer.periodic
¿El cálculo es pesado y bloquea la UI?      → Isolate.spawn
```

---

## 🔥 Publicación con Firebase App Distribution

### ¿Qué es Firebase App Distribution?

Firebase App Distribution permite distribuir versiones pre-release de tu APK a testers de forma segura, sin pasar por el proceso completo de la Play Store. Los testers reciben un correo con un enlace de descarga directo.

---

### 🔄 Flujo completo: Generar APK → Distribución → Testers → Instalación → Actualización

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUJO DE DISTRIBUCIÓN                       │
└─────────────────────────────────────────────────────────────────┘

  1. DESARROLLADOR
     │
     ├─ Modifica código / corrige bugs
     ├─ Incrementa versión en pubspec.yaml
     │   (ej: 1.0.0+1  →  1.0.1+2)
     │
     ▼
  2. GENERAR APK DE RELEASE
     │   flutter build apk --release
     │   → build/app/outputs/flutter-apk/app-release.apk
     │
     ▼
  3. SUBIR A FIREBASE APP DISTRIBUTION
     │   Firebase Console → App Distribution → Nueva versión
     │   → Adjuntar APK + Agregar Release Notes
     │
     ▼
  4. NOTIFICACIÓN A TESTERS
     │   Firebase envía email automáticamente
     │   → El tester hace clic en el enlace
     │
     ▼
  5. INSTALACIÓN EN DISPOSITIVO TESTER
     │   → Descarga el APK desde el navegador
     │   → Habilita "Fuentes desconocidas" si es necesario
     │   → Instala la app
     │
     ▼
  6. NUEVA VERSIÓN (ACTUALIZACIÓN)
     │   El desarrollador sube una versión nueva (ej: 1.0.2+3)
     │   → Firebase notifica al tester
     │   → El tester instala sobre la versión anterior
     └─────────────────────────────────────────────────────┘
```

---

### 📦 Sección "Publicación" — Pasos resumidos

#### Paso 1 — Verificar configuración previa

Asegúrate de que los siguientes archivos estén correctamente configurados:

| Archivo | Qué verificar |
|---------|---------------|
| `android/app/src/main/AndroidManifest.xml` | Permiso `INTERNET` declarado |
| `android/app/google-services.json` | Archivo de Firebase presente |
| `android/app/build.gradle.kts` | `versionCode = flutter.versionCode` |
| `pubspec.yaml` | Versión coherente (`versionName+versionCode`) |

El permiso de Internet debe estar declarado explícitamente:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application ...>
```

#### Paso 2 — Incrementar versión en `pubspec.yaml`

```yaml
# Formato: versionName+versionCode
# versionName → lo que ve el usuario (semver)
# versionCode → entero incremental que Android usa internamente

version: 1.0.1+2   # ← v1.0.1, build number 2
```

> ⚠️ El `versionCode` **siempre debe ser mayor** que el de la versión anterior. Firebase rechazará un APK con el mismo `versionCode`.

#### Paso 3 — Generar el APK de release

```bash
flutter build apk --release
```

El APK generado se encuentra en:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### Paso 4 — Subir a Firebase App Distribution

1. Ir a [console.firebase.google.com](https://console.firebase.google.com)
2. Seleccionar el proyecto → **App Distribution**
3. Clic en **"Lanzar"** o **"+"**
4. Arrastrar/seleccionar `app-release.apk`
5. Agregar **Release Notes** (ver formato abajo)
6. Seleccionar grupo de testers → **"Distribuir"**

#### Paso 5 — El tester instala la app

El tester recibirá un email de Firebase con un enlace. Al hacer clic:
1. Descarga la app de Firebase App Tester (si no la tiene)
2. Acepta la invitación
3. Instala el APK directamente desde la app de Firebase

#### Paso 6 — Actualización incremental

Para subir una nueva versión:
1. Modificar código
2. Incrementar versión: `1.0.1+2` → `1.0.2+3`
3. Repetir pasos 3 al 5

Los testers existentes recibirán notificación automática.

---

### 🔁 Cómo replicar el proceso en el equipo

```bash
# 1. Clonar el repositorio
git clone <url-del-repo>
cd electiva_2026

# 2. Instalar dependencias
flutter pub get

# 3. Asegurarse de tener google-services.json
# Descargarlo desde Firebase Console → Configuración del proyecto
# Copiarlo en: android/app/google-services.json

# 4. Incrementar versión en pubspec.yaml (manualmente)
# version: X.Y.Z+N  ← cambiar N y Z según corresponda

# 5. Generar APK
flutter build apk --release

# 6. Subir el APK a Firebase App Distribution
# (desde la consola web de Firebase)
```

---

### 🏷️ Versionado — Convención utilizada

#### Formato

```
version: versionName+versionCode
         └────┬────┘ └────┬────┘
         Semver 3 partes  Entero autoincremental
         (lo ve el usuario) (lo usa Android/Firebase)
```

#### Historial de versiones

| versionName | versionCode | pubspec.yaml | Descripción |
|-------------|-------------|--------------|-------------|
| 1.0.0 | 1 | `1.0.0+1` | ✅ Release inicial — Firebase configurado |
| 1.0.1 | 2 | `1.0.1+2` | 🎨 Cambio de paleta de colores + documentación |

#### Regla semver aplicada

```
1  .  0  .  1  +  2
│     │    │      │
│     │    │      └── versionCode: entero, siempre sube
│     │    └───────── patch: bug fix o cambio menor (colores, docs)
│     └────────────── minor: nueva funcionalidad compatible
└──────────────────── major: cambio incompatible / redesign total
```

---

### 📝 Formato de Release Notes

Las Release Notes se escriben al subir cada versión a Firebase App Distribution. Deben ser concisas y en el idioma del equipo (español en este caso).

#### Plantilla

```
v{versionName} — {título corto}

Cambios:
• {descripción del cambio 1}
• {descripción del cambio 2}

Testers: probar {funcionalidad específica} en dispositivos con Android {versión mínima}+
```

#### Ejemplos reales del proyecto

```
v1.0.0 — Primera versión con Firebase

Cambios:
• Integración inicial de Firebase Core
• Permiso INTERNET agregado al AndroidManifest
• Módulos: Future/async, Timer/Cronómetro, Isolate

Testers: verificar que la app abre correctamente y que el cronómetro
funciona sin congelar la UI.
```

```
v1.0.1 — Nuevo esquema de colores + documentación

Cambios:
• Nueva paleta: índigo profundo (#5C35CC) + teal (#00BFA5)
• Drawer rediseñado con gradiente y avatar
• README actualizado con guía de Firebase App Distribution

Testers: confirmar que la navegación del Drawer funciona
correctamente con el nuevo diseño en Android 8+.
```

---

## 🔐 Notas sobre Seguridad y Firma

El APK de release está actualmente firmado con la **clave de debug** (suficiente para Firebase App Distribution):

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug") // ← aceptable para pruebas
    }
}
```

> Para publicar en la **Play Store** en el futuro, se deberá configurar una `keystore` propia y no compartir las credenciales en el repositorio.
