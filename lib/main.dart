import 'package:electiva_2026/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'themes/app_theme.dart'; // Importar el tema
import 'package:firebase_core/firebase_core.dart'; // Importa esto
import 'firebase_options.dart'; // Importa el archivo generado

void main() async {
  // 2. Esta línea es obligatoria cuando inicializas algo antes del runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Inicializamos Firebase usando las opciones generadas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // build es un metodo que se ejecuta cada vez que se necesita redibujar la pantalla
    //go_router para navegacion
    return MaterialApp.router(
      theme:
          AppTheme.lightTheme, //thema personalizado y permamente en toda la app
      title:
          'Flutter - UCEVA', // Usa el tema personalizado, no se muestra el tema por defecto. esto se visualiza en toda la app
      routerConfig: appRouter, // Usa el router configurado
    );
  }
}
