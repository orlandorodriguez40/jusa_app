import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditarPerfilScreen extends StatefulWidget {
  final int userId;
  final String nombreActual;
  final String telefonoActual;

  const EditarPerfilScreen(
      {super.key,
      required this.userId,
      required this.nombreActual,
      required this.telefonoActual});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.nombreActual);
    _phoneCtrl = TextEditingController(text: widget.telefonoActual);
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final response = await http.patch(
        Uri.parse(
            "https://sistema.jusaimpulsemkt.com/api/editar-usuario-app/${widget.userId}"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: json.encode({
          "name": _nameCtrl.text.trim(),
          "telefono": _phoneCtrl.text.trim(),
        }),
      );

      // 🛡️ Guard check después del await
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("✅ Actualizado")));
        Navigator.pop(context, data["user"]);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("❌ Error al guardar")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre Completo"),
              validator: (v) => v!.isEmpty ? "Obligatorio" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: "Teléfono"),
              validator: (v) => v!.isEmpty ? "Obligatorio" : null,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _update,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GUARDAR"),
            )
          ],
        ),
      ),
    );
  }
}
