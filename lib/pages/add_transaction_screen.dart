// ignore: file_names
import 'package:flutter/material.dart';
import 'package:cuzdanim_app/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:cuzdanim_app/language_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  final int
      userId; // BURASI EKLENDİ - Kimin harcaması olduğunu bilmek için şart

  const AddTransactionScreen(
      {super.key, this.transaction, required this.userId});

  @override
  AddTransactionScreenState createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  String _type = 'expense';
  String _category = 'Other';
  DateTime _selectedDate = DateTime.now();

  // Dinamik kategori listemiz
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!['amount'].toString();
      _descriptionController.text = widget.transaction!['description'];
      _type = widget.transaction!['type'];
      _category = widget.transaction!['category'];
      _selectedDate = DateTime.parse(widget.transaction!['date']);
    }

    // SAYFA AÇILIRKEN SADECE BU KULLANICININ KATEGORİLERİNİ ÇEK
    _loadUserCategories();
  }

  // Veritabanındaki kategorileri listeye ekleyen fonksiyon
  Future<void> _loadUserCategories() async {
    // BURASI DÜZELTİLDİ: widget.userId gönderiliyor
    final dbCategories = await _dbHelper.getCategories(widget.userId);
    setState(() {
      for (var cat in dbCategories) {
        String catName = cat['name'].toString();
        if (!_categories.contains(catName)) {
          _categories.add(catName);
        }
      }
      if (widget.transaction != null && !_categories.contains(_category)) {
        _categories.add(_category);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        final double inputAmount = double.parse(_amountController.text);
        final transactionData = {
          'amount': inputAmount,
          'description': _descriptionController.text,
          'type': _type,
          'category': _category,
          'date': _selectedDate.toIso8601String(),
          'userId': widget.userId,
        };

        final db = await _dbHelper.database;
        await db.insert('transactions', transactionData);

        if (!mounted) return;

        // --- KRİTİK DÜZELTME BURADA BAŞLIYOR ---

        // 1. Önce güncel bakiyeyi hesaplayalım (Senin DatabaseHelper'daki fonksiyonun adını yazdım)
        // Veritabanından o anki net durumu çekelim
        double toplamGelir = await _dbHelper.getTotalIncome(widget.userId);
        double toplamGider = await _dbHelper.getTotalExpense(widget.userId);
        double netBakiye = toplamGelir - toplamGider;

        // Terminale bak abi, burada ne yazdığı çok önemli!
        debugPrint("--- KEDİ TESTİ LOGLARI ---");
        debugPrint("Seçilen Tip: $_type"); // 'Expense' mi yoksa 'expense' mi?
        debugPrint("Toplam Gelir: $toplamGelir");
        debugPrint("Toplam Gider: $toplamGider");
        debugPrint("Hesaplanan Net Bakiye: $netBakiye");

        // ŞART: Tip 'Expense' veya 'expense' ise VE bakiye 0 veya altına düştüyse
        // .toLowerCase() kullanarak harf büyüklüğü hatasını engelliyoruz.
        if (_type.toLowerCase() == 'expense' && netBakiye == 0) {
          debugPrint("DURUM: Kedi diyaloğu açılıyor çünkü bakiye sıfır!");

          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: Image.asset(
                          'assets/images/nomoney.jpg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // BAKİYE YAZISI (Gerçek bakiyeyi yazdırıyoruz)
                      Text(
                        // BU SATIRI ŞÖYLE DEĞİŞTİR:
                        "Bakiye: ${netBakiye.toStringAsFixed(2)} ₺",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Colors.redAccent,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: IconButton(
                      icon: const Icon(Icons.cancel,
                          color: Colors.white70, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        // --- DÜZELTME BİTTİ ---

        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        debugPrint("HATA: $e");
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    bool isTr = langProvider.currentLocale.languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTr
              ? (widget.transaction == null ? "İşlem Ekle" : "İşlemi Düzenle")
              : (widget.transaction == null
                  ? "Add Transaction"
                  : "Edit Transaction"),
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11606F), Color(0xFF5AE7E7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isTr ? "Miktar" : "Amount",
                  prefixIcon:
                      const Icon(Icons.attach_money, color: Color(0xFFC2B32A)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isTr ? "Bir miktar girin" : "Enter an amount";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: isTr ? "Açıklama" : "Description",
                  prefixIcon:
                      const Icon(Icons.description, color: Color(0xFFEDDA32)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? (isTr ? "Bir açıklama girin" : "Enter a description")
                    : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue:
                    _type, // initialValue yerine value kullanmak daha sağlamdır
                decoration: InputDecoration(
                  labelText: isTr ? "Tür" : "Type",
                  prefixIcon:
                      const Icon(Icons.type_specimen, color: Color(0xFFEDDA32)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
                items: ["income", "expense"].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type == "income"
                        ? (isTr ? "Gelir" : "Income")
                        : (isTr ? "Gider" : "Expense")),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _categories.contains(_category)
                    ? _category
                    : _categories.last,
                decoration: InputDecoration(
                  labelText: isTr ? "Kategori" : "Category",
                  prefixIcon:
                      const Icon(Icons.category, color: Color(0xFFEDDA32)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      isTr ? _translateCategory(category) : category,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(isTr ? "Tarih" : "Date",
                    style: const TextStyle(color: Color(0xFF167716))),
                subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0],
                    style: const TextStyle(fontSize: 16)),
                trailing:
                    const Icon(Icons.calendar_today, color: Color(0xFF167716)),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: Color(0xFF167716)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB2B2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
                child: Text(
                  isTr
                      ? (widget.transaction == null ? "İşlem Ekle" : "Güncelle")
                      : (widget.transaction == null
                          ? "Add Transaction"
                          : "Update"),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateCategory(String category) {
    switch (category) {
      case 'Food':
        return 'Gıda';
      case 'Transport':
        return 'Ulaşım';
      case 'Shopping':
        return 'Alışveriş';
      case 'Bills':
        return 'Faturalar';
      case 'Other':
        return 'Diğer';
      default:
        return category;
    }
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
