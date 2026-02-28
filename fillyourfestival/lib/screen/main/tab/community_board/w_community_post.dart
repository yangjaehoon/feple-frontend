import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/config.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_write_board.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunityPost extends StatefulWidget {
  final String boardname;

  const CommunityPost({super.key, required this.boardname});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  late Future<List<Map<String, dynamic>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    String boarduri = '';
    if (widget.boardname == "FreeBoard") {
      boarduri = '$baseUrl/posts/free';
    } else if (widget.boardname == "HotBoard") {
      boarduri = '$baseUrl/posts/hot';
    } else if (widget.boardname == "GetuserBoard") {
      boarduri = '$baseUrl/posts/mate';
    }
    final response = await http.get(Uri.parse(boarduri));
    if (response.statusCode == 200) {
      final List<dynamic> parsed = json.decode(utf8.decode(response.bodyBytes));
      return parsed.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load free boards');
    }
  }

  void _refresh() {
    setState(() {
      _postsFuture = _fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      body: Stack(children: [
        SizedBox(
          height: 600,
          child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.loadingIndicator),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load data: ${snapshot.error}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No data available.',
                        style: TextStyle(color: colors.textSecondary)),
                  );
                } else {
                  List<dynamic> postDataList = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: postDataList.length,
                    itemBuilder: (context, int index) {
                      Map<String, dynamic> postData =
                          postDataList[index] as Map<String, dynamic>;
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: ((context) => EnralgePost(
                                    boardname: widget.boardname,
                                    id: postData['id'],
                                    nickname: postData['nickname'],
                                    title: postData['title'],
                                    content: postData['content'],
                                    heart: postData['likeCount'],
                                  )),
                            ),
                          );
                        },
                        title: Text(
                          postData['title'],
                          style: TextStyle(
                            color: colors.textTitle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          postData['content'],
                          style: TextStyle(color: colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded,
                                color: AppColors.kawaiiPink, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              postData['likeCount'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textTitle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.comment_rounded,
                                color: colors.textSecondary, size: 16),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colors.activate,
                          child: Text(
                            postData['nickname'][0],
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return Divider(
                        thickness: 1,
                        color: colors.listDivider,
                      );
                    },
                  );
                }
              }),
        ),
        Positioned(
          bottom: 40,
          left: 150,
          child: FloatingActionButton.extended(
            backgroundColor: colors.activate,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WritePost(
                    boardname: widget.boardname,
                  ),
                ),
              ).then((_) => _refresh());
            },
            label: const Text('글 쓰기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            icon: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ]),
    );
  }
}
