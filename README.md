# 📱 Electiva 2026 — Flutter Educativo

Aplicación Flutter didáctica que demuestra conceptos clave de programación asíncrona, timers e isolates en Dart/Flutter.

---

## 🗂️ Pantallas de la aplicación

| Ruta | Pantalla | Concepto principal |
|------|----------|--------------------|
| `/` | Inicio | Navegación general |
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

Usa `Isolate` cuando tienes una tarea **CPU-bound** (cálculos pesados, parsing, compresión) que bloquearía el hilo principal y congalaría la UI. Los Isolates tienen su propia memoria y se comunican mediante `SendPort` / `ReceivePort`.

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
- Dependencias: `go_router`

---

## 📚 Regla de decisión rápida

```
¿La operación espera I/O (red, disco, BD)?  → Future + async/await
¿Necesito repetir algo cada N ms/s?         → Timer.periodic
¿El cálculo es pesado y bloquea la UI?      → Isolate.spawn
```
