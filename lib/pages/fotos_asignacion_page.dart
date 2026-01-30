import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// ---------------- MODELO INTERNO ----------------
class FotoItem {
  final int id; // ID real de la foto (ej: 55)
  final String url; // URL completa
  bool seleccionada;

  FotoItem({
    required this.id,
    required this.url,
    this.seleccionada = false,
  });
}

/// ---------------- PANTALLA ----------------
class FotosAsignacionPage extends StatefulWidget {
  final int idAsignacion;

  const FotosAsignacionPage({Key? key, required this.idAsignacion})
      : super(key: key);

  @override
  State<FotosAsignacionPage> createState() => _FotosAsignacionPageState();
}

class _FotosAsignacionPageState extends State<FotosAsignacionPage> {
  final Logger logger = Logger();

  static const String baseImageUrl =
      "https://sistema.jusaimpulsemkt.com/storage/";

  List<FotoItem> fotos = [];
  bool cargando = true;
  bool eliminando = false;
  int fotoSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    _cargarFotos();
  }

  /// ---------------- CARGAR FOTOS ----------------
  Future<void> _cargarFotos() async {
    final url =
        "https://sistema.jusaimpulsemkt.com/api/fotos-asignacion-app/${widget.idAsignacion}";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["estatus"] == true && data["datos"] != null) {
          fotos = List<FotoItem>.from(
            data["datos"].map((item) {
              return FotoItem(
                id: item["id"], // 👈 ID DE LA FOTO
                url: "$baseImageUrl${item["foto"]}",
              );
            }),
          );
        }
      }
    } catch (e, stack) {
      logger.e("Error cargando fotos", error: e, stackTrace: stack);
    }

    cargando = false;
    if (mounted) setState(() {});
  }

  /// ---------------- ELIMINAR FOTOS ----------------
  Future<void> _eliminarSeleccionadas() async {
    final seleccionadas = fotos.where((f) => f.seleccionada).toList();

    if (seleccionadas.isEmpty) return;

    setState(() => eliminando = true);

    try {
      for (final foto in seleccionadas) {
        final response = await http.delete(
          Uri.parse(
              "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/${foto.id}"),
          headers: {"Accept": "application/json"},
        );

        if (response.statusCode != 200) {
          logger.w("No se pudo eliminar foto ID ${foto.id}");
        }
      }

      // Eliminar de la UI
      fotos.removeWhere((f) => f.seleccionada);
      fotoSeleccionada = 0;
    } catch (e, stack) {
      logger.e("Error eliminando fotos", error: e, stackTrace: stack);
    }

    eliminando = false;
    if (mounted) setState(() {});
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fotos Asignación ${widget.idAsignacion}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Eliminar seleccionadas",
            onPressed: eliminando ? null : _eliminarSeleccionadas,
          )
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : fotos.isEmpty
              ? const Center(child: Text("No hay fotos disponibles"))
              : Column(
                  children: [
                    // ---------- IMAGEN PRINCIPAL ----------
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.network(
                          fotos[fotoSeleccionada].url,
                          key: ValueKey(fotos[fotoSeleccionada].url),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Text("No se pudo cargar")),
                        ),
                      ),
                    ),

                    // ---------- MINIATURAS + CHECKLIST ----------
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotos.length,
                        itemBuilder: (context, index) {
                          final foto = fotos[index];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                fotoSeleccionada = index;
                              });
                            },
                            child: Column(
                              children: [
                                Checkbox(
                                  value: foto.seleccionada,
                                  onChanged: (v) {
                                    setState(() {
                                      foto.seleccionada = v ?? false;
                                    });
                                  },
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: fotoSeleccionada == index
                                          ? Colors.blue
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: Image.network(
                                    foto.url,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    if (eliminando)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
    );
  }
}
