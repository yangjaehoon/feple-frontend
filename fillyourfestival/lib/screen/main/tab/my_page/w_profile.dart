import 'package:fast_app_base/screen/main/tab/my_page/d_myinformation.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatefulWidget {
  Future<MyInfo> myInfo;
  ProfileWidget({super.key, required this.myInfo});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.all(12.0),
          child: CircleAvatar(
            //프로필 이미지
            radius: 50,
            backgroundImage: AssetImage('assets/image/basic_profile.png'),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              //이름
              'User1',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              //레벨
              'Lv.23',
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
                    print('눌림');
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
