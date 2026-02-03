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
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        userId: widget.user["id"],
        userName: widget.user["username"],
        fotosServidor: widget.fotosServidor,
      ),
      PerfilScreen(usuario: widget.user), // ✅ pasamos el objeto completo
      const SizedBox(), // salir
    ];
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
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
