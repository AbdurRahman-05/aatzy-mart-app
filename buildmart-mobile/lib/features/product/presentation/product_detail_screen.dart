import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isSaved = false;
  bool _isLoading = true;
  Map<String, dynamic>? _product;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final res = await api.get('/buyer/products/${widget.productId}');
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          _product = res.data['product'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load live product details.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = _product;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Product details not found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProductDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final rawSpecs = p['specifications'];
    final Map<String, String> specs = {};
    if (rawSpecs is Map) {
      rawSpecs.forEach((key, value) {
        specs[key.toString()] = value.toString();
      });
    } else {
      specs['Packaging'] = 'Standard B2B Packing';
      specs['Min Order Quantity'] = '100 units';
    }

    final imagesList = p['images'] as List?;
    final images = (imagesList != null && imagesList.isNotEmpty)
        ? imagesList
        : ['https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=600'];

    final double price = p['price_per_unit'] != null ? double.parse(p['price_per_unit'].toString()) : 420.0;
    final String unit = p['unit_type'] ?? 'Bag';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isSaved ? Colors.red : AppColors.textPrimary),
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isSaved ? 'Saved to favorites' : 'Removed from favorites')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(images[index], fit: BoxFit.cover, width: double.infinity);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          p['business_type'] ?? 'Verified Supplier',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p['name'] ?? '',
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rate / Unit display
                  Text(
                    'Estimated Rate: ₹${price.toStringAsFixed(0)} / $unit',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),

                  const SizedBox(height: 12),
                  Text('Product Description', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(p['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),

                  const SizedBox(height: 12),
                  Text('Specifications', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(color: AppColors.border, width: 1, borderRadius: BorderRadius.circular(8)),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                    },
                    children: specs.entries.map((entry) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(entry.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(entry.value, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),

                  const SizedBox(height: 12),
                  Text('Supplier Details', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(p['logo_url'] ?? 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?auto=format&fit=crop&q=80&w=200', width: 52, height: 52, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['company_name'] ?? 'BuildMart Supplier', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(p['supplier_location'] ?? 'All India', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                ],
                              ),
                              if (p['website'] != null) ...[
                                const SizedBox(height: 4),
                                Text(p['website'], style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contacting ${p['company_name'] ?? "supplier"} via phone...')),
                  );
                },
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: const Text('Call Supplier'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/inquiry-form',
                    extra: {
                      'supplierId': p['supplier_id'],
                      'productId': p['id'],
                      'productName': p['name'],
                      'productImage': images[0]
                    },
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send B2B Inquiry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
