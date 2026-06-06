import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String category;
  final String date;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'General',
      date: json['published_at'] != null 
          ? json['published_at'].toString().split('T')[0] 
          : '2026-06-05',
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isLoading = false;
  List<NewsArticle> _newsList = [];
  String? _errorMessage;
  String _selectedMaterialTab = 'Cement';

  final Map<String, List<double>> _trendData = {
    'Cement': [440, 435, 430, 422, 420],
    'Steel': [56000, 56500, 57200, 57800, 58000],
    'Bricks': [8.2, 8.1, 8.3, 8.5, 8.6],
  };

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final res = await api.get('/buyer/news');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['news'] ?? [];
        setState(() {
          _newsList = list.map((item) => NewsArticle.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Offline mode. Showing cached market news.';
        _newsList = _getFallbackNews();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<NewsArticle> _getFallbackNews() {
    return [
      NewsArticle(
        id: '1',
        title: 'Steel prices surge 5% in Indian retail markets',
        content: 'Retail prices for TMT steel rebars have surged across major metro hubs due to increased raw iron ore costs and seasonal infrastructure spikes.',
        category: 'Steel',
        date: '2026-06-05',
      ),
      NewsArticle(
        id: '2',
        title: 'Monsoon season prompts cement price reductions',
        content: 'In anticipation of the construction slowdown during heavy rains, top manufacturers like UltraTech and ACC have revised rates downward.',
        category: 'Cement',
        date: '2026-06-04',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('B2B Construction News'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Material Pricing Index chart simulator
                  Text(
                    'Live Price Trend Index',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text('Visual price movement tracker of key construction commodities.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Tabs selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _trendData.keys.map((mat) {
                            final isSelected = _selectedMaterialTab == mat;
                            return ChoiceChip(
                              label: Text(mat),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedMaterialTab = mat);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        // Simulated Chart bars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _trendData[_selectedMaterialTab]!.asMap().entries.map((entry) {
                            final val = entry.value;
                            final list = _trendData[_selectedMaterialTab]!;
                            final maxVal = list.reduce((a, b) => a > b ? a : b);
                            final heightPercent = (val / maxVal) * 100;

                            return Column(
                              children: [
                                Text(
                                  _selectedMaterialTab == 'Steel' 
                                      ? '₹${(val / 1000).toStringAsFixed(1)}k' 
                                      : '₹${val.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 32,
                                  height: heightPercent.clamp(20, 100).toDouble(),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.secondary],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('M-${5 - entry.key}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. News Articles List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trending Industry Reports',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _fetchNews,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: Colors.black87), textAlign: TextAlign.center),
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _newsList.length,
                    itemBuilder: (context, index) {
                      final art = _newsList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    art.category.toUpperCase(),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                Text(art.date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              art.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              art.content,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
