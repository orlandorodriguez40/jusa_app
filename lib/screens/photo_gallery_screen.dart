import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhotoGalleryScreen extends StatefulWidget {
  final List<dynamic> fotosServidor;

  static const String baseImageUrl =
      "https://sistema.jusaimpulsemkt.com/storage/";

  const PhotoGalleryScreen({
    super.key,
    required this.fotosServidor,
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  // ===============================
  // ELIMINAR FOTO (USA ID O RUTA)
  // ===============================
  Future<void> _eliminarFotoPorRuta(String ruta, int index) async {
    const url = 'https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'ruta': ruta,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          widget.fotosServidor.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto eliminada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la foto')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  void _confirmarEliminar(String ruta, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Deseas eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarFotoPorRuta(ruta, index);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
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
        itemCount: widget.fotosServidor.length,
        itemBuilder: (context, index) {
          final String ruta = widget.fotosServidor[index]["foto"] ?? "";

          if (ruta.isEmpty) {
            return const Center(child: Icon(Icons.broken_image));
          }

          final String imageUrl = "${PhotoGalleryScreen.baseImageUrl}$ruta";

          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // ✅ BOTÓN SIEMPRE VISIBLE
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _confirmarEliminar(ruta, index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
