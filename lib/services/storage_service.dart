import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile(String filePath, {required String fileName}) async {
    try {
      Reference ref = _storage.ref().child("uploads/$fileName");
      UploadTask uploadTask = ref.putFile(Uri.parse(filePath).toFilePath() as dynamic);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      // Optionally, save the URL to Firestore under a user subcollection.
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
}
