// import 'package:dio/dio.dart';
//
// const _API_PREFIX = "http://13.209.108.218:8080/users";
//
// class User{
//   Future<void> getReq() async{
//     Response response;
//     Dio dio = new Dio();
//     response = await dio.get("$_API_PREFIX");
//     print(response.data.toString());
//   }
//
//   Future<void> postReq() async{
//     Response response;
//     Dio dio = new Dio();
//     response = await dio.patch(_API_PREFIX,data:{ "post_num": 100});
//     print(response.data.toString());
//   }
// }
//
//
// User user = User();