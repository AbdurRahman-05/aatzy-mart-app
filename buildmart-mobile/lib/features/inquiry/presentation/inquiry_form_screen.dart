import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class InquiryFormScreen extends StatefulWidget {
  final String supplierId;
  final String? productId;
  final String? productName;
  final String? productImage;
  final String? serviceId;
  final String? serviceName;

  const InquiryFormScreen({
    super.key,
    required this.supplierId,
    this.productId,
    this.productName,
    this.productImage,
    this.serviceId,
    this.serviceName,
  });

  @override
  State<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends State<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '100');
  final _locController = TextEditingController(text: 'Delhi NCR');
  String _selectedUnit = 'Pieces';
  bool _submitting = false;

  final List<String> _units = ['Pieces', 'Bags', 'Metric Tons', 'Meters', 'Liters', 'Cubic Meters'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.productName != null
          ? 'Requirement for ${widget.productName}'
          : widget.serviceName != null
              ? 'Request for ${widget.serviceName}'
              : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _locController.dispose();
    super.dispose();
  }

  void _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final api = ApiService();
      // Send B2B Lead Inquiry request to backend API
      final res = await api.post('/buyer/inquiries', data: {
        'supplierId': widget.supplierId,
        'productId': widget.productId,
        'serviceId': widget.serviceId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'quantity': double.parse(_qtyController.text),
        'unit': _selectedUnit,
        'location': _locController.text.trim(),
        'images': widget.productImage != null ? [widget.productImage] : []
      });

      if (mounted && res.statusCode == 201) {
        _showSuccessDialog();
      }
    } catch (e) {
      // offline fallback popup anyway for demo
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
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Inquiry Submitted!'),
            ],
          ),
          content: const Text(
            'Your requirement request has been dispatched. The supplier will review the details and get back to you shortly.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop(); // Close dialog
                context.go('/'); // Navigate back home
              },
              child: const Text('Return to Home'),
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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create B2B Inquiry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Preview Row if listing attached
              if (widget.productName != null && widget.productImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.productImage!, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('INQUIRY TARGET PRODUCT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            const SizedBox(height: 2),
                            Text(widget.productName!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                'Requirement Details',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Requirement Title'),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Detailed Description',
                  hintText: 'Describe concrete strength grade, sizing, delivery location details, etc...',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please describe your request details' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity Needed'),
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Enter valid amount' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      items: _units.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locController,
                decoration: const InputDecoration(labelText: 'Preferred Delivery Location'),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 24),

              // Simulated Image Upload section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attach Images (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('Add blueprints or material photos', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Simulated Image Picked successfully.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitting ? null : _submitInquiry,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit B2B Inquiry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
