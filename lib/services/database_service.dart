// database_service.dart
class DatabaseService {
  /// Returns dummy user data after a short delay.
  static Future<Map<String, dynamic>> getUserData() async {
    await Future.delayed(Duration(seconds: 1));
    return {
      "name": "John Doe",
      "email": "johndoe@example.com",
      // Leave empty to use a default image.
      "photoUrl": ""
    };
  }

  /// Returns simulated prescription data.
  static Future<Map<String, dynamic>?> getLatestPrescription() async {
    await Future.delayed(Duration(seconds: 1));
    return {
      "medicine": "Paracetamol",
      "dosage": "500mg",
      "uploadedAt": DateTime.now().toIso8601String()
    };
  }
}
