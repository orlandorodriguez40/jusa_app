import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class FotosAsignacionPage extends StatefulWidget {
  final int idAsignacion;

  const FotosAsignacionPage({Key? key, required this.idAsignacion})
      : super(key: key);

  @override
  State<FotosAsignacionPage> createState() => _FotosAsignacionPageState();
}

class _FotosAsignacionPageState extends State<FotosAsignacionPage> {
  final logger = Logger();

  static const String baseImageUrl =
      "https://sistema.jusaimpulsemkt.com/storage/";

  List<String> fotosUrls = [];
  bool cargando = true;
  int fotoSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    _cargarFotos();
  }

  Future<void> _cargarFotos() async {
    final url =
        'https://sistema.jusaimpulsemkt.com/api/fotos-asignacion-app/${widget.idAsignacion}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['estatus'] == true && data['datos'] != null) {
          setState(() {
            fotosUrls = List<String>.from(
              data['datos'].map((item) {
                String ruta = item['foto'].toString().trim();
                final urlFinal = "$baseImageUrl$ruta";
                logger.i("URL IMAGEN => $urlFinal");
                return urlFinal;
              }),
            );
            cargando = false;
          });
        } else {
          cargando = false;
        }
      } else {
        cargando = false;
        logger.e("StatusCode: ${response.statusCode}");
      }
    } catch (e, stack) {
      cargando = false;
      logger.e("Error cargando fotos", error: e, stackTrace: stack);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fotos Asignación ${widget.idAsignacion}')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : fotosUrls.isEmpty
              ? const Center(child: Text("No hay fotos disponibles"))
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.network(
                          fotosUrls[fotoSeleccionada],
                          key: ValueKey(fotosUrls[fotoSeleccionada]),
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text("No se pudo cargar la imagen"),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotosUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                fotoSeleccionada = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: fotoSeleccionada == index
                                      ? Colors.blue
                                      : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: Image.network(
                                fotosUrls[index],
                                key: ValueKey(fotosUrls[index]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
