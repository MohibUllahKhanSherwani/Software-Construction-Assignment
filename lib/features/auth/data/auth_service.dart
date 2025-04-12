// lib/features/auth/data/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../domain/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;

  UserModel? get user => _user;

  /// Register a new user and save additional data in Firestore.
  Future<UserModel?> register(
    String email,
    String password,
    String role,
    String school,
  ) async {
    try {
      // Create the user using Firebase Auth.
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save extra user data to Firestore in a "users" collection first
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': result.user!.email!,
        'role': role,
        'school': school,
        'hasSubmittedFees': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Then create UserModel instance with the saved data
      _user = UserModel(
        uid: result.user!.uid,
        email: result.user!.email!,
        role: role,
        school: school,
        hasSubmittedFees: false,
      );

      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return null;
    }
  }

  /// Login via Firebase.
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // For this demo, assume emails ending with admin@domain.com are admins.
      String role =
          email.endsWith('admin@domain.com')
              ? AppConstants.adminRole
              : AppConstants.parentRole;

      // Get user document to fetch school
      final userDoc =
          await _firestore.collection('users').doc(result.user!.uid).get();

      // Check if document exists and has school field
      String school = '';
      if (userDoc.exists && userDoc.data()?.containsKey('school') == true) {
        school = userDoc['school'] ?? '';
      }

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      _user = UserModel(
        uid: result.user!.uid,
        email: result.user!.email!,
        role: role,
        school: userData['school'] ?? '',
        hasSubmittedFees: userData['hasSubmittedFees'] ?? false,
      );

      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }

  Future<List<UserModel>> fetchAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final docData = doc.data() as Map<String, dynamic>;
        return UserModel(
          uid: docData['uid'] ?? '',
          email: docData['email'] ?? '',
          role: docData['role'] ?? AppConstants.parentRole,
          school: docData['school'] ?? '',
          hasSubmittedFees: docData['hasSubmittedFees'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  /// Log out the user.
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
