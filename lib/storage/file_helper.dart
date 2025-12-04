import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FileHelper {
  /// Get the app's document directory for storing attachments
  static Future<String> getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    return attachmentsDir.path;
  }

  /// Pick a file from device and copy it to app's attachments directory
  /// Returns the new file path or null if user cancelled or error occurred
  static Future<String?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowCompression: true,
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final sourcePath = result.files.single.path!;
      final fileName = result.files.single.name;

      // Copy file to app's directory with timestamp prefix
      final attachmentsDir = await getAttachmentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '$attachmentsDir/${timestamp}_$fileName';

      final sourceFile = File(sourcePath);
      await sourceFile.copy(newPath);

      return newPath;
    } catch (e) {
      return null;
    }
  }

  /// Delete attachment file from storage
  static Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail - file may have been already deleted
    }
  }

  /// Open/view the attached file using default system app
  static Future<void> openFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await OpenFile.open(path);
      }
    } catch (e) {
      // Silently fail - no suitable app to open file
    }
  }

  /// Extract file name from full path
  static String getFileName(String path) {
    return path.split('/').last;
  }

  /// Get file extension without dot
  static String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  /// Check if file is an image based on extension
  static bool isImage(String path) {
    final ext = getFileExtension(path);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  /// Get file size in human-readable format (B, KB, MB)
  static Future<String> getFileSize(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return 'Unknown';
      }

      final bytes = await file.length();

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
