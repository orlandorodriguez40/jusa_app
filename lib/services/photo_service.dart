import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class PhotoService {
  final Logger logger = Logger();

  /// Obtener fotos de una asignación
  Future<List<dynamic>> fetchPhotos(int asignacionId) async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://sistema.jusaimpulsemkt.com/api/fotos-asignacion-app/$asignacionId"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["datos"] ?? [];
      } else {
        throw Exception("Error al cargar fotos: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("Excepción fetchPhotos: $e");
      rethrow;
    }
  }

  /// Subir foto de una asignación
  Future<void> uploadPhoto(File photoFile, int asignacionId) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("https://sistema.jusaimpulsemkt.com/api/tomar-foto-app"),
      );

      request.fields['asignacion_id'] = asignacionId.toString();
      request.files
          .add(await http.MultipartFile.fromPath('file', photoFile.path));

      logger
          .i("Enviando foto: ${photoFile.path} para asignacion $asignacionId");

      final response = await request.send();

      if (response.statusCode != 200) {
        final respStr = await response.stream.bytesToString();
        throw Exception("Error al enviar la foto: $respStr");
      }
    } catch (e) {
      logger.e("Excepción uploadPhoto: $e");
      rethrow;
    }
  }
}
