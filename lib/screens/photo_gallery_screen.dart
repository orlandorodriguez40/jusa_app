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
    // Ordenar por ID descendente (más nueva arriba)
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
  }

  // 🕵️ ESCÁNER DE TIEMPO MEJORADO
  String _analizarTiempo(dynamic foto) {
    // Intentamos detectar el nombre de la llave que trae la fecha
    final String? fechaRaw = foto["created_at"] ??
        foto["fecha"] ??
        foto["timestamp"] ??
        foto["updated_at"];

    if (fechaRaw == null) {
      // Si llegamos aquí, es que el JSON no tiene ninguna de esas llaves
      return "Llaves: ${foto.keys.toString()}";
    }

    try {
      DateTime fechaFoto = DateTime.parse(fechaRaw).toUtc();
      DateTime ahoraUtc = DateTime.now().toUtc();
      int diferencia = ahoraUtc.difference(fechaFoto).inSeconds;
      return "$diferencia"; // Retorna los segundos como String
    } catch (e) {
      return "Formato: $fechaRaw"; // Si la fecha tiene un formato raro
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
        title: const Text("Galería (Diagnóstico)"),
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
          mainAxisSpacing: 35, // Espacio para el debug
        ),
        itemCount: fotos.length,
        itemBuilder: (context, index) {
          final fotoData = fotos[index];
          final String ruta = fotoData["foto"] ?? "";
          final int id = fotoData["id"] ?? 0;
          final String imageUrl = "${PhotoGalleryScreen.baseImageUrl}$ruta";

          // Usamos el analizador para obtener el mensaje o los segundos
          final String resultadoDebug = _analizarTiempo(fotoData);

          // Intentamos convertir a número para la regla de los 5 min
          final int? segundos = int.tryParse(resultadoDebug);

          // REGLA: Mostrar botón solo si detectamos segundos y es menor a 5 min
          // He ampliado el margen a 1 hora (3600) solo para ver si aparece con desfase
          final bool mostrarBoton =
              segundos != null && segundos < 300 && segundos > -3600;

          return Column(
            children: [
              Expanded(
                child: Stack(
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
                    // Forzamos visibilidad si es una prueba, o usamos mostrarBoton
                    if (mostrarBoton || segundos == null)
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
                ),
              ),
              const SizedBox(height: 4),
              // TEXTO DE DIAGNÓSTICO
              Text(
                segundos != null ? "$segundos seg" : resultadoDebug,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (segundos != null && segundos < 300)
                      ? Colors.green
                      : Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
