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
    // Ordenar por ID descendente para que las recientes aparezcan primero
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
  }

  /// Procesa la fecha en formato DD/MM/YYYY y determina si es de hoy
  bool _esFotoDeHoy(dynamic foto) {
    final String? fechaRaw =
        foto["created_at"] ?? foto["fecha"] ?? foto["updated_at"];

    if (fechaRaw == null) return false;

    try {
      // Separamos DD/MM/YYYY
      List<String> partes = fechaRaw.split('/');
      if (partes.length == 3) {
        // Reconstruimos a formato ISO (YYYY-MM-DD) para que DateTime lo entienda
        String fechaIso =
            "${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}";
        DateTime fechaFoto = DateTime.parse(fechaIso);
        DateTime ahora = DateTime.now();

        // Comparamos solo año, mes y día
        return fechaFoto.year == ahora.year &&
            fechaFoto.month == ahora.month &&
            fechaFoto.day == ahora.day;
      }
      return false;
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
          const SnackBar(
              content: Text("Error al eliminar la foto del servidor")),
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
        content:
            const Text("¿Seguro que quieres borrar esta foto definitivamente?"),
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
        title: const Text("Fotos de la visita"),
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
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85, // Ajuste para dar espacio al texto inferior
        ),
        itemCount: fotos.length,
        itemBuilder: (context, index) {
          final fotoData = fotos[index];
          final String ruta = fotoData["foto"] ?? "";
          final int id = fotoData["id"] ?? 0;
          final String fechaMostrar =
              fotoData["created_at"] ?? fotoData["fecha"] ?? "";
          final String imageUrl = "${PhotoGalleryScreen.baseImageUrl}$ruta";

          final bool permiteEliminar = _esFotoDeHoy(fotoData);

          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                      if (permiteEliminar)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => confirmarEliminacion(id, index),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 4)
                                ],
                              ),
                              child: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    fechaMostrar,
                    style: TextStyle(
                      fontSize: 12,
                      color: permiteEliminar
                          ? Colors.green[700]
                          : Colors.grey[600],
                      fontWeight:
                          permiteEliminar ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
