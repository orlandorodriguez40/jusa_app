import 'login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _indiceActual = 0;

  Future<Map<String, dynamic>> cargarPerfil() async {
    final url = Uri.parse(
        "https://sistema.jusaimpulsemkt.com/api/editar-usuario-app/1");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar perfil");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: [
          // Opción 1: Asignaciones → Pantalla 2
          const Center(child: Text("Pantalla 2 - Asignaciones")),

          // Opción 2: Perfil → API
          FutureBuilder<Map<String, dynamic>>(
            future: cargarPerfil(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else {
                final perfil = snapshot.data!;
                return Scaffold(
                  appBar: AppBar(title: const Text("Perfil")),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Perfil del usuario",
                            style: TextStyle(fontSize: 20)),
                        Text("Nombre: ${perfil['name'] ?? 'N/A'}"),
                        Text("Email: ${perfil['email'] ?? 'N/A'}"),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          // Opción 3: Salir → Pantalla 1
          const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          if (index == 2) {
            // Mostrar SnackBar antes de salir
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sesión cerrada")),
            );

            // Acción de salir: reemplaza y limpia toda la pila
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => const LoginScreen()), // 👈 vuelve al login
              (Route<dynamic> route) => false,
            );
          } else {
            setState(() {
              _indiceActual = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Asignaciones",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: "Salir",
          ),
        ],
      ),
    );
  }
}
