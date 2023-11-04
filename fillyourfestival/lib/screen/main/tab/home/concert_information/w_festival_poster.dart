import 'package:flutter/material.dart';

class FestivalPoster extends StatefulWidget {
  const FestivalPoster({super.key, required this.posterName});

  final String posterName;

  @override
  State<FestivalPoster> createState() => _FestivalPosterState();
}

class _FestivalPosterState extends State<FestivalPoster> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      height: 300,
      child:  ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          widget.posterName,
          fit: BoxFit.fill,
        ),
      ),

    );
  }
}
