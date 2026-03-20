// menu_screen.dart
import 'package:flutter/material.dart';
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
    // Inicializamos con una copia profunda para evitar mutaciones inesperadas
    usuario = Map<String, dynamic>.from(widget.user);
  }

  int _obtenerNivelId() {
    // 🚨 REFUERZO: Buscamos el nivel en todas las llaves posibles que pueda retornar tu API
    // tras una consulta o una edición.
    var nivel = usuario["nivel_id"] ??
        usuario["id_nivel"] ??
        widget.user["nivel_id"] ??
        3; // Por defecto 3 si no encuentra nada

    return int.tryParse(nivel.toString()) ?? 3;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int nivelId = _obtenerNivelId();

    // Definimos las pantallas pasando siempre el objeto 'usuario' actualizado
    final List<Widget> pantallas = [
      DashboardScreen(
        userId: usuario["id"] ?? 0,
        userName: usuario["name"] ?? usuario["nombre"] ?? "Usuario",
        nivelId: nivelId,
        fotosServidor: widget.fotosServidor,
      ),
      PerfilScreen(
        usuario: usuario,
        onPerfilActualizado: (datosActualizados) {
          // ✅ ACCIÓN CLAVE: Al guardar cambios en el perfil,
          // refrescamos el estado del menú para mantener la consistencia.
          setState(() {
            usuario = Map<String, dynamic>.from(datosActualizados);
          });
        },
      ),
    ];

    return Scaffold(
      // Usamos pantallas[_selectedIndex] para reflejar los cambios de estado inmediatamente
      body: pantallas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            // ✅ MANTENER REPORTE: Si el nivel NO es 3, siempre será "Reporte"
            icon: Icon(nivelId == 3
                ? Icons.assignment_rounded
                : Icons.bar_chart_rounded),
            label: nivelId == 3 ? "Asignaciones" : "Reporte",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Perfil",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app_rounded),
            label: "Salir",
          ),
        ],
      ),
    );
  }
}
