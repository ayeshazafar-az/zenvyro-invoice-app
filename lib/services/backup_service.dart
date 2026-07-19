// lib/services/backup_service.dart

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

class BackupService {
  // Get the path to your current database file
  // Important: This name must match exactly what is in DBHelper
  static Future<String> get _dbPath async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'zenvyro_invoices_v7.db');
  }

  // --- BACKUP ---
  // Shares the .db file so the user can save it to Google Drive, Email, or Files
  static Future<bool> backupDatabase() async {
    try {
      final path = await _dbPath;
      final dbFile = File(path);

      if (await dbFile.exists()) {
        await Share.shareXFiles(
            [XFile(path)],
            text: 'Zenvyro Invoices Database Backup'
        );
        return true;
      }
      return false;
    } catch (e) {
      print("Backup error: $e");
      return false;
    }
  }

  // --- RESTORE ---
  // Opens file picker, gets the backed-up .db file, and overwrites the current one
  static Future<bool> restoreDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // 'any' is safest for avoiding OS file-type restrictions
      );

      if (result != null && result.files.single.path != null) {
        File sourceFile = File(result.files.single.path!);
        final destinationPath = await _dbPath;

        // 1. Safely close the database connection before overwriting
        await DBHelper.instance.closeAndResetDatabase();

        // 2. Replace the current database file with the selected backup file
        await sourceFile.copy(destinationPath);

        return true; // Success!
      }
      return false; // User canceled picker
    } catch (e) {
      print("Restore error: $e");
      return false;
    }
  }
}