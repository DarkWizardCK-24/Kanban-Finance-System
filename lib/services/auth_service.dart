import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/id_generator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = await IdGenerator.generateUserId();
    final now = DateTime.now();

    final user = UserModel(
      id: userId,
      uid: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      age: UserModel.calculateAge(dateOfBirth),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(user.toMap());

    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    return UserModel.fromMap(doc.data()!);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toMap());
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
