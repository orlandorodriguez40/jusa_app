// perfil_screen.dart
import 'package:flutter/material.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final Function(Map<String, dynamic>)? onPerfilActualizado;

  const PerfilScreen({
    super.key,
    required this.usuario,
    this.onPerfilActualizado,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Map<String, dynamic> usuarioLocal;

  @override
  void initState() {
    super.initState();
    // Clonamos los datos recibidos para manejarlos localmente
    usuarioLocal = Map<String, dynamic>.from(widget.usuario);
  }

  @override
  void didUpdateWidget(covariant PerfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el widget padre (MenuScreen) actualiza los datos, refrescamos aquí
    if (oldWidget.usuario != widget.usuario) {
      setState(() {
        usuarioLocal = Map<String, dynamic>.from(widget.usuario);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Manejo de nombres con prioridades según los campos de tu API
    final String nombreAMostrar =
        usuarioLocal["name"] ?? usuarioLocal["nombre"] ?? "No definido";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mi Perfil",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF424949),
        centerTitle: true,
        // Eliminamos el arrow_back manual ya que al ser parte del BottomNav no lo necesita,
        // pero lo dejamos si planeas navegar a esta pantalla de forma independiente.
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  "assets/images/logo-jusa-2-opt.png",
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_rounded,
                        size: 60, color: Colors.grey);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildInfoCard(
              Icons.person_outline_rounded, "Nombre completo", nombreAMostrar),
          _buildInfoCard(Icons.account_circle_outlined, "Usuario de acceso",
              usuarioLocal["username"] ?? "Sin usuario"),
          _buildInfoCard(Icons.phone_android_outlined, "Número de contacto",
              usuarioLocal["telefono"] ?? "Sin teléfono"),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
              label: const Text("EDITAR INFORMACIÓN",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                // Navegamos y esperamos el retorno del nuevo mapa de usuario
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditarPerfilScreen(
                      userId: usuarioLocal["id"],
                      nombreActual:
                          nombreAMostrar == "No definido" ? "" : nombreAMostrar,
                      telefonoActual: usuarioLocal["telefono"] ?? "",
                    ),
                  ),
                );

                if (!mounted) return;

                if (result != null && result is Map<String, dynamic>) {
                  // ✅ IMPORTANTE: Actualizamos localmente
                  setState(() {
                    usuarioLocal = Map<String, dynamic>.from(result);
                  });

                  // ✅ NOTIFICAMOS AL MENU_SCREEN:
                  // Esto garantiza que el nivelId se mantenga y la opción "Reporte" no cambie.
                  if (widget.onPerfilActualizado != null) {
                    widget.onPerfilActualizado!(result);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x144CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green, size: 22),
          ),
          title: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF2C3E50)),
          ),
          subtitle: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 60),
          child: Divider(thickness: 0.6, height: 1),
        ),
      ],
    );
  }
}
