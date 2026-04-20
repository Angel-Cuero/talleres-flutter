import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/base_view.dart';

// ══════════════════════════════════════════════════════════════
//  SERVICIO SIMULADO
// ══════════════════════════════════════════════════════════════

/// Modelo de dato retornado por el servicio.
class Producto {
  final int id;
  final String nombre;
  final double precio;
  Producto({required this.id, required this.nombre, required this.precio});
}

/// Servicio que simula una consulta remota con [Future.delayed].
class ProductoService {
  static final _random = Random();

  /// Consulta datos: espera 2–3 s y puede lanzar un error (~30 % de las veces).
  static Future<List<Producto>> consultarProductos() async {
    if (kDebugMode) print('[Future] ① Antes de la consulta — iniciando petición...');

    // Delay aleatorio entre 2 y 3 segundos
    final delay = 2 + _random.nextInt(2); // 2 o 3
    await Future.delayed(Duration(seconds: delay));

    if (kDebugMode) print('[Future] ② Durante la espera — el delay terminó ($delay s)');

    // Simular error con probabilidad ~30 %
    if (_random.nextDouble() < 0.30) {
      if (kDebugMode) print('[Future] ✗ Error simulado — se lanza una excepción');
      throw Exception('Error de red: no se pudo conectar al servidor.');
    }

    final productos = [
      Producto(id: 1, nombre: 'Laptop Pro', precio: 2_499_000),
      Producto(id: 2, nombre: 'Teclado Mecánico', precio: 350_000),
      Producto(id: 3, nombre: 'Monitor 4K', precio: 1_200_000),
      Producto(id: 4, nombre: 'Mouse Inalámbrico', precio: 180_000),
      Producto(id: 5, nombre: 'Audífonos BT', precio: 420_000),
      Producto(id: 6, nombre: 'Webcam HD', precio: 290_000),
    ];

    if (kDebugMode) print('[Future] ③ Después de la consulta — ${productos.length} productos obtenidos');
    return productos;
  }
}

// ══════════════════════════════════════════════════════════════
//  ESTADOS
// ══════════════════════════════════════════════════════════════
enum EstadoCarga { inicial, cargando, exito, error }

// ══════════════════════════════════════════════════════════════
//  VISTA
// ══════════════════════════════════════════════════════════════
class FutureView extends StatefulWidget {
  const FutureView({super.key});

  @override
  State<FutureView> createState() => _FutureViewState();
}

class _FutureViewState extends State<FutureView> {
  EstadoCarga _estado = EstadoCarga.inicial;
  List<Producto> _productos = [];
  String _mensajeError = '';
  final List<String> _consoleLogs = [];

  // ─── Consulta principal ────────────────────────────────────
  Future<void> _consultarDatos() async {
    setState(() {
      _estado = EstadoCarga.cargando;
      _productos = [];
      _mensajeError = '';
      _consoleLogs.clear();
    });

    _addLog('① Antes — llamando a ProductoService.consultarProductos()');

    try {
      final datos = await ProductoService.consultarProductos();
      _addLog('③ Después — datos recibidos exitosamente (${datos.length} ítems)');

      if (!mounted) return;
      setState(() {
        _estado = EstadoCarga.exito;
        _productos = datos;
      });
    } catch (e) {
      _addLog('✗ Error capturado: $e');
      if (!mounted) return;
      setState(() {
        _estado = EstadoCarga.error;
        _mensajeError = e.toString();
      });
    }
  }

  void _addLog(String mensaje) {
    if (kDebugMode) print('[Future] $mensaje');
    if (mounted) {
      setState(() {
        _consoleLogs.add('${_timestamp()} $mensaje');
      });
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    return '[${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}]';
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BaseView(
      title: 'Future / async / await',
      body: Column(
        children: [
          // ── Banner de estado ──
          _EstadoBanner(estado: _estado, mensajeError: _mensajeError),

          // ── Botón consultar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _estado == EstadoCarga.cargando ? null : _consultarDatos,
                icon: _estado == EstadoCarga.cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: Text(
                  _estado == EstadoCarga.cargando ? 'Consultando...' : 'Consultar datos',
                ),
              ),
            ),
          ),

          // ── Consola ──
          if (_consoleLogs.isNotEmpty)
            _ConsolaWidget(logs: _consoleLogs),

          const Divider(height: 1),

          // ── Contenido principal ──
          Expanded(child: _buildBody(cs)),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    switch (_estado) {
      case EstadoCarga.inicial:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_outlined, size: 64, color: cs.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Presiona "Consultar datos" para iniciar',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        );

      case EstadoCarga.cargando:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando datos del servidor…',
                  style: TextStyle(fontSize: 15)),
            ],
          ),
        );

      case EstadoCarga.exito:
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: _productos.length,
          itemBuilder: (_, i) => _ProductoCard(producto: _productos[i]),
        );

      case EstadoCarga.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Error al consultar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                Text(_mensajeError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _consultarDatos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ══════════════════════════════════════════════════════════════

class _EstadoBanner extends StatelessWidget {
  final EstadoCarga estado;
  final String mensajeError;
  const _EstadoBanner({required this.estado, required this.mensajeError});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late IconData icon;
    late String texto;

    switch (estado) {
      case EstadoCarga.inicial:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        icon = Icons.info_outline;
        texto = 'Estado: Inicial — listo para consultar';
      case EstadoCarga.cargando:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        icon = Icons.hourglass_top_rounded;
        texto = 'Estado: Cargando… por favor espera';
      case EstadoCarga.exito:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        texto = 'Estado: Éxito ✓ — datos cargados correctamente';
      case EstadoCarga.error:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.error_outline;
        texto = 'Estado: Error ✗ — consulta fallida';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ConsolaWidget extends StatelessWidget {
  final List<String> logs;
  const _ConsolaWidget({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1E2E),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.terminal, color: Colors.greenAccent, size: 14),
            const SizedBox(width: 6),
            const Text('Consola', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
          ]),
          const SizedBox(height: 4),
          ...logs.map((l) => Text(l,
              style: const TextStyle(
                  color: Color(0xFFCDD6F4),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.5))),
        ],
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('#${producto.id} ${producto.nombre}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                    fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              '\$${producto.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} COP',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
