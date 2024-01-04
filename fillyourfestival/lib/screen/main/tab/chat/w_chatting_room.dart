import 'package:flutter/material.dart';
import 'w_message.dart';
import 'w_newmessage.dart';

class ChattingRoom extends StatefulWidget {
  final String chattingroomname;
  const ChattingRoom({super.key, required this.chattingroomname});

  @override
  State<ChattingRoom> createState() => _ChattingRoomState();
}

class _ChattingRoomState extends State<ChattingRoom> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chattingroomname),
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
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 400,
                  child: Messages(chattingroomname: widget.chattingroomname),
                ),
                Positioned(
                  bottom: 50,
                  child: NewMessage(chattingroomname: widget.chattingroomname),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
