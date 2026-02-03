import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FotoItem {
  final int id;
  final String url;

  FotoItem({
    required this.id,
    required this.url,
  });
}

class FotosAsignacionPage extends StatefulWidget {
  final List<FotoItem> fotos;

  const FotosAsignacionPage({
    super.key,
    required this.fotos,
  });

  @override
  State<FotosAsignacionPage> createState() => _FotosAsignacionPageState();
}

class _FotosAsignacionPageState extends State<FotosAsignacionPage> {
  late List<FotoItem> _fotos;

  @override
  void initState() {
    super.initState();
    _fotos = List.from(widget.fotos);
  }

  Future<void> _eliminarFoto(FotoItem foto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Eliminar foto"),
        content: const Text("¿Deseas eliminar esta foto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final response = await http.delete(
      Uri.parse(
        "https://sistema.jusaimpulsemkt.com/api/eliminar-foto-app/${foto.id}",
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        _fotos.remove(foto);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al eliminar la foto"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fotos"),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _fotos.length,
        itemBuilder: (context, index) {
          final foto = _fotos[index];

          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    foto.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
              ),

              /// 🧺 BOTÓN ELIMINAR
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => _eliminarFoto(foto),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 20,
                    ),
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
//fin
