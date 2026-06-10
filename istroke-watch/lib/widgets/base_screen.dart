import 'dart:ui';

import 'package:flutter/material.dart';

import '../styles/colors/app_color.dart';

class BaseScreen extends StatelessWidget {
  final Widget body;
  final bool resizeToAvoidBottomInset;

  const BaseScreen({
    super.key,
    required this.body,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          /// Background gradient
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColor.background,
                  AppColor.primary.withValues(alpha: 0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// Setengah lingkaran blur di bawah
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: ClipOval(
          //     child: BackdropFilter(
          //       filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          //       child: Container(
          //         width: MediaQuery.of(context).size.width * 1.5,
          //         height: MediaQuery.of(context).size.width * 0.8,
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color: AppColor.primary.withValues(alpha: 0.4),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          /// Isi konten utama
          SafeArea(child: body),
        ],
      ),
    );
  }
}
