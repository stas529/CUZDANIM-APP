import 'package:flutter/material.dart';
// LanguageProvider için
import 'package:cuzdanim_app/database/database_helper.dart';

// 1. Burayı StatefulWidget yaptık ve userId ekledik
class ProfileScreen extends StatefulWidget {
  final int? userId; // Giriş yapan kullanıcının ID'si
  final String name;
  final String email;

  const ProfileScreen(
      {super.key, this.userId, required this.name, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 2. Kutuları kontrol etmek için Controller'lar
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    debugPrint("PROFİL SAYFASI AÇILDI! GELEN ID: ${widget.userId}");
    // İlk etapta widget'tan gelen verileri koyuyoruz (boş kalmasın diye)
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);

    // AMA hemen ardından veritabanına gidip en güncel halini çekiyoruz
    _loadLatestUserData();
  }

  // Veritabanındaki en güncel veriyi çekip kutucukları güncelleyen fonksiyon
  void _loadLatestUserData() async {
    final dbHelper = DatabaseHelper();
    var userData = await dbHelper.getUser(widget.userId ?? 0);

    if (userData != null && mounted) {
      setState(() {
        _nameController.text = userData['name'] ?? widget.name;
        _emailController.text = userData['email'] ?? widget.email;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color(0xFF004D40);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profilim",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF002F35),
                      const Color(0xFF004D40),
                    ] // Gece Turkuazı
                  : [
                      const Color(0xFF11606F),
                      const Color(0xFF5AE7E7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. ÜST ALAN: MODERN PROFİL KAFASI
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                // KAVİSLİ KÖŞELER
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35)),

                // ARKA PLAN RESMİ
                image: const DecorationImage(
                  image: AssetImage(
                      "assets/images/profil.jpg"), // pubspec'teki adıyla aynı olmalı
                  fit: BoxFit.cover, // Resmi kutuya tam sığdırır
                  opacity:
                      0.4, // Yazıların okunması için resmi biraz şeffaf yapıyoruz
                ),

                // RENK GEÇİŞİ (RESİMLE BİRLEŞİR)
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF002F35), const Color(0xFF004D40)]
                      : [
                          const Color.fromARGB(255, 176, 188, 191),
                          const Color.fromARGB(255, 159, 198, 198)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(_nameController.text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text(_emailController.text,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // 2. PROFİL BİLGİLERİ (Tıklanabilir Alanlar)
            _buildCategoryTitle("Kişisel Bilgiler"),
            _buildInfoCard([
              _buildEditableTile(
                  Icons.badge_outlined, "Kullanıcı Adı", _nameController),
              _buildEditableTile(
                  Icons.alternate_email, "E-posta Adresi", _emailController),
            ]),

            // 3. UYGULAMA & VERİTABANI BİLGİLERİ (Geri Getirdiğimiz Kısımlar)
            _buildCategoryTitle("Uygulama & Sistem"),
            _buildInfoCard([
              _buildStaticTile(Icons.workspace_premium_outlined, "Hesap Durumu",
                  "Standart Kullanıcı"),
              _buildStaticTile(Icons.storage_rounded, "Veri Kaynağı",
                  "Yerel SQLite Veritabanı"),
              _buildStaticTile(Icons.security_update_good, "Uygulama Versiyonu",
                  "v1.0.4 - Kararlı"),
            ]),

            const SizedBox(height: 25),

            // 4. KAYDET BUTONU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 96, 178, 181),
                  minimumSize: const Size(double.infinity, 55),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  debugPrint("BUTONA BASILDI - NOKTA");
                  final dbHelper = DatabaseHelper();

                  // 1. Verileri al ve temizle
                  String newName = _nameController.text.trim();
                  String newEmail = _emailController.text.trim();

                  // ID Kontrolü
                  if (widget.userId == null) {
                    _showError("Hata: Kullanıcı ID bulunamadı!");
                    return;
                  }

                  // 2. Boşluk Kontrolü
                  if (newName.isEmpty || newEmail.isEmpty) {
                    _showError("İsim ve Email alanları boş bırakılamaz! ⚠️");
                    return;
                  }

                  // 3. Email Format Kontrolü
                  bool emailGecerliMi =
                      RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(newEmail);
                  if (!emailGecerliMi) {
                    _showError("Lütfen geçerli bir e-posta adresi girin! 📧");
                    return;
                  }

                  // Veritabanından mevcut şifreyi çekiyoruz
                  var userData = await dbHelper.getUser(widget.userId!);
                  String currentPassword = userData?['password'] ?? "123456";

                  // --- TEK VE TEMİZ GÜNCELLEME İŞLEMİ ---
                  try {
                    debugPrint("--- GÜNCELLEME DENENİYOR ---");
                    int result = await dbHelper.updateUser(
                      widget.userId!,
                      newName,
                      newEmail,
                      currentPassword,
                    );

                    if (result > 0) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Bilgileriniz kalıcı olarak güncellendi ✅"),
                          backgroundColor: Colors.green,
                        ),
                      );

                      await Future.delayed(const Duration(milliseconds: 500));
                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    } else {
                      _showError("Hata: Kayıt güncellenemedi!");
                    }
                  } catch (e) {
                    debugPrint("DB Update Hatası: $e");
                    // Email UNIQUE (Benzersizlik) hatası kontrolü
                    if (e.toString().contains("UNIQUE")) {
                      _showError(
                          "Bu e-posta adresi başka bir kullanıcıya ait! ❌");
                    } else {
                      _showError("Sistem hatası: $e");
                    }
                  }
                },
                child: const Text(
                  "Değişiklikleri Kaydet",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

// --- YARDIMCI TASARIM WIDGETLARI (Hatalar burada düzeltildi) ---

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, top: 20, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                letterSpacing: 1.1)),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(
                  20), // withOpacity yerine withAlpha kullanarak hatayı çözdük
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEditableTile(
      IconData icon, String label, TextEditingController controller) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFF11606F)
                .withAlpha(30), // Burada da hatayı çözdük
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF11606F), size: 22),
      ),
      title:
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.only(top: 4)),
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildStaticTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.blueGrey.withAlpha(30), // Hata giderildi
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blueGrey, size: 22),
      ),
      title:
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87)),
    );
  }
}
