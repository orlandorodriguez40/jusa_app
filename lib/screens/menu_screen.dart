import 'package:flutter/material.dart';
// 🚨 ASEGÚRATE DE QUE ESTA LÍNEA ESTÉ EXACTAMENTE ASÍ:
import 'dashboard_screen.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> fotosServidor;

  const MenuScreen(
      {super.key, required this.user, required this.fotosServidor});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;
  late Map<String, dynamic> usuario;

  @override
  void initState() {
    super.initState();
    usuario = Map<String, dynamic>.from(widget.user);
  }

  int _obtenerNivelId() {
    var nivel = usuario["nivel_id"] ?? usuario["id_nivel"] ?? 3;
    return int.tryParse(nivel.toString()) ?? 3;
  }

  void _onItemTapped(int index) {
    // Índice 2 es el botón "Salir"
    if (index == 2) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int nivelId = _obtenerNivelId();

    // Lista de pantallas para el cuerpo del Scaffold
    final List<Widget> pantallas = [
      DashboardScreen(
        userId: usuario["id"] ?? 0,
        userName: usuario["name"] ?? usuario["nombre"] ?? "Usuario",
        nivelId: nivelId,
        fotosServidor: widget.fotosServidor,
      ),
      PerfilScreen(
        usuario: usuario,
        onPerfilActualizado: (act) {
          setState(() {
            usuario = act;
          });
        },
      ),
    ];

    return Scaffold(
      body: pantallas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(nivelId == 3 ? Icons.assignment : Icons.bar_chart),
            label: nivelId == 3 ? "Asignaciones" : "Reporte",
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Perfil"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.exit_to_app), label: "Salir"),
        ],
      ),
    );
  }
}
