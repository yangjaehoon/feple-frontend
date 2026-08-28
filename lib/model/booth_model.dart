import 'json_reader.dart';

/// 부스 모델
class BoothModel {
  final int id;
  final String name;
  final String boothType;
  final String boothTypeName;
  final double latitude;
  final double longitude;
  final String? description;
  final String? imageUrl;

  const BoothModel({
    required this.id,
    required this.name,
    required this.boothType,
    required this.boothTypeName,
    required this.latitude,
    required this.longitude,
    this.description,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'boothType': boothType,
        'boothTypeName': boothTypeName,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'imageUrl': imageUrl,
      };

  factory BoothModel.fromJson(Map<String, dynamic> j) => BoothModel(
        id: j.integer('id'),
        name: j.str('name'),
        boothType: j.str('boothType'),
        boothTypeName: j.str('boothTypeName'),
        latitude: j.dbl('latitude'),
        longitude: j.dbl('longitude'),
        description: j.strOrNull('description'),
        imageUrl: j.strOrNull('imageUrl'),
      );
}
