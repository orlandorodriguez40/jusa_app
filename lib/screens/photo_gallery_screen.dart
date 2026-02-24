import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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
  // Esta variable controlará la visibilidad global de los botones de borrar
  bool _permitirBorradoSesion = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fotos = List.from(widget.fotosServidor);
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));

    _iniciarCronometro();
  }

  // Iniciamos el cronómetro de 5 minutos
  void _iniciarCronometro() {
    _timer?.cancel(); // Cancelar cualquier timer previo
    _permitirBorradoSesion = true;

    _timer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _permitirBorradoSesion = false; // Bloqueo total después de 5 min
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Limpiar el timer al salir de la pantalla
    super.dispose();
  }

  bool _esFotoDeHoy(dynamic foto) {
    // Si la sesión de 5 minutos expiró, ya no se puede borrar nada
    if (!_permitirBorradoSesion) return false;

    final String? fechaRaw =
        foto["created_at"] ?? foto["fecha"] ?? foto["updated_at"];
    if (fechaRaw == null) return false;

    try {
      List<String> partes = fechaRaw.split(RegExp(r'[/-]'));
      if (partes.length == 3) {
        String fechaIso =
            "${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}";
        DateTime fechaFoto = DateTime.parse(fechaIso);
        DateTime ahora = DateTime.now();

        return fechaFoto.year == ahora.year &&
            fechaFoto.month == ahora.month &&
            fechaFoto.day == ahora.day;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ... (métodos eliminarFoto y confirmarEliminacion se mantienen iguales)

  Future<void> eliminarFoto(int id, int index) async {
    try {
      final url = Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/$id");
      final response = await http.delete(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => fotos.removeAt(index));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Foto eliminada")));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void confirmarEliminacion(int id, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Deseas borrar esta foto?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              eliminarFoto(id, index);
            },
            child: const Text("Eliminar"),
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
            onPressed: () {
              setState(() {
                _iniciarCronometro(); // Reinicia el tiempo al refrescar
              });
            },
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: fotos.length,
        itemBuilder: (context, index) {
          final fotoData = fotos[index];
          final String imageUrl =
              "${PhotoGalleryScreen.baseImageUrl}${fotoData["foto"]}";
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
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      if (permiteEliminar)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () =>
                                confirmarEliminacion(fotoData["id"], index),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    fotoData["created_at"] ?? fotoData["fecha"] ?? "",
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            permiteEliminar ? Colors.green[700] : Colors.grey,
                        fontWeight: permiteEliminar
                            ? FontWeight.bold
                            : FontWeight.normal),
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
