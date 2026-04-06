import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/FestivalPreview.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dto_artist_photo_response.dart';

const _dailyOption = FestivalPreview(
    id: -2, title: '일상 사진', location: '', posterUrl: '', startDate: '');
const _snsOption = FestivalPreview(
    id: -3, title: 'SNS 사진', location: '', posterUrl: '', startDate: '');
const _otherOption = FestivalPreview(
    id: -1, title: '기타', location: '', posterUrl: '', startDate: '');

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

  Future<void> _deletePhoto(int photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await DioClient.dio.delete('/artists/${widget.artistId}/photos/$photoId');
      refresh();
    } catch (e) {
      debugPrint('delete error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')),
      );
    }
  }

  void _showEditBottomSheet(ArtistPhotoResponse photo) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditPhotoSheet(
        colors: colors,
        artistId: widget.artistId,
        photo: photo,
        onSave: (newTitle, newDesc) async {
          try {
            await DioClient.dio.patch(
              '/artists/${widget.artistId}/photos/${photo.photoId}',
              data: {'title': newTitle, 'description': newDesc},
            );
            refresh();
          } catch (e) {
            debugPrint('update error: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수정 중 오류가 발생했습니다.')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final currentUserId =
        Provider.of<UserProvider>(context, listen: false).user?.id;

    if (isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: CircularProgressIndicator(color: colors.loadingIndicator),
          ),
        ),
      );
    }

    if (photos.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
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
        ),
      );
    }

    return SliverList.builder(
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isUploader =
            currentUserId != null && photo.uploaderUserId == currentUserId;

        return Padding(
          padding:
              EdgeInsets.only(bottom: index == photos.length - 1 ? 0 : 12.0),
          child: Container(
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
                      onDoubleTap: () => toggleLike(photo.photoId),
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
                        onTap: () => toggleLike(photo.photoId),
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
                  child: SizedBox(
                    height: 195,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 제목 + 더보기 버튼
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  photo.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: colors.textTitle,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isUploader)
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.more_vert_rounded,
                                      color: colors.textSecondary, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditBottomSheet(photo);
                                    } else if (value == 'delete') {
                                      _deletePhoto(photo.photoId);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(Icons.edit_rounded,
                                            size: 16,
                                            color: colors.textSecondary),
                                        const SizedBox(width: 8),
                                        const Text('수정'),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        const Icon(Icons.delete_rounded,
                                            size: 16, color: Colors.red),
                                        const SizedBox(width: 8),
                                        const Text('삭제',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ]),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // 카테고리 chip
                          if (photo.description.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.activate.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                photo.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.activate,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 사진 수정 바텀시트 ──

class _EditPhotoSheet extends StatefulWidget {
  final int artistId;
  final ArtistPhotoResponse photo;
  final AbstractThemeColors colors;
  final void Function(String title, String description) onSave;

  const _EditPhotoSheet({
    required this.artistId,
    required this.photo,
    required this.colors,
    required this.onSave,
  });

  @override
  State<_EditPhotoSheet> createState() => _EditPhotoSheetState();
}

class _EditPhotoSheetState extends State<_EditPhotoSheet> {
  late final TextEditingController _titleCtrl;
  List<FestivalPreview> _festivals = [];
  FestivalPreview? _selectedFestival;
  bool _loadingFestivals = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.photo.title);
    _loadFestivals();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFestivals() async {
    try {
      final resp =
          await DioClient.dio.get('/artists/${widget.artistId}/schedule');
      final list = resp.data as List<dynamic>;
      final festivals = list.map((e) {
        final m = e as Map<String, dynamic>;
        return FestivalPreview(
          id: (m['festivalId'] as num).toInt(),
          title: (m['title'] ?? '') as String,
          location: (m['location'] ?? '') as String,
          posterUrl: (m['posterUrl'] ?? '') as String,
          startDate: m['startDate']?.toString() ?? '',
        );
      }).toList();

      // 현재 description 기준으로 초기 선택값 결정
      final desc = widget.photo.description;
      FestivalPreview? preSelected;
      if (desc == '일상 사진') {
        preSelected = _dailyOption;
      } else if (desc == 'SNS 사진') {
        preSelected = _snsOption;
      } else if (desc.isEmpty) {
        preSelected = _otherOption;
      } else {
        for (final f in festivals) {
          if (f.title == desc) {
            preSelected = f;
            break;
          }
        }
        preSelected ??= _otherOption;
      }

      if (mounted) {
        setState(() {
          _festivals = festivals;
          _selectedFestival = preSelected;
          _loadingFestivals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFestivals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사진 수정',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: '제목',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.activate, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FestivalPreview>(
            initialValue: _selectedFestival,
            decoration: InputDecoration(
              labelText: '페스티벌',
              labelStyle: TextStyle(color: colors.textSecondary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.activate, width: 2),
              ),
            ),
            hint: _loadingFestivals
                ? const Text('불러오는 중...')
                : const Text('페스티벌을 선택하세요'),
            items: [
              ..._festivals.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.title, overflow: TextOverflow.ellipsis),
                  )),
              const DropdownMenuItem(value: _dailyOption, child: Text('일상 사진')),
              const DropdownMenuItem(value: _snsOption, child: Text('SNS 사진')),
              const DropdownMenuItem(value: _otherOption, child: Text('기타')),
            ],
            onChanged: (f) => setState(() => _selectedFestival = f),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final newTitle = _titleCtrl.text.trim();
                if (newTitle.isEmpty) return;
                final newDesc = _selectedFestival?.id == -1
                    ? ''
                    : (_selectedFestival?.title ?? '');
                Navigator.pop(context);
                widget.onSave(newTitle, newDesc);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.activate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('저장',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
