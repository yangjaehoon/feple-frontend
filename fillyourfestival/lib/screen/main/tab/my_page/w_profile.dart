// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../model/user_model.dart';
// import '../../../../provider/user_provider.dart';
//
// class ProfileWidget extends StatefulWidget {
//
//   @override
//   State<ProfileWidget> createState() => _ProfileWidgetState();
// }
//
// class _ProfileWidgetState extends State<ProfileWidget> {
//   @override
//   void initState() {
//     super.initState();
//     // initState에서 fetchUserData 호출
//     Provider.of<UserProvider>(context, listen: false).fetchUserData();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     UserProvider userProvider = Provider.of<UserProvider>(context);
//     User? user = userProvider.user;
//
//     return Row(
//       children: [
//         Padding(
//           padding: EdgeInsets.all(12.0),
//           child: CircleAvatar(
//             //프로필 이미지
//             radius: 50,
//             backgroundImage: AssetImage('assets/image/basic_profile.png'),
//           ),
//         ),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               //이름
//               'User1',
//               style: TextStyle(fontSize: 30),
//             ),
//             Text(
//               //레벨
//               'Lv.23',
//               style: TextStyle(
//                 fontSize: 15,
//               ),
//             ),
//           ],
//         ),
//         Expanded(
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     print('눌림');
//                   },
//                   child: Text('프로필 수정'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:fast_app_base/screen/main/tab/my_page/w_change_nickname.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../model/user_model.dart';
import '../../../../provider/user_provider.dart';

class ProfileWidget extends StatefulWidget {
  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  @override
  void initState() {
    super.initState();
    // initState에서 fetchUserData 호출
    Provider.of<UserProvider>(context, listen: false).fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    // UserProvider를 통해 user 데이터 가져오기
    UserProvider userProvider = Provider.of<UserProvider>(context);
    User? user = userProvider.user;


    return user == null
        ? Center(child: CircularProgressIndicator()) // 로딩 중일 때
        : Row(
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: CircleAvatar(
                  // 프로필 이미지
                  radius: 50,
                  backgroundImage: AssetImage('assets/image/basic_profile.png'),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // 사용자 이름 표시
                    user.uid,
                    style: TextStyle(fontSize: 30),
                  ),
                  ElevatedButton(onPressed:(){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context)=>const ChangeNickname())
                    );
                  }, child: Text("닉네임 변경")),
                  Text(
                    // 사용자 레벨 표시
                    'Lv.${user.level}',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          print('프로필 수정 버튼 눌림');
                        },
                        child: Text('프로필 수정'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}
