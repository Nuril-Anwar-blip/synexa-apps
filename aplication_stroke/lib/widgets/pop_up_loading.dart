import 'package:flutter/material.dart';
import '../styles/colors/app_color.dart';

class PopUpLoading extends StatelessWidget {
  const PopUpLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => false,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Container(
            height: 150,
            width: 150,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColor.primary,
                  strokeWidth: 4,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Loading",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
