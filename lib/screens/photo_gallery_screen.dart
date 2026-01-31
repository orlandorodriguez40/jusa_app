import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PhotoGalleryScreen extends StatefulWidget {
  final List<dynamic> fotosServidor;

  // URL base QUE YA SABEMOS QUE FUNCIONA
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
  // ELIMINAR FOTO (AÚN NO DEFINITIVO)
  // ===============================
  Future<void> _eliminarFoto(int fotoId, int index) async {
    // ⚠️ ESTE ENDPOINT ES TEMPORAL
    // CUANDO ME PASES LA API REAL, AQUÍ LO AJUSTAMOS
    final url =
        'https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/$fotoId';

    try {
      final response = await http.delete(Uri.parse(url));

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
          const SnackBar(content: Text('No se pudo eliminar la foto')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  // ===============================
  // CONFIRMAR ELIMINACIÓN
  // ===============================
  void _confirmarEliminar(int fotoId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text(
          '¿Seguro que deseas eliminar esta foto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarFoto(fotoId, index);
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

  // ===============================
  // UI
  // ===============================
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
          final foto = widget.fotosServidor[index];

          final int? fotoId = foto['id']; // 👈 ID DE LA IMAGEN
          final String ruta = foto['foto'] ?? '';

          if (ruta.isEmpty) {
            return const Center(child: Icon(Icons.broken_image));
          }

          final String imageUrl = "${PhotoGalleryScreen.baseImageUrl}$ruta";

          return Stack(
            children: [
              // ===============================
              // IMAGEN
              // ===============================
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 40),
                ),
              ),

              // ===============================
              // ID + BOTÓN ELIMINAR
              // ===============================
              if (fotoId != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🆔 ID
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(153, 0, 0, 0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: $fotoId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 🗑 BOTÓN ELIMINAR
                      InkWell(
                        onTap: () => _confirmarEliminar(fotoId, index),
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
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
