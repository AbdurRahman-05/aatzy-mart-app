import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class InquiryModel {
  final String id;
  final String date;
  final String supplierName;
  final String productName;
  final double quantityVal;
  final String quantity;
  final String status; // New, Viewed, Contacted, Closed
  final double? quotedPrice;
  final String deliveryStatus; // Pending, Packed, Dispatched, Delivered
  final double gstPercent;

  InquiryModel({
    required this.id,
    required this.date,
    required this.supplierName,
    required this.productName,
    required this.quantityVal,
    required this.quantity,
    required this.status,
    this.quotedPrice,
    required this.deliveryStatus,
    required this.gstPercent,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    final qtyVal = json['quantity'] != null ? double.parse(json['quantity'].toString()) : 0.0;
    return InquiryModel(
      id: json['id'] ?? '',
      date: json['created_at'] != null 
          ? json['created_at'].toString().split('T')[0] 
          : '2026-06-05',
      supplierName: json['supplier_name'] ?? 'BuildMart Supplier',
      productName: json['product_name'] ?? json['title'] ?? 'Inquiry Request',
      quantityVal: qtyVal,
      quantity: '$qtyVal ${json['unit'] ?? "Units"}',
      status: json['status'] ?? 'New',
      quotedPrice: json['quoted_price'] != null ? double.parse(json['quoted_price'].toString()) : null,
      deliveryStatus: json['delivery_status'] ?? 'Pending',
      gstPercent: json['gst_percent'] != null ? double.parse(json['gst_percent'].toString()) : 18.0,
    );
  }
}

class MyInquiriesScreen extends StatefulWidget {
  const MyInquiriesScreen({super.key});

  @override
  State<MyInquiriesScreen> createState() => _MyInquiriesScreenState();
}

class _MyInquiriesScreenState extends State<MyInquiriesScreen> {
  bool _isLoading = false;
  List<InquiryModel> _inquiries = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
  }

  Future<void> _fetchInquiries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final res = await api.get('/buyer/inquiries');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['inquiries'] ?? [];
        setState(() {
          _inquiries = list.map((item) => InquiryModel.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching inquiries: $e');
      setState(() {
        _errorMessage = 'Failed to load inquiries. Showing demo offline inquiries.';
        _inquiries = _getFallbackInquiries();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<InquiryModel> _getFallbackInquiries() {
    return [
      InquiryModel(
        id: 'a9a9a9a9-a9a9-a9a9-a9a9-a9a9a9a9a9a9',
        date: '2026-06-04',
        supplierName: 'UltraTech Build Solutions',
        productName: 'UltraTech Premium Cement OPC 53 Grade',
        quantityVal: 500,
        quantity: '500 Bags',
        status: 'Closed',
        quotedPrice: 410.00,
        deliveryStatus: 'Packed',
        gstPercent: 18.0,
      ),
    ];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blueAccent;
      case 'Viewed':
        return Colors.orangeAccent;
      case 'Contacted':
        return AppColors.secondary;
      case 'Quote Sent':
        return Colors.purpleAccent;
      case 'Accepted':
        return AppColors.success;
      case 'Rejected':
        return Colors.redAccent;
      case 'Lead Rejected':
        return Colors.grey;
      case 'Closed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showTimeline(InquiryModel inq) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: _TimelineView(
                inquiryId: inq.id,
                inq: inq,
                onStatusUpdated: _fetchInquiries,
              ),
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
        title: const Text('My Sent Inquiries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInquiries,
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
                  child: _inquiries.isEmpty
                      ? const Center(child: Text('No inquiries sent yet. Go find products and send requirement!'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _inquiries.length,
                          itemBuilder: (context, index) {
                            final inq = _inquiries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () => _showTimeline(inq),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'ID: ${inq.id.length > 8 ? inq.id.substring(0, 8).toUpperCase() : inq.id}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(inq.status).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(50),
                                              border: Border.all(color: _getStatusColor(inq.status).withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              inq.status == 'Closed' ? 'Deal Finalized' : inq.status,
                                              style: TextStyle(color: _getStatusColor(inq.status), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        inq.productName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Supplier: ${inq.supplierName}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quantity: ${inq.quantity}',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                      
                                      if (inq.quotedPrice != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Supplier Quoted Price:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                              Text(
                                                '₹${inq.quotedPrice!.toStringAsFixed(2)} / Unit',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const Divider(height: 24, color: AppColors.border),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Sent on: ${inq.date}',
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                inq.status == 'Closed' ? 'Track Shipping' : 'Track Timeline',
                                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
}

class _TimelineView extends StatefulWidget {
  final String inquiryId;
  final InquiryModel inq;
  final VoidCallback onStatusUpdated;

  const _TimelineView({required this.inquiryId, required this.inq, required this.onStatusUpdated});

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  bool _loading = true;
  bool _isUpdating = false;
  InquiryModel? _liveInq;
  List<dynamic> _timelineLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final api = ApiService();
      final res = await api.put('/buyer/inquiries/${widget.inquiryId}/status', data: {
        'status': newStatus,
        'notes': newStatus == 'Accepted' ? 'Quote accepted by buyer.' : 'Quote rejected by buyer.',
      });
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quote $newStatus successfully!')),
          );
          widget.onStatusUpdated();
          context.pop();
        }
      }
    } catch (e) {
      // Simulation / offline fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quote updated to $newStatus (Simulation)')),
        );
        widget.onStatusUpdated();
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _fetchTimeline() async {
    try {
      final api = ApiService();
      final res = await api.get('/buyer/inquiries/${widget.inquiryId}');
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          if (res.data['inquiry'] != null) {
            _liveInq = InquiryModel.fromJson(res.data['inquiry']);
          }
          _timelineLogs = res.data['timeline'] ?? [];
        });
      }
    } catch (e) {
      // Offline / network failure fallback
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isCompleted ? AppColors.primary : AppColors.border,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isCompleted ? AppColors.textSecondary : AppColors.border,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingStage(String stageName, String stageDesc, bool isActive, bool isPast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.success : (isPast ? AppColors.primary : Colors.grey.shade300),
              ),
              child: Icon(
                isActive ? Icons.check : (isPast ? Icons.done : Icons.circle_outlined),
                size: 14,
                color: Colors.white,
              ),
            ),
            Container(
              width: 2,
              height: 40,
              color: isPast ? AppColors.primary : Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stageName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isActive ? AppColors.success : (isPast ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stageDesc,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final inq = _liveInq ?? widget.inq;
    
    // Delivery tracking variables
    final ds = inq.deliveryStatus;
    final isPacked = ds == 'Packed' || ds == 'Dispatched' || ds == 'Delivered';
    final isDispatched = ds == 'Dispatched' || ds == 'Delivered';
    final isDelivered = ds == 'Delivered';

    // Pricing & GST Invoice calculations
    final double baseAmount = (inq.quotedPrice ?? 0) * inq.quantityVal;
    final double gstAmount = baseAmount * (inq.gstPercent / 100);
    final double cgstAmount = gstAmount / 2;
    final double sgstAmount = gstAmount / 2;
    final double totalInvoice = baseAmount + gstAmount;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inq.status == 'Closed' ? 'Deal Finalized & Shipping' : 'Inquiry Tracker',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'ID: ${widget.inquiryId.toUpperCase()}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // IF DEAL IS CLOSED, DISPLAY THE AMAZON/FLIPKART STYLE PACKAGING TRACKER
          if (inq.status == 'Closed') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Delivery Tracker Stages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildShippingStage(
                    'Order Confirmed & Deal Closed',
                    'Supplier has locked quotes and finalized specifications.',
                    ds == 'Pending',
                    isPacked,
                  ),
                  _buildShippingStage(
                    'Material Packaging Processed',
                    'Goods are packed and verified for quality control checks.',
                    ds == 'Packed',
                    isDispatched,
                  ),
                  _buildShippingStage(
                    'Dispatched & In-Transit',
                    'Consignment left supplier warehouse hub.',
                    ds == 'Dispatched',
                    isDelivered,
                  ),
                  _buildShippingStage(
                    'Delivered Successfully',
                    'Goods received and verified at the building project site.',
                    ds == 'Delivered',
                    false,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Otherwise show normal negotiation history
            _buildTimelineStep(
              'Inquiry Submitted',
              'Dispatched requirement specifications to supplier on ${inq.date}',
              true,
            ),
            _buildTimelineStep(
              'Supplier Reviewed Lead',
              inq.status != 'New' ? 'Supplier opened and viewed lead details' : 'Waiting for supplier review...',
              inq.status != 'New',
            ),
            _buildTimelineStep(
              'Quote Proposed',
              inq.quotedPrice != null 
                  ? 'Supplier submitted a quote of ₹${inq.quotedPrice!.toStringAsFixed(2)} / Unit' 
                  : 'Awaiting supplier price quotation proposal...',
              inq.quotedPrice != null,
            ),
            if (inq.status == 'Accepted')
              _buildTimelineStep(
                'Quote Accepted',
                'You accepted the quote proposal. Awaiting delivery scheduling.',
                true,
              )
            else if (inq.status == 'Rejected')
              _buildTimelineStep(
                'Quote Rejected',
                'You rejected this quote proposal. Awaiting revised offer.',
                true,
              )
            else if (inq.status == 'Lead Rejected')
              _buildTimelineStep(
                'Lead Terminated',
                'Supplier rejected or closed this lead transaction.',
                true,
              )
            else
              _buildTimelineStep(
                'Deal Finalized',
                inq.status == 'Closed' ? 'Deal finalized' : 'Awaiting completion...',
                inq.status == 'Closed',
              ),
          ],

          if (inq.quotedPrice != null) ...[
            const SizedBox(height: 24),
            // Pro-Forma Tax GST Invoice Display
            Text(
              'Tax GST Billing Invoice Details',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Base Item Amount (${inq.quantity})', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      Text('₹${baseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CGST (${(inq.gstPercent/2).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('₹${cgstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SGST (${(inq.gstPercent/2).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('₹${sgstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Billing Amount (incl. GST)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('₹${totalInvoice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (inq.status == 'Quote Sent') ...[
            const SizedBox(height: 24),
            if (_isUpdating)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('Rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('Accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
          
          if (_timelineLogs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Timeline Update History',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timelineLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 16, color: AppColors.border),
                itemBuilder: (context, index) {
                  final log = _timelineLogs[index];
                  final dateStr = log['created_at'] != null 
                      ? log['created_at'].toString().split('T')[0] 
                      : '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(log['status'] ?? '').withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log['status'] ?? 'Updated',
                              style: TextStyle(
                                color: _getStatusColor(log['status'] ?? ''),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        log['notes'] ?? '',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3),
                      ),
                      if (log['changed_by_name'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'By: ${log['changed_by_name']}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Dismiss Tracker'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blueAccent;
      case 'Viewed':
        return Colors.orangeAccent;
      case 'Contacted':
        return AppColors.secondary;
      case 'Quote Sent':
        return Colors.purpleAccent;
      case 'Accepted':
        return AppColors.success;
      case 'Rejected':
        return Colors.redAccent;
      case 'Lead Rejected':
        return Colors.grey;
      case 'Closed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
