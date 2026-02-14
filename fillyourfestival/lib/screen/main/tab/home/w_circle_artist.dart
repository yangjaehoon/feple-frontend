import 'package:flutter/material.dart';
import '../../../../model/artist_model.dart';
import '../../../../provider/artist_provider.dart';
import 'artist_page/f_artist_page.dart';

class CircleArtistWidget extends StatelessWidget {
  const CircleArtistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Artist>>(
      future: fetchArtists(), // GET /artists 호출해서 List<Artist> 반환
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('아티스트 로딩 실패: ${snapshot.error}'));
        }

        final artists = snapshot.data ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artists.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 한 줄에 3개의 이미지
            mainAxisSpacing: 10,
            crossAxisSpacing: 5,
            //childAspectRatio: 0.66
          ),
          // 전체 이미지 개수
          itemBuilder: (BuildContext context, int index) {
            final artist = artists[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ArtistPage(
                            artistName: artist.name,
                            artistId: artist.id
                        ),
                  ),
                );
                //TODO: 밑에 print문 지워야함
                print(artist.name);
              },
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Image.network(
                        artist.profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                        const ColoredBox(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  //Text(Artists[index].name),
                  Text(artist.name),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
