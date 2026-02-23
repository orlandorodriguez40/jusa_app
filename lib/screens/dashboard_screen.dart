import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart'; // Librería de GPS
import 'package:image/image.dart' as img; // Librería de procesamiento de imagen
import 'package:path_provider/path_provider.dart'; // Para archivos temporales
import 'photo_gallery_screen.dart';
import 'perfil_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final List<dynamic> fotosServidor;

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
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = {
      "id": widget.userId,
      "name": widget.userName,
      "username": widget.userName,
      "telefono": "---",
      "cliente": "Cargando...",
    };
    _fetchAsignaciones();
  }

  // --- FUNCIÓN: Obtener coordenadas GPS ---
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('El GPS está desactivado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de GPS denegado.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Los permisos de GPS están bloqueados permanentemente.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // --- FUNCIÓN: Poner texto sobre la foto ---
  Future<File> _addWatermark(File imageFile, Position pos) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      return imageFile;
    }

    String timestamp = DateTime.now().toString().split('.')[0];
    String text =
        "LAT: ${pos.latitude.toStringAsFixed(6)}\nLON: ${pos.longitude.toStringAsFixed(6)}\nFECHA: $timestamp";

    // Dibujamos el texto en la parte inferior izquierda
    img.drawString(
      originalImage,
      text,
      font: img.arial24,
      x: 30,
      y: originalImage.height - 140,
      color: img.ColorRgba8(255, 255, 255, 255), // Blanco sólido
    );

    final tempDir = await getTemporaryDirectory();
    final path =
        "${tempDir.path}/marked_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final File markedFile = File(path);
    await markedFile.writeAsBytes(img.encodeJpg(originalImage, quality: 90));

    return markedFile;
  }

  void _abrirPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilScreen(
          usuario: _userData,
          onPerfilActualizado: (datosNuevos) {
            if (!mounted) {
              return;
            }
            setState(() {
              _userData = datosNuevos;
            });
          },
        ),
      ),
    );
  }

  Future<void> _fetchAsignaciones() async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://sistema.jusaimpulsemkt.com/api/mis-asignaciones-app/${widget.userId}"),
        headers: const {"Accept": "application/json"},
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> fetchedAsignaciones = data["datos"] ?? [];

        setState(() {
          _asignaciones = fetchedAsignaciones;
          _loading = false;

          if (_asignaciones.isNotEmpty) {
            final primera = _asignaciones[0];
            _userData["cliente"] = primera["cliente"] ?? "Sin asignar";
            if (primera["user_name"] != null) {
              _userData["name"] = primera["user_name"];
            }
            if (primera["telefono"] != null) {
              _userData["telefono"] = primera["telefono"];
            }
          }
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // --- FUNCIÓN ACTUALIZADA: Tomar foto con GPS y Marca de Agua ---
  Future<void> _takePhoto(dynamic asignacion) async {
    Position? currentPosition;
    try {
      currentPosition = await _determinePosition();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("GPS: $e")));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (photo == null || !mounted) {
      return;
    }

    setState(() {
      _sendingPhoto = true;
    });

    try {
      File originalFile = File(photo.path);
      File markedFile = await _addWatermark(originalFile, currentPosition);

      final request = http.MultipartRequest('POST',
          Uri.parse("https://sistema.jusaimpulsemkt.com/api/tomar-foto-app"));
      request.fields['asignacion_id'] = asignacion["id"].toString();
      request.fields['latitud'] = currentPosition.latitude.toString();
      request.fields['longitud'] = currentPosition.longitude.toString();
      request.files
          .add(await http.MultipartFile.fromPath('file', markedFile.path));

      final response = await request.send();

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Foto con GPS enviada")));
        _fetchAsignaciones();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Error al procesar foto")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingPhoto = false;
        });
      }
    }
  }

  Future<void> _viewPhotos(dynamic asignacion) async {
    try {
      final response = await http.get(Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/fotos-asignacion-app/${asignacion["id"]}"));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final List fotos = json.decode(response.body)["datos"] ?? [];
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PhotoGalleryScreen(fotosServidor: fotos)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error galería")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 🛠️ SOLUCIÓN PARA LA FRANJA ROJA
      appBar: AppBar(
        backgroundColor: const Color(0xFF424949),
        centerTitle: true,
        title: Text("PANEL - ${_userData["name"]}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SafeArea(
            // 🛠️ PROTEGE EL DISEÑO EN BORDES
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _abrirPerfil,
                    child: Image.asset("assets/images/logo-jusa-2-opt.png",
                        height: 70), // Ajustado ligeramente para ganar espacio
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildList(),
                  ),
                ],
              ),
            ),
          ),
          if (_sendingPhoto)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_asignaciones.isEmpty) {
      return const Center(child: Text("No hay asignaciones disponibles"));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(), // 🛠️ MEJORA EL SCROLL
      itemCount: _asignaciones.length,
      itemBuilder: (context, index) {
        final asign = _asignaciones[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fecha: ${asign["fecha"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Cliente: ${asign["cliente"]}"),
                Text("Plaza: ${asign["plaza"]}"),
                Text("Ubicación: ${asign["ciudad"]}"),
                Text("Estatus: ${asign["estatus"]}"),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.green),
                      onPressed: () => _takePhoto(asign),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.blue),
                      onPressed: () => _viewPhotos(asign),
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
}
