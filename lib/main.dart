import 'package:flutter/material.dart';
import 'pages/fotos_asignacion_page.dart'; // Importa la página de fotos

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Constructor correcto

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // const permitido
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key); // Constructor correcto

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'), // const permitido
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // No const porque idAsignacion es dinámico
                builder: (context) =>
                    const FotosAsignacionPage(idAsignacion: 11),
              ),
            );
          },
          child: const Text('Ver Fotos Asignación'), // const permitido
        ),
      ),
    );
  }
}
