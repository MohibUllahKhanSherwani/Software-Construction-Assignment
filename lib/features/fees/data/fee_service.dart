import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/fee_model.dart';

class FeeService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update fee for a school
  Future<void> setSchoolFee(Fee fee) async {
    await _firestore
        .collection('school_fees')
        .doc(fee.schoolId)
        .set(fee.toMap());
    notifyListeners();
  }

  // Get all school fees (stream)
  Stream<List<Fee>> getAllSchoolFees() {
    return _firestore
        .collection('school_fees')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Fee.fromMap(doc.data())).toList(),
        );
  }

  // Get all school fees (future)
  Future<List<Fee>> getAllFees() async {
    final snapshot = await _firestore.collection('school_fees').get();
    return snapshot.docs.map((doc) => Fee.fromMap(doc.data())).toList();
  }

  // Get fee for a specific school
  Future<Fee?> getSchoolFee(String schoolId) async {
    final doc = await _firestore.collection('school_fees').doc(schoolId).get();
    return doc.exists ? Fee.fromMap(doc.data()!) : null;
  }

  // Submit fee payment and update user status
  Future<void> submitFeePayment({
    required String userId,
    required String schoolId,
    required double amount,
  }) async {
    // Update the fee record
    final feeDoc =
        await _firestore.collection('school_fees').doc(schoolId).get();
    if (feeDoc.exists) {
      final fee = Fee.fromMap(feeDoc.data()!);
      final updatedFee = fee.copyWith(
        isPaid: true,
        paidDate: DateTime.now(),
        userId: userId,
      );
      await _firestore
          .collection('school_fees')
          .doc(schoolId)
          .set(updatedFee.toMap());
    }

    // Update user's hasSubmittedFees status
    await _firestore.collection('users').doc(userId).update({
      'hasSubmittedFees': true,
      'lastFeePayment': FieldValue.serverTimestamp(),
    });
  }
}
