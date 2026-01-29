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
  final logger = Logger(); // Inicializa Logger
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
        if (data['estatus'] == true) {
          setState(() {
            fotosUrls = List<String>.from(data['datos'].map((item) =>
                'https://sistema.jusaimpulsemkt.com/storage/${item['foto']}'));
            cargando = false;
          });
        } else {
          setState(() {
            cargando = false;
          });
          logger.w('API respondió con estatus false');
        }
      } else {
        setState(() {
          cargando = false;
        });
        logger.e('Error en response.statusCode: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      setState(() {
        cargando = false;
      });
      // Logger con argumentos nombrados
      logger.e('Error al cargar fotos', error: e, stackTrace: stacktrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fotos Asignación ${widget.idAsignacion}')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : fotosUrls.isEmpty
              ? const Center(child: Text('No hay fotos disponibles'))
              : Column(
                  children: [
                    // Imagen principal
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          fotosUrls[fotoSeleccionada],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Text('No se pudo cargar la imagen')),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Miniaturas
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
                                    width: 2),
                              ),
                              child: Image.network(
                                fotosUrls[index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
    );
  }
}
