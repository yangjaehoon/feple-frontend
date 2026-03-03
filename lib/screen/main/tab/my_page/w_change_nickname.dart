import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/user_model.dart';
import '../../../../network/dio_client.dart';
import '../../../../provider/user_provider.dart';

class ChangeNickname extends StatefulWidget {
  const ChangeNickname({super.key});

  @override
  State<ChangeNickname> createState() => _ChangeNicknameState();
}

class _ChangeNicknameState extends State<ChangeNickname> {
  var nicknameController = TextEditingController();

  Future<void> _updateNickname(UserProvider userProvider, int id) async {
    final nickname = nicknameController.text.trim();

    final resp = await DioClient.dio.put(
      '/users/$id',
      data: {'nickname': nickname},
    );

    final updated = User.fromJson(resp.data as Map<String, dynamic>);
    await userProvider.setUser(updated);
  }

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    User? user = userProvider.user;

    return Scaffold(
        appBar: AppBar(
          title: const Text('닉네임 변경'),
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
          Text(
            "변경할 닉네임을 입력해주세요.",
            style: TextStyle(fontSize: 22),
          ),
          TextField(
            controller: nicknameController,
            style: TextStyle(fontSize: 22, color: Colors.blue),
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'ex) 페벌러'),
          ),
          ElevatedButton(
              onPressed: () async {
                try {
                  await _updateNickname(userProvider, user!.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('닉네임이 변경되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('닉네임 변경에 실패했습니다.\n$e')),
                  );
                }
              },
              child: Text("확인")),
        ]));
  }
}
