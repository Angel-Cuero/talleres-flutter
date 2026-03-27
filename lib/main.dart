import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taller 1 Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 193, 48, 48)),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variable de estado para el título
  String _appBarTitle = 'Hola, Flutter';

  // Función para alternar el título usando setState()
  void _changeTitle() {
    setState(() {
      if (_appBarTitle == 'Hola, Flutter') {
        _appBarTitle = '¡Título cambiado!';
      } else {
        _appBarTitle = 'Hola, Flutter';
      }
    });

    // Mostrar el SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Título actualizado'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_appBarTitle),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Widget Adicional 1: Container con márgenes, colores y bordes
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color.fromARGB(255, 192, 53, 53), width: 2),
                ),
                child: const Text(
                  'Estudiante:\nAngel Julián Cuero Jinénez\nCódigo: 230231018',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // Imágenes en un Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagen desde la red
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Text('Image.network()'),
                          const SizedBox(height: 8),
                          Image.network(
                            'https://i.pinimg.com/736x/1e/3e/25/1e3e2531ad07bb04e21070b7ae49463c.jpg',
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Imagen desde los assets
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Text('Image.asset()'),
                          const SizedBox(height: 8),
                          Image.asset(
                            'Images/rickross.jpeg',
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.image_not_supported,
                                  size: 100,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Botón principal (Obligatorio) que altera el estado
              ElevatedButton(
                onPressed: _changeTitle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Cambiar Título',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 20),

              // Widget Adicional 2: OutlinedButton con Icono (acción adicional)
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Esta es una acción adicional!'),
                      backgroundColor: Color.fromARGB(255, 194, 52, 52),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Acción Adicional'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}