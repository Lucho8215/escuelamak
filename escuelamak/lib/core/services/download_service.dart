// ============================================================
// DOWNLOAD SERVICE — Servicio para descargar archivos
// ============================================================
// Maneja la descarga de PDFs y otros archivos desde URLs.
// Utiliza path_provider para obtener directorios de almacenamiento.
// ============================================================

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DownloadService {
  // Descarga un archivo desde una URL y lo guarda en el directorio de documentos
  static Future<String?> downloadFile(String url, String fileName) async {
    try {
      // Obtener el directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);

      // Verificar si el archivo ya existe
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        return filePath;
      }

      // Descargar el archivo
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Guardar el archivo
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Obtiene la ruta del directorio de descargas
  static Future<String> getDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Verifica si un archivo ya existe localmente
  static Future<bool> fileExists(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Obtiene la ruta local de un archivo si existe
  static Future<String?> getLocalPath(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
