import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../../../auth/token_store.dart';
import '../../../../../../config.dart';
import 'dto_artist_photo_response.dart';

class ImgCollectionWidget extends StatefulWidget {
  const ImgCollectionWidget(
      {super.key,
        required this.artistId,
        required this.artistName
      });

  final int artistId;
  final String artistName;

  @override
  State<ImgCollectionWidget> createState() => ImgCollectionWidgetState();
}

class ImgCollectionWidgetState extends State<ImgCollectionWidget> {
  List<ArtistPhotoResponse> photos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  void refresh() {
    loadPhotos();
  }


  Future<void> loadPhotos() async {
    try {
      setState(() => isLoading = true);

      final token = await TokenStore.readAccessToken();
      final dio = Dio();

      final res = await dio.get(
        '$baseUrl/artists/${widget.artistId}/photos',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200) {
        setState(() {
          photos = (res.data as List)
              .map((e) => ArtistPhotoResponse.fromJson(e))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('load photos error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (photos.isEmpty) {
      return const Center(child: Text('아직 등록된 사진이 없습니다.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return Container(
          height: 160,
          margin: EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            photo.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                child: Text("리뷰"),
                              ),
                              const PopupMenuItem(
                                child: Text("삭제"),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          photo.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
