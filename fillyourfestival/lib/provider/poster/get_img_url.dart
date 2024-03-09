
import 'package:firebase_storage/firebase_storage.dart';

Future<String> GetImgUrl( imagePath) async {
  try {
    // Create a reference with the provided file path
    Reference ref = FirebaseStorage.instance.ref().child(imagePath);

    // Get the download URL for the image
    String downloadURL = await ref.getDownloadURL();

    return downloadURL;
  } catch (e) {
    print('Error downloading image: $e');
    // Handle the error or return a default URL
    return ''; // You can return a default image URL or handle the error as needed
  }
}