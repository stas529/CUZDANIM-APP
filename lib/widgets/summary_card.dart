import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Card yerine Container kullanıyoruz çünkü dekorasyon üzerinde tam kontrol sağlar
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        // 1. KART RENGİ: AppBar'ın koyu lacivertiyle uyumlu Midnight Navy
        color: isDark ? const Color(0xFF1A2226) : Colors.white,

        borderRadius: BorderRadius.circular(16.0),

        // 2. KARTIN KENARLIĞI: AppBar turkuazının ince bir hattı (Karanlıkta kartı patlatır)
        border: Border.all(
          color: isDark
              ? const Color(0xFF006064).withAlpha(100)
              : Colors.grey.withAlpha(40),
          width: 1.2,
        ),

        // 3. GÖLGE: Dark mode'da turkuaz bir derinlik, light mode'da yumuşak gölge
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF006064).withAlpha(40)
                : Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(40),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        // YAZI RENGİ: Dark mode'da saf beyaz yerine hafif grimsi beyaz (daha lüks durur)
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            color, // Senin özel yeşil/kırmızı/turkuaz renklerin
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: isDark ? Colors.white38 : Colors.grey),
          ],
        ),
      ),
    );
  }
}
