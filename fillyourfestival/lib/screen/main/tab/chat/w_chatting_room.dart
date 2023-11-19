import 'package:flutter/material.dart';
import 'w_message.dart';
import 'w_newmessage.dart';

class ChattingRoom extends StatefulWidget {
  const ChattingRoom({super.key});

  @override
  State<ChattingRoom> createState() => _ChattingRoomState();
}

class _ChattingRoomState extends State<ChattingRoom> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('한요한 채팅방'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: Messages(),
            ),
            Positioned(
              bottom: 50,
              child: NewMessage(),
            ),
          ],
        ),
      ),
    );
  }
}
