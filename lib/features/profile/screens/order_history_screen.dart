import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/profile_service.dart';
import '../models/order_history_model.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ProfileService _profileService = ProfileService();
  List<OrderHistoryItem> _allOrders = [];
  List<OrderHistoryItem> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedType = 'All'; // 'All', 'Subscription', 'Consultation'
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _profileService.getOrderHistory();
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        // Search filter
        final matchesSearch = order.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (order.utrNumber != null && order.utrNumber!.toLowerCase().contains(_searchQuery.toLowerCase()));

        // Type filter
        final matchesType = _selectedType == 'All' || order.type == _selectedType;

        // Status filter
        bool matchesStatus = true;
        if (_selectedStatus != 'All') {
          final statusLower = order.status.toLowerCase();
          if (_selectedStatus == 'pending') {
            matchesStatus = ['pending', 'pending_payment', 'paymentpending', 'created'].contains(statusLower);
          } else if (_selectedStatus == 'verification_pending') {
            matchesStatus = ['verification_pending', 'verificationpending'].contains(statusLower);
          } else if (_selectedStatus == 'success') {
            matchesStatus = ['success', 'paid', 'booked', 'confirmed', 'completed'].contains(statusLower);
          } else if (_selectedStatus == 'failed') {
            matchesStatus = ['failed', 'rejected', 'cancelled'].contains(statusLower);
          }
        }

        return matchesSearch && matchesType && matchesStatus;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
      case 'booked':
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'pending_payment':
      case 'paymentpending':
      case 'created':
        return Colors.amber[800]!;
      case 'verification_pending':
      case 'verificationpending':
        return Colors.purple;
      case 'failed':
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
        return 'Paid / Success';
      case 'pending':
      case 'pending_payment':
      case 'paymentpending':
        return 'Pending Payment';
      case 'verification_pending':
      case 'verificationpending':
        return 'Verification Pending';
      case 'failed':
        return 'Failed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order & Payment History',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and filters toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Search field
                TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: FemFlowColors.textMuted),
                    hintText: 'Search by Order ID or UTR...',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: FemFlowColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Type filter buttons
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Subscription', 'Consultation'].map((type) {
                            final isSelected = _selectedType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedType = type);
                                    _applyFilters();
                                  }
                                },
                                selectedColor: FemFlowColors.primary,
                                disabledColor: Colors.transparent,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : FemFlowColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: FemFlowColors.textMuted),
                        style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Status')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'verification_pending', child: Text('Verifying')),
                          DropdownMenuItem(value: 'success', child: Text('Success')),
                          DropdownMenuItem(value: 'failed', child: Text('Failed')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                            _applyFilters();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchOrderHistory,
                              style: ElevatedButton.styleFrom(backgroundColor: FemFlowColors.primary),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchOrderHistory,
                        color: FemFlowColors.primary,
                        child: _filteredOrders.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _filteredOrders.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderCard(_filteredOrders[index]);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderHistoryItem order) {
    final formattedDate = DateFormat('MMM dd, yyyy  hh:mm a').format(order.createdAt);
    final isSubscription = order.type == 'Subscription';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
          if (result == true) {
            _fetchOrderHistory();
          }
        },
        child: Row(
          children: [
            // Left Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSubscription ? Colors.pink : Colors.purple).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSubscription ? Icons.workspace_premium : Icons.video_call,
                color: isSubscription ? Colors.pink : Colors.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Middle Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FemFlowColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Order ID: ${order.orderId}',
                    style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: FemFlowColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Right Price & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.currency == 'INR' ? '₹' : order.currency}${order.amount.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FemFlowColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getStatusColor(order.status).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _formatStatus(order.status),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                child: Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              const Text(
                'No orders found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'No orders or payments match your current query filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FemFlowColors.textSecondary, height: 1.5, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
