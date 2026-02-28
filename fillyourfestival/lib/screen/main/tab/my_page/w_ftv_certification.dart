import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

class FtvCertificationWidget extends StatefulWidget {
  const FtvCertificationWidget({super.key});

  @override
  State<FtvCertificationWidget> createState() => _FtvCertificationWidgetState();
}

class _FtvCertificationWidgetState extends State<FtvCertificationWidget> {
  List<Map<String, dynamic>> ftv_certification = [
    {
      "id": 1,
      "title": "psy_show",
      "path": "assets/image/ftv_certification/psy_certification.jpg",
    },
    {
      "id": 2,
      "title": "rapbeat",
      "path": "assets/image/ftv_certification/rapbeat_certification.jpg",
    },
    {
      "id": 3,
      "title": "seouljazzftv",
      "path": "assets/image/ftv_certification/seouljazzftv_certification.jpg",
    },
    {
      "id": 4,
      "title": "thecryground",
      "path": "assets/image/ftv_certification/thecryground_certification.jpg",
    },
    {
      "id": 5,
      "title": "waterbomb",
      "path": "assets/image/ftv_certification/waterbomb_certification.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.kawaiiMint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '페스티벌 인증 🎪',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: ftv_certification.length,
            itemBuilder: (BuildContext context, int index) {
              Map<String, dynamic> certification = ftv_certification[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.kawaiiMint,
                            AppColors.skyBlue,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.skyBlue.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(certification['path']),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        certification['title'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
