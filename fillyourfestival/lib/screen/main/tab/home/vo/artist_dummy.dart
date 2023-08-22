import 'package:fast_app_base/screen/main/tab/home/vo/vo_artist.dart';

final hanyohan = Artist("한요한", "assets/image/artist/hanyohan.jpg");
final changmo = Artist("창모", "assets/image/artist/changmo.jpg");
final ashisland = Artist("애쉬아일랜드", "assets/image/artist/ashisland.jpg");
final kimseungmin = Artist("김승민", "assets/image/artist/kimseungmin.jpg");
final leellamrz = Artist("릴러말즈", "assets/image/artist/leellamarz.jpg");
final loco = Artist("로꼬", "assets/image/artist/loco.jpg");
final swings = Artist("스윙스", "assets/image/artist/swings.jpg");

void main(){
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
];