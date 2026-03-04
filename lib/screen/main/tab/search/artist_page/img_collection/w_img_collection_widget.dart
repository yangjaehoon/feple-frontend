import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'dto_artist_photo_response.dart';

class ImgCollectionWidget extends StatefulWidget {
  const ImgCollectionWidget(
      {super.key, required this.artistId, required this.artistName});

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

  Future<void> toggleLike(int photoId) async {
    try {
      await DioClient.dio.post(
        '/artists/${widget.artistId}/photos/$photoId/like',
      );
      setState(() {
        final photoIndex = photos.indexWhere((p) => p.photoId == photoId);
        if (photoIndex != -1) {
          final photo = photos[photoIndex];
          photos[photoIndex] = ArtistPhotoResponse(
            photoId: photo.photoId,
            url: photo.url,
            uploaderUserId: photo.uploaderUserId,
            createdAt: photo.createdAt,
            title: photo.title,
            description: photo.description,
            likecount:
                photo.isLiked ? photo.likecount - 1 : photo.likecount + 1,
            isLiked: !photo.isLiked,
          );
          // 좋아요 순 재정렬
          photos.sort((a, b) => b.likecount.compareTo(a.likecount));
        }
      });
    } catch (e) {
      debugPrint('toggle like error: $e');
      refresh();
    }
  }

  Future<void> loadPhotos() async {
    try {
      setState(() => isLoading = true);

      final res = await DioClient.dio.get(
        '/artists/${widget.artistId}/photos',
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
    final colors = context.appColors;

    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: CircularProgressIndicator(color: colors.loadingIndicator),
        ),
      );
    }

    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 48, color: colors.textSecondary),
              const SizedBox(height: 12),
              Text(
                '아직 등록된 사진이 없습니다.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final photo = photos[index];
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 이미지 썸네일 + 하트 오버레이
              Stack(
                children: [
                  GestureDetector(
                    onDoubleTap: () {
                      toggleLike(photo.photoId!);
                    },
                    child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      width: 195,
                      height: 195,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 195,
                        height: 195,
                        color: colors.listDivider,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colors.loadingIndicator,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 195,
                        height: 195,
                        color: colors.listDivider,
                        child: Icon(Icons.broken_image_rounded,
                            color: colors.textSecondary),
                      ),
                    ),
                  ),
                  ),
                  // 좋아요 버튼 (왼쪽 아래)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: GestureDetector(
                      onTap: () => toggleLike(photo.photoId!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              photo.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: photo.isLiked
                                  ? AppColors.kawaiiPink
                                  : Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${photo.likecount}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 정보 영역
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        photo.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colors.textTitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // 설명
                      Text(
                        photo.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
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
