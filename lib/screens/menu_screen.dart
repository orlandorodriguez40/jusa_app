import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart'; // 👈 asegúrate de que la ruta sea correcta

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _indiceActual = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: const [
          // ASIGNACIONES: tu pantalla real
          DashboardScreen(userId: 0, userName: "Usuario"),

          // PERFIL: lo conectaremos en el paso 3
          Center(child: Text("Pantalla de Perfil (API)")),

          // SALIR: no necesita pantalla
          SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          if (index == 2) {
            // SALIR: vuelve al login y limpia la pila
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sesión cerrada")),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
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
