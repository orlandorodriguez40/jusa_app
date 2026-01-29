// import 'dart:io';
import 'package:flutter/material.dart';

class PhotoGalleryScreen extends StatelessWidget {
  final List<dynamic> fotosServidor;
  const PhotoGalleryScreen({super.key, required this.fotosServidor});

  @override
  Widget build(BuildContext context) {
    if (fotosServidor.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Fotos tomadas")),
        body: const Center(
          child: Text(
            "No hay fotos disponibles",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

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
          String? fotoPath = fotosServidor[index]["foto"];

          // Para Windows: usa placeholder si la URL no existe o falla
          final String imageUrl = (fotoPath != null && fotoPath.isNotEmpty)
              ? "https://sistema.jusaimpulsemkt.com/$fotoPath"
              : "https://via.placeholder.com/150";

          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Si falla la carga de la imagen, mostrar placeholder
              return Image.network(
                "https://via.placeholder.com/150",
                fit: BoxFit.cover,
              );
            },
          );
        },
      ),
    );
  }
}
// Fin
