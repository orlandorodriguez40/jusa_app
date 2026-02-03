import 'package:flutter/material.dart';
import 'editar_perfil_screen.dart';

class PerfilScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const PerfilScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF424949),
        title: const Text("Perfil"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
              usuario["profile_photo_url"] ??
                  "https://ui-avatars.com/api/?name=${usuario["name"] ?? "U"}&color=7F9CF5&background=EBF4FF",
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(usuario["name"] ?? "Sin nombre"),
              subtitle: const Text("Nombre"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(usuario["username"] ?? "Sin usuario"),
              subtitle: const Text("Usuario"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: Text(usuario["telefono"] ?? "Sin teléfono"),
              subtitle: const Text("Teléfono"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.update),
              title: Text(usuario["updated_at"] ?? "Sin fecha"),
              subtitle: const Text("Última actualización"),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Editar Perfil"),
            onPressed: () async {
              final actualizado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarPerfilScreen(
                    userId: usuario["id"],
                    nombreActual: usuario["name"] ?? "",
                    telefonoActual: usuario["telefono"] ?? "",
                  ),
                ),
              );

              if (actualizado != null && actualizado is Map) {
                usuario["name"] = actualizado["name"];
                usuario["telefono"] = actualizado["telefono"];
              }
            },
          ),
        ],
      ),
    );
  }
}
