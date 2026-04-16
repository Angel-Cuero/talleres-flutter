import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/base_view.dart';

// Modelo que representa cada tarea ejecutada en un Isolate
class IsolateTaskInfo {
  final int id;
  final DateTime startTime;
  DateTime? endTime;
  String estado; // 'ejecutando' | 'completado'
  String? resultado;

  IsolateTaskInfo({required this.id, required this.startTime})
      : estado = 'ejecutando';

  Duration? get duracion => endTime?.difference(startTime);
}

class IsolateView extends StatefulWidget {
  const IsolateView({super.key});

  @override
  State<IsolateView> createState() => _IsolateViewState();
}

class _IsolateViewState extends State<IsolateView> {
  final List<IsolateTaskInfo> _tareas = [];
  int _nextId = 1;

  // Obtiene la cantidad de núcleos del procesador del dispositivo
  final int _nucleos = Platform.numberOfProcessors;

  // Cantidad de isolates actualmente en ejecución
  int get _ejecutando => _tareas.where((t) => t.estado == 'ejecutando').length;

  // El botón solo se habilita si hay núcleos disponibles
  bool get _puedeEjecutar => _ejecutando < _nucleos;

  Future<void> _lanzarIsolate() async {
    final id = _nextId++;
    final tarea = IsolateTaskInfo(id: id, startTime: DateTime.now());

    setState(() {
      _tareas.add(tarea);
    });

    final receivePort = ReceivePort();

    await Isolate.spawn(_simulacionTareaPesada, receivePort.sendPort);

    final sendPort = await receivePort.first as SendPort;
    final response = ReceivePort();

    sendPort.send(["Tarea #$id", response.sendPort]);

    final resultado = await response.first as String;

    if (!mounted) return;
    setState(() {
      tarea.endTime = DateTime.now();
      tarea.estado = 'completado';
      tarea.resultado = resultado;
    });
  }

  // Función estática ejecutada dentro del Isolate (no puede acceder al estado)
  static void _simulacionTareaPesada(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final message in port) {
      final data = message[0] as String;
      final replyPort = message[1] as SendPort;

      // Simula carga computacional: suma hasta 10.000.000
      int counter = 0;
      for (int i = 1; i <= 10000000; i++) {
        counter += i;
      }

      if (kDebugMode) print("[$data] Suma completada: $counter");

      replyPort.send("Suma 1..10M = $counter");
      port.close();
      Isolate.exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ejecutando = _ejecutando;
    final disponibles = _nucleos - ejecutando;

    return BaseView(
      title: "Demo de Isolates",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card de núcleos del procesador ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.developer_board,
                      size: 36,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Núcleos del dispositivo",
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            "$ejecutando en uso · $disponibles libres",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$_nucleos",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Botón para lanzar un nuevo Isolate ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _puedeEjecutar ? _lanzarIsolate : null,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text("Lanzar nuevo Isolate"),
                ),
                if (!_puedeEjecutar)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "Límite alcanzado: todos los núcleos están ocupados.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              "Isolates ejecutados",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          // ── Lista de Isolates ──
          Expanded(
            child: _tareas.isEmpty
                ? const Center(
                    child: Text(
                      "Presiona el botón para lanzar un Isolate",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _tareas.length,
                    itemBuilder: (context, index) {
                      // Mostramos el más reciente primero
                      final tarea = _tareas[_tareas.length - 1 - index];
                      final ejecutando = tarea.estado == 'ejecutando';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: ejecutando
                                ? Colors.orange.shade300
                                : Colors.green.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: ejecutando
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 28,
                                ),
                          title: Text(
                            "Isolate #${tarea.id}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "Inicio: ${_formatHora(tarea.startTime)}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (tarea.resultado != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  tarea.resultado!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                          trailing: ejecutando
                              ? const Chip(
                                  label: Text(
                                    "Ejecutando",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.orange,
                                )
                              : Chip(
                                  label: Text(
                                    "${tarea.duracion!.inMilliseconds} ms",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors.green.shade100,
                                ),
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
      "${dt.hour.toString().padLeft(2, '0')}:"
      "${dt.minute.toString().padLeft(2, '0')}:"
      "${dt.second.toString().padLeft(2, '0')}";
}
