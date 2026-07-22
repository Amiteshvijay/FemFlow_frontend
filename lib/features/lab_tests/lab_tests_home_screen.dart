import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:femlyra/core/theme/FemLyra_colors.dart';
import 'package:femlyra/shared/widgets/app_card.dart';
import 'package:femlyra/features/lab_tests/providers/cart_provider.dart';
import 'package:femlyra/features/lab_tests/lab_cart_screen.dart';

class LabTestsHomeScreen extends StatefulWidget {
  final bool useCurrentLocation;
  final int initialTab;

  const LabTestsHomeScreen({
    super.key,
    this.useCurrentLocation = false,
    this.initialTab = 0,
  });

  @override
  State<LabTestsHomeScreen> createState() => _LabTestsHomeScreenState();
}

class _LabTestsHomeScreenState extends State<LabTestsHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = "Home - 110021, New Delhi";
  String _selectedCategory = "All";
  String _searchQuery = "";

  final List<Map<String, dynamic>> _categories = [
    {"name": "All", "icon": Icons.grid_view},
    {"name": "PCOS", "icon": Icons.spa_outlined},
    {"name": "Thyroid", "icon": Icons.biotech_outlined},
    {"name": "Vitamins", "icon": Icons.wb_sunny_outlined},
    {"name": "Fertility", "icon": Icons.favorite_border},
    {"name": "Pregnancy", "icon": Icons.child_care},
    {"name": "Diabetes", "icon": Icons.water_drop_outlined},
  ];

  final List<Map<String, dynamic>> _packages = [
    {
      "name": "PCOS Support Package",
      "description": "Comprehensive hormone evaluation tracking cycle irregularity, insulin resistance, and androgen excess.",
      "tests": ["LH", "FSH", "Prolactin", "Free Testosterone", "TSH"],
      "mrp": 2499,
      "sellingPrice": 1499,
      "category": "PCOS",
      "homeCollection": true,
      "femaleCollector": true,
      "turnaround": "24 Hours",
    },
    {
      "name": "Fertility Assessment Package",
      "description": "Essential biomarkers evaluating ovarian reserve, thyroid function, and ovulation viability.",
      "tests": ["AMH", "FSH", "LH", "Estradiol", "Prolactin"],
      "mrp": 3999,
      "sellingPrice": 2499,
      "category": "Fertility",
      "homeCollection": true,
      "femaleCollector": true,
      "turnaround": "36 Hours",
    },
    {
      "name": "Pregnancy Monitoring Package",
      "description": "Routine antenatal checkup covering blood health, sugar levels, and thyroid parameters.",
      "tests": ["CBC", "TSH", "Blood Sugar Fasting", "Urine Routine"],
      "mrp": 1999,
      "sellingPrice": 1199,
      "category": "Pregnancy",
      "homeCollection": true,
      "femaleCollector": true,
      "turnaround": "12 Hours",
    },
    {
      "name": "Anemia & Fatigue Profile",
      "description": "Identifies root causes of physical exhaustion, iron deficiency, and hemoglobin counts.",
      "tests": ["Hemoglobin", "Ferritin", "Iron Profile", "Vitamin B12"],
      "mrp": 1599,
      "sellingPrice": 899,
      "category": "Vitamins",
      "homeCollection": true,
      "femaleCollector": false,
      "turnaround": "24 Hours",
    },
    {
      "name": "Thyroid Health Package",
      "description": "Evaluates thyroid gland efficiency with high-precision T3, T4, and ultra-sensitive TSH.",
      "tests": ["TSH", "Total T3", "Total T4"],
      "mrp": 999,
      "sellingPrice": 499,
      "category": "Thyroid",
      "homeCollection": true,
      "femaleCollector": false,
      "turnaround": "8 Hours",
    },
    {
      "name": "Women's Preventive Wellness",
      "description": "Full body baseline profile checking liver, kidney, vitamins, lipids, and blood components.",
      "tests": ["CBC", "TSH", "Vitamin D", "HbA1c", "Lipid Profile", "LFT", "KFT"],
      "mrp": 4999,
      "sellingPrice": 2999,
      "category": "All",
      "homeCollection": true,
      "femaleCollector": true,
      "turnaround": "24 Hours",
    },
  ];

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _selectedLocation = "Detecting location...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text('Please enable location services to find nearest labs.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (result == true) {
          await Geolocator.openLocationSettings();
        }
        setState(() {
          _selectedLocation = "Delhi Enclave, Safdarjung";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _selectedLocation = "Permission Denied (Delhi)";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Denied'),
            content: const Text('Location permissions are permanently denied. Please enable them in app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (result == true) {
          await Geolocator.openAppSettings();
        }
        setState(() {
          _selectedLocation = "Delhi Enclave, Safdarjung";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = "Current Location (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})";
      });
    } catch (e) {
      setState(() {
        _selectedLocation = "Delhi Enclave, Safdarjung";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.useCurrentLocation) {
      _detectCurrentLocation();
    }
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Location',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _detectCurrentLocation();
                },
                icon: const Icon(Icons.my_location, color: FemLyraColors.primary),
                label: const Text('Use Current Location', style: TextStyle(color: FemLyraColors.primary)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: FemLyraColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary)),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.home_outlined, color: FemLyraColors.primary),
                title: const Text('Home'),
                subtitle: const Text('H-12, Green Park, New Delhi - 110016'),
                onTap: () {
                  setState(() {
                    _selectedLocation = "Home - 110016, Green Park";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.work_outline, color: FemLyraColors.primary),
                title: const Text('Office'),
                subtitle: const Text('Building 4B, Cyber City, Gurugram - 122002'),
                onTap: () {
                  setState(() {
                    _selectedLocation = "Office - 122002, Gurugram";
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              const Divider(color: FemLyraColors.border),
              const SizedBox(height: 8),
              const Text(
                'Note: Your location is only used to list serviceable labs and show accurate prices.',
                style: TextStyle(fontSize: 11, color: FemLyraColors.textMuted),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPackageDetailBottomSheet(Map<String, dynamic> package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      package['name'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (package['homeCollection'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Home Collection', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  if (package['femaleCollector'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Female Collector Available', style: TextStyle(color: FemLyraColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About this Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemLyraColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(package['description'], style: const TextStyle(color: FemLyraColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 20),
                      Text('Tests Included (${(package['tests'] as List).length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemLyraColors.textPrimary)),
                      const SizedBox(height: 12),
                      ...(package['tests'] as List).map((test) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: FemLyraColors.warmWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FemLyraColors.border, width: 0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(test, style: const TextStyle(fontWeight: FontWeight.w600, color: FemLyraColors.textPrimary)),
                                const Icon(Icons.check_circle_outline, color: FemLyraColors.primary, size: 16),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),
                      const Text('Preparation Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemLyraColors.textPrimary)),
                      const SizedBox(height: 8),
                      const Text(
                        '• Fasting required for 10-12 hours prior to collection.\n• Water is allowed.\n• Do not stop current thyroid medications without consulting your doctor.',
                        style: TextStyle(color: FemLyraColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'General disclaimers and recommendations: Doctor and laboratory instructions must take priority over general FemLyra advice.',
                                style: TextStyle(fontSize: 11, color: Colors.orange, height: 1.3, fontWeight: FontWeight.w600),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const Divider(color: FemLyraColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${package['mrp']}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: FemLyraColors.textMuted, fontSize: 14)),
                        Text('₹${package['sellingPrice']}', style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 24)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LabCartProvider>().addItem(package);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${package['name']} added to booking cart!'),
                            backgroundColor: FemLyraColors.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FemLyraColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter packages based on category & search
    final filteredPackages = _packages.where((pkg) {
      final matchesCat = _selectedCategory == "All" || pkg['category'] == _selectedCategory;
      final matchesSearch = pkg['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (pkg['tests'] as List).any((t) => t.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: FemLyraColors.textPrimary,
        title: const Text('Lab Test Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Consumer<LabCartProvider>(
            builder: (context, cart, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LabCartScreen()),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Selection Bar
            GestureDetector(
              onTap: _showLocationBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: FemLyraColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocation,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: FemLyraColors.textSecondary),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: FemLyraColors.border),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search experience
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search CBC, Thyroid, PCOS Profile...',
                      prefixIcon: const Icon(Icons.search, color: FemLyraColors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FemLyraColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FemLyraColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FemLyraColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Promos & Trusted partner notice
                  AppCard(
                    color: FemLyraColors.blushMist,
                    border: BorderSide(color: FemLyraColors.primary.withValues(alpha: 0.2), width: 1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NABL Accredited Partners',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FemLyraColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Accurate results from certified lab partners with safe home collection options.',
                                style: TextStyle(fontSize: 11, color: FemLyraColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Learn More >',
                                style: TextStyle(color: FemLyraColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.verified_user, size: 48, color: FemLyraColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Horizontal categories
                  const Text('Shop by Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = _selectedCategory == cat['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat['name'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? FemLyraColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? FemLyraColors.primary : FemLyraColors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(cat['icon'], color: isSelected ? Colors.white : FemLyraColors.primary, size: 20),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : FemLyraColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Health packages section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == "All" ? 'Women\'s Health Packages' : '$_selectedCategory Packages',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                      ),
                      Text(
                        '${filteredPackages.length} Available',
                        style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (filteredPackages.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_outlined, size: 48, color: FemLyraColors.textMuted),
                            const SizedBox(height: 12),
                            const Text('No packages found matching search criteria.', style: TextStyle(color: FemLyraColors.textSecondary)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = "All";
                                  _searchQuery = "";
                                  _searchController.clear();
                                });
                              },
                              child: const Text('Reset Filters', style: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPackages.length,
                      itemBuilder: (context, idx) {
                        final pkg = filteredPackages[idx];
                        final discount = (((pkg['mrp'] - pkg['sellingPrice']) / pkg['mrp']) * 100).round();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: AppCard(
                            onTap: () => _showPackageDetailBottomSheet(pkg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pkg['name'],
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pkg['description'],
                                            style: const TextStyle(fontSize: 11, color: FemLyraColors.textSecondary, height: 1.3),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: FemLyraColors.primary, borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        '$discount% OFF',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: FemLyraColors.warmWhite, borderRadius: BorderRadius.circular(6), border: Border.all(color: FemLyraColors.border, width: 0.5)),
                                      child: Text('${(pkg['tests'] as List).length} Tests', style: const TextStyle(fontSize: 10, color: FemLyraColors.textSecondary)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: FemLyraColors.warmWhite, borderRadius: BorderRadius.circular(6), border: Border.all(color: FemLyraColors.border, width: 0.5)),
                                      child: Text('Reports in ${pkg['turnaround']}', style: const TextStyle(fontSize: 10, color: FemLyraColors.textSecondary)),
                                    ),
                                    if (pkg['femaleCollector'])
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: FemLyraColors.blushMist, borderRadius: BorderRadius.circular(6)),
                                        child: const Text('Female Phlebotomist Available', style: TextStyle(fontSize: 10, color: FemLyraColors.primary, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text('₹${pkg['sellingPrice']}', style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Text('₹${pkg['mrp']}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: FemLyraColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _showPackageDetailBottomSheet(pkg),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: FemLyraColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('View Details', style: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
