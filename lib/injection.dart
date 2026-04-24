import 'package:get_it/get_it.dart';

import 'service/artist_follow_service.dart';
import 'service/artist_photo_service.dart';
import 'service/artist_schedule_service.dart';
import 'service/artist_service.dart';
import 'service/auth_service.dart';
import 'service/certification_service.dart';
import 'service/comment_service.dart';
import 'service/fcm_service.dart';
import 'service/festival_service.dart';
import 'service/notification_service.dart';
import 'service/post_service.dart';
import 'service/user_service.dart';

final sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<AuthService>(() => AuthService.instance);
  sl.registerLazySingleton<FcmService>(() => FcmService.instance);

  sl.registerLazySingleton<ArtistFollowService>(() => ArtistFollowService());
  sl.registerLazySingleton<ArtistPhotoService>(() => ArtistPhotoService());
  sl.registerLazySingleton<ArtistScheduleService>(() => ArtistScheduleService());
  sl.registerLazySingleton<ArtistService>(() => ArtistService());
  sl.registerLazySingleton<CertificationService>(() => CertificationService());
  sl.registerLazySingleton<CommentService>(() => CommentService());
  sl.registerLazySingleton<FestivalService>(() => FestivalService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<PostService>(() => PostService());
  sl.registerLazySingleton<UserService>(() => UserService());
}
