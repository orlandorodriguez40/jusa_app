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
    // Ordenar para que la más nueva sea la primera
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
  }

  bool _puedeEliminar(dynamic foto) {
    // -------------------------------------------------------
    // 🧪 PRUEBA DE DIAGNÓSTICO: FORZAMOS EL BOTÓN A APARECER
    // -------------------------------------------------------

    final String? createdAt = foto["created_at"];
    if (createdAt != null) {
      try {
        DateTime fechaFoto = DateTime.parse(createdAt).toUtc();
        DateTime ahoraUtc = DateTime.now().toUtc();
        int diferenciaSegundos = ahoraUtc.difference(fechaFoto).inSeconds;

        // Esto aparecerá en tu consola de VS Code/Android Studio
        debugPrint(
            "FOTO ID ${foto['id']} -> Segundos transcurridos: $diferenciaSegundos");
      } catch (e) {
        debugPrint("Error parseando fecha: $e");
      }
    }

    return true; // <--- Cambiado a TRUE para que el icono salga sí o sí
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
          const SnackBar(
              content: Text("El servidor no permitió la eliminación")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de red")),
      );
    }
  }

  void confirmarEliminacion(int id, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text("¿Quieres eliminar esta foto definitivamente?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () {
              Navigator.pop(context);
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
        title: const Text("Galería (Modo Debug)"),
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

          final bool mostrarBoton = _puedeEliminar(fotoData);

          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
              ),
              if (mostrarBoton)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
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
