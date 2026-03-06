import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

class FtvCertificationWidget extends StatefulWidget {
  const FtvCertificationWidget({super.key});

  @override
  State<FtvCertificationWidget> createState() => _FtvCertificationWidgetState();
}

class _FtvCertificationWidgetState extends State<FtvCertificationWidget> {
  static const int _placeholderCount = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3, height: 20,
                decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '페스티벌 인증',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: colors.textTitle,
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
            itemCount: _placeholderCount,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.certRingColor.withValues(alpha: 0.3),
                        boxShadow: [
                          BoxShadow(
                            color: colors.cardShadow.withValues(alpha: 0.08),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: colors.certRingColor.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 30,
                            color: colors.textTitle.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        '인증 없음',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textTitle.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
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
