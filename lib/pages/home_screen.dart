import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuzdanim_app/language_provider.dart'; // Dosya yolun neyse o
import 'package:cuzdanim_app/database/database_helper.dart';
import 'package:cuzdanim_app/pages/add_transaction_screen.dart';
import 'package:cuzdanim_app/widgets/summary_card.dart';
import 'profile_screen.dart'; // ProfileScreen sınıfının olduğu dosya
import 'login_register.dart'; // LoginRegister sınıfının olduğu dosya
import 'categories_screen.dart';

// 1. ADIM: Sınıf tanımını bul ve değişkenleri ekle
class HomeScreen extends StatefulWidget {
  // Bu iki satır mutlaka burada olmalı:
  final int? userId;
  final String? userName;
  final String? userEmail;

  // Constructor'a da bunları eklemelisin:
  const HomeScreen({super.key, this.userName, this.userEmail, this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseHelper dbHelper;
  late Future<List<Map<String, dynamic>>> _transactionsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    debugPrint("ANA SAYFA AÇILDI, ID: ${widget.userId}");
    dbHelper = DatabaseHelper();
    _loadData();
  }

  // Load transactions and summary data
  void _loadData() {
    _transactionsFuture = _fetchTransactions();
    _fetchSummaryData();
  }

  // Fetch summary data (income, expenses, balance)
  Future<void> _fetchSummaryData() async {
    try {
      final db = await dbHelper.database;
      final int uId = widget.userId!;

      // Get total income
      final incomeResult = await db.rawQuery(
          "SELECT SUM(amount) as total FROM transactions WHERE type = 'income' AND userId = ?",
          [uId]); // KİLİT BURADA
      _totalIncome = incomeResult.first['total'] != null
          ? (incomeResult.first['total'] as num).toDouble()
          : 0.0;

      // Get total expenses
      final expenseResult = await db.rawQuery(
          "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense' AND userId = ?",
          [uId]); // KİLİT BURADA
      _totalExpenses = expenseResult.first['total'] != null
          ? (expenseResult.first['total'] as num).toDouble()
          : 0.0;

      setState(() {
        _balance = _totalIncome - _totalExpenses;
      });
    } catch (e) {
      debugPrint("Özet verisi çekilirken hata: $e");
    }
  }

  // Fetch all transactions
  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    try {
      // KENDİ YAZDIĞIN DatabaseHelper FONKSİYONUNU ÇAĞIR:
      // Bu sayede 'where userId = ?' şartı otomatik devreye girecek.
      return await dbHelper.getTransactions(widget.userId!);
    } catch (e) {
      debugPrint("Hata oluştu: $e");
      return [];
    }
  }

  void showLogoutDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            langProvider.currentLocale.languageCode == 'tr'
                ? 'Oturumu Kapat'
                : 'Logout',
          ),
          content: Text(
            langProvider.currentLocale.languageCode == 'tr'
                ? 'Çıkış yapmak istediğinizden emin misiniz?'
                : 'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text(
                langProvider.currentLocale.languageCode == 'tr'
                    ? 'İptal'
                    : 'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                    context, '/'); // Navigate to login screen
              },
              child: Text(
                langProvider.currentLocale.languageCode == 'tr'
                    ? 'Çıkış Yap'
                    : 'Logout',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFFFFDF5), // Off-White Arka Plan

      appBar: AppBar(
        titleSpacing: 20,
        // BAŞLIK: İşlem Geçmişi ile milimetrik aynı hizada olması için düz Text kullanıyoruz
        title: Text(
          langProvider.currentLocale.languageCode == 'tr'
              ? "Cüzdanım"
              : "My Wallet",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle:
            false, // Yazıyı en sola yaslar (İşlemler sayfasındaki gibi)
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        // Midnight Blue Gradyan (Keskin Köşeli)
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF002F35),
                      const Color(0xFF004D40)
                    ] // Gece Turkuazı
                  : [const Color(0xFF11606F), const Color(0xFF5AE7E7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        // Sayfanın tamamını kaydırılabilir yapar
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Summary Cards Bölümü
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // GELİR KARTI - Senin özel yeşil renginle
                  SummaryCard(
                    title: langProvider.currentLocale.languageCode == 'tr'
                        ? 'Gelir'
                        : 'Income',
                    amount:
                        '${langProvider.currencySymbol}${_totalIncome.toStringAsFixed(2)}',
                    color: const Color(0xFF278E43), // HEX: #278E43
                    icon: Icons.arrow_upward,
                  ),
                  const SizedBox(height: 12),

                  // GİDER KARTI - Senin özel kırmızı renginle
                  SummaryCard(
                    title: langProvider.currentLocale.languageCode == 'tr'
                        ? 'Gider'
                        : 'Expenses',
                    amount:
                        '${langProvider.currencySymbol}${_totalExpenses.toStringAsFixed(2)}',
                    color: const Color(0xFFED2024), // HEX: #ED2024
                    icon: Icons.arrow_downward,
                  ),
                  const SizedBox(height: 12),

                  // BAKİYE KARTI - Dark Mode'da parlayan özel Turkuaz/Mavi
                  SummaryCard(
                    title: langProvider.currentLocale.languageCode == 'tr'
                        ? 'Bakiye'
                        : 'Balance',
                    amount:
                        '${langProvider.currencySymbol}${_balance.toStringAsFixed(2)}',
                    // Dark Mode'da daha canlı bir mavi, Light Mode'da klasik lacivert
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF4FCBD6)
                        : const Color(0xFF004e92),
                    icon: Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),

            // İşlemler Başlığı (Opsiyonel ama şık durur)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  langProvider.currentLocale.languageCode == 'tr'
                      ? 'Son İşlemler'
                      : 'Recent Transactions',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Recent Transactions Bölümü
            // NOT: Expanded'ı kaldırdık çünkü SingleChildScrollView içinde çalışmaz!
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                        child: Text(
                            langProvider.currentLocale.languageCode == 'tr'
                                ? 'Henüz işlem bulunmuyor.'
                                : 'No transactions yet.')),
                  );
                }

                final transactions = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true, // Listeyi içeriği kadar küçültür
                  physics:
                      const NeverScrollableScrollPhysics(), // Listenin kendi kaydırmasını kapatır (ana sayfa kayacak)
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionTile(transaction);
                  },
                );
              },
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddTransactionScreen(userId: widget.userId!)),
          );

          if (result == true) {
            setState(() {
              _loadData(); // Refresh transactions and summary data
            });
          }
        },
        backgroundColor: const Color.fromARGB(255, 28, 127, 136),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget to display each transaction
  // Widget to display each transaction
  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final langProvider = Provider.of<LanguageProvider>(context);
    bool isIncome = transaction['type'] == 'income';
    bool isTr = langProvider.currentLocale.languageCode == 'tr';

    String categoryName = transaction['category'].toString();

    // Süslü parantezleri ekleyerek uyarıları (lints) susturuyoruz
    if (isTr) {
      if (categoryName == 'Food') {
        categoryName = 'Gıda';
      } else if (categoryName == 'Bills') {
        categoryName = 'Faturalar';
      } else if (categoryName == 'Transport') {
        categoryName = 'Ulaşım';
      } else if (categoryName == 'Other') {
        categoryName = 'Diğer';
      } else if (categoryName == 'Entertainment') {
        categoryName = 'Eğlence';
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${transaction['description']} - ${transaction['date']}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Text(
          '${isIncome ? "+" : "-"}${langProvider.currencySymbol}${transaction['amount']}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _showTransactionActions(context, transaction),
      ),
    );
  }

  // Show options for Edit and Delete
  void _showTransactionActions(
      BuildContext context, Map<String, dynamic> transaction) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isTr = langProvider.currentLocale.languageCode == 'tr';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // 1. Arka Plan Rengi (Uygulamanın inci beyazı tonu)
          backgroundColor: const Color(0xFFFFFDF5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

          // 2. Başlık Rengi (Koyu Turkuaz / Midnight Teal)
          title: Text(
            isTr ? "İşlem Seçenekleri" : "Transaction Actions",
            style: const TextStyle(
              color: Color(0xFF006064),
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            isTr ? "Ne yapmak istersiniz?" : "What would you like to do?",
            style: const TextStyle(color: Color(0xFF2C3E50)), // Antrasit yazı
          ),

          actions: [
            // VAZGEÇ (Gümüş/Gri Tonu)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isTr ? "Vazgeç" : "Cancel",
                style: const TextStyle(color: Color(0xFF7F8C8D)),
              ),
            ),

            // DÜZENLE (Senin Meşhur Altın Rengin)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editTransaction(transaction);
              },
              child: Text(
                isTr ? "Düzenle" : "Edit",
                style: const TextStyle(
                  color: Color(0xFFC2B32A), // Lüks Altın
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // SİL (Ağır Kırmızı / Vişne Çürüğü)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteTransaction(transaction['id']);
              },
              child: Text(
                isTr ? "Sil" : "Delete",
                style: const TextStyle(
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Edit transaction
  void _editTransaction(Map<String, dynamic> transaction) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTransactionScreen(
            transaction: transaction,
            userId: widget.userId!,
          ),
        ));

    if (result == true) {
      setState(() {
        _loadData(); // Refresh transactions and summary data
      });
    }
  }

  // Delete transaction
  Future<void> _deleteTransaction(int transactionId) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool isTr = langProvider.currentLocale.languageCode == 'tr';

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTr ? "İşlemi Sil" : "Delete Transaction"),
        content: Text(isTr
            ? "Bu işlemi silmek istediğinizden emin misiniz?"
            : "Are you sure you want to delete this transaction?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTr ? "İptal" : "Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isTr ? "Sil" : "Delete",
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    // ... devamındaki silme kodları aynı kalıyor

    if (confirmDelete) {
      try {
        final db = await dbHelper.database;
        await db.delete('transactions',
            where: 'id = ?', whereArgs: [transactionId]);
        setState(() {
          _loadData(); // Refresh transactions and summary data
        });
      } catch (e) {
        // print("Error deleting transaction: $e");
      }
    }
  }

  // Drawer Widget
  Widget _buildDrawer() {
    final langProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF0F6FA),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. HEADER: Giriş yapan kullanıcının bilgileri
          DrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/halbuki.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(isDark ? 140 : 60),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_circle, size: 60, color: Colors.white),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _dbHelper.getUser(widget.userId ?? 0),
                  builder: (context, snapshot) {
                    // Varsayılan değerler
                    String displayName = widget.userName ??
                        (langProvider.currentLocale.languageCode == 'tr'
                            ? 'Kullanıcı Adı'
                            : 'User Name');
                    String displayEmail =
                        widget.userEmail ?? 'user@example.com';

                    // Veritabanından güncel veriler geldiyse onları ata
                    if (snapshot.hasData && snapshot.data != null) {
                      displayName = snapshot.data!['name'] ?? displayName;
                      displayEmail = snapshot.data!['email'] ?? displayEmail;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height: 4), // İsim ve mail arasına hafif boşluk
                        Text(
                          displayEmail,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. MENÜ ELEMANLARI
          _buildDrawerTile(
            icon: Icons.account_box,
            title: langProvider.currentLocale.languageCode == 'tr'
                ? 'Hesap'
                : 'Account',
            isDark: isDark,
            onTap: () async {
              Navigator.pop(context); // Drawer'ı kapat

              // 1. Profil sayfasına git ve bir sonuç (result) bekle
              // Navigator.push olan yeri bul ve şununla değiştir:
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: widget
                        .userId, // BURASI KRİTİK: Ana sayfadaki ID'yi buraya veriyoruz!
                    name: widget.userName ?? "Bilinmiyor",
                    email: widget.userEmail ?? "Bilinmiyor",
                  ),
                ),
              );

              // 2. Eğer profil sayfasında 'Kaydet'e basılıp geri gelindiyse (true döndüyse)
              if (result == true) {
                setState(() {
                  // Bu boş setState, sayfayı (ve içindeki Drawer'ı) yeniden çizdirir.
                  // DrawerHeader içindeki FutureBuilder böylece veritabanından yeni ismi çeker.
                  debugPrint("Profil güncellendi, ana sayfa tazeleniyor...");
                });
              }
            },
          ),

          _buildDrawerTile(
            icon: Icons.category,
            title: langProvider.currentLocale.languageCode == 'tr'
                ? 'Kategoriler'
                : 'Categories',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CategoriesScreen(userId: widget.userId!),
                ),
              );
            },
          ),

          const Divider(color: Colors.black12),

          // 3. ÇIKIŞ YAP
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFB22222)),
            title: Text(
              langProvider.currentLocale.languageCode == 'tr'
                  ? 'Çıkış Yap'
                  : 'Logout',
              style: const TextStyle(
                  color: Color(0xFFB22222), fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginRegister()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  } // _buildDrawer burada bitti!

  // --- YARDIMCI FONKSİYONU ŞİMDİ BURAYA, DIŞARIYA KOYDUK ---
  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? const Color(0xFF5AE7E7) : const Color(0xFF11606F),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF2C3E50),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
