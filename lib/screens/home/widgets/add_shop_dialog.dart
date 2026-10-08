import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/shop_model.dart';
import '../../../providers/firestore_providers.dart';

class AddShopDialog extends ConsumerStatefulWidget {
  const AddShopDialog({super.key});

  @override
  ConsumerState<AddShopDialog> createState() => _AddShopDialogState();
}

class _AddShopDialogState extends ConsumerState<AddShopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _balanceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stopOrderController = TextEditingController(text: '1');

  late String _selectedRoute;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final todayRoute = AppConstants.getTodayDefaultRoute();
    _selectedRoute = todayRoute != AppConstants.routeAll
        ? todayRoute
        : AppConstants.defaultRoutes[1];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _balanceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stopOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final stopOrder = int.tryParse(_stopOrderController.text.trim()) ?? 1;

    final newShop = ShopModel(
      shopId: '', // Service generates UUID
      shopName: _nameController.text.trim(),
      ownerName: _ownerController.text.trim(),
      route: _selectedRoute,
      contactNumber: _phoneController.text.trim(),
      currentBalance: balance,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      stopOrder: stopOrder,
      lastRemark: 'New Tiny Fab retailer added to route.',
      lastVisited: DateTime.now(),
    );

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addShop(newShop);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shop "${newShop.shopName}" added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding shop: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRoutes = AppConstants.defaultRoutes
        .where((r) => r != 'All Routes')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Route Shop',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Shop Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Shop / Business Name *',
                    hintText: 'e.g. Al-Noor Supermarket',
                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Please enter shop name' : null,
                ),
                const SizedBox(height: 12),

                // Owner Name
                TextFormField(
                  controller: _ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Proprietor / Contact Person',
                    hintText: 'e.g. Mohammad Bilal',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Route Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedRoute,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Weekly Route *',
                    prefixIcon: Icon(Icons.alt_route_rounded, size: 20),
                  ),
                  items: availableRoutes.map((route) {
                    return DropdownMenuItem(
                      value: route,
                      child: Text(
                        route,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRoute = val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // City / Town & Stop Sequence Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City / Town *',
                          hintText: 'e.g. Kottakkal, Thalassery',
                          prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Enter city/town' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _stopOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stop #',
                          hintText: '1',
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Contact Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Opening Pending Balance
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Opening Pending Balance (₹)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.currency_rupee, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Address / GPS Landmark',
                    hintText: 'e.g. Main Bazar, Near Bus Stand',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Add Shop to Route'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
