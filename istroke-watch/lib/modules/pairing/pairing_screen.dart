import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../services/remote/auth_service.dart';
import '../../styles/colors/app_color.dart';
import '../../supabase/supabase_client.dart';
import '../../widgets/base_screen.dart';
import '../../widgets/pop_up_loading.dart';
import '../dahsboard/dashboard_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  String? _pairingCode;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initPairing();
  }

  Future<void> _initPairing() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString("pairing_code");

    String code;
    if (savedCode != null) {
      code = savedCode;
    } else {
      code = const Uuid().v4();
      await prefs.setString("pairing_code", code);

      await SupabaseManager.client.from("pairings").insert({
        "pairing_code": code,
      });
    }

    setState(() {
      _pairingCode = code;
      _isLoading = false;
    });
  }

  Future<void> _tryLogin() async {
    if (_pairingCode == null) return;

    setState(() => _isLoading = true);

    final response = await SupabaseManager.client
        .from("pairings")
        .select()
        .eq("pairing_code", _pairingCode!)
        .maybeSingle();

    setState(() => _isLoading = false);

    if (response != null &&
        response["refresh_token"] != null &&
        response["user_id"] != null) {
      final success = await _authService.saveSessionFromPairing(
        refreshToken: response["refresh_token"],
        userId: response["user_id"],
        email: response["email"],
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  DashboardScreen(userId:  response["user_id"])),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Lakukan scan terlebih dahulu!",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      body: _isLoading
          ? const PopUpLoading()
          : _pairingCode == null
          ? const Text("Gagal Membuat QR CODE")
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(8),
                      height: MediaQuery.sizeOf(context).width * 0.65,
                      width: MediaQuery.sizeOf(context).width * 0.65,
                      decoration: BoxDecoration(
                        color: AppColor.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QrImageView(
                        data: _pairingCode!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.65,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: _tryLogin,
                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
    );
  }
}
