import 'package:flutter/material.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import 'package:cuzdanim_app/language_provider.dart';
import '../database/database_helper.dart';
import 'forgot_password_screen.dart';

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  State<LoginRegister> createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  bool _isLogin = true; // Track if it's login or register page
  bool _isPasswordVisible = false; // Track password visibility

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // For registration

  final _formKey = GlobalKey<FormState>(); // Form key for validation
  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
        backgroundColor:
            Colors.transparent, // Scaffold'un kendi beyazlığını kapatır
        body: Container(
            width: double.infinity, // Ekran genişliğini tam kapla
            height: double.infinity, // Ekran yüksekliğini tam kapla
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/sonArkaplan.png"),
                fit: BoxFit
                    .fill, // İŞTE BURASI: Resmi çekiştirip ekrana tam oturtur, asla kesmez!
              ),
            ),
            // Buradan aşağısı senin mevcut child: Stack(...) veya Column(...) yapınla devam edecek
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  // CARD widget'ını ya SİL ya da buradaki gibi color: Colors.transparent yap
                  child: Card(
                    elevation:
                        0, // Gölgeyi de sıfırlayalım ki şeffaflık temiz görünsün
                    color: Colors.transparent, // İŞTE ÇÖZÜM BURASI
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: BoxDecoration(
                        // BUZLU CAM EFEKTİ
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        // Hafif bir gölge istersen camı belli etmek için:
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // LOGO - Orijinal rengine (deepPurple) geri döndü
                              const Icon(
                                Icons.account_circle,
                                size: 80,
                                color: Color(0xFFC2B32A),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                langProvider.currentLocale.languageCode == 'tr'
                                    ? (_isLogin
                                        ? "Hoş geldiniz"
                                        : "Hesap Oluştur")
                                    : (_isLogin
                                        ? "Welcome Back!"
                                        : "Create Account"),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .black87, // YAZI SİYAH/KOYU (OKUNUR)
                                ),
                              ),
                              const SizedBox(height: 20),
                              // KULLANICI ADI KUTUSU (Orijinal siyah/koyu hali)
                              // KULLANICI ADI GİRİŞ YERİ
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  // KUTUNUN İÇİNİ DE ŞEFFAF YAPTIK
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  labelText:
                                      langProvider.currentLocale.languageCode ==
                                              'tr'
                                          ? 'Kullanıcı Adı'
                                          : 'Username',
                                  labelStyle:
                                      const TextStyle(color: Colors.black87),
                                  // Tıklayınca yukarı çıkan yazı rengi senin seçtiğin mor
                                  floatingLabelStyle: const TextStyle(
                                    color: Color(0xFF006064),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  prefixIcon: const Icon(Icons.person,
                                      color: Colors.black),

                                  // 1. NORMAL KENARLIK (Tıklanmadığında siyah/gri)
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: Colors.black54),
                                  ),

                                  // 2. TIKLAYINCA SENİN SEÇTİĞİN ÖZEL MOR (focusedBorder)
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC2B32A), // Senin rengin
                                      width: 1.5,
                                    ),
                                  ),

                                  // 3. GENEL KENARLIK (Her ihtimale karşı)
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: Colors.black),
                                  ),
                                ),
                                // VALIDATOR KISMI (Eğer devamında varsa buraya ekleyebilirsin)
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return langProvider
                                                .currentLocale.languageCode ==
                                            'tr'
                                        ? 'Lütfen kullanıcı adı giriniz'
                                        : 'Please enter a username';
                                  }
                                  return null;
                                },
                              ), // <-- BU VİRGÜL TEXTFORMFIELD'I KAPATIYOR
                              const SizedBox(height: 16),
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  // KUTU İÇİ ŞEFFAFLIK
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.2),

                                  // TIKLAYINCA YUKARI ÇIKAN YAZI RENGİ (SENİN MORUN)
                                  floatingLabelStyle: const TextStyle(
                                    color: Color(0xFF006064),
                                    fontWeight: FontWeight.bold,
                                  ),

                                  labelText:
                                      langProvider.currentLocale.languageCode ==
                                              'tr'
                                          ? 'Şifre'
                                          : 'Password',
                                  labelStyle:
                                      const TextStyle(color: Colors.black87),
                                  prefixIcon: const Icon(Icons.lock,
                                      color: Colors.black),

                                  // ŞİFRE GÖSTER/GİZLE BUTONU
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.black54,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
// 1. NORMAL KENARLIK (TIKLANMADIĞINDA)
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: Colors.black54),
                                  ),

                                  // 2. TIKLAYINCA ÇIKAN ALTIN RENK (FOCUSEDBORDER)
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC2B32A),
                                      width:
                                          2.0, // Belirgin olması için 2 yaptık
                                    ),
                                  ),

                                  // 3. HATA DURUMUNDA BİLE ALTIN GÖRÜNSÜN (Kırmızıyı engeller)
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFC2B32A), width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFC2B32A), width: 2),
                                  ),

                                  // 4. GENEL KENARLIK
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return langProvider
                                                .currentLocale.languageCode ==
                                            'tr'
                                        ? 'Lütfen şifre giriniz'
                                        : 'Please enter a password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Email Field (for registration)
                              if (!_isLogin)
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    labelText: langProvider
                                                .currentLocale.languageCode ==
                                            'tr'
                                        ? 'E-posta'
                                        : 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              if (!_isLogin) const SizedBox(height: 16),

                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        debugPrint(
                                            "--- LOGİN BUTONUNA BASILDI ---");
                                        if (_formKey.currentState!.validate()) {
                                          final dbHelper = DatabaseHelper();
                                          // 1. Verileri al ve temizle
                                          final username =
                                              _usernameController.text.trim();
                                          final password =
                                              _passwordController.text.trim();
                                          debugPrint(
                                              "Giris deneniyor (Kullanıcı Adı): $username / $password");

                                          if (_isLogin) {
                                            // --- GİRİŞ YAPMA (LOGIN) ---
                                            // Debug için konsola yazdırıyoruz (Hata varsa terminalde görelim)
                                            debugPrint(
                                                "Giris deneniyor: $username / $password");

                                            final user = await dbHelper
                                                .loginUser(username, password);

                                            if (user != null) {
                                              debugPrint(
                                                  "✅ Giris Basarili! ID: ${user['id']}");
                                              if (!mounted) return;
                                              debugPrint(
                                                  "Giris Basarili! ID: ${user['id']} Kullanici: ${user['name']}");

                                              // Navigator'ı bu şekilde yazarsan arkada hiçbir sayfa kalmaz, kilitlenme önlenir.
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MainNavigationScreen(
                                                    userId: user[
                                                        'id'], // ID'yi buradan gönderiyoruz
                                                    userName: user['name'] ??
                                                        "Kullanıcı",
                                                    userEmail:
                                                        user['email'] ?? "",
                                                  ),
                                                ),
                                                (route) =>
                                                    false, // Eski tüm sayfaları (Login vs.) siler.
                                              );
                                            } else {
                                              debugPrint(
                                                  "❌ Hata: Kullanıcı adı veya şifre hatalı!");
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Hatalı e-posta veya şifre!")),
                                              );
                                            }
                                          } else {
                                            // --- KAYIT OLMA (REGISTER) ---

                                            // BURAYA EKLEDİK: Şifre Kontrolü (Veritabanına gitmeden hemen önce)
                                            if (password.length < 6) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(langProvider
                                                              .currentLocale
                                                              .languageCode ==
                                                          'tr'
                                                      ? "Şifre en az 6 karakter olmalıdır!"
                                                      : "Password must be at least 6 characters!"),
                                                  backgroundColor:
                                                      Colors.orange.shade800,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              return; // Şifre kısaysa aşağıya (dbHelper'a) geçme, burada dur!
                                            }

                                            // Şifre 6 haneliyse buraya devam eder:
                                            try {
                                              int result =
                                                  await dbHelper.registerUser(
                                                _usernameController.text.trim(),
                                                _emailController.text.trim(),
                                                password, // Trimlenmiş şifre
                                              );

                                              if (result > 0) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(langProvider
                                                                .currentLocale
                                                                .languageCode ==
                                                            'tr'
                                                        ? "Kayıt başarılı! Şimdi giriş yapabilirsiniz."
                                                        : "Registration successful! Please login."),
                                                    backgroundColor:
                                                        Colors.green,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                                setState(() => _isLogin = true);
                                              }
                                            } catch (e) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(langProvider
                                                              .currentLocale
                                                              .languageCode ==
                                                          'tr'
                                                      ? "Bu e-posta zaten kullanımda!"
                                                      : "This email is already in use!"),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: const BorderSide(
                                              color: Color(0xFFFFF1D0),
                                              width: 1.5),
                                        ),
                                        backgroundColor:
                                            const Color(0xFFC2B32A),
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: const Color(0xFFC2B32A)
                                            .withAlpha(128),
                                      ),
                                      child: Text(
                                        langProvider.currentLocale
                                                    .languageCode ==
                                                'tr'
                                            ? (_isLogin
                                                ? "Giriş Yap"
                                                : "Kayıt Ol")
                                            : (_isLogin ? "Login" : "Register"),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),

                                  // --- ŞİFREMİ UNUTTUM BUTONU ---
                                  if (_isLogin)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          final TextEditingController
                                              resetEmailController =
                                              TextEditingController();
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(langProvider
                                                          .currentLocale
                                                          .languageCode ==
                                                      'tr'
                                                  ? "Şifre Hatırlatıcı"
                                                  : "Password Recovery"),
                                              content: TextField(
                                                controller:
                                                    resetEmailController,
                                                decoration: InputDecoration(
                                                  hintText: langProvider
                                                              .currentLocale
                                                              .languageCode ==
                                                          'tr'
                                                      ? "E-postanızı girin"
                                                      : "Enter your email",
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(langProvider
                                                              .currentLocale
                                                              .languageCode ==
                                                          'tr'
                                                      ? "İptal"
                                                      : "Cancel"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    final pass =
                                                        await DatabaseHelper()
                                                            .getPasswordByEmail(
                                                                resetEmailController
                                                                    .text);
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    Navigator.pop(context);

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(pass !=
                                                                null
                                                            ? (langProvider
                                                                        .currentLocale
                                                                        .languageCode ==
                                                                    'tr'
                                                                ? "Şifreniz: $pass"
                                                                : "Your password: $pass")
                                                            : (langProvider
                                                                        .currentLocale
                                                                        .languageCode ==
                                                                    'tr'
                                                                ? "E-posta bulunamadı!"
                                                                : "Email not found!")),
                                                        backgroundColor:
                                                            pass != null
                                                                ? Colors.teal
                                                                : Colors.red,
                                                      ),
                                                    );
                                                  },
                                                  child: Text(langProvider
                                                              .currentLocale
                                                              .languageCode ==
                                                          'tr'
                                                      ? "Şifreyi Göster"
                                                      : "Show Password"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets
                                                .zero, // Kenar boşluklarını sıfırla ki hizalı dursun
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            langProvider.currentLocale
                                                        .languageCode ==
                                                    'tr'
                                                ? "Şifremi Unuttum"
                                                : "Forgot Password?",
                                            style: const TextStyle(
                                              color: Color(0xFF006064),
                                              fontSize: 13,
                                              fontWeight: FontWeight
                                                  .bold, // Tıklanabilir olduğu belli olsun diye kalınlaştırdım
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16.0),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin =
                                        !_isLogin; // Toggle between Login and Register
                                  });
                                },
                                child: Text(
                                  langProvider.currentLocale.languageCode ==
                                          'tr'
                                      ? (_isLogin
                                          ? "Hesabınız yok mu? Kayıt Olun"
                                          : "Zaten hesabınız var mı? Giriş Yapın")
                                      : (_isLogin
                                          ? "Don't have an account? Register"
                                          : "Already have an account? Login"),
                                  style: const TextStyle(
                                    color: Color(0xFF006064),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )));
  }
}
