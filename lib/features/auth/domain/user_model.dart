class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'parent'
  final String school;
  final bool hasSubmittedFees; // New field

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.school,
    required this.hasSubmittedFees, // Include hasSubmittedFees in constructor
  });
}
