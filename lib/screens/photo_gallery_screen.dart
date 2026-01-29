import 'package:flutter/material.dart';

class PhotoGalleryScreen extends StatelessWidget {
  final List<dynamic> fotosServidor;

  static const String baseImageUrl =
      "https://sistema.jusaimpulsemkt.com/storage/";

  const PhotoGalleryScreen({super.key, required this.fotosServidor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fotos tomadas")),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: fotosServidor.length,
        itemBuilder: (context, index) {
          final String ruta = fotosServidor[index]["foto"] ?? "";
          final String imageUrl = "$baseImageUrl$ruta";

          return Image.network(
            imageUrl,
            key: ValueKey(imageUrl),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              size: 40,
            ),
          );
        },
      ),
    );
  }
}
