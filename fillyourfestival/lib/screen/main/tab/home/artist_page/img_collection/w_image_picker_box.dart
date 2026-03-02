import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 이미지 선택/미리보기 박스
class ImagePickerBox extends StatelessWidget {
  final Uint8List? imageData;
  final VoidCallback onTap;
  final String label;

  const ImagePickerBox({
    super.key,
    required this.imageData,
    required this.onTap,
    this.label = '사진 추가',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(20),
          height: 240,
          width: 240,
          decoration: BoxDecoration(
            color: Colors.grey[200]!,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: imageData == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.black),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                )
              : Image.memory(imageData!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
