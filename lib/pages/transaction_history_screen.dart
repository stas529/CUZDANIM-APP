import 'package:flutter/material.dart';
import 'package:cuzdanim_app/database/database_helper.dart';
import 'add_transaction_screen.dart';
import 'package:provider/provider.dart';
import 'package:cuzdanim_app/language_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final int userId;
  const TransactionHistoryScreen({super.key, required this.userId});

  @override
  TransactionHistoryScreenState createState() =>
      TransactionHistoryScreenState();
}

class TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _transactions = [];
  String _searchQuery = "";
  String _filterType = "All";

  @override
  void initState() {
    super.initState();
    _loadTransactions(); // Sayfa açılır açılmaz motoru çalıştırır
  }

  Future<void> _loadTransactions() async {
    final db = await _dbHelper.database;

    // Buraya 'where' ve 'whereArgs' ekleyerek gümrüğü kuruyoruz
    final transactions = await db.query(
      'transactions',
      where: 'userId = ?', // Sadece bu kullanıcının verileri
      whereArgs: [widget.userId],
      orderBy: 'date DESC',
    );

    setState(() {
      _transactions = transactions;
    });
  }

  // --- GRUPLANDIRMA FONKSİYONU (Hatalardan temizlenmiş hali) ---
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tx in transactions) {
      String date = tx['date'].toString().split("T")[0];
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(tx);
    }
    return grouped;
  }

  Future<void> _deleteTransaction(int id) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isTr = langProvider.currentLocale.languageCode == 'tr';

    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isTr ? "İşlemi Sil" : "Delete Transaction"),
            content: Text(isTr
                ? "Bu işlemi silmek istediğinize emin misiniz?"
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
        ) ??
        false;

    if (!mounted) return;

    if (confirmDelete) {
      final db = await _dbHelper.database;
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
      _loadTransactions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr ? "İşlem silindi" : "Transaction deleted"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    // Filtreleme Mantığı (Arama ve Tip)
    List<Map<String, dynamic>> filteredTransactions =
        _transactions.where((transaction) {
      final matchesSearch = transaction['description']
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final matchesFilter = _filterType == "All" ||
          transaction['type'].toString().toLowerCase() ==
              _filterType.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();

    // Verileri tarihe göre gruplandırıyoruz
    final groupedData = _groupTransactionsByDate(filteredTransactions);
    final sortedDates =
        groupedData.keys.toList(); // date DESC olduğu için zaten sıralı gelecek

    return Scaffold(
      appBar: AppBar(
        title: Text(
          langProvider.currentLocale.languageCode == 'tr'
              ? "İşlem Geçmişi"
              : "Transaction History",
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterModal(),
          ),
        ],
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        langProvider.currentLocale.languageCode == 'tr'
                            ? 'Henüz işlem bulunmuyor.'
                            : 'No transactions yet.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        String dateKey = sortedDates[index];
                        List<Map<String, dynamic>> dayTransactions =
                            groupedData[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- TARİH BAŞLIĞI ---
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white10
                                  : Colors.grey[200],
                              child: Text(
                                // Tarihi DD.MM.YYYY formatına çeviriyoruz
                                dateKey.split('-').reversed.join('.'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // --- O GÜNE AİT İŞLEMLER ---
                            ...dayTransactions
                                .map((tx) => _buildTransactionCard(tx)),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: langProvider.currentLocale.languageCode == 'tr'
              ? 'İşlemlerde Ara'
              : 'Search Transactions',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ""),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final langProvider = Provider.of<LanguageProvider>(context);
    bool isIncome = transaction['type'].toString().toLowerCase() == 'income' ||
        transaction['type'].toString().toLowerCase() == 'gelir';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      elevation: 2,
      child: Dismissible(
        key: Key(transaction['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          alignment: Alignment.centerRight,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          await _deleteTransaction(transaction['id']);
          return false;
        },
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            transaction['description'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            _getTranslatedCategory(transaction['category'], langProvider),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: Text(
            "${langProvider.currencySymbol}${transaction['amount'].toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          onTap: () => _showTransactionActions(context, transaction),
        ),
      ),
    );
  }

  String _getTranslatedCategory(String category, LanguageProvider lang) {
    if (lang.currentLocale.languageCode != 'tr') return category;
    switch (category) {
      case 'Food':
        return 'Gıda';
      case 'Transport':
        return 'Ulaşım';
      case 'Shopping':
        return 'Alışveriş';
      case 'Bills':
        return 'Faturalar';
      default:
        return 'Diğer';
    }
  }

  void _showTransactionActions(
      BuildContext context, Map<String, dynamic> transaction) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isTr = langProvider.currentLocale.languageCode == 'tr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTr ? "İşlem Seçenekleri" : "Transaction Actions"),
        content:
            Text(isTr ? "Ne yapmak istersiniz?" : "What would you like to do?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editTransaction(transaction);
            },
            child: Text(isTr ? "Düzenle" : "Edit"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransaction(transaction['id']);
            },
            child: Text(isTr ? "Sil" : "Delete",
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editTransaction(Map<String, dynamic> transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          transaction: transaction,
          userId: widget.userId,
        ),
      ),
    );
    if (result == true) _loadTransactions();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final langProvider = Provider.of<LanguageProvider>(context);
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                langProvider.currentLocale.languageCode == 'tr'
                    ? "İşlemleri Filtrele"
                    : "Filter Transactions",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _filterType,
                decoration: InputDecoration(
                  labelText: langProvider.currentLocale.languageCode == 'tr'
                      ? "İşlem Türü"
                      : "Transaction Type",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: ["All", "Income", "Expense"].map((type) {
                  String label = type;
                  if (langProvider.currentLocale.languageCode == 'tr') {
                    if (type == "All") {
                      label = "Hepsi";
                    } else if (type == "Income") {
                      label = "Gelir";
                    } else {
                      label = "Gider";
                    }
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (value) => setState(() => _filterType = value!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(langProvider.currentLocale.languageCode == 'tr'
                      ? "Filtreleri Uygula"
                      : "Apply Filters"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
