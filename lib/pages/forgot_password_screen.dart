import 'package:flutter/material.dart';
// DatabaseHelper yolunu kontrol et
import 'package:cuzdanim_app/database/database_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetPassword() async {
    String email = _emailController.text.trim();
    String newPass = _newPasswordController.text.trim();

    if (email.isEmpty || newPass.isEmpty) {
      _showSnackBar("Lütfen tüm alanları doldurun! ⚠️", Colors.orange);
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar(
          "Yeni şifre en az 6 karakter olmalıdır! 🔐", Colors.redAccent);
      return;
    }

    // DatabaseHelper'daki fonksiyonu çağırıyoruz
    int result = await _dbHelper.updatePassword(email, newPass);

    if (result > 0) {
      _showSnackBar("Şifreniz başarıyla güncellendi! ✅", Colors.green);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context); // Login'e geri dön
    } else {
      _showSnackBar("Bu email ile kayıtlı kullanıcı bulunamadı! ❌", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şifremi Unuttum"),
        backgroundColor: const Color.fromARGB(255, 96, 178, 181),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset,
                size: 100, color: Color.fromARGB(255, 96, 178, 181)),
            const SizedBox(height: 20),
            const Text(
              "Yeni şifrenizi belirlemek için kayıtlı e-posta adresinizi girin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "E-posta Adresi",
                prefixIcon: const Icon(Icons.email),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Yeni Şifre",
                prefixIcon: const Icon(Icons.vpn_key),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 96, 178, 181),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Şifreyi Güncelle",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
