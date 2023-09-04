import 'package:fast_app_base/screen/main/tab/home/vo/vo_artist.dart';

final hanyohan = Artist(
  name: "한요한",
  faceImagePath: "assets/image/artist/hanyohan.jpg",
  fanCount: 5000,
);
final changmo = Artist(
  name: "창모",
  faceImagePath: "assets/image/artist/changmo.jpg",
);
final ashisland = Artist(
  name: "애쉬아일랜드",
  faceImagePath: "assets/image/artist/ashisland.jpg",
);
final kimseungmin = Artist(
  name: "김승민",
  faceImagePath: "assets/image/artist/kimseungmin.jpg",
);
final leellamrz = Artist(
  name: "릴러말즈",
  faceImagePath: "assets/image/artist/leellamarz.jpg",
);
final loco = Artist(
  name: "로꼬",
  faceImagePath: "assets/image/artist/loco.jpg",
);
final swings = Artist(
  name: "스윙스",
  faceImagePath: "assets/image/artist/swings.jpg",
);
final ph1 = Artist(
  name: "PH-1",
  faceImagePath: "assets/image/artist/swings.jpg",
);
final beo = Artist(
  name: "비오",
  faceImagePath: "assets/image/artist/swings.jpg",
);
final justhis = Artist(
  name: "저스디스",
  faceImagePath: "assets/image/artist/swings.jpg",
);
final chin = Artist(
  name: "친",
  faceImagePath: "assets/image/artist/swings.jpg",
);
final jaypark = Artist(
  name: "박재범",
  faceImagePath: "assets/image/artist/swings.jpg",
);
final bignaughty = Artist(
  name: "빅나티",
  faceImagePath: "assets/image/artist/swings.jpg",
);

void main() {
  print(Artists[1].faceImagePath);
}

final Artists = [
  hanyohan,
  changmo,
  ashisland,
  kimseungmin,
  leellamrz,
  loco,
  swings,
  ph1,
  beo,
  justhis,
  chin,
  jaypark,
  bignaughty,
];
