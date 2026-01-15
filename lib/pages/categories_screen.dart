import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuzdanim_app/language_provider.dart';
import 'package:cuzdanim_app/database/database_helper.dart';

class CategoriesScreen extends StatefulWidget {
  final int userId;
  // userId initialized hatası burada çözüldü:
  const CategoriesScreen({super.key, required this.userId});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  Future<void> _refreshCategories() async {
    setState(() => _isLoading = true);
    // getCategories artık widget.userId ile çalışıyor
    final data = await _dbHelper.getCategories(widget.userId);
    setState(() {
      _categories = data.where((cat) {
        final String name = cat['name'] ?? '';
        return name != 'Food' &&
            name != 'Transport' &&
            name != 'Shopping' &&
            name != 'Bills' &&
            name != 'Other';
      }).toList();

      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isTr = langProvider.currentLocale.languageCode == 'tr';
    final TextEditingController localController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTr ? "Yeni Kategori Ekle" : "Add New Category",
          style: const TextStyle(
              color: Color(0xFF11606F), fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: localController,
          decoration: InputDecoration(
            hintText: isTr
                ? "Kategori adı (Örn: Eğlence)"
                : "Category name (Ex: Entertainment)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF60B2B5), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTr ? "İptal" : "Cancel",
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF60B2B5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = localController.text.trim();
              if (name.isNotEmpty) {
                // insertCategory'ye widget.userId eklendi
                await _dbHelper.insertCategory(name, 'Gider', widget.userId);

                if (!mounted) return;
                Navigator.pop(context);
                _refreshCategories();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        isTr ? "Kategori eklendi! ✅" : "Category added! ✅"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(isTr ? "Ekle" : "Add",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final bool isTr = langProvider.currentLocale.languageCode == 'tr';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isTr ? "Kategorilerim" : "My Categories",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF60B2B5),
                Color(0xFF46969B),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Text(
                    isTr
                        ? "Henüz kategori eklemediniz."
                        : "No categories added yet.",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF11606F),
                          child: Text(
                            cat['name'] != null && cat['name'].isNotEmpty
                                ? cat['name'][0].toUpperCase()
                                : "?",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          cat['name'] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(isTr
                                    ? "Kategoriyi Sil"
                                    : "Delete Category"),
                                content: Text(isTr
                                    ? "Bu kategoriyi silmek istediğinize emin misiniz?"
                                    : "Are you sure you want to delete this category?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(isTr ? "İptal" : "Cancel")),
                                  TextButton(
                                    onPressed: () async {
                                      await _dbHelper.deleteCategory(cat['id']);
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      _refreshCategories();
                                    },
                                    child: Text(
                                      isTr ? "Sil" : "Delete",
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF11606F),
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
