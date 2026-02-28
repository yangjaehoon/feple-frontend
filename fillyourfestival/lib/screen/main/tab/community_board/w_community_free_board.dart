import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../config.dart';
import '../../../../model/post_model.dart';
import '../../../../service/post_service.dart';

class FreeBoard extends StatefulWidget {
  final String boardname;

  const FreeBoard({super.key, required this.boardname});

  @override
  State<FreeBoard> createState() => _FreeBoardState();
}

class _FreeBoardState extends State<FreeBoard> {
  final PostService postService = PostService();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withOpacity(0.12),
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
                  AppColors.kawaiiMint,
                  AppColors.skyBlue.withOpacity(0.7),
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
                          const CommunityPost(boardname: "FreeBoard")),
                    ));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        "자유 게시판",
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
                future: postService.fetchPosts('FreeBoard'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.skyBlue),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load data: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    );
                  } else {
                    List postDataList = snapshot.data!;
                    if (postDataList.isEmpty) {
                      return const Center(
                        child: Text(
                          'No data available.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    } else {
                      return ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: postDataList.length,
                          itemBuilder: (context, int index) {
                            Post postData = postDataList[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                postData.title,
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                postData.nickname,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
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
                                    postData.likeCount.toString(),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textMain,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.chat_bubble_outline_rounded,
                                      color: AppColors.skyBlue, size: 16),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Divider(
                              thickness: 1,
                              color: Colors.grey.shade100,
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
