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
    // Ordenar por ID descendente
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
  }

  bool _puedeEliminar(dynamic foto) {
    final String? createdAt = foto["created_at"];
    if (createdAt == null) return false;

    try {
      // Intentamos parsear la fecha.
      // Si el server no envía 'Z' al final, asumimos que es UTC.
      DateTime fechaFoto = DateTime.parse(createdAt).toUtc();
      DateTime ahoraUtc = DateTime.now().toUtc();

      // Calculamos la diferencia absoluta para evitar problemas si el reloj
      // del server está unos segundos adelantado al del celular.
      int diferenciaSegundos = ahoraUtc.difference(fechaFoto).inSeconds;

      debugPrint("--- LOG DE TIEMPO (ID ${foto['id']}) ---");
      debugPrint("Diferencia calculada: $diferenciaSegundos segundos");

      // Permitimos borrar si han pasado menos de 5 minutos (300 seg)
      // Agregamos un margen de error de 60 segundos por desfase de relojes
      return diferenciaSegundos >= -60 && diferenciaSegundos < 300;
    } catch (e) {
      debugPrint("Error parseando fecha: $e");
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
        const SnackBar(content: Text("Error de conexión")),
      );
    }
  }

  void confirmarEliminacion(int id, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar foto"),
        content: const Text(
            "¿Deseas borrar esta imagen? Esta acción no se puede deshacer."),
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
        title: const Text("Galería de Fotos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
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
