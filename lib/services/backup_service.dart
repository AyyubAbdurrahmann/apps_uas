import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';
import 'export_service.dart';

class BackupService {
  // static final FirebaseStorage _storage = FirebaseStorage.instance;
  // static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Anonymous login for cloud backup
  static Future<void> signInAnonymously() async {
    // if (_auth.currentUser == null) {
    //   await _auth.signInAnonymously();
    // }
  }

  static Future<String?> backupToCloud(List<Expense> expenses) async {
    // Cloud backup not available on this platform
    return null;
  }

  static Future<List<String>> listBackups() async {
    // Cloud backup not available on this platform
    return [];
  }

  static Future<String?> downloadBackup(String fileName) async {
    // Cloud backup not available on this platform
    return null;
  }

  static Future<bool> deleteBackup(String fileName) async {
    // Cloud backup not available on this platform
    return false;
  }
}
