import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../../core/widgets/custom_image.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final String imageUrl;

  CategoryItem(this.id, this.name, this.icon, this.imageUrl);

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    IconData iconData = Icons.construction_rounded;
    final String nameLower = (json['name'] ?? '').toString().toLowerCase();
    if (nameLower.contains('elect')) {
      iconData = Icons.bolt_rounded;
    } else if (nameLower.contains('plumb')) {
      iconData = Icons.plumbing_rounded;
    } else if (nameLower.contains('paint')) {
      iconData = Icons.format_paint_rounded;
    } else if (nameLower.contains('solar') || nameLower.contains('energy')) {
      iconData = Icons.solar_power_rounded;
    } else if (nameLower.contains('furnit') || nameLower.contains('wood')) {
      iconData = Icons.chair_rounded;
    } else if (nameLower.contains('interior') || nameLower.contains('design')) {
      iconData = Icons.weekend_rounded;
    } else if (nameLower.contains('machin') || nameLower.contains('tool')) {
      iconData = Icons.precision_manufacturing_rounded;
    } else if (nameLower.contains('hardw') || nameLower.contains('cement') || nameLower.contains('steel')) {
      iconData = Icons.build_outlined;
    }

    return CategoryItem(
      json['id']?.toString() ?? '',
      json['name'] ?? 'Category',
      iconData,
      json['image_url'] ?? 'https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=200',
    );
  }
}

class HomeProductItem {
  final String id;
  final String name;
  final String supplier;
  final String location;
  final String imageUrl;
  final double pricePerUnit;
  final String unitType;

  HomeProductItem({
    required this.id,
    required this.name,
    required this.supplier,
    required this.location,
    required this.imageUrl,
    required this.pricePerUnit,
    required this.unitType,
  });

  factory HomeProductItem.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List?;
    final imgUrl = (imagesList != null && imagesList.isNotEmpty)
        ? imagesList[0] as String
        : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=300';

    return HomeProductItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      supplier: json['company_name'] ?? 'BuildMart Supplier',
      location: json['supplier_location'] ?? 'All India',
      imageUrl: imgUrl,
      pricePerUnit: (json['price_per_unit'] != null) ? double.parse(json['price_per_unit'].toString()) : 420.0,
      unitType: json['unit_type'] ?? 'Bag',
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  List<CategoryItem> _categories = [];
  List<HomeProductItem> _featuredProducts = [];

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&q=80&w=800',
    'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchFeaturedProducts();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _bannerImages.length;
        });
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final api = ApiService();
      final res = await api.get('/buyer/categories');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['categories'] ?? [];
        setState(() {
          _categories = list.map((item) => CategoryItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _categories = _getFallbackCategories();
      });
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  List<CategoryItem> _getFallbackCategories() {
    return [
      CategoryItem('1', 'Construction', Icons.architecture_rounded, 'https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=200'),
      CategoryItem('2', 'Electrical', Icons.bolt_rounded, 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&q=80&w=200'),
      CategoryItem('3', 'Plumbing', Icons.plumbing_rounded, 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=200'),
      CategoryItem('4', 'Interior', Icons.weekend_rounded, 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&q=80&w=200'),
      CategoryItem('5', 'Machinery', Icons.precision_manufacturing_rounded, 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=200'),
    ];
  }

  Future<void> _fetchFeaturedProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final api = ApiService();
      final res = await api.get('/buyer/products?limit=5');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['products'] ?? [];
        setState(() {
          _featuredProducts = list.map((item) => HomeProductItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _featuredProducts = _getFallbackProducts();
      });
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  List<HomeProductItem> _getFallbackProducts() {
    return [
      HomeProductItem(
        id: 'f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6',
        name: 'UltraTech Cement OPC 53',
        supplier: 'UltraTech Solutions',
        location: 'Mumbai, MH',
        imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=300',
        pricePerUnit: 420.0,
        unitType: 'Bag',
      ),
      HomeProductItem(
        id: 'a7a7a7a7-a7a7-a7a7-a7a7-a7a7a7a7a7a7',
        name: 'TMT Steel Rebars Fe 550D',
        supplier: 'UltraTech Solutions',
        location: 'Mumbai, MH',
        imageUrl: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=300',
        pricePerUnit: 58000.0,
        unitType: 'Metric Ton',
      ),
    ];
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final String buyerName = authState.user?.name ?? 'Guest';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi, $buyerName 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'BuildMart',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_rounded, color: AppColors.primary),
            onPressed: () => context.push('/my-inquiries'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Premium Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onSubmitted: (query) {
                          context.push('/products?query=$query');
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search products, services, or suppliers...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                      onPressed: () => context.push('/products'),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Sliding Hero Banner
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _bannerImages.length,
                onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(_bannerImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Premium Building Materials',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get bulk pricing inquiries from verified suppliers',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bannerImages.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index ? AppColors.primary : AppColors.border,
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            // Premium B2B News Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => context.push('/news'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F4C81), Color(0xFF00AEEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.newspaper_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Construction Material News & Price Trends',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track daily steel, cement fluctuations & policy news.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Categories Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse B2B Categories',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingCategories
                      ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            return GestureDetector(
                              onTap: () {
                                context.push('/products?categoryId=${cat.id}');
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border, width: 1),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    child: Icon(cat.icon, color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            // 4. Horizontal Featured Products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Featured Products', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => context.push('/products'),
                    child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            _isLoadingProducts
                ? const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _featuredProducts.length,
                      itemBuilder: (context, index) {
                        final item = _featuredProducts[index];
                        return _buildProductCard(
                          context,
                          item.id,
                          item.name,
                          item.supplier,
                          item.location,
                          item.imageUrl,
                          item.pricePerUnit,
                          item.unitType,
                        );
                      },
                    ),
                  ),

            // 5. Featured Suppliers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('Premium Suppliers', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildSupplierCard('UltraTech Build Solutions', 'Manufacturer', 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?auto=format&fit=crop&q=80&w=150'),
                  _buildSupplierCard('Supreme Pipes & Sanitary', 'Distributor', 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&q=80&w=150'),
                  _buildSupplierCard('Apex Machinery Ltd', 'Exporter', 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=150'),
                ],
              ),
            ),

            // 6. Trending Searches
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trending B2B Searches', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTrendTag(context, 'OPC 53 Cement'),
                      _buildTrendTag(context, 'TMT Rebars'),
                      _buildTrendTag(context, 'PVC Pipes'),
                      _buildTrendTag(context, 'Concrete Mixers'),
                      _buildTrendTag(context, 'Solar Panels'),
                      _buildTrendTag(context, 'Office Chairs'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String id, String name, String supplier, String location, String img, double price, String unit) {
    return GestureDetector(
      onTap: () => context.push('/products/$id'),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: BuildMartImage(imageUrl: img, height: 95, width: 150, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supplier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${price.toStringAsFixed(0)} / $unit',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 10, color: AppColors.secondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard(String name, String type, String img) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BuildMartImage(imageUrl: img, width: 44, height: 44, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendTag(BuildContext context, String tag) {
    return ActionChip(
      label: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50), side: const BorderSide(color: AppColors.border)),
      onPressed: () {
        context.push('/products?query=$tag');
      },
    );
  }
}
