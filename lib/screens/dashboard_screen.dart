import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'photo_gallery_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final List<dynamic> fotosServidor; // ✅ nuevo parámetro

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.fotosServidor,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Logger logger = Logger();
  bool _loading = true;
  bool _sendingPhoto = false;
  List<dynamic> _asignaciones = [];

  @override
  void initState() {
    super.initState();
    _fetchAsignaciones();
  }

  Future<void> _fetchAsignaciones() async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://sistema.jusaimpulsemkt.com/api/mis-asignaciones-app/${widget.userId}"),
        headers: const {"Accept": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _asignaciones = data["datos"] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showSnackBar("Error al cargar asignaciones");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _takePhoto(dynamic asignacion) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (!mounted) return;

    if (photo != null) {
      final File nuevaFoto = File(photo.path);
      final int asignacionId = asignacion["id"];

      setState(() => _sendingPhoto = true);

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse("https://sistema.jusaimpulsemkt.com/api/tomar-foto-app"),
        );
        request.fields['asignacion_id'] = asignacionId.toString();
        request.files
            .add(await http.MultipartFile.fromPath('file', nuevaFoto.path));

        logger.i(
            "Enviando foto: ${nuevaFoto.path} para asignacion $asignacionId");

        final response = await request.send();

        if (!mounted) return;

        if (response.statusCode == 200) {
          _showSnackBar("✅ Foto enviada correctamente");
          setState(() => _loading = true);
          await _fetchAsignaciones();
          setState(() => _loading = false);
        } else {
          final respStr = await response.stream.bytesToString();
          _showSnackBar(
              "❌ Error al enviar la foto: ${response.statusCode} - $respStr");
        }
      } catch (e) {
        if (!mounted) return;
        _showSnackBar("❌ Excepción al enviar la foto: $e");
      } finally {
        if (mounted) setState(() => _sendingPhoto = false);
      }
    }
  }

  Future<void> _viewPhotos(dynamic asignacion) async {
    final int asignacionId = asignacion["id"];

    try {
      final response = await http.get(
        Uri.parse(
            "https://sistema.jusaimpulsemkt.com/api/fotos-asignacion-app/$asignacionId"),
        headers: const {"Accept": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List fotosServidor = data["datos"] ?? [];

        if (fotosServidor.isEmpty) {
          _showSnackBar("No hay fotos en el servidor");
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhotoGalleryScreen(fotosServidor: fotosServidor),
          ),
        );
      } else {
        _showSnackBar("Error al cargar fotos: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Excepción al cargar fotos: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_asignaciones.isEmpty) {
      return const Center(
        child: Text(
          "No hay asignaciones disponibles.",
          style: TextStyle(color: Color(0xFF424949), fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _asignaciones.length,
      itemBuilder: (context, index) {
        final asignacion = _asignaciones[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fecha: ${asignacion["fecha"] ?? ""}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Cliente: ${asignacion["cliente"] ?? ""}"),
                Text("Plaza: ${asignacion["plaza"] ?? ""}"),
                Text("Ubicación: ${asignacion["ciudad"] ?? ""}"),
                Text("Estatus: ${asignacion["estatus"] ?? ""}"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: _sendingPhoto
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt, color: Colors.green),
                      tooltip: "Tomar",
                      onPressed:
                          _sendingPhoto ? null : () => _takePhoto(asignacion),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.blue),
                      tooltip: "Ver",
                      onPressed: () => _viewPhotos(asignacion),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF424949),
            title: Text(
              "PANEL - ${widget.userName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Image.asset("assets/images/logo-jusa-2-opt.png", height: 80),
                const SizedBox(height: 20),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),
        if (_sendingPhoto)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.35),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        "Enviando foto...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
