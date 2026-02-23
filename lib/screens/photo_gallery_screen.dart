import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhotoGalleryScreen extends StatefulWidget {
  final List<dynamic> fotosServidor;

  static const String baseImageUrl =
      "https://sistema.jusaimpulsemkt.com/storage/";

  const PhotoGalleryScreen({super.key, required this.fotosServidor});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late List<dynamic> fotos;

  @override
  void initState() {
    super.initState();
    fotos = List.from(widget.fotosServidor);
  }

  bool _puedeEliminar(dynamic foto) {
    if (foto["created_at"] == null) {
      return false;
    }

    try {
      DateTime fechaFoto = DateTime.parse(foto["created_at"]).toLocal();
      DateTime ahora = DateTime.now();
      int diferencia = ahora.difference(fechaFoto).inMinutes;

      return diferencia < 5;
    } catch (e) {
      return false;
    }
  }

  Future<void> eliminarFoto(int id, int index) async {
    final url = Uri.parse(
        "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/$id");

    final response = await http.delete(url);

    if (!mounted) {
      return;
    }

    if (response.statusCode == 200) {
      setState(() {
        fotos.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto eliminada correctamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar la foto")),
      );
    }
  }

  void confirmarEliminacion(int id, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Seguro que quieres eliminar esta foto?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () {
              Navigator.of(context).pop();
              eliminarFoto(id, index);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fotos tomadas")),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: fotos.length,
        itemBuilder: (context, index) {
          final fotoData = fotos[index];
          final String ruta = fotoData["foto"] ?? "";
          final int id = fotoData["id"] ?? 0;
          final String imageUrl = "${PhotoGalleryScreen.baseImageUrl}$ruta";
          final bool mostrarBorrar = _puedeEliminar(fotoData);

          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  key: ValueKey(imageUrl),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 40,
                  ),
                ),
              ),
              if (mostrarBorrar) ...[
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      // ✅ CORRECCIÓN: Usando .withValues(alpha: ...) en lugar de .withOpacity
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        confirmarEliminacion(id, index);
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
