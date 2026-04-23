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

  factory BoothModel.fromJson(Map<String, dynamic> j) => BoothModel(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        boothType: j['boothType'] as String,
        boothTypeName: j['boothTypeName'] as String,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        description: j['description'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );
}
