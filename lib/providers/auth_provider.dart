import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AuthProvider with ChangeNotifier {
  late FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _firebaseInitialized = false;

  AuthProvider() {
    // Only initialize Firebase if not on Windows
    if (!Platform.isWindows) {
      _auth = FirebaseAuth.instance;
      _firebaseInitialized = true;
    }
  }

  User? get currentUser => _firebaseInitialized ? _auth.currentUser : null;
  bool get isSignedIn => currentUser != null;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      if (_firebaseInitialized) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      }
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    try {
      if (_firebaseInitialized) {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await userCredential.user!.updateDisplayName(name);
      }
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        if (_firebaseInitialized) {
          GoogleAuthProvider googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          
          await _auth.signInWithPopup(googleProvider);
        }
      } else {
        // For mobile and desktop, use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        if (_firebaseInitialized) {
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await _auth.signInWithCredential(credential);
        }
      }
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    if (_firebaseInitialized) {
      await _auth.signOut();
    }
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    notifyListeners();
  }
}