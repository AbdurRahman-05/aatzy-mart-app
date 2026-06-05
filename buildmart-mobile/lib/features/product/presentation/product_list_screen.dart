import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class ProductItem {
  final String id;
  final String name;
  final String supplierName;
  final String location;
  final String imageUrl;
  final String description;
  final double pricePerUnit;
  final String unitType;

  ProductItem({
    required this.id,
    required this.name,
    required this.supplierName,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.pricePerUnit,
    required this.unitType,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List?;
    final imgUrl = (imagesList != null && imagesList.isNotEmpty)
        ? imagesList[0] as String
        : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400';

    return ProductItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      supplierName: json['company_name'] ?? json['supplierName'] ?? 'BuildMart Supplier',
      location: json['supplier_location'] ?? json['location'] ?? 'All India',
      imageUrl: imgUrl,
      description: json['description'] ?? '',
      pricePerUnit: (json['price_per_unit'] != null) ? double.parse(json['price_per_unit'].toString()) : 420.0,
      unitType: json['unit_type'] ?? 'Bag',
    );
  }
}

class ProductListScreen extends StatefulWidget {
  final String? categoryId;

  const ProductListScreen({super.key, this.categoryId});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedLocation = 'All India';
  String _selectedType = 'All';
  
  bool _isLoading = false;
  List<ProductItem> _products = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      
      final Map<String, dynamic> queryParams = {};
      if (widget.categoryId != null) {
        queryParams['categoryId'] = widget.categoryId;
      }
      if (_searchQuery.isNotEmpty) {
        queryParams['query'] = _searchQuery;
      }
      if (_selectedLocation != 'All India') {
        queryParams['location'] = _selectedLocation;
      }
      if (_selectedType != 'All') {
        queryParams['supplierType'] = _selectedType;
      }

      final res = await api.get('/buyer/products', queryParameters: queryParams);
      
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['products'] ?? [];
        setState(() {
          _products = list.map((item) => ProductItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection Error: Unable to fetch products.';
        _products = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<ProductItem> _getFallbackProducts() {
    return [
      ProductItem(
        id: 'f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6',
        name: 'UltraTech Premium Cement OPC 53 Grade',
        supplierName: 'UltraTech Build Solutions',
        location: 'Mumbai, Maharashtra',
        imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400',
        description: 'OPC 53 Grade high-durability structural cement.',
        pricePerUnit: 420.0,
        unitType: 'Bag',
      ),
      ProductItem(
        id: 'a7a7a7a7-a7a7-a7a7-a7a7-a7a7a7a7a7a7',
        name: 'Reinforced Steel Rebars TMT Fe 550D',
        supplierName: 'UltraTech Build Solutions',
        location: 'Mumbai, Maharashtra',
        imageUrl: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=400',
        description: 'High-ductility TMT rebars.',
        pricePerUnit: 58000.0,
        unitType: 'Metric Ton',
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
        title: const Text('B2B Sourcing Products'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val);
                    _fetchProducts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Press enter to search...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    fillColor: AppColors.background,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterDropdown(
                        'Location: $_selectedLocation',
                        ['All India', 'Mumbai', 'Ahmedabad', 'Kolkata', 'Bengaluru'],
                        (val) {
                          setState(() => _selectedLocation = val);
                          _fetchProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        'Supplier Type: $_selectedType',
                        ['All', 'Manufacturer', 'Wholesaler', 'Distributor'],
                        (val) {
                          setState(() => _selectedType = val);
                          _fetchProducts();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          if (_errorMessage != null)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No approved B2B products found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final item = _products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(item.imageUrl, width: 95, height: 95, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.supplierName,
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item.pricePerUnit.toStringAsFixed(0)} / ${item.unitType}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.secondary),
                                            const SizedBox(width: 4),
                                            Text(item.location, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () => context.push('/products/${item.id}'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('View Details', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options, ValueChanged<String> onChanged) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) {
        return options.map((opt) {
          return PopupMenuItem(value: opt, child: Text(opt));
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(50),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
