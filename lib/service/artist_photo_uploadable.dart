import 'package:feple/model/photo_upload_draft.dart';

abstract class ArtistPhotoUploadable {
  Future<void> uploadPhoto(PhotoUploadDraft draft);
}
