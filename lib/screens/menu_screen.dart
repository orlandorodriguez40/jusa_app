import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';
import 'reporte_screen.dart';

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

  /// Centralizamos la obtención del nivel para evitar repetir código
  int _obtenerNivelId() {
    var nivel = usuario["nivel_id"] ?? usuario["id_nivel"] ?? 3;
    return int.tryParse(nivel.toString()) ?? 3;
  }

  Widget _obtenerPantallaActual() {
    final int userId = usuario["id"] ?? 0;
    final String nombre = usuario["name"] ?? usuario["nombre"] ?? "Usuario";
    final int nivelId = _obtenerNivelId();

    // 🟢 Lógica para NIVEL 3 (Solo Asignaciones, Perfil, Salir)
    if (nivelId == 3) {
      if (_selectedIndex == 0) {
        return DashboardScreen(
          userId: userId,
          userName: nombre,
          nivelId: nivelId,
          fotosServidor: widget.fotosServidor,
        );
      }
      if (_selectedIndex == 1) {
        return PerfilScreen(
          usuario: usuario,
          onPerfilActualizado: (act) => setState(() => usuario = act),
        );
      }
    }
    // 🔵 Lógica para NIVEL 2 y 4 (Solo Reporte, Perfil, Salir)
    else {
      if (_selectedIndex == 0) return ReporteScreen(userId: userId);
      if (_selectedIndex == 1) {
        return PerfilScreen(
          usuario: usuario,
          onPerfilActualizado: (act) => setState(() => usuario = act),
        );
      }
    }

    return const Center(child: CircularProgressIndicator());
  }

  void _onItemTapped(int index) {
    // 💡 Quitamos 'nivelId' de aquí porque ya no se usaba, evitando el warning.

    // En el nuevo diseño, 'Salir' siempre es el tercer botón (índice 2)
    // ya sea [Asignaciones, Perfil, Salir] o [Reporte, Perfil, Salir]
    const int indiceSalir = 2;

    if (index == indiceSalir) {
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
    final int nivelId = _obtenerNivelId();

    return Scaffold(
      body: _obtenerPantallaActual(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: [
          // 🛡️ Filtro: Solo nivel 3 ve Asignaciones
          if (nivelId == 3)
            const BottomNavigationBarItem(
                icon: Icon(Icons.assignment), label: "Asignaciones"),

          // 🛡️ Filtro: Solo nivel 2 o 4 ven Reporte
          if (nivelId == 2 || nivelId == 4)
            const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: "Reporte"),

          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Perfil"),

          const BottomNavigationBarItem(
              icon: Icon(Icons.exit_to_app), label: "Salir"),
        ],
      ),
    );
  }
}
