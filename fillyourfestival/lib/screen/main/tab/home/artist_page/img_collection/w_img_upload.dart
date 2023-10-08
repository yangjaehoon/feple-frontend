import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImgUpload extends StatefulWidget {
  const ImgUpload({super.key});

  @override
  State<ImgUpload> createState() => _ImgUploadState();
}

class _ImgUploadState extends State<ImgUpload> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController titleTEC = TextEditingController();
  TextEditingController locTEC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("사진 올리기"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: EdgeInsets.all(20),
                  height: 240,
                  width: 240,
                  decoration: BoxDecoration(
                    color: Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        color: Colors.black,
                        Icons.add,
                      ),
                      Text(
                        "아티스트 사진 추가",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleTEC,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "작품명",
                        hintText: "작품명을 입력하세요."
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return "필수 입력 항목입니다.";
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    TextFormField(
                      controller: locTEC,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "페스티벌 이름",
                          hintText: "페스티벌 위치나 이름을 입력하세요."
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return "필수 입력 항목입니다.";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
