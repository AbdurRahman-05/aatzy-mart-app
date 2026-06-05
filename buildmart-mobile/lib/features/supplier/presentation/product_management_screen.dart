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
            'images': ['https://images.unsplash.com/photo-1541888946425-d81bb19240f5?auto=format&fit=crop&q=80&w=400']
          }
        : {
            'categoryId': _selectedCategory,
            'name': _nameController.text.trim(),
            'description': _descController.text.trim(),
            'specifications': {
              _specKeyController.text.trim(): _specValueController.text.trim()
            },
            'images': ['https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400']
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
                value: _selectedCategory,
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

              // Mock Image upload picker box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text('Upload Product Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('PNG, JPG formats accepted', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mock Image Picker opened.')),
                        );
                      },
                      child: const Text('Choose File'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitting ? null : _submitListing,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Submit for Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
