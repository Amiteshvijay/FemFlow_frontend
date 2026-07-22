import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/app_card.dart';
import 'data/pill_reminder_service.dart';
import 'models/pill_reminder_models.dart';
import 'create_pill_reminder_screen.dart';
import 'pill_reminder_detail_screen.dart';

class PillReminderListScreen extends StatefulWidget {
  const PillReminderListScreen({super.key});

  @override
  State<PillReminderListScreen> createState() => _PillReminderListScreenState();
}

class _PillReminderListScreenState extends State<PillReminderListScreen> with SingleTickerProviderStateMixin {
  final PillReminderService _service = PillReminderService();
  late TabController _tabController;
  
  List<Medication> _medications = [];
  List<MedicationDose> _timeline = [];
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissions();
    _fetchData();
  }

  Future<void> _checkPermissions() async {
    final ns = NotificationService();
    await ns.requestPermissions();
    await ns.requestExactAlarmPermission();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final meds = await _service.getMedications();
      final timeline = await _service.getTimeline(date: _selectedDate);
      
      setState(() {
        _medications = meds;
        _timeline = timeline;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Medications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: FemLyraColors.primary,
          unselectedLabelColor: FemLyraColors.textMuted,
          indicatorColor: FemLyraColors.primary,
          tabs: const [
            Tab(text: 'Timeline'),
            Tab(text: 'My Medicines'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineTab(),
                _buildMedicationsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePillReminderScreen()),
        ).then((_) => _fetchData()),
        label: const Text('Add Medicine'),
        icon: const Icon(Icons.add),
        backgroundColor: FemLyraColors.primary,
      ),
    );
  }

  Widget _buildTimelineTab() {
    return Column(
      children: [
        _buildDatePicker(),
        Expanded(
          child: _timeline.isEmpty 
            ? _buildEmptyTimeline()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _timeline.length,
                itemBuilder: (context, index) => _buildTimelineItem(_timeline[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? FemLyraColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : FemLyraColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : FemLyraColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimelineItem(MedicationDose dose) {
    final timeStr = DateFormat('hh:mm a').format(dose.scheduledAt.toLocal());
    final statusColor = _getStatusColor(dose.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          children: [
            ListTile(
              leading: _getMedicineIcon(dose.medicineType),
              title: Text(dose.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${dose.dosageValue ?? ''} • $timeStr'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dose.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (dose.status == 'upcoming' || dose.status == 'missed')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleDoseAction(dose.id, 'skip'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleDoseAction(dose.id, 'take'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Take'),
                      ),
                    ),
                  ],
                ),
              ),
            if (dose.status == 'taken' && dose.actualTakenAt != null)
               Padding(
                 padding: const EdgeInsets.only(bottom: 8),
                 child: Text(
                   'Taken at ${DateFormat('hh:mm a').format(dose.actualTakenAt!.toLocal())}',
                   style: const TextStyle(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDoseAction(int id, String action) async {
    try {
      if (action == 'take') {
        await _service.takeDose(id);
      } else {
        await _service.skipDose(id);
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return _buildEmptyMeds();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PillReminderDetailScreen(reminder: med)),
            ).then((_) => _fetchData()),
            child: ListTile(
              leading: _getMedicineIcon(med.medicineType),
              title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${med.dosageValue ?? ''} • ${med.repeatType.toUpperCase()}'),
              trailing: const Icon(Icons.chevron_right, color: FemLyraColors.textMuted),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTimeline() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: Colors.green.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No doses scheduled for this day.', style: TextStyle(color: FemLyraColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyMeds() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'No medications added yet.\nAdd your first medicine to start tracking.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 16),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'taken': return Colors.green;
      case 'skipped': return Colors.orange;
      case 'missed': return Colors.red;
      default: return FemLyraColors.textMuted;
    }
  }

  Widget _getMedicineIcon(String type) {
    IconData icon;
    switch (type) {
      case 'pill': icon = Icons.medication; break;
      case 'capsule': icon = Icons.medication_liquid; break;
      case 'tablet': icon = Icons.medication; break;
      case 'syrup': icon = Icons.liquor; break;
      case 'injection': icon = Icons.vaccines; break;
      default: icon = Icons.medication;
    }
    return CircleAvatar(
      backgroundColor: FemLyraColors.primary.withValues(alpha: 0.1),
      child: Icon(icon, color: FemLyraColors.primary, size: 20),
    );
  }
}
