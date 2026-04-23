class Artist {
  final String name;
  final String faceImagePath;
  int fanCount = 0;

  Artist({
    required this.name,
    required this.faceImagePath,
    this.fanCount = 0,
  });
}
