import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cuzdanim_app/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:cuzdanim_app/language_provider.dart';

class ReportsScreen extends StatefulWidget {
  final int userId;
  const ReportsScreen({super.key, required this.userId});

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<Map<String, dynamic>> _reportsFuture;
  List<String> selectedCategories = [];
  List<String> allCategories = [
    'Food',
    'Bills',
    'Transport',
    'Shopping',
    'Other'
  ];
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String selectedType = 'Gider';

  // Controller'ı burada tanımlıyoruz ki sayfa açık kaldığı sürece yaşasın
  final ScrollController horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadData(widget.userId);

    // Debug logunu buraya ekleyelim
    horizontalScrollController.addListener(() {
      debugPrint("KAYDIRMA POZİSYONU: ${horizontalScrollController.offset}");
    });
  }

  @override
  void dispose() {
    horizontalScrollController.dispose(); // Belleği temizle
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadData(int userId) async {
    try {
      final db = await _dbHelper.database;
      String whereClause = "userId = ?";
      List<dynamic> whereArgs = [userId];

      if (selectedStartDate != null && selectedEndDate != null) {
        whereClause += " AND date BETWEEN ? AND ?";
        whereArgs.add(selectedStartDate!.toIso8601String().substring(0, 10));
        whereArgs.add(selectedEndDate!.toIso8601String().substring(0, 10));
      }

      final transactions = await db.query('transactions',
          where: whereClause, whereArgs: whereArgs);

      if (transactions.isEmpty) {
        return {
          "categorySpending": <String, double>{},
          "dailyData": <String, dynamic>{}
        };
      }

      Map<String, double> categoryData = {};
      Map<String, Map<String, double>> dailyData = {};
      String currentFilter = selectedType.trim().toLowerCase();

      for (var transaction in transactions) {
        double amount =
            double.tryParse(transaction['amount'].toString()) ?? 0.0;
        String dbType =
            (transaction['type'] ?? "").toString().trim().toLowerCase();
        String category = (transaction['category'] ?? "Other").toString();
        String dateString = (transaction['date'] ?? "").toString();

        bool isTypeMatch = false;

        if (currentFilter.contains('gelir') ||
            currentFilter.contains('income')) {
          if (dbType.contains('gelir') || dbType.contains('income')) {
            isTypeMatch = true;
          }
        } else if (currentFilter.contains('gider') ||
            currentFilter.contains('expense')) {
          if (dbType.contains('gider') || dbType.contains('expense')) {
            isTypeMatch = true;
          }
        }

        bool isCategoryMatch =
            selectedCategories.isEmpty || selectedCategories.contains(category);
        if (isTypeMatch && isCategoryMatch) {
          categoryData[category] = (categoryData[category] ?? 0) + amount;
        }

        if (dateString.length >= 10) {
          String dayKey = "01";
          try {
            if (dateString.contains('-')) {
              dayKey = dateString.split('-').last.substring(0, 2);
            } else if (dateString.contains('.')) {
              dayKey = dateString.split('.').first.padLeft(2, '0');
            }
          } catch (e) {
            dayKey = "01";
          }

          if (!dailyData.containsKey(dayKey)) {
            dailyData[dayKey] = {'income': 0.0, 'expense': 0.0};
          }

          if (dbType.contains('gelir') || dbType.contains('income')) {
            dailyData[dayKey]!['income'] =
                (dailyData[dayKey]!['income'] ?? 0) + amount;
          } else {
            dailyData[dayKey]!['expense'] =
                (dailyData[dayKey]!['expense'] ?? 0) + amount;
          }
        }
      }
      return {"categorySpending": categoryData, "dailyData": dailyData};
    } catch (e) {
      debugPrint("HATA _loadData: $e");
      return {"categorySpending": {}, "dailyData": {}};
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFFFFDF5),
      appBar: AppBar(
        title: Text(
          langProvider.currentLocale.languageCode == 'tr'
              ? 'Raporlar'
              : 'Reports',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF11606F), Color(0xFF5AE7E7)]),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final categorySpending = Map<String, double>.from(
              snapshot.data?["categorySpending"] ?? {});
          final dailyDataMap =
              Map<String, dynamic>.from(snapshot.data?["dailyData"] ?? {});

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 20),
                _buildChartCard(
                  context,
                  title: langProvider.currentLocale.languageCode == 'tr'
                      ? "Kategori Analizi"
                      : "Category Analysis",
                  child: categorySpending.isEmpty
                      ? _buildNoDataWidget(context)
                      : Column(
                          children: [
                            SizedBox(
                                height: 250,
                                child: PieChart(PieChartData(
                                  sections: categorySpending.entries
                                      .map((e) => PieChartSectionData(
                                            value: e.value,
                                            title:
                                                "${_getTranslatedCategory(e.key, langProvider)}\n${e.value.toStringAsFixed(0)}",
                                            radius: 50,
                                            color: _getChartColor(e.key),
                                            titleStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ))
                                      .toList(),
                                ))),
                            _buildLegend(categorySpending),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                _buildChartCard(
                  context,
                  title: langProvider.currentLocale.languageCode == 'tr'
                      ? "Günlük Trend"
                      : "Daily Trend",
                  child: dailyDataMap.isEmpty
                      ? _buildNoDataWidget(context)
                      : _buildDailyBarChart(dailyDataMap),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyBarChart(Map<String, dynamic> dailyData) {
    var sortedDays = dailyData.keys.toList()..sort();
    double maxVal = 500.0;
    for (var val in dailyData.values) {
      double inc = (val['income'] as num?)?.toDouble() ?? 0.0;
      double exp = (val['expense'] as num?)?.toDouble() ?? 0.0;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    double finalMaxY = (maxVal * 1.2).clamp(500.0, 100000.0);

    return Scrollbar(
      controller: horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: horizontalScrollController,
        scrollDirection: Axis.horizontal,
        reverse: false, // Eğer ters gelirse true yaparsın
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        child: Container(
          // Genişliği 120 yapıyoruz ki grafik ferahlasın, noktalar net görünsün
          width: (sortedDays.length * 60.0)
              .clamp(MediaQuery.of(context).size.width, 3000.0),
          height: 380,
          padding: const EdgeInsets.only(bottom: 25, right: 20, top: 20),
          child: Stack(
            // İŞTE SİHİR BURADA: Çubuk ve Çizgi üst üste!
            children: [
              // 1. KATMAN: SÜTUNLAR (BARLAR)
              BarChart(
                BarChartData(
                  maxY: finalMaxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (val, meta) {
                        int i = val.toInt();
                        if (i < 0 || i >= sortedDays.length) {
                          return const SizedBox();
                        }
                        return SideTitleWidget(
                            meta: meta,
                            child: Text(sortedDays[i],
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)));
                      },
                    )),
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 45)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(sortedDays.length, (index) {
                    String day = sortedDays[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                            toY: dailyData[day]['income'],
                            color: Colors.green,
                            width: 14,
                            borderRadius: BorderRadius.zero),
                        BarChartRodData(
                            toY: dailyData[day]['expense'],
                            color: Colors.red,
                            width: 14,
                            borderRadius: BorderRadius.zero),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final langProvider = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2226) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? const Color(0xFF006B76).withAlpha(180)
                : Colors.grey.withAlpha(60),
            width: 1.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  langProvider.currentLocale.languageCode == 'tr'
                      ? "Filtreler"
                      : "Filters",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedType = 'Gider';
                    selectedStartDate = null;
                    selectedEndDate = null;
                    selectedCategories = [];
                    _reportsFuture = _loadData(widget.userId);
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(langProvider.currentLocale.languageCode == 'tr'
                    ? "Temizle"
                    : "Clear"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTypeFilter(),
          const SizedBox(height: 12),
          _buildDateRangeFilter(),
          const SizedBox(height: 12),
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return DropdownButtonFormField<String>(
      initialValue: selectedType,
      decoration: InputDecoration(
          labelText:
              langProvider.currentLocale.languageCode == 'tr' ? "Tür" : "Type",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      items: [
        DropdownMenuItem(
            value: 'Gider',
            child: Text(langProvider.currentLocale.languageCode == 'tr'
                ? "Gider"
                : "Expense")),
        DropdownMenuItem(
            value: 'Gelir',
            child: Text(langProvider.currentLocale.languageCode == 'tr'
                ? "Gelir"
                : "Income")),
      ],
      onChanged: (value) {
        setState(() {
          selectedType = value!;
          _reportsFuture = _loadData(widget.userId);
        });
      },
    );
  }

  Widget _buildDateRangeFilter() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Row(children: [
      Expanded(
          child: TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now());
                if (date != null) {
                  setState(() {
                    selectedStartDate = date;
                    _reportsFuture = _loadData(widget.userId);
                  });
                }
              },
              child: Text(selectedStartDate == null
                  ? (langProvider.currentLocale.languageCode == 'tr'
                      ? "Başlangıç Tarihi"
                      : "Start Date")
                  : selectedStartDate!.toIso8601String().substring(0, 10)))),
      const SizedBox(width: 8),
      Expanded(
          child: TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now());
                if (date != null) {
                  setState(() {
                    selectedEndDate = date;
                    _reportsFuture = _loadData(widget.userId);
                  });
                }
              },
              child: Text(selectedEndDate == null
                  ? (langProvider.currentLocale.languageCode == 'tr'
                      ? "Bitiş Tarihi"
                      : "End Date")
                  : selectedEndDate!.toIso8601String().substring(0, 10)))),
    ]);
  }

  Widget _buildCategoryFilter() {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          langProvider.currentLocale.languageCode == 'tr'
              ? "Kategoriye Göre Filtrele"
              : "Filter by Category",
          style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          children: allCategories.map((category) {
            return FilterChip(
              label: Text(_getTranslatedCategory(category, langProvider)),
              selected: selectedCategories.contains(category),
              onSelected: (val) {
                setState(() {
                  val
                      ? selectedCategories.add(category)
                      : selectedCategories.remove(category);
                  _reportsFuture = _loadData(widget.userId);
                });
              },
            );
          }).toList()),
    ]);
  }

  String _getTranslatedCategory(
      String category, LanguageProvider langProvider) {
    if (langProvider.currentLocale.languageCode != 'tr') return category;
    Map<String, String> tr = {
      'Food': 'Gıda',
      'Bills': 'Faturalar',
      'Transport': 'Ulaşım',
      'Shopping': 'Alışveriş',
      'Other': 'Diğer'
    };
    return tr[category] ?? category;
  }

  Widget _buildChartCard(BuildContext context,
      {required String title, required Widget child}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2226) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(40))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        child
      ]),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final bool isTr = langProvider.currentLocale.languageCode == 'tr';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Sadece içeriği kadar yer kaplasın
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Senin Photoshop'ta tertemiz yaptığın o masum kedi
            Image.asset(
              'assets/images/PS.png',
              height: 120, // Grafik alanına cuk diye oturması için bu boy ideal
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 15),
            Text(
              isTr ? "Veri bulunamadı" : "No data found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors
                    .grey[600], // Hafif gri yaparak kediyi ön plana çıkardık
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Wrap(
        spacing: 8,
        children: data.entries
            .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 12, height: 12, color: _getChartColor(e.key)),
                  const SizedBox(width: 4),
                  Text(_getTranslatedCategory(e.key, langProvider),
                      style: const TextStyle(fontSize: 12)),
                ]))
            .toList());
  }

  Color _getChartColor(String category) {
    switch (category) {
      case 'Shopping':
        return const Color(0xFFED2024);
      case 'Food':
        return const Color(0xFFFEBD11);
      case 'Transport':
        return const Color(0xFF278E43);
      case 'Bills':
        return const Color.fromARGB(255, 150, 31, 201);
      case 'Other':
        return const Color.fromARGB(255, 42, 142, 219);
      default:
        return const Color.fromARGB(255, 100, 23, 23);
    }
  }
}
