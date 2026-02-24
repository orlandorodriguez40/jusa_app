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
    // Clonamos la lista y la ordenamos por ID para que la nueva salga arriba
    fotos = List.from(widget.fotosServidor);
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
  }

  // Lógica de tiempo mejorada
  bool _puedeEliminar(dynamic foto) {
    if (foto["created_at"] == null) return false;

    try {
      // Parseo flexible: intentamos leer la fecha del servidor
      DateTime fechaFoto = DateTime.parse(foto["created_at"]).toUtc();
      DateTime ahora = DateTime.now().toUtc();

      int diferenciaSegundos = ahora.difference(fechaFoto).inSeconds;

      // Imprime esto en tu consola para ver el desfase real
      debugPrint("ID: ${foto['id']} | Segundos: $diferenciaSegundos");

      // Mostramos el botón si han pasado menos de 300 segundos (5 min)
      // Agregamos un margen de 60 segundos por si los relojes no coinciden
      return diferenciaSegundos < 300 && diferenciaSegundos > -60;
    } catch (e) {
      return false;
    }
  }

  Future<void> eliminarFoto(int id, int index) async {
    try {
      final url = Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/$id");

      final response = await http.delete(url);

      if (!mounted) return;

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
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
            onPressed: () => Navigator.of(context).pop(),
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
      appBar: AppBar(
        title: const Text("Fotos tomadas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
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

          // Aplicamos la restricción aquí
          final bool visible = _puedeEliminar(fotoData);

          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  key: ValueKey(imageUrl),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 40,
                  ),
                ),
              ),
              // Solo mostramos el Positioned si está en el rango de 5 min
              if (visible)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 3)
                        ]),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => confirmarEliminacion(id, index),
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
