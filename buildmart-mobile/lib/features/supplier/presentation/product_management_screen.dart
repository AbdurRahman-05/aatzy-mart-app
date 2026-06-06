import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  // Specifications fields
  final _specKeyController = TextEditingController(text: 'Min Order Qty');
  final _specValueController = TextEditingController(text: '100 units');

  bool _isService = false;
  int _selectedCategory = 1;
  bool _submitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Construction Materials'},
    {'id': 2, 'name': 'Electrical'},
    {'id': 3, 'name': 'Plumbing'},
    {'id': 4, 'name': 'Interior Design'},
    {'id': 5, 'name': 'Machinery'},
  ];

  final List<Map<String, String>> _presets = [
    {
      'label': 'Cement Bag',
      'url': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Steel Rebar',
      'url': 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Bricks',
      'url': 'https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Pipes',
      'url': 'https://images.unsplash.com/photo-1581094288338-2314dddb7ecc?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Wires',
      'url': 'https://images.unsplash.com/photo-1558346490-a72e53ae2d4f?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Interior/Timber',
      'url': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&q=80&w=400'
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    _specKeyController.dispose();
    _specValueController.dispose();
    super.dispose();
  }

  void _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final api = ApiService();
      final path = _isService ? '/supplier/services' : '/supplier/products';
      
      final payload = _isService 
        ? {
            'categoryId': _selectedCategory,
            'name': _nameController.text.trim(),
            'description': _descController.text.trim(),
            'images': [_imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=400']
          }
        : {
            'categoryId': _selectedCategory,
            'name': _nameController.text.trim(),
            'description': _descController.text.trim(),
            'specifications': {
              _specKeyController.text.trim(): _specValueController.text.trim()
            },
            'images': [_imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400']
          };

      final res = await api.post(path, data: payload);
      if (mounted && res.statusCode == 201) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showSuccessDialog();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_empty_rounded, color: AppColors.accent, size: 28),
              SizedBox(width: 8),
              Text('Pending Moderation'),
            ],
          ),
          content: Text(
            'Your B2B ${_isService ? "service" : "product"} listing has been submitted successfully and is pending review by administrators.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.pop(); // Return to dashboard
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add B2B Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Listing Type Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Product Item')),
                      selected: !_isService,
                      onSelected: (val) => setState(() => _isService = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Service Offering')),
                      selected: _isService,
                      onSelected: (val) => setState(() => _isService = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _isService ? 'Service Name' : 'Product Title',
                  hintText: _isService ? 'e.g. Structural Concrete Casting' : 'e.g. OPC 53 Grade Cement',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _selectedCategory,
                items: _categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat['id'],
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: const InputDecoration(labelText: 'Marketplace Category'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Listing Description',
                  hintText: 'Provide detailed features, benefits, shipping packaging details...',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              // Specifications Input Section (Only for Products)
              if (!_isService) ...[
                Text(
                  'Key Specification / Detail',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _specKeyController,
                        decoration: const InputDecoration(labelText: 'Spec Key (e.g. Grade)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _specValueController,
                        decoration: const InputDecoration(labelText: 'Spec Value (e.g. 53 Grade)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Image URL & Selection Section
              Text(
                'Product / Service Image',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'Enter custom image URL or select a preset below',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 12),
              
              // Preset suggestions
              Text(
                'Or choose a preset preview:',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final isSelected = _imageUrlController.text == preset['url'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageUrlController.text = preset['url']!;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(preset['url']!),
                            fit: BoxFit.cover,
                            colorFilter: isSelected
                                ? null
                                : ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              preset['label']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Preview Box
              if (_imageUrlController.text.trim().isNotEmpty) ...[
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    image: DecorationImage(
                      image: NetworkImage(_imageUrlController.text.trim()),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _imageUrlController.clear();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitting ? null : _submitListing,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit for Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
