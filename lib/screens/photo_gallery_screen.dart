import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PhotoGalleryScreen extends StatefulWidget {
  final List<dynamic> fotosServidor;
  final dynamic asignacion; // Recibido del dashboard
  final int nivelId; // Recibido del dashboard

  static const String baseImageUrl =
      "https://sistema.jusaimpulsemkt.com/storage/";

  const PhotoGalleryScreen({
    super.key,
    required this.fotosServidor,
    required this.asignacion,
    required this.nivelId,
  });

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
    // Solo el nivel 3 (chofer) puede eliminar sus fotos recientes
    if (widget.nivelId != 3 || _cargandoTiempos) {
      return false;
    }

    String id = foto['id'].toString();
    int? registro = _tiemposFotos[id];
    if (registro == null) {
      return false;
    }

    final String? fechaRaw =
        foto["created_at"] ?? foto["fecha"] ?? foto["updated_at"];
    if (fechaRaw == null) {
      return false;
    }

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
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/$id");
      final response = await http.delete(url);

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("timestamp_foto_$id");
        setState(() => fotos.removeAt(index));
        messenger.showSnackBar(
            const SnackBar(content: Text("Foto eliminada correctamente")));
      }
    } catch (e) {
      if (mounted) {
        messenger
            .showSnackBar(const SnackBar(content: Text("Error de conexión")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esAuditoria = (widget.nivelId == 2 || widget.nivelId == 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Visita", style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF424949),
      ),
      body: _cargandoTiempos
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (esAuditoria) ...[
                  SliverToBoxAdapter(child: _buildHeaderAuditoria()),
                ],
                if (fotos.isEmpty) ...[
                  SliverFillRemaining(child: _buildEmptyState()),
                ] else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: _buildGridSliver(),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildHeaderAuditoria() {
    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          color: Colors.grey[300],
          child: Stack(
            children: [
              const Center(
                  child:
                      Icon(Icons.map_outlined, size: 60, color: Colors.grey)),
              Positioned(
                bottom: 15,
                left: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    "📍 ${widget.asignacion["plaza"]}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("DETALLES DEL REPORTE",
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_city,
                      color: Colors.indigo, size: 20),
                  const SizedBox(width: 8),
                  Text("${widget.asignacion["ciudad"]}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text("Fecha: ${widget.asignacion["fecha"]}"),
                  const SizedBox(width: 15),
                  const Icon(Icons.access_time, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text("Hora: ${widget.asignacion["hora"] ?? 'N/A'}"),
                ],
              ),
            ],
          ),
        ),
        const Divider(thickness: 1, height: 1),
      ],
    );
  }

  Widget _buildGridSliver() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
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
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      if (permiteEliminar)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => _confirmarEliminacion(f["id"], index),
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
                    f["created_at"] ?? f["fecha"] ?? "Sin fecha",
                    style: TextStyle(
                        fontSize: 11,
                        color: permiteEliminar ? Colors.green : Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
        childCount: fotos.length,
      ),
    );
  }

  void _confirmarEliminacion(int id, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Deseas borrar esta foto?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("No")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                eliminarFoto(id, index);
              },
              child: const Text("Sí, borrar")),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("NO HAY FOTOS"));
  }
}
