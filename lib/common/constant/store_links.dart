/// 앱 다운로드 링크.
/// iOS는 아직 미출시라 Play스토어 URL 하나로 통일한다. App Store 출시 후에는
/// `Platform.isIOS` 분기로 `https://apps.apple.com/app/id<APP_STORE_ID>` 를 추가할 것.
const String kAppDownloadUrl =
    'https://play.google.com/store/apps/details?id=com.dobino.feple';

/// 고객센터(카카오톡 오픈채팅).
const String kCustomerServiceUrl = 'https://open.kakao.com/o/guLhbJki';

/// 개인정보처리방침.
const String kPrivacyPolicyUrl =
    'https://yangjae.notion.site/feple-privacy?source=copy_link';

/// 이용약관. 현재 노션 문서 하나가 이용약관과 개인정보처리방침을 함께 담고 있어
/// [kPrivacyPolicyUrl]과 동일하다. 별도 문서로 분리되면 이 값만 교체하면 된다.
const String kTermsOfServiceUrl = kPrivacyPolicyUrl;
