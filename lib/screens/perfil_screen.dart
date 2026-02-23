import 'package:flutter/material.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final Function(Map<String, dynamic>)? onPerfilActualizado;

  const PerfilScreen(
      {super.key, required this.usuario, this.onPerfilActualizado});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Map<String, dynamic> usuarioLocal;

  @override
  void initState() {
    super.initState();
    usuarioLocal = Map<String, dynamic>.from(widget.usuario);
  }

  @override
  void didUpdateWidget(covariant PerfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usuario != widget.usuario) {
      setState(() {
        usuarioLocal = Map<String, dynamic>.from(widget.usuario);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Buscamos el nombre en varias llaves posibles
    final String nombreAMostrar =
        usuarioLocal["name"] ?? usuarioLocal["nombre"] ?? "No definido";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue, // Como en tu captura
              child: nombreAMostrar == "No definido"
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(Icons.person, "Nombre", nombreAMostrar),
          _buildInfoCard(Icons.account_circle, "Usuario",
              usuarioLocal["username"] ?? "Sin usuario"),
          _buildInfoCard(Icons.phone, "Teléfono",
              usuarioLocal["telefono"] ?? "Sin teléfono"),
          const SizedBox(height: 20),
          TextButton.icon(
            icon: const Icon(Icons.edit, color: Colors.green),
            label: const Text("EDITAR DATOS",
                style: TextStyle(color: Colors.green)),
            onPressed: () async {
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
                if (widget.onPerfilActualizado != null) {
                  widget.onPerfilActualizado!(result);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.green),
          title: Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(label),
        ),
        const Divider(),
      ],
    );
  }
}
