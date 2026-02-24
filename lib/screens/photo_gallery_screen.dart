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
    // Copiamos la lista y la ordenamos por fecha (más reciente arriba)
    fotos = List.from(widget.fotosServidor);
    fotos.sort(
        (a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
  }

  bool _puedeEliminar(dynamic foto) {
    if (foto["created_at"] == null) return false;

    try {
      // 1. Convertimos la fecha del servidor (Laravel suele enviar UTC)
      DateTime fechaFoto = DateTime.parse(foto["created_at"]).toUtc();

      // 2. Obtenemos la hora actual en UTC para una comparación exacta
      DateTime ahoraUtc = DateTime.now().toUtc();

      // 3. Calculamos la diferencia de tiempo
      Duration diferencia = ahoraUtc.difference(fechaFoto);

      // Solo permitimos eliminar si han pasado menos de 5 minutos
      return diferencia.inMinutes >= 0 && diferencia.inMinutes < 5;
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
          const SnackBar(content: Text("No se pudo eliminar la foto")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión al eliminar")),
      );
    }
  }

  void confirmarEliminacion(int id, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text(
            "¿Seguro que quieres borrar esta foto? Solo tienes 5 minutos desde que la tomaste."),
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
        title: const Text("Fotos tomadas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(
                () {}), // Refresca para actualizar el tiempo de los botones
          )
        ],
      ),
      body: fotos.isEmpty
          ? const Center(child: Text("No hay fotos registradas"))
          : GridView.builder(
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
                final String imageUrl =
                    "${PhotoGalleryScreen.baseImageUrl}$ruta";
                final bool mostrarBorrar = _puedeEliminar(fotoData);

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
                    if (mostrarBorrar)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(180),
                            shape: BoxShape.circle,
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
