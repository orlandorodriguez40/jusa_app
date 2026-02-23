import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> fotosServidor;

  const MenuScreen({
    super.key,
    required this.user,
    required this.fotosServidor,
  });

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

  // 🛠️ Función auxiliar para extraer el nombre real sin importar la llave
  String _obtenerNombreValido() {
    return usuario["name"] ?? // Opción 1 (estándar)
        usuario["nombre"] ?? // Opción 2 (español)
        usuario["username"] ?? // Opción 3 (fallback)
        "Usuario"; // Opción final
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombreParaMostrar = _obtenerNombreValido();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            userId: usuario["id"] ?? 0,
            userName: nombreParaMostrar, // ✅ Ahora siempre tendrá un valor
            fotosServidor: widget.fotosServidor,
          ),
          PerfilScreen(
            usuario: usuario,
            onPerfilActualizado: (actualizado) {
              setState(() {
                usuario = actualizado;
              });
            },
          ),
          const SizedBox(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: "Asignaciones"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          BottomNavigationBarItem(
              icon: Icon(Icons.exit_to_app), label: "Salir"),
        ],
      ),
    );
  }
}
