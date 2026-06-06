import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';

class DashboardLeadItem {
  final String id;
  final String productName;
  final double quantity;
  final String status;
  final double? quotedPrice;
  final double costPrice;
  final double gstPercent;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;

  DashboardLeadItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.status,
    this.quotedPrice,
    required this.costPrice,
    required this.gstPercent,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
  });

  factory DashboardLeadItem.fromJson(Map<String, dynamic> json) {
    return DashboardLeadItem(
      id: json['id'] ?? '',
      productName: json['product_name'] ?? json['service_name'] ?? json['title'] ?? 'Inquiry',
      quantity: json['quantity'] != null ? double.parse(json['quantity'].toString()) : 1.0,
      status: json['status'] ?? 'New',
      quotedPrice: json['quoted_price'] != null ? double.parse(json['quoted_price'].toString()) : null,
      costPrice: json['cost_price'] != null ? double.parse(json['cost_price'].toString()) : 310.00,
      gstPercent: json['gst_percent'] != null ? double.parse(json['gst_percent'].toString()) : 18.0,
      buyerName: json['buyer_name'] ?? 'Buyer Client',
      buyerPhone: json['buyer_phone'] ?? '',
      buyerEmail: json['buyer_email'] ?? '',
    );
  }
}

class CatalogItem {
  final String id;
  final String name;
  final String description;
  final String status;
  final String categoryName;
  final bool isService;

  CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.categoryName,
    required this.isService,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json, bool isService) {
    return CatalogItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Approved',
      categoryName: json['category_name'] ?? 'General',
      isService: isService,
    );
  }
}

class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  State<SupplierDashboardScreen> createState() => _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  int _currentTab = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Stats Data
  Map<String, dynamic> _stats = {
    'totalProducts': 0,
    'totalServices': 0,
    'newLeads': 0,
    'closedLeads': 0,
  };

  // Lists
  List<DashboardLeadItem> _leadsList = [];
  List<CatalogItem> _productsList = [];
  List<CatalogItem> _servicesList = [];
  
  // Catalog View Switch (0 = Products, 1 = Services)
  int _catalogTypeIndex = 0;

  // Interactive GST Calculator State
  double _calcBaseAmount = 50000.0;
  double _calcGstPercent = 18.0;
  final _baseAmountController = TextEditingController(text: '50000.00');

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchCatalogData();
  }

  @override
  void dispose() {
    _baseAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      
      // 1. Fetch dashboard metrics
      final resStats = await api.get('/supplier/dashboard');
      if (resStats.statusCode == 200 && resStats.data != null) {
        setState(() {
          _stats = resStats.data['stats'] ?? {};
        });
      }

      // 2. Fetch leads
      final resLeads = await api.get('/supplier/leads');
      if (resLeads.statusCode == 200 && resLeads.data != null) {
        final List list = resLeads.data['leads'] ?? [];
        setState(() {
          _leadsList = list.map((item) => DashboardLeadItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection Error: Unable to fetch live metrics.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCatalogData() async {
    try {
      final api = ApiService();
      
      // Fetch Products
      final prodRes = await api.get('/supplier/products');
      if (prodRes.statusCode == 200 && prodRes.data != null) {
        final List list = prodRes.data['products'] ?? [];
        setState(() {
          _productsList = list.map((item) => CatalogItem.fromJson(item, false)).toList();
        });
      }

      // Fetch Services
      final servRes = await api.get('/supplier/services');
      if (servRes.statusCode == 200 && servRes.data != null) {
        final List list = servRes.data['services'] ?? [];
        setState(() {
          _servicesList = list.map((item) => CatalogItem.fromJson(item, true)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading catalog lists: $e');
    }
  }

  Future<void> _deleteCatalogItem(CatalogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${item.name}" listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final api = ApiService();
        final path = item.isService ? '/supplier/services/${item.id}' : '/supplier/products/${item.id}';
        final res = await api.delete(path);
        
        if (res.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${item.name}" removed successfully.')),
            );
          }
          _fetchCatalogData();
          _fetchDashboardData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete listing.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showUpdateLeadDialog(DashboardLeadItem lead) {
    final priceController = TextEditingController(text: lead.quotedPrice?.toString() ?? '');
    final notesController = TextEditingController();
    String selectedStatus = lead.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quote / Update Lead',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text('Inquiry for: ${lead.productName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Divider(height: 24),

              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Lead Status'),
                items: ['New', 'Viewed', 'Contacted', 'Closed'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedStatus = val;
                },
              ),
              const SizedBox(height: 16),

              // Quoted Price
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quoted Price per Unit (₹)',
                  hintText: 'Enter your quote amount...',
                ),
              ),
              const SizedBox(height: 16),

              // Action Notes
              TextFormField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Note',
                  hintText: 'e.g. Discussed bulk discount and shipping timeline...',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    final api = ApiService();
                    final price = double.tryParse(priceController.text.trim());
                    
                    final res = await api.put(
                      '/supplier/leads/${lead.id}/status',
                      data: {
                        'status': selectedStatus,
                        'quotedPrice': price,
                        'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      },
                    );

                    if (res.statusCode == 200) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Lead updated successfully!')),
                      );
                      _fetchDashboardData();
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Failed to update lead status.')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _getTabTitle(),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchDashboardData();
              _fetchCatalogData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Catalog'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline_rounded), activeIcon: Icon(Icons.mail_rounded), label: 'Leads'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Tools'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTabBody(),
    );
  }

  String _getTabTitle() {
    switch (_currentTab) {
      case 0:
        return 'Supplier Panel';
      case 1:
        return 'My Catalog';
      case 2:
        return 'Leads Inbox';
      case 3:
        return 'Commercial Tools';
      default:
        return 'BuildMart';
    }
  }

  Widget _buildTabBody() {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildCatalogTab();
      case 2:
        return _buildLeadsTab();
      case 3:
        return _buildToolsTab();
      default:
        return const SizedBox();
    }
  }

  // TAB 1: OVERVIEW & QUICK ACTIONS (No scrolling required for key actions!)
  Widget _buildHomeTab() {
    // Lead conversion metrics
    final int newLeadsCount = _stats['newLeads'] ?? 0;
    final int closedLeadsCount = _stats['closedLeads'] ?? 0;
    final int totalLeads = newLeadsCount + closedLeadsCount;
    final double closedRatio = totalLeads > 0 ? (closedLeadsCount / totalLeads) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.black87), textAlign: TextAlign.center),
            ),

          // Welcome Card
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operational Dashboard',
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    const Text('Manage listings, trade catalogs, and respond to incoming orders.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Count cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Active Products', '${_stats['totalProducts']}', Icons.inventory_2_outlined, Colors.indigo),
              _buildStatCard('Services Offered', '${_stats['totalServices']}', Icons.handyman_outlined, Colors.teal),
              _buildStatCard('New Inquiries', '${_stats['newLeads']}', Icons.notifications_active_outlined, AppColors.accent),
              _buildStatCard('Closed Deals', '${_leadsList.where((l) => l.status == 'Closed').length}', Icons.task_alt_outlined, AppColors.success),
            ],
          ),
          const SizedBox(height: 20),

          // QUICK ACTIONS HEADER
          Text(
            'Quick Operations',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          // Quick Actions Horizontal Grid (Extremely user friendly, no scrolling needed!)
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.add_box_rounded,
                  label: 'Add Listing',
                  color: AppColors.primary,
                  onTap: () => context.push('/supplier-add-product').then((_) {
                    _fetchCatalogData();
                    _fetchDashboardData();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.mail_rounded,
                  label: 'Leads Inbox',
                  color: AppColors.accent,
                  onTap: () => setState(() => _currentTab = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.edit_note_rounded,
                  label: 'Edit Profile',
                  color: Colors.blueGrey,
                  onTap: () => context.push('/supplier-profile'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // conversion summary card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lead Conversion Rate',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Converted $closedLeadsCount out of $totalLeads total inquiries.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: closedRatio,
                    backgroundColor: AppColors.border,
                    color: AppColors.success,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Conversion: ${(closedRatio * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const Text('Target: 70%', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: CATALOG MANAGEMENT (Real-time product & service catalogs)
  Widget _buildCatalogTab() {
    final currentList = _catalogTypeIndex == 0 ? _productsList : _servicesList;

    return Column(
      children: [
        // Tab Selector for Products vs Services
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text('Products (${_productsList.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  selected: _catalogTypeIndex == 0,
                  onSelected: (val) {
                    if (val) setState(() => _catalogTypeIndex = 0);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text('Services (${_servicesList.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  selected: _catalogTypeIndex == 1,
                  onSelected: (val) {
                    if (val) setState(() => _catalogTypeIndex = 1);
                  },
                ),
              ),
            ],
          ),
        ),

        // List View of Listings
        Expanded(
          child: currentList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('No listings found in your catalog.', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/supplier-add-product').then((_) => _fetchCatalogData()),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Listing'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentList.length,
                  itemBuilder: (context, index) {
                    final item = currentList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product icon or image placeholder
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.isService ? Icons.handyman : Icons.inventory_2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.categoryName,
                                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(item.status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 9.5, 
                                        fontWeight: FontWeight.w800, 
                                        color: _getStatusColor(item.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteCatalogItem(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 3: LEADS INBOX (Review and manage all inquiries)
  Widget _buildLeadsTab() {
    return _leadsList.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline_rounded, size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No inquiries received yet.', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _leadsList.length,
            itemBuilder: (context, index) {
              final lead = _leadsList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              lead.productName,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getLeadStatusColor(lead.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lead.status,
                              style: TextStyle(
                                fontSize: 9.5, 
                                fontWeight: FontWeight.w800, 
                                color: _getLeadStatusColor(lead.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Buyer info row
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Buyer: ${lead.buyerName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Requested Quantity: ${lead.quantity.toStringAsFixed(0)} units', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),

                      if (lead.quotedPrice != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'Quoted Price: ₹${lead.quotedPrice!.toStringAsFixed(2)} / unit', 
                              style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],

                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showUpdateLeadDialog(lead),
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('Update Quote / Status'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // TAB 4: TOOLS & ANALYTICS (P&L and GST calculators out of the main screen!)
  Widget _buildToolsTab() {
    // Dynamic Profit & Loss calculations from Closed deals
    double totalRevenue = 0.0;
    double totalCost = 0.0;
    for (var lead in _leadsList) {
      if (lead.status == 'Closed' && lead.quotedPrice != null) {
        totalRevenue += (lead.quotedPrice! * lead.quantity);
        totalCost += (lead.costPrice * lead.quantity);
      }
    }
    final double netProfit = totalRevenue - totalCost;
    final double profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

    // GST Invoice Tool calculation
    final double gstAmount = _calcBaseAmount * (_calcGstPercent / 100);
    final double cgstAmount = gstAmount / 2;
    final double sgstAmount = gstAmount / 2;
    final double grandTotalInvoice = _calcBaseAmount + gstAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Commercial P&L
          Text(
            'Profit & Loss Statements',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Net Profit Margin', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            '${profitMargin.toStringAsFixed(1)}%',
                            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.trending_up, color: AppColors.success, size: 24),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPnlMetric('Total Revenue', '₹${(totalRevenue / 1000).toStringAsFixed(1)}k'),
                      _buildPnlMetric('Material Cost', '₹${(totalCost / 1000).toStringAsFixed(1)}k'),
                      _buildPnlMetric('Net Profit', '₹${(netProfit / 1000).toStringAsFixed(1)}k', valueColor: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // GST Calculator
          Text(
            'GST Tax Billing Calculator',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _baseAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Base Taxable Value (₹)',
                      hintText: 'Enter trade base price...',
                    ),
                    onChanged: (val) {
                      final amount = double.tryParse(val) ?? 0.0;
                      setState(() {
                        _calcBaseAmount = amount;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    initialValue: _calcGstPercent,
                    decoration: const InputDecoration(labelText: 'Applicable GST Slab (%)'),
                    items: [5.0, 12.0, 18.0, 28.0].map((gst) {
                      return DropdownMenuItem(value: gst, child: Text('${gst.toStringAsFixed(0)}% GST'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _calcGstPercent = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Base Amount', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                            Text('₹${_calcBaseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CGST (${(_calcGstPercent / 2).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('₹${cgstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SGST (${(_calcGstPercent / 2).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('₹${sgstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Invoice Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('₹${grandTotalInvoice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Pending':
        return AppColors.accent;
      case 'Rejected':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getLeadStatusColor(String status) {
    switch (status) {
      case 'Closed':
        return AppColors.success;
      case 'Contacted':
        return Colors.blue;
      case 'Viewed':
        return Colors.amber;
      case 'New':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPnlMetric(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
