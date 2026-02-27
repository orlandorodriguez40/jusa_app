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
  final Map<String, int> _tiemposFotos = {};
  bool _cargandoTiempos = true;

  @override
  void initState() {
    super.initState();
    fotos = List.from(widget.fotosServidor);
    fotos.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
    _inicializarPersistencia();
  }

  Future<void> _inicializarPersistencia() async {
    final prefs = await SharedPreferences.getInstance();
    final ahora = DateTime.now().millisecondsSinceEpoch;

    for (var foto in fotos) {
      String id = foto['id'].toString();
      String key = "timestamp_foto_$id";
      if (!prefs.containsKey(key)) {
        await prefs.setInt(key, ahora);
      }
      _tiemposFotos[id] = prefs.getInt(key) ?? ahora;
    }

    if (mounted) {
      setState(() => _cargandoTiempos = false);
    }

    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  bool _puedeEliminar(dynamic foto) {
    if (_cargandoTiempos) return false;
    String id = foto['id'].toString();
    int? registro = _tiemposFotos[id];
    if (registro == null) return false;

    final String? fechaRaw =
        foto["created_at"] ?? foto["fecha"] ?? foto["updated_at"];
    if (fechaRaw == null) return false;

    try {
      List<String> partes = fechaRaw.split(RegExp(r'[/-]'));
      if (partes.length == 3) {
        String iso =
            "${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}";
        DateTime fechaServer = DateTime.parse(iso);
        DateTime ahora = DateTime.now();

        if (fechaServer.year != ahora.year ||
            fechaServer.month != ahora.month ||
            fechaServer.day != ahora.day) {
          return false;
        }
        return (ahora.millisecondsSinceEpoch - registro) < 300000;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> eliminarFoto(int id, int index) async {
    // 🛡️ Capturamos el Messenger antes del await para evitar errores de context
    final messenger = ScaffoldMessenger.of(context);

    try {
      final url = Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/$id");
      final response = await http.delete(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("timestamp_foto_$id");

        setState(() => fotos.removeAt(index));

        messenger.showSnackBar(
          const SnackBar(content: Text("Foto eliminada correctamente")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
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
              child: const Text("Cancelar")),
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
        backgroundColor: const Color(0xFF424949),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: _cargandoTiempos
          ? const Center(child: CircularProgressIndicator())
          : fotos.isEmpty
              ? _buildEmptyState()
              : _buildGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined,
              size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "NO HAY FOTOS PARA MOSTRAR",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
          const SizedBox(height: 10),
          const Text("Desliza hacia abajo o usa el botón refrescar",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Regresar"),
          )
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: fotos.length,
      itemBuilder: (context, index) {
        final f = fotos[index];
        final String imageUrl =
            "${PhotoGalleryScreen.baseImageUrl}${f["foto"]}";
        final bool permiteEliminar = _puedeEliminar(f);

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          onTap: () => confirmarEliminacion(f["id"], index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4)
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
                  f["created_at"] ?? f["fecha"] ?? "Sin fecha",
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        permiteEliminar ? Colors.green[800] : Colors.grey[600],
                    fontWeight:
                        permiteEliminar ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
