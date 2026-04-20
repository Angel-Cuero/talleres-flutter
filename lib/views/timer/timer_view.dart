import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/base_view.dart';

// ══════════════════════════════════════════════════════════════
//  MODELO DE LAP
// ══════════════════════════════════════════════════════════════
class LapInfo {
  final int numero;
  final Duration tiempo;
  LapInfo({required this.numero, required this.tiempo});
}

// ══════════════════════════════════════════════════════════════
//  VISTA DEL CRONÓMETRO
// ══════════════════════════════════════════════════════════════

/// Pantalla que demuestra el uso de [Timer] para un cronómetro.
///
/// Características:
/// - [Timer.periodic] cada 100 ms para actualizar el tiempo.
/// - Cancelación del timer en pausa, reinicio y [dispose] (limpieza de recursos).
/// - Registro de "laps" al pausar.
/// - Cuatro botones: Iniciar / Pausar / Reanudar / Reiniciar.
class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> with TickerProviderStateMixin {
  // ─── Estado del cronómetro ──────────────────────────────────
  Timer? _timer;                  // Referencia al Timer activo
  Duration _elapsed = Duration.zero; // Tiempo acumulado
  bool _corriendo = false;        // ¿Está el timer activo?
  bool _iniciado = false;         // ¿Se presionó Iniciar alguna vez?
  final List<LapInfo> _laps = []; // Registro de laps

  // Animación del display
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  // ─── Lógica del Timer ───────────────────────────────────────

  /// Inicia o reanuda el cronómetro.
  /// Usa [Timer.periodic] con intervalo de 100 ms.
  void _iniciar() {
    setState(() {
      _corriendo = true;
      _iniciado = true;
    });
    // Timer.periodic llama al callback cada [duration] hasta ser cancelado.
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _elapsed += const Duration(milliseconds: 100);
      });
    });
  }

  /// Pausa el cronómetro: cancela el timer y guarda un lap.
  void _pausar() {
    _timer?.cancel(); // ← limpieza de recursos
    _timer = null;
    setState(() {
      _corriendo = false;
      _laps.add(LapInfo(numero: _laps.length + 1, tiempo: _elapsed));
    });
  }

  /// Reinicia todo: cancela el timer, limpia el tiempo y los laps.
  void _reiniciar() {
    _timer?.cancel(); // ← limpieza de recursos
    _timer = null;
    setState(() {
      _elapsed = Duration.zero;
      _corriendo = false;
      _iniciado = false;
      _laps.clear();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ← limpieza al salir de la vista
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Formato de tiempo ──────────────────────────────────────

  /// Formatea la duración como  MM:SS.d
  String _formatElapsed(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ds = (d.inMilliseconds ~/ 100).remainder(10).toString();
    return '$mm:$ss.$ds';
  }

  String _formatLap(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$mm:$ss.$ms';
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BaseView(
      title: 'Cronómetro — Timer',
      body: Column(
        children: [
          // ── Display grande ──
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.9),
                    cs.tertiary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _corriendo ? '⏱ Corriendo' : (_iniciado ? '⏸ Pausado' : '● Listo'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: _corriendo ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                    child: Text(
                      _formatElapsed(_elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laps registrados: ${_laps.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Botones ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Iniciar / Pausar / Reanudar
                Expanded(
                  child: _corriendo
                      ? FilledButton.icon(
                          onPressed: _pausar,
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('Pausar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: _iniciar,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(_iniciado ? 'Reanudar' : 'Iniciar'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Reiniciar
                OutlinedButton.icon(
                  onPressed: _iniciado ? _reiniciar : null,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reiniciar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),

          // ── Nota técnica ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: cs.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: cs.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Timer.periodic(100 ms) · cancel() al pausar/reiniciar/dispose()',
                        style: TextStyle(fontSize: 11, color: cs.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Lista de Laps ──
          Expanded(
            flex: 2,
            child: _laps.isEmpty
                ? Center(
                    child: Text(
                      'Los laps aparecerán aquí al pausar',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Text(
                          'Registro de laps',
                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _laps.length,
                          itemBuilder: (_, i) {
                            final lap = _laps[_laps.length - 1 - i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: cs.primaryContainer,
                                child: Text(
                                  '${lap.numero}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer),
                                ),
                              ),
                              title: Text(
                                'Lap ${lap.numero}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: Text(
                                _formatLap(lap.tiempo),
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
