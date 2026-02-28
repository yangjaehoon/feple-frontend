import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HotBoard extends StatefulWidget {
  final String boardname;

  const HotBoard({super.key, required this.boardname});

  @override
  State<StatefulWidget> createState() => _HotBoardState();
}

class _HotBoardState extends State<HotBoard> {
  Future<List<dynamic>> getpost() async {
    final response =
        await http.get(Uri.parse('http://13.209.108.218:8080/hotboards/previews'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load hot boards');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  colors.hotBoardGradientStart,
                  colors.hotBoardGradientEnd,
                ],
              ),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: ((context) =>
                        const CommunityPost(boardname: "HotBoard")),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: AppColors.sunnyYellow, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        "인기 게시판",
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        "더보기",
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
                future: getpost(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colors.loadingIndicator,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load data: ${snapshot.error}',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    );
                  } else {
                    List<dynamic> postDataList = snapshot.data!;
                    if (postDataList.isEmpty) {
                      return Center(
                        child: Text(
                          'No data available.',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      );
                    } else {
                      return ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: postDataList.length,
                          itemBuilder: (context, int index) {
                            Map<String, dynamic> postData = postDataList[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                postData['postname'],
                                style: TextStyle(
                                  color: colors.textTitle,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                postData['datetime'],
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite_rounded,
                                      color: AppColors.kawaiiPink, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    postData['favorite'].toString(),
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: colors.textTitle,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      color: colors.activate, size: 16),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Divider(
                              thickness: 1,
                              color: colors.listDivider,
                              indent: 16,
                              endIndent: 16,
                            );
                          });
                    }
                  }
                }),
          ),
        ],
      ),
    );
  }
}
