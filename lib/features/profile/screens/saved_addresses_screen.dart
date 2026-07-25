import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../data/address_service.dart';
import '../models/user_address.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final AddressService _addressService = AddressService();
  List<UserAddress> _addresses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _addressService.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load saved addresses. Please try again.';
        });
      }
    }
  }

  Future<void> _deleteAddress(UserAddress address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${address.displayTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && address.id != null) {
      try {
        await _addressService.deleteAddress(address.id!);
        await _loadAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted successfully'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete address: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _setDefaultAddress(UserAddress address) async {
    if (address.id == null || address.isDefault) return;

    try {
      await _addressService.setDefaultAddress(address.id!);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set "${address.displayTitle}" as default address'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openAddressFormModal([UserAddress? existingAddress]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressFormBottomSheet(
        existingAddress: existingAddress,
        onSave: () {
          Navigator.of(context).pop();
          _loadAddresses();
        },
      ),
    );
  }

  IconData _getLabelIcon(String label) {
    if (label == 'office') return Icons.work_outline_rounded;
    if (label == 'other') return Icons.location_on_outlined;
    return Icons.home_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Saved Addresses",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadAddresses,
                        style: ElevatedButton.styleFrom(backgroundColor: FemLyraColors.primary),
                        child: const Text("Retry", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: FemLyraColors.softBlush,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_outlined, size: 48, color: FemLyraColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No Saved Addresses",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add your home or office address for fast\nlab test bookings & sample collections.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _openAddressFormModal(),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: const Text("Add New Address", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FemLyraColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final item = _addresses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isDefault
                                  ? FemLyraColors.primary
                                  : Colors.grey.shade200,
                              width: item.isDefault ? 1.8 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: item.isDefault
                                            ? FemLyraColors.softBlush
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getLabelIcon(item.label),
                                        color: item.isDefault ? FemLyraColors.primary : Colors.grey[700],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item.displayTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: FemLyraColors.textPrimary,
                                      ),
                                    ),
                                    if (item.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: FemLyraColors.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "Default",
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: FemLyraColors.primary),
                                      onPressed: () => _openAddressFormModal(item),
                                      tooltip: "Edit Address",
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                      onPressed: () => _deleteAddress(item),
                                      tooltip: "Delete Address",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (item.fullName != null && item.fullName!.isNotEmpty)
                                  Text(
                                    item.fullName!,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: FemLyraColors.textPrimary),
                                  ),
                                if (item.phoneNumber != null && item.phoneNumber!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      "Phone: ${item.phoneNumber}",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  item.formattedAddress,
                                  style: const TextStyle(fontSize: 13, color: FemLyraColors.textSecondary, height: 1.4),
                                ),
                                const SizedBox(height: 10),
                                if (!item.isDefault)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _setDefaultAddress(item),
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: FemLyraColors.primary),
                                      label: const Text(
                                        "Set as Default",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openAddressFormModal(),
              backgroundColor: FemLyraColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text("Add Address", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

class _AddressFormBottomSheet extends StatefulWidget {
  final UserAddress? existingAddress;
  final VoidCallback onSave;

  const _AddressFormBottomSheet({
    this.existingAddress,
    required this.onSave,
  });

  @override
  State<_AddressFormBottomSheet> createState() => _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState extends State<_AddressFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();

  late String _label;
  late TextEditingController _customLabelController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _line1Controller;
  late TextEditingController _line2Controller;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late bool _isDefault;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingAddress;
    _label = item?.label ?? 'home';
    _customLabelController = TextEditingController(text: item?.customLabel ?? '');
    _fullNameController = TextEditingController(text: item?.fullName ?? '');
    _phoneController = TextEditingController(text: item?.phoneNumber ?? '');
    _line1Controller = TextEditingController(text: item?.addressLine1 ?? '');
    _line2Controller = TextEditingController(text: item?.addressLine2 ?? '');
    _landmarkController = TextEditingController(text: item?.landmark ?? '');
    _cityController = TextEditingController(text: item?.city ?? '');
    _stateController = TextEditingController(text: item?.state ?? '');
    _pincodeController = TextEditingController(text: item?.pincode ?? '');
    _isDefault = item?.isDefault ?? false;
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newAddress = UserAddress(
      id: widget.existingAddress?.id,
      label: _label,
      customLabel: _label == 'other' ? _customLabelController.text.trim() : null,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      addressLine1: _line1Controller.text.trim(),
      addressLine2: _line2Controller.text.trim(),
      landmark: _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _isDefault,
    );

    try {
      if (widget.existingAddress != null && widget.existingAddress!.id != null) {
        await _addressService.updateAddress(widget.existingAddress!.id!, newAddress);
      } else {
        await _addressService.addAddress(newAddress);
      }

      widget.onSave();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingAddress == null ? "Add New Address" : "Edit Address",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Address Type Chips
              const Text("Address Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FemLyraColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip('home', 'Home', Icons.home_outlined),
                  const SizedBox(width: 8),
                  _buildTypeChip('office', 'Office', Icons.work_outline_rounded),
                  const SizedBox(width: 8),
                  _buildTypeChip('other', 'Other', Icons.location_on_outlined),
                ],
              ),
              if (_label == 'other') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customLabelController,
                  decoration: InputDecoration(
                    labelText: "Custom Label (e.g. Mom's House)",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Contact Details
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Address Line 1
              TextFormField(
                controller: _line1Controller,
                decoration: InputDecoration(
                  labelText: "Flat / House No. / Building Name *",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter house/flat details' : null,
              ),
              const SizedBox(height: 12),

              // Address Line 2
              TextFormField(
                controller: _line2Controller,
                decoration: InputDecoration(
                  labelText: "Street / Area / Locality",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Landmark & City
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _landmarkController,
                      decoration: InputDecoration(
                        labelText: "Landmark (Optional)",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: "City *",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // State & Pincode
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: "State",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Pincode *",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Set Default Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Make this my default address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: _isDefault,
                activeColor: FemLyraColors.primary,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemLyraColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.existingAddress == null ? "Save Address" : "Update Address",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _label == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : FemLyraColors.primary),
      label: Text(label),
      selected: isSelected,
      selectedColor: FemLyraColors.primary,
      backgroundColor: FemLyraColors.softBlush,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : FemLyraColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _label = type);
        }
      },
    );
  }
}
