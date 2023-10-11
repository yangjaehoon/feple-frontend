import 'package:fast_app_base/screen/main/tab/home/artist_page/img_collection/w_img_upload.dart';
import 'package:flutter/material.dart';

class ImgCollection extends StatefulWidget {
  const ImgCollection({super.key});

  @override
  State<ImgCollection> createState() => _ImgCollectionState();
}

class _ImgCollectionState extends State<ImgCollection> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 140,
                color: Colors.blue,
              ),
              Container(
                height: 140,
                color: Colors.red,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 40,
          right: 10,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImgUpload()),
              );
            },
          ),
        ),
      ],
    );
  }
}
