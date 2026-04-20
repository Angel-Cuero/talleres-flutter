import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/base_view.dart';

// ══════════════════════════════════════════════════════════════
//  MODELOS
// ══════════════════════════════════════════════════════════════

/// Representa una tarea ejecutada (en un Isolate o en el main thread).
class TareaInfo {
  final int id;
  final DateTime startTime;
  final int n;           // Valor de N elegido por el usuario
  final bool enIsolate;  // true = Isolate · false = main thread
  DateTime? endTime;
  String estado;         // 'ejecutando' | 'completado'
  String? resultado;

  TareaInfo({
    required this.id,
    required this.startTime,
    required this.n,
    required this.enIsolate,
  }) : estado = 'ejecutando';

  Duration? get duracion => endTime?.difference(startTime);
}

// ══════════════════════════════════════════════════════════════
//  FUNCIÓN CPU-BOUND (top-level → se puede pasar a Isolate.spawn)
// ══════════════════════════════════════════════════════════════

/// Parámetro enviado al Isolate mediante el [SendPort].
class _IsolateParams {
  final SendPort replyPort;
  final int n;
  _IsolateParams(this.replyPort, this.n);
}

/// Función estática CPU-bound ejecutada dentro del Isolate.
/// Calcula la suma de 1 a [_IsolateParams.n] sin acceso al estado UI.
void _sumaEnIsolate(_IsolateParams params) {
  if (kDebugMode) print('[Isolate] Iniciando suma 1..${ params.n }');

  int suma = 0;
  for (int i = 1; i <= params.n; i++) {
    suma += i;
  }

  if (kDebugMode) print('[Isolate] Suma completada: $suma');
  params.replyPort.send(suma);
}

// ══════════════════════════════════════════════════════════════
//  VISTA
// ══════════════════════════════════════════════════════════════
class IsolateView extends StatefulWidget {
  const IsolateView({super.key});

  @override
  State<IsolateView> createState() => _IsolateViewState();
}

class _IsolateViewState extends State<IsolateView> {
  // ─── Estado ────────────────────────────────────────────────
  final List<TareaInfo> _tareas = [];
  int _nextId = 1;
  final int _nucleos = Platform.numberOfProcessors;

  // Valor de N elegido con el slider
  static const _opcionesN = [10000000, 50000000, 100000000];
  int _nIndex = 0; // índice en _opcionesN

  int get _n => _opcionesN[_nIndex];
  String _formatN(int n) => n >= 1000000 ? '${n ~/ 1000000}M' : '$n';

  int get _ejecutando => _tareas.where((t) => t.estado == 'ejecutando').length;
  bool get _puedeEjecutar => _ejecutando < _nucleos;

  // ─── Lanzar en Isolate ─────────────────────────────────────
  Future<void> _lanzarIsolate() async {
    final id = _nextId++;
    final tarea = TareaInfo(
        id: id, startTime: DateTime.now(), n: _n, enIsolate: true);

    setState(() => _tareas.add(tarea));

    if (kDebugMode) {
      print('[IsolateView] Lanzando Isolate #$id con N=${_formatN(_n)}');
    }

    final receivePort = ReceivePort();

    // Isolate.spawn recibe la función top-level y los parámetros.
    await Isolate.spawn(
      _sumaEnIsolate,
      _IsolateParams(receivePort.sendPort, _n),
    );

    // Esperamos el resultado enviado por el Isolate vía SendPort.
    final suma = await receivePort.first as int;

    if (!mounted) return;
    setState(() {
      tarea.endTime = DateTime.now();
      tarea.estado = 'completado';
      tarea.resultado = 'Σ 1..${ _formatN(_n) } = $suma';
    });
  }

  // ─── Ejecutar en main thread (para comparar) ───────────────
  void _ejecutarEnMainThread() {
    final id = _nextId++;
    final n = _n;
    final tarea = TareaInfo(
        id: id, startTime: DateTime.now(), n: n, enIsolate: false);

    setState(() => _tareas.add(tarea));

    if (kDebugMode) {
      print('[MainThread] Iniciando suma 1..${_formatN(n)} — la UI se bloqueará');
    }

    // ⚠️ Esto BLOQUEA el hilo principal (y la UI)
    int suma = 0;
    for (int i = 1; i <= n; i++) {
      suma += i;
    }

    if (kDebugMode) {
      print('[MainThread] Suma completada: $suma');
    }

    setState(() {
      tarea.endTime = DateTime.now();
      tarea.estado = 'completado';
      tarea.resultado = 'Σ 1..${_formatN(n)} = $suma';
    });
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ejecutando = _ejecutando;
    final disponibles = _nucleos - ejecutando;

    return BaseView(
      title: 'Isolates — Tarea Pesada',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card de núcleos ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: cs.primaryContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.developer_board,
                        size: 36, color: cs.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Núcleos del dispositivo',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onPrimaryContainer
                                      .withValues(alpha: 0.8))),
                          Text('$ejecutando en uso · $disponibles libres',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('$_nucleos',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Selector de N ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tamaño de la tarea (N):',
                            style: TextStyle(fontSize: 13)),
                        Text(
                          'Suma 1..${_formatN(_n)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    Slider(
                      value: _nIndex.toDouble(),
                      min: 0,
                      max: (_opcionesN.length - 1).toDouble(),
                      divisions: _opcionesN.length - 1,
                      label: _formatN(_n),
                      onChanged: (v) =>
                          setState(() => _nIndex = v.round()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _opcionesN
                          .map((v) => Text(_formatN(v),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5))))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Botones ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Isolate
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _puedeEjecutar ? _lanzarIsolate : null,
                    icon: const Icon(Icons.device_hub_rounded),
                    label: const Text('En Isolate'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                // Main thread
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ejecutarEnMainThread,
                    icon: const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange),
                    label: const Text('Main thread\n(bloquea UI)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
              ],
            ),
          ),

          if (!_puedeEjecutar)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Límite alcanzado: todos los núcleos están ocupados.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text('Historial de tareas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),

          // ── Lista de tareas ──
          Expanded(
            child: _tareas.isEmpty
                ? Center(
                    child: Text('Presiona un botón para ejecutar una tarea',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4))))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _tareas.length,
                    itemBuilder: (_, index) {
                      final tarea =
                          _tareas[_tareas.length - 1 - index];
                      final ejecucion = tarea.estado == 'ejecutando';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: ejecucion
                                ? Colors.orange.shade300
                                : tarea.enIsolate
                                    ? Colors.green.shade300
                                    : Colors.blue.shade200,
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: ejecucion
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3))
                              : Icon(
                                  tarea.enIsolate
                                      ? Icons.check_circle
                                      : Icons.warning_amber_rounded,
                                  color: tarea.enIsolate
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 28,
                                ),
                          title: Text(
                            'Tarea #${tarea.id} — ${tarea.enIsolate ? "Isolate" : "Main thread"}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inicio: ${_formatHora(tarea.startTime)}',
                                  style: const TextStyle(fontSize: 11)),
                              if (tarea.resultado != null)
                                Text(tarea.resultado!,
                                    style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: ejecucion
                              ? const Chip(
                                  label: Text('Ejecutando',
                                      style: TextStyle(fontSize: 11)),
                                  backgroundColor: Colors.orange)
                              : Chip(
                                  label: Text(
                                    '${tarea.duracion!.inMilliseconds} ms',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: tarea.enIsolate
                                      ? Colors.green.shade100
                                      : Colors.blue.shade100),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}
