import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // Web OAuth Client ID from google-services.json for sha-collect project
  static const String webClientId =
      '1012136392195-0bbej9gvjimmot001csam0uqoes1t3g6.apps.googleusercontent.com';

  final _userStreamController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: webClientId,
              scopes: ['email', 'profile'],
            ) {
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      _firebaseAuth.authStateChanges().listen((user) {
        if (user != null) {
          _currentUser = UserModel(
            uid: user.uid,
            displayName: user.displayName ?? 'Hadi Sha',
            email: user.email ?? '',
            photoUrl: user.photoURL,
          );
        } else if (_currentUser != null && !_currentUser!.uid.startsWith('agent-')) {
          _currentUser = null;
        }
        _userStreamController.add(_currentUser);
      }, onError: (e) {
        debugPrint('Auth state listener note: $e');
      });
    } catch (e) {
      debugPrint('Firebase auth listener init note: $e');
    }
  }

  Stream<UserModel?> get authStateChanges async* {
    yield _currentUser;
    yield* _userStreamController.stream;
  }

  UserModel? get currentUser => _currentUser;

  /// Google Sign In & Sign Up
  Future<UserModel?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (primaryErr) {
        debugPrint('Primary GoogleSignIn error: $primaryErr, trying fallback...');
        final fallbackSignIn = GoogleSignIn(scopes: ['email']);
        googleUser = await fallbackSignIn.signIn();
      }

      if (googleUser == null) {
        // User cancelled the Google sign-in prompt
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        _currentUser = UserModel(
          uid: user.uid,
          displayName: user.displayName ?? googleUser.displayName ?? 'Hadi Sha',
          email: user.email ?? googleUser.email,
          photoUrl: user.photoURL ?? googleUser.photoUrl,
        );
        _userStreamController.add(_currentUser);
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Google Sign-In exception: $e');
      rethrow;
    }
    return null;
  }

  /// Sign in as named executive with Firebase Auth session
  Future<void> signInAsCustomAgent({required String name, required String email}) async {
    try {
      if (_firebaseAuth.currentUser == null) {
        final cred = await _firebaseAuth.signInAnonymously();
        await cred.user?.updateDisplayName(name);
      }
    } catch (e) {
      debugPrint('Anonymous auth note (proceeding with local executive credentials): $e');
    }

    final firebaseUid = _firebaseAuth.currentUser?.uid;
    final agentModel = UserModel.agent(name: name, email: email);
    _currentUser = UserModel(
      uid: firebaseUid ?? agentModel.uid,
      displayName: agentModel.displayName,
      email: agentModel.email,
      photoUrl: null,
      role: agentModel.role,
    );
    _userStreamController.add(_currentUser);
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _currentUser = null;
    _userStreamController.add(null);
  }
}
