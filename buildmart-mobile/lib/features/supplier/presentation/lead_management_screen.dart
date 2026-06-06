import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class LeadItem {
  final String id;
  final String date;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String requirementTitle;
  final String requirementDesc;
  final String quantity;
  final double quantityVal;
  final String unit;
  final String location;
  String status; // New, Viewed, Contacted, Closed
  double? quotedPrice;
  String deliveryStatus; // Pending, Packed, Dispatched, Delivered
  double gstPercent;

  LeadItem({
    required this.id,
    required this.date,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.requirementTitle,
    required this.requirementDesc,
    required this.quantity,
    required this.quantityVal,
    required this.unit,
    required this.location,
    required this.status,
    this.quotedPrice,
    required this.deliveryStatus,
    required this.gstPercent,
  });

  factory LeadItem.fromJson(Map<String, dynamic> json) {
    final qtyVal = json['quantity'] != null ? double.parse(json['quantity'].toString()) : 100.0;
    final unitStr = json['unit'] ?? 'Units';
    return LeadItem(
      id: json['id'] ?? '',
      date: json['created_at'] != null 
          ? json['created_at'].toString().split('T')[0] 
          : '2026-06-05',
      buyerName: json['buyer_name'] ?? 'Demo Buyer',
      buyerPhone: json['buyer_phone'] ?? '+91 99999 99999',
      buyerEmail: json['buyer_email'] ?? 'buyer@buildmart.com',
      requirementTitle: json['title'] ?? json['product_name'] ?? 'Material Requirement',
      requirementDesc: json['description'] ?? 'Bulk order request details.',
      quantity: '$qtyVal $unitStr',
      quantityVal: qtyVal,
      unit: unitStr,
      location: json['location'] ?? 'All India',
      status: json['status'] ?? 'New',
      quotedPrice: json['quoted_price'] != null ? double.parse(json['quoted_price'].toString()) : null,
      deliveryStatus: json['delivery_status'] ?? 'Pending',
      gstPercent: json['gst_percent'] != null ? double.parse(json['gst_percent'].toString()) : 18.0,
    );
  }
}

class LeadManagementScreen extends StatefulWidget {
  const LeadManagementScreen({super.key});

  @override
  State<LeadManagementScreen> createState() => _LeadManagementScreenState();
}

class _LeadManagementScreenState extends State<LeadManagementScreen> {
  bool _isLoading = false;
  List<LeadItem> _leads = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final res = await api.get('/supplier/leads');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['leads'] ?? [];
        setState(() {
          _leads = list.map((item) => LeadItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection Error: Unable to fetch live leads.';
        _leads = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _updateLeadStatus(
    LeadItem lead,
    String newStatus,
    String notes, {
    double? quotedPrice,
    String? deliveryStatus,
    double? gstPercent,
  }) async {
    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final res = await api.put('/supplier/leads/${lead.id}/status', data: {
        'status': newStatus,
        'notes': notes,
        'quotedPrice': quotedPrice,
        'deliveryStatus': deliveryStatus,
        'gstPercent': gstPercent,
      });

      if (res.statusCode == 200) {
        setState(() {
          lead.status = newStatus;
          if (quotedPrice != null) lead.quotedPrice = quotedPrice;
          if (deliveryStatus != null) lead.deliveryStatus = deliveryStatus;
          if (gstPercent != null) lead.gstPercent = gstPercent;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lead status updated to $newStatus successfully!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        lead.status = newStatus;
        if (quotedPrice != null) lead.quotedPrice = quotedPrice;
        if (deliveryStatus != null) lead.deliveryStatus = deliveryStatus;
        if (gstPercent != null) lead.gstPercent = gstPercent;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline simulation: status & quotes updated locally.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blueAccent;
      case 'Viewed':
        return Colors.orangeAccent;
      case 'Contacted':
        return AppColors.secondary;
      case 'Closed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showStatusUpdateDialog(LeadItem lead) {
    String selectedStatus = lead.status;
    String selectedDeliveryStatus = lead.deliveryStatus;
    double selectedGstPercent = lead.gstPercent;
    
    final notesController = TextEditingController(text: 'Updated status to $selectedStatus');
    final quotedPriceController = TextEditingController(text: lead.quotedPrice?.toString() ?? '410.00');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isClosed = selectedStatus == 'Closed';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Update Lead & Quote Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Select Status'),
                      items: ['New', 'Viewed', 'Contacted', 'Closed'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedStatus = val;
                            notesController.text = 'Updated status to $val';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    if (isClosed) ...[
                      TextFormField(
                        controller: quotedPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quoted Rate per Unit (₹)',
                          hintText: 'e.g. 410.00',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDeliveryStatus,
                        decoration: const InputDecoration(labelText: 'Delivery Stage'),
                        items: ['Pending', 'Packed', 'Dispatched', 'Delivered'].map((stage) {
                          return DropdownMenuItem(value: stage, child: Text(stage));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedDeliveryStatus = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<double>(
                        initialValue: selectedGstPercent,
                        decoration: const InputDecoration(labelText: 'GST Percent (%)'),
                        items: [5.0, 12.0, 18.0, 28.0].map((gst) {
                          return DropdownMenuItem(value: gst, child: Text('${gst.toStringAsFixed(0)}%'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedGstPercent = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Timeline Notes',
                        hintText: 'Enter call details or quotation notes...',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final qPrice = double.tryParse(quotedPriceController.text);
                    _updateLeadStatus(
                      lead,
                      selectedStatus,
                      notesController.text.trim(),
                      quotedPrice: qPrice,
                      deliveryStatus: selectedDeliveryStatus,
                      gstPercent: selectedGstPercent,
                    );
                  },
                  child: const Text('Submit Update'),
                ),
              ],
            );
          },
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
        title: const Text('Lead Management Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeads,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    color: Colors.amber.shade100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: Colors.black87), textAlign: TextAlign.center),
                  ),
                Expanded(
                  child: _leads.isEmpty
                      ? const Center(child: Text('No buyer inquiries received yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _leads.length,
                          itemBuilder: (context, index) {
                            final lead = _leads[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'DATE: ${lead.date}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(lead.status).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(50),
                                            border: Border.all(color: _getStatusColor(lead.status).withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            lead.status == 'Closed' ? 'Deal Closed' : lead.status,
                                            style: TextStyle(color: _getStatusColor(lead.status), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Row 2: Requirement Title & quantity
                                    Text(
                                      lead.requirementTitle,
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lead.requirementDesc,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                    const SizedBox(height: 12),

                                    // Specs boxes
                                    Row(
                                      children: [
                                        _buildBadge(Icons.shopping_bag_outlined, 'Qty: ${lead.quantity}'),
                                        const SizedBox(width: 8),
                                        _buildBadge(Icons.location_on_rounded, lead.location),
                                      ],
                                    ),
                                    
                                    if (lead.status == 'Closed') ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _buildBadge(Icons.monetization_on_outlined, 'Quoted: ₹${lead.quotedPrice?.toStringAsFixed(2) ?? "N/A"}'),
                                          const SizedBox(width: 8),
                                          _buildBadge(Icons.local_shipping_outlined, 'Shipment: ${lead.deliveryStatus}'),
                                        ],
                                      ),
                                    ],
                                    
                                    const Divider(height: 24, color: AppColors.border),

                                    // Buyer info
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.background,
                                          child: Icon(Icons.person, color: AppColors.primary, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lead.buyerName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                              ),
                                              Text(
                                                'Email: ${lead.buyerEmail} | Ph: ${lead.buyerPhone}',
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Actions Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showStatusUpdateDialog(lead),
                                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                                            label: const Text('Update Deal & Quote'),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              side: const BorderSide(color: AppColors.primary),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Calling Buyer ${lead.buyerName}: ${lead.buyerPhone}...')),
                                              );
                                            },
                                            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                                            label: const Text('Call Buyer'),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ],
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

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
