import 'package:get_it/get_it.dart';

import 'service/artist_follow_service.dart';
import 'service/artist_photo_service.dart';
import 'service/artist_schedule_service.dart';
import 'service/artist_service.dart';
import 'service/auth_service.dart';
import 'service/certification_service.dart';
import 'service/comment_service.dart';
import 'service/fcm_service.dart';
import 'service/festival_detail_service.dart';
import 'service/festival_interaction_service.dart';
import 'service/festival_service.dart';
import 'service/notification_preference_service.dart';
import 'service/notification_service.dart';
import 'service/post_service.dart';
import 'service/report_service.dart';
import 'service/scrap_service.dart';
import 'service/search_service.dart';
import 'service/artist_suggestion_service.dart';
import 'service/song_request_service.dart';
import 'service/song_service.dart';
import 'service/user_activity_service.dart';
import 'service/user_service.dart';

final sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<AuthService>(() => AuthService.instance);
  sl.registerLazySingleton<FcmService>(() => FcmService.instance);

  sl.registerLazySingleton<ArtistFollowService>(() => ArtistFollowService());
  sl.registerLazySingleton<ArtistSuggestionService>(() => ArtistSuggestionService());
  sl.registerLazySingleton<ArtistPhotoService>(() => ArtistPhotoService());
  sl.registerLazySingleton<ArtistScheduleService>(() => ArtistScheduleService());
  sl.registerLazySingleton<ArtistService>(() => ArtistService());
  sl.registerLazySingleton<CertificationService>(() => CertificationService());
  sl.registerLazySingleton<CommentService>(() => CommentService());
  sl.registerLazySingleton<FestivalService>(() => FestivalService());
  sl.registerLazySingleton<FestivalDetailService>(() => FestivalDetailService());
  sl.registerLazySingleton<FestivalInteractionService>(() => FestivalInteractionService());
  sl.registerLazySingleton<NotificationPreferenceService>(() => NotificationPreferenceService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<PostService>(() => PostService());
  sl.registerLazySingleton<ReportService>(() => ReportService());
  sl.registerLazySingleton<ScrapService>(() => ScrapService());
  sl.registerLazySingleton<SearchService>(() => SearchService());
  sl.registerLazySingleton<SongRequestService>(() => SongRequestService());
  sl.registerLazySingleton<SongService>(() => SongService());
  sl.registerLazySingleton<UserActivityService>(() => UserActivityService());
  sl.registerLazySingleton<UserService>(() => UserService());
}
