import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/home_screen.dart';
import '../calendar/calendar_screen.dart';
import '../chat/femai_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../../shared/widgets/universal_plus_button.dart';
import '../../core/theme/femflow_colors.dart';
import 'shell_events.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressedAt;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final List<Widget> _screens = [
    Navigator(
      key: _navigatorKeys[0],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const HomeScreen()),
    ),
    Navigator(
      key: _navigatorKeys[1],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const CalendarScreen()),
    ),
    Navigator(
      key: _navigatorKeys[2],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const FemAIChatScreen()),
    ),
    Navigator(
      key: _navigatorKeys[3],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ),
  ];

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setSelectedIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SwitchTabNotification>(
      onNotification: (notification) {
        setSelectedIndex(notification.index);
        return true;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          
          final navigator = _navigatorKeys[_selectedIndex].currentState;
          
          // 1. Handle nested navigators pop
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            return;
          }

          // 2. If not on Home tab, switch to Home tab
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            return;
          }

          // 3. Handle double-back to exit on Home tab root
          final now = DateTime.now();
          if (_lastBackPressedAt == null || 
              now.difference(_lastBackPressedAt!) > const Duration(seconds: 2)) {
            _lastBackPressedAt = now;
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          // 4. Exit app safely
          await SystemNavigator.pop();
        },
        child: Scaffold(
        body: RepaintBoundary(
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          elevation: 10,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                )),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNavItem(1, Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar'),
                )),
                // Integrated Universal Plus Button
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -20), // Lift it slightly up
                    child: const UniversalPlusButton(),
                  ),
                ),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNavItem(2, Icons.auto_awesome_outlined, Icons.auto_awesome, 'FemAI'),
                )),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
                )),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? FemFlowColors.primary : FemFlowColors.textMuted,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? FemFlowColors.primary : FemFlowColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsGate extends StatelessWidget {
  const InsightsGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const FemAIChatScreen();
  }
}
