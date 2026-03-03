// class Post {
//   late List<String> comments;
//   late String content, userId, time;
//   late int heart, favorite;

//   Post(
//       {required this.comments,
//       required this.content,
//       required this.userId,
//       required this.time,
//       required this.heart,
//       required this.favorite});

//   factory Post.fromJson(json) {
//     json.forEach((key, value) {});
//     return Post(
//       comments: List<String>.from(json['comments']),
//       content: json['content'] as String,
//       favorite: json['favorite'] as int,
//       heart: json['heart'] as int,
//       time: json['time'] as String,
//       userId: json['userId'] as String,
//     );
//   }
// }