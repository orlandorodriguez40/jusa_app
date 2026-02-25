import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  // Usamos final para evitar la advertencia del linter
  final Map<String, int> _tiemposFotos = {};
  bool _cargandoTiempos = true;

  @override
  void initState() {
    super.initState();
    fotos = List.from(widget.fotosServidor);
    // Ordenar: fotos más nuevas primero
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));

    _inicializarPersistencia();
  }

  /// Gestiona el registro de tiempo persistente para cada imagen
  Future<void> _inicializarPersistencia() async {
    final prefs = await SharedPreferences.getInstance();
    final ahora = DateTime.now().millisecondsSinceEpoch;

    for (var foto in fotos) {
      String id = foto['id'].toString();
      String key = "timestamp_foto_$id";

      // Si la app ve la foto por primera vez, guarda el momento exacto
      if (!prefs.containsKey(key)) {
        await prefs.setInt(key, ahora);
      }

      _tiemposFotos[id] = prefs.getInt(key) ?? ahora;
    }

    if (mounted) {
      setState(() {
        _cargandoTiempos = false;
      });
    }

    // Refresca la UI cada 30 segundos para ocultar iconos que expiren
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  /// Determina si una foto cumple las reglas para ser borrada
  bool _puedeEliminar(dynamic foto) {
    if (_cargandoTiempos) return false;

    String id = foto['id'].toString();
    int? timestampRegistro = _tiemposFotos[id];

    if (timestampRegistro == null) return false;

    final String? fechaRaw =
        foto["created_at"] ?? foto["fecha"] ?? foto["updated_at"];
    if (fechaRaw == null) return false;

    try {
      // Normaliza fecha del servidor (24/02/2026 o 24-02-2026)
      List<String> partes = fechaRaw.split(RegExp(r'[/-]'));
      if (partes.length == 3) {
        String fechaIso =
            "${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}";
        DateTime fechaFotoServer = DateTime.parse(fechaIso);
        DateTime ahora = DateTime.now();

        // Regla 1: Debe ser la misma fecha calendario
        bool esMismoDia = fechaFotoServer.year == ahora.year &&
            fechaFotoServer.month == ahora.month &&
            fechaFotoServer.day == ahora.day;

        if (!esMismoDia) return false;

        // Regla 2: Máximo 5 minutos (300,000 milisegundos) desde el registro local
        int diferenciaMilis = ahora.millisecondsSinceEpoch - timestampRegistro;

        return diferenciaMilis < 300000;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> eliminarFoto(int id, int index) async {
    try {
      final url = Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/$id");
      final response = await http.delete(url);

      // Guardia para evitar errores si el usuario cerró la pantalla (Async gap)
      if (!mounted) return;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("timestamp_foto_$id");

        if (!mounted) return;

        setState(() => fotos.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto eliminada correctamente")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error: El servidor rechazó la solicitud")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión al intentar eliminar")),
      );
    }
  }

  void confirmarEliminacion(int id, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text("¿Deseas eliminar esta foto permanentemente?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              eliminarFoto(id, index);
            },
            child:
                const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Galería de Visita"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: _cargandoTiempos
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: fotos.length,
              itemBuilder: (context, index) {
                final fotoData = fotos[index];
                final String imageUrl =
                    "${PhotoGalleryScreen.baseImageUrl}${fotoData["foto"]}";
                final bool permiteEliminar = _puedeEliminar(fotoData);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                            ),
                            if (permiteEliminar)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: GestureDetector(
                                  onTap: () => confirmarEliminacion(
                                      fotoData["id"], index),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4)
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
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          fotoData["created_at"] ??
                              fotoData["fecha"] ??
                              "Sin fecha",
                          style: TextStyle(
                            fontSize: 11,
                            color: permiteEliminar
                                ? Colors.green[800]
                                : Colors.grey[600],
                            fontWeight: permiteEliminar
                                ? FontWeight.bold
                                : FontWeight.normal,
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
