import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// `Firebase.initializeApp()`이 실제 플랫폼 채널 없이 완료되도록 하는 최소 fake.
class FakeFirebasePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebasePlatform {
  final List<FirebaseAppPlatform> _apps = [];

  @override
  List<FirebaseAppPlatform> get apps => _apps;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final app = FirebaseAppPlatform(
      name ?? defaultFirebaseAppName,
      options ??
          const FirebaseOptions(
            apiKey: 'fake-api-key',
            appId: 'fake-app-id',
            messagingSenderId: 'fake-sender-id',
            projectId: 'fake-project-id',
          ),
    );
    _apps.add(app);
    return app;
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _apps.firstWhere((a) => a.name == name);
  }
}

/// 테스트에서 `Firebase.initializeApp()`을 실제 플랫폼 채널 없이 1회 초기화.
Future<void> setupFakeFirebaseCore() async {
  Firebase.delegatePackingProperty = FakeFirebasePlatform();
  await Firebase.initializeApp();
}

/// 이메일/닉네임 등 로그인 흐름에서 필요한 최소 사용자 정보를 담은 fake.
class FakeUserPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UserPlatform {
  FakeUserPlatform({
    String uid = 'uid-1',
    bool isEmailVerified = true,
    this.deleteThrows = false,
  })  : _uid = uid,
        _isEmailVerified = isEmailVerified;

  final String _uid;
  bool _isEmailVerified;
  bool deleteThrows;
  int sendEmailVerificationCallCount = 0;
  int reloadCallCount = 0;
  Map<String, String?>? lastUpdatedProfile;

  @override
  String get uid => _uid;

  @override
  bool get isEmailVerified => _isEmailVerified;

  void setEmailVerified(bool value) => _isEmailVerified = value;

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {
    sendEmailVerificationCallCount++;
  }

  @override
  Future<String?> getIdToken(bool forceRefresh) async => 'fake-id-token';

  bool updateProfileThrows = false;

  @override
  Future<void> updateProfile(Map<String, String?> profile) async {
    if (updateProfileThrows) throw Exception('updateProfile failed');
    lastUpdatedProfile = profile;
  }

  @override
  Future<void> delete() async {
    if (deleteThrows) throw Exception('delete failed');
  }

  @override
  Future<void> reload() async {
    reloadCallCount++;
  }
}

class FakeUserCredentialPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UserCredentialPlatform {
  FakeUserCredentialPlatform(this._user);

  final UserPlatform? _user;

  @override
  UserPlatform? get user => _user;
}

/// `FirebaseAuth.instance`가 실제 플랫폼 채널 없이 동작하도록 하는 fake.
/// 필요한 메서드만 오버라이드하며, 그 외 호출은 [Fake]의 기본 동작(예외)을 따른다.
class FakeFirebaseAuthPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebaseAuthPlatform {
  UserPlatform? _currentUser;
  int signOutCallCount = 0;
  String? lastPasswordResetEmail;

  Future<UserCredentialPlatform> Function(String email, String password)?
      onSignInWithEmailAndPassword;
  Future<UserCredentialPlatform> Function(String email, String password)?
      onCreateUserWithEmailAndPassword;
  Future<UserCredentialPlatform> Function(AuthCredential credential)?
      onSignInWithCredential;

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) =>
      this;

  @override
  UserPlatform? get currentUser => _currentUser;

  @override
  set currentUser(UserPlatform? userPlatform) => _currentUser = userPlatform;

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await onSignInWithEmailAndPassword!(email, password);
    _currentUser = credential.user;
    return credential;
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await onCreateUserWithEmailAndPassword!(email, password);
    _currentUser = credential.user;
    return credential;
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(AuthCredential credential) async {
    final result = await onSignInWithCredential!(credential);
    _currentUser = result.user;
    return result;
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    _currentUser = null;
  }
}
