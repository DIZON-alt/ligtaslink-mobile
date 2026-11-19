import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';
import 'disaster_alerts.dart';
import 'disaster_push_service.dart';
import 'firebase_auth_service.dart';
import 'incident_reports_api.dart';
import 'login_page.dart';
import 'profile_api.dart';
import 'services_api.dart';
import 'services_page.dart';

const _emergencyRed = Color(0xFFC62828);
const _trustBlue = Color(0xFF0D47A1);
const _successGreen = Color(0xFF2E7D32);

class AppDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppDestination(this.label, this.icon, this.selectedIcon);
}

class EmergencyService {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const EmergencyService({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _destinations = <AppDestination>[
  AppDestination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  AppDestination(
      'Services', Icons.volunteer_activism_outlined, Icons.volunteer_activism),
  AppDestination(
    'National Hub',
    Icons.public_outlined,
    Icons.public,
  ),
  AppDestination(
    'Report Incident',
    Icons.report_outlined,
    Icons.report,
  ),
  AppDestination(
    'Emergency Contacts',
    Icons.contact_phone_outlined,
    Icons.contact_phone,
  ),
  AppDestination('Profile', Icons.person_outline, Icons.person),
  AppDestination('Settings', Icons.settings_outlined, Icons.settings),
];

const _services = <EmergencyService>[
  EmergencyService(
    name: 'Ambulance',
    description: 'Request medical assistance',
    icon: Icons.medical_services_outlined,
    color: Color(0xFFC62828),
  ),
  EmergencyService(
    name: 'Fire Rescue',
    description: 'Report fire or smoke',
    icon: Icons.local_fire_department_outlined,
    color: Color(0xFFE65100),
  ),
  EmergencyService(
    name: 'Police Help',
    description: 'Request police assistance',
    icon: Icons.local_police_outlined,
    color: Color(0xFF0D47A1),
  ),
  EmergencyService(
    name: 'Road Rescue',
    description: 'Report a road emergency',
    icon: Icons.car_crash_outlined,
    color: Color(0xFF6A1B9A),
  ),
  EmergencyService(
    name: 'Flood Rescue',
    description: 'Report flooding or request rescue',
    icon: Icons.flood_outlined,
    color: Color(0xFF00ACC1),
  ),
];

const _chatAreas = <String>[
  'Panacan',
  'Sasa',
  'Ilang',
  'Tibungco',
  'Bunawan',
  'Bangkal',
  'Buhangin',
  'Talomo',
  'Toril',
];

// Kept only for the legacy chat widget below. The active National Alerts screen
// uses two compact dropdowns instead of rendering these values as buttons.
const _chatFilters = <String>[
  'All Areas',
  'My Area',
  ..._chatAreas,
];

class CommunityMessage {
  final String senderName;
  final String senderEmail;
  final String area;
  final String reportType;
  final String location;
  final String message;
  final String timeLabel;
  final String status;
  final String referenceId;
  final bool isOfficial;

  const CommunityMessage({
    required this.senderName,
    required this.senderEmail,
    required this.area,
    required this.reportType,
    required this.location,
    required this.message,
    required this.timeLabel,
    required this.status,
    required this.referenceId,
    this.isOfficial = false,
  });
}

class CommunityPost {
  final String senderName;
  final String senderEmail;
  final String area;
  final String text;
  final String timeLabel;
  final bool isModerator;

  const CommunityPost({
    required this.senderName,
    required this.senderEmail,
    required this.area,
    required this.text,
    required this.timeLabel,
    this.isModerator = false,
  });
}

const _starterChatMessages = <CommunityMessage>[
  CommunityMessage(
    senderName: 'LigtasLink Admin',
    senderEmail: 'admin@ligtaslink.local',
    area: 'National',
    reportType: 'National Advisory',
    location: 'Philippines',
    message:
        'Welcome to the national safety feed. Submitted area reports appear here after verification.',
    timeLabel: '9:00 AM',
    status: 'Official advisory',
    referenceId: 'LL-NAT-001',
    isOfficial: true,
  ),
  CommunityMessage(
    senderName: 'Community Volunteer',
    senderEmail: 'volunteer@ligtaslink.local',
    area: 'Panacan',
    reportType: 'Road Rescue',
    location: 'Panacan main road',
    message:
        'The main road is clear. Emergency lanes should remain open for responders.',
    timeLabel: '9:18 AM',
    status: 'Verified',
    referenceId: 'LL-DC-1024',
  ),
  CommunityMessage(
    senderName: 'Safety Coordinator',
    senderEmail: 'safety@ligtaslink.local',
    area: 'Sasa',
    reportType: 'Medical Advisory',
    location: 'Sasa community hall',
    message:
        'A first-aid orientation is scheduled at the community hall this afternoon.',
    timeLabel: '10:05 AM',
    status: 'Official advisory',
    referenceId: 'LL-DC-1025',
    isOfficial: true,
  ),
  CommunityMessage(
    senderName: 'Area Moderator',
    senderEmail: 'moderator@ligtaslink.local',
    area: 'Tibungco',
    reportType: 'Weather Advisory',
    location: 'Tibungco area',
    message:
        'Light rain reported. Drive carefully and watch for slippery roads.',
    timeLabel: '10:24 AM',
    status: 'Verified',
    referenceId: 'LL-DC-1026',
  ),
];

const _starterCommunityPosts = <CommunityPost>[
  CommunityPost(
    senderName: 'LigtasLink Admin',
    senderEmail: 'admin@ligtaslink.local',
    area: 'National',
    text:
        'Welcome to the National Community Chat. Choose an area to follow local conversations.',
    timeLabel: '9:05 AM',
    isModerator: true,
  ),
  CommunityPost(
    senderName: 'Panacan Volunteer',
    senderEmail: 'panacan@ligtaslink.local',
    area: 'Panacan',
    text: 'Community responders are available near the barangay hall today.',
    timeLabel: '9:32 AM',
    isModerator: true,
  ),
  CommunityPost(
    senderName: 'Sasa Resident',
    senderEmail: 'resident@ligtaslink.local',
    area: 'Sasa',
    text:
        'Please keep the road beside the community hall clear this afternoon.',
    timeLabel: '10:11 AM',
  ),
];

class HomePage extends StatefulWidget {
  final AuthService auth;
  final LocalUser user;

  const HomePage({
    super.key,
    required this.auth,
    required this.user,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _servicesApi = ServicesApi(
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    ),
  );
  static final _disasterAlertsApi = DisasterAlertsApi();
  static const _notificationsEnabledKey = 'ligtaslink_push_enabled_v1';
  static const _earthquakePushEnabledKey = 'ligtaslink_earthquake_push_v1';
  static const _typhoonPushEnabledKey = 'ligtaslink_typhoon_push_v1';
  final _pushService = DisasterPushService();
  int _selectedIndex = 0;
  int _requestCount = 0;
  bool _notificationsEnabled = false;
  bool _earthquakePushEnabled = true;
  bool _typhoonPushEnabled = true;
  bool _locationEnabled = true;
  bool _alertsLoading = true;
  DisasterAlertsSnapshot? _disasterAlerts;
  Timer? _alertsRefreshTimer;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  final List<RemoteMessage> _foregroundAlerts = [];
  final List<CommunityMessage> _communityMessages = [
    ..._starterChatMessages,
  ];
  final List<CommunityPost> _communityPosts = [
    ..._starterCommunityPosts,
  ];

  @override
  void initState() {
    super.initState();
    _refreshOfficialAlerts();
    _initializePushNotifications();
    _alertsRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshOfficialAlerts(),
    );
    if (_pushService.isSupportedPlatform && _pushService.isConfigured) {
      _foregroundMessageSubscription =
          _pushService.foregroundMessages.listen(_handlePushMessage);
      _openedMessageSubscription = _pushService.openedMessages.listen(
        (_) => _selectDestination(2),
      );
    }
  }

  @override
  void dispose() {
    _alertsRefreshTimer?.cancel();
    _foregroundMessageSubscription?.cancel();
    _openedMessageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshOfficialAlerts() async {
    if (_disasterAlerts == null && mounted) {
      setState(() => _alertsLoading = true);
    }
    final snapshot = await _disasterAlertsApi.fetch();
    if (!mounted) return;
    setState(() {
      _disasterAlerts = snapshot;
      _alertsLoading = false;
    });
  }

  Future<void> _initializePushNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final notificationsEnabled =
        preferences.getBool(_notificationsEnabledKey) ?? false;
    final earthquakesEnabled =
        preferences.getBool(_earthquakePushEnabledKey) ?? true;
    final typhoonsEnabled = preferences.getBool(_typhoonPushEnabledKey) ?? true;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _earthquakePushEnabled = earthquakesEnabled;
      _typhoonPushEnabled = typhoonsEnabled;
    });
    if (notificationsEnabled && _pushService.isConfigured) {
      try {
        await _pushService.updateSubscriptions(
          enabled: true,
          earthquakes: earthquakesEnabled,
          typhoons: typhoonsEnabled,
        );
      } catch (error) {
        _showPushError(error);
      }
    }
  }

  void _handlePushMessage(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Disaster alert';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    setState(() {
      _foregroundAlerts.insert(0, message);
      if (_foregroundAlerts.length > 10) _foregroundAlerts.removeLast();
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title: $body'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _selectDestination(2),
        ),
      ),
    );
  }

  void _showPushError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Push notification settings: $error')),
    );
  }

  Future<void> _changeNotificationsEnabled(bool enabled) async {
    try {
      await _pushService.updateSubscriptions(
        enabled: enabled,
        earthquakes: _earthquakePushEnabled,
        typhoons: _typhoonPushEnabled,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_notificationsEnabledKey, enabled);
      if (mounted) setState(() => _notificationsEnabled = enabled);
    } catch (error) {
      _showPushError(error);
    }
  }

  Future<void> _changeEarthquakePushEnabled(bool enabled) async {
    try {
      if (_notificationsEnabled) {
        await _pushService.updateSubscriptions(
          enabled: true,
          earthquakes: enabled,
          typhoons: _typhoonPushEnabled,
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_earthquakePushEnabledKey, enabled);
      if (mounted) setState(() => _earthquakePushEnabled = enabled);
    } catch (error) {
      _showPushError(error);
    }
  }

  Future<void> _changeTyphoonPushEnabled(bool enabled) async {
    try {
      if (_notificationsEnabled) {
        await _pushService.updateSubscriptions(
          enabled: true,
          earthquakes: _earthquakePushEnabled,
          typhoons: enabled,
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_typhoonPushEnabledKey, enabled);
      if (mounted) setState(() => _typhoonPushEnabled = enabled);
    } catch (error) {
      _showPushError(error);
    }
  }

  String get _firstName {
    final trimmed = widget.user.name.trim();
    if (trimmed.isEmpty) return 'Member';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  void _selectDestination(int index, {bool closeDrawer = false}) {
    if (closeDrawer) Navigator.of(context).pop();
    setState(() => _selectedIndex = index);
    if (index == 2) _refreshOfficialAlerts();
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: const Text('Sign out?'),
        content: const Text(
          'You will return to the LigtasLink login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;

    await widget.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(auth: widget.auth),
      ),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: _emergencyRed),
        title: const Text('Delete account permanently?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.auth is FirebaseAuthService
                  ? 'Your account, profile, and Firestore incident reports will be deleted. This cannot be undone. Enter your password to confirm.'
                  : 'Your local account and saved account data will be deleted. This cannot be undone. Enter your password to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _emergencyRed),
            onPressed: () => Navigator.of(context).pop(passwordController.text),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (password == null || password.isEmpty) return;

    try {
      await widget.auth.deleteAccount(password: password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(auth: widget.auth),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account could not be deleted: $error')),
      );
    }
  }

  Future<String?> _recordRequest(
    String service,
    String area,
    String location,
    String details,
  ) async {
    String referenceId;
    try {
      if (widget.auth is FirebaseAuthService) {
        final documentId = await IncidentReportsApi().createReport(
          service: service,
          area: area,
          location: location,
          details: details,
        );
        referenceId = 'LL-${documentId.substring(0, 8).toUpperCase()}';
      } else {
        referenceId = 'LL-${(_requestCount + 1).toString().padLeft(4, '0')}';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incident report could not be saved: $error')),
        );
      }
      return null;
    }

    if (!mounted) return null;
    setState(() {
      _requestCount++;
      _communityMessages.insert(
        0,
        CommunityMessage(
          senderName: widget.user.name,
          senderEmail: widget.user.email,
          area: area,
          reportType: service,
          location: location,
          message: details,
          timeLabel: 'Now',
          status: 'Pending verification',
          referenceId: referenceId,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.auth is FirebaseAuthService
            ? '$referenceId was saved. This app does not contact emergency services.'
            : '$referenceId was added to this session only. Sign in with Firebase to save reports across devices.'),
        action: SnackBarAction(
          label: 'View feed',
          onPressed: () => _selectDestination(2),
        ),
      ),
    );
    return referenceId;
  }

  void _sendCommunityPost(String area, String text) {
    setState(() {
      _communityPosts.insert(
        0,
        CommunityPost(
          senderName: widget.user.name,
          senderEmail: widget.user.email,
          area: area,
          text: text,
          timeLabel: 'Now',
        ),
      );
    });
  }

  Future<void> _showEmergencyConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.sos, color: _emergencyRed, size: 42),
        title: const Text('Activate Emergency SOS?'),
        content: const Text(
          'Use this action to prepare an urgent emergency request. In a real emergency in the Philippines, call 911.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _emergencyRed),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.warning_amber),
            label: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _showReportSheet(initialService: 'Emergency SOS');
    }
  }

  Future<void> _showReportSheet({String? initialService}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: _QuickReportForm(
          initialService: initialService,
          onSubmit: (service, area, location, details) async {
            final referenceId =
                await _recordRequest(service, area, location, details);
            if (referenceId != null && context.mounted) {
              Navigator.of(context).pop();
            }
            return referenceId;
          },
        ),
      ),
    );
  }

  Widget _selectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardScreen(
          firstName: _firstName,
          requestCount: _requestCount,
          onSosPressed: _showEmergencyConfirmation,
          onServicePressed: (service) =>
              _showReportSheet(initialService: service.name),
          onViewContacts: () => _selectDestination(4),
        );
      case 1:
        return ServicesPage(
          api: _servicesApi,
          onRequest: (serviceName) =>
              _showReportSheet(initialService: serviceName),
        );
      case 2:
        return _NationalAlertsScreen(
          currentUser: widget.user,
          messages: _communityMessages,
          communityPosts: _communityPosts,
          onSendPost: _sendCommunityPost,
          disasterAlerts: _disasterAlerts,
          alertsLoading: _alertsLoading,
          foregroundAlerts: _foregroundAlerts,
          onRefreshAlerts: _refreshOfficialAlerts,
        );
      case 3:
        return _IncidentReportScreen(onSubmit: _recordRequest);
      case 4:
        return const _EmergencyContactsScreen();
      case 5:
        return _ProfileScreen(
          user: widget.user,
          firestoreEnabled: widget.auth is FirebaseAuthService,
          onDeleteAccount: _deleteAccount,
        );
      case 6:
        return _SettingsScreen(
          notificationsEnabled: _notificationsEnabled,
          earthquakePushEnabled: _earthquakePushEnabled,
          typhoonPushEnabled: _typhoonPushEnabled,
          pushConfigured:
              _pushService.isSupportedPlatform && _pushService.isConfigured,
          onNotificationsChanged: _changeNotificationsEnabled,
          onEarthquakePushChanged: _changeEarthquakePushEnabled,
          onTyphoonPushChanged: _changeTyphoonPushEnabled,
          locationEnabled: _locationEnabled,
          onLocationChanged: (value) {
            setState(() => _locationEnabled = value);
          },
          onSignOut: _signOut,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDrawer() {
    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        _selectDestination(index, closeDrawer: true);
      },
      children: [
        _DrawerHeader(user: widget.user),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 8, 16, 10),
          child: Text(
            'LIGTASLINK SERVICES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ..._destinations.map(
          (destination) => NavigationDrawerDestination(
            label: Text(destination.label),
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 14, 28, 8),
          child: Divider(),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () {
            Navigator.of(context).pop();
            _signOut();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wideLayout = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LigtasLink',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _destinations[_selectedIndex].label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open National Hub',
            onPressed: () => _selectDestination(2),
            icon: Badge(
              label: Text('${_communityMessages.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: wideLayout
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  labelType: NavigationRailLabelType.all,
                  useIndicator: true,
                  destinations: _destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          label: Text(destination.label),
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _selectedScreen()),
              ],
            )
          : _selectedScreen(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showReportSheet(),
              backgroundColor: _emergencyRed,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_alert),
              label: const Text('Report emergency'),
            )
          : null,
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final LocalUser user;

  const _DrawerHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_emergencyRed, Color(0xFF8E1B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo_ligtaslink.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(Icons.verified, size: 16, color: _successGreen),
                  label: Text('Verified member'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardScreen extends StatelessWidget {
  final String firstName;
  final int requestCount;
  final VoidCallback onSosPressed;
  final ValueChanged<EmergencyService> onServicePressed;
  final VoidCallback onViewContacts;

  const _DashboardScreen({
    required this.firstName,
    required this.requestCount,
    required this.onSosPressed,
    required this.onServicePressed,
    required this.onViewContacts,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth;
          final columns = contentWidth >= 620 ? 4 : 2;
          final cardRatio = contentWidth >= 620 ? 1.08 : 1.14;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_trustBlue, Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _trustBlue.withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOUR SAFETY HUB',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Stay safe, $firstName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  'Emergency support and safety information in one place.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 62,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      color: const Color(0xFFFFF5F5),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: _emergencyRed.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sos,
                                color: _emergencyRed,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need urgent help?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Start an Emergency SOS request.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _emergencyRed,
                              ),
                              onPressed: onSosPressed,
                              child: const Text('SOS'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Emergency Services',
                      subtitle: 'Select the help you need',
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: cardRatio,
                      ),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return _ServiceCard(
                          service: service,
                          onTap: () => onServicePressed(service),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Activity',
                      subtitle: 'Your recent safety requests',
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: requestCount == 0
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          child: Icon(
                            requestCount == 0
                                ? Icons.check_circle_outline
                                : Icons.history,
                            color: requestCount == 0
                                ? _successGreen
                                : const Color(0xFFE65100),
                          ),
                        ),
                        title: Text(
                          requestCount == 0
                              ? 'No active emergency requests'
                              : '$requestCount prototype request${requestCount == 1 ? '' : 's'} recorded',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          requestCount == 0
                              ? 'Your current safety status is clear.'
                              : 'Requests in this classroom build are stored only for the current session.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(Icons.phone_in_talk, color: _trustBlue),
                        ),
                        title: const Text(
                          'Emergency Contacts',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'View 911 and your organization contacts.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: onViewContacts,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final EmergencyService service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(service.icon, color: service.color),
              ),
              const Spacer(),
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                service.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReportForm extends StatefulWidget {
  final String? initialService;
  final Future<String?> Function(
    String service,
    String area,
    String location,
    String details,
  ) onSubmit;

  const _QuickReportForm({
    this.initialService,
    required this.onSubmit,
  });

  @override
  State<_QuickReportForm> createState() => _QuickReportFormState();
}

class _QuickReportFormState extends State<_QuickReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _detailsController = TextEditingController();
  late String _service;
  String _area = 'Panacan';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.initialService ?? _services.first.name;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choices = <String>{
      'Emergency SOS',
      ..._services.map((service) => service.name),
      if (widget.initialService != null) widget.initialService!,
    }.toList();

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick Emergency Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use the standard format so responders can scan the report quickly.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _service,
              decoration: const InputDecoration(
                labelText: 'Emergency service',
                prefixIcon: Icon(Icons.emergency_outlined),
              ),
              items: choices
                  .map(
                    (choice) => DropdownMenuItem(
                      value: choice,
                      child: Text(choice),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _service = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _area,
              decoration: const InputDecoration(
                labelText: 'Area',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: _chatAreas
                  .map(
                    (area) => DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _area = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Exact location',
                hintText: 'Street, building, or landmark',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Enter your current location'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'What happened?',
                hintText:
                    'Describe the danger, people affected, and help needed',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              validator: (value) => (value?.trim().length ?? 0) < 10
                  ? 'Enter at least 10 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _emergencyRed,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setState(() => _isSubmitting = true);
                      final referenceId = await widget.onSubmit(
                        _service,
                        _area,
                        _locationController.text.trim(),
                        _detailsController.text.trim(),
                      );
                      if (!mounted) return;
                      if (referenceId == null) {
                        setState(() => _isSubmitting = false);
                      }
                    },
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmitting ? 'Saving report…' : 'Submit emergency report',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Legacy chat implementation retained for reference while National Alerts is
// connected to Firebase. It is not part of the active navigation.
// ignore: unused_element
class _CommunityChatScreen extends StatefulWidget {
  final LocalUser currentUser;
  final List<CommunityMessage> messages;
  final void Function(String area, String message) onSend;

  const _CommunityChatScreen({
    required this.currentUser,
    required this.messages,
    required this.onSend,
  });

  @override
  State<_CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<_CommunityChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedArea = 'All Areas';
  String _myArea = 'Panacan';
  String _postingArea = 'Panacan';

  List<CommunityMessage> get _visibleMessages {
    if (_selectedArea == 'All Areas') return widget.messages;
    final area = _selectedArea == 'My Area' ? _myArea : _selectedArea;
    return widget.messages.where((message) => message.area == area).toList();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_selectedArea != 'All Areas') {
      setState(() => _selectedArea = _postingArea);
    }
    widget.onSend(_postingArea, message);
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _showChatInformation() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Chat Guidelines',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 14),
              _GuidelineItem(
                icon: Icons.location_on_outlined,
                text: 'Choose the correct area before posting an update.',
              ),
              _GuidelineItem(
                icon: Icons.privacy_tip_outlined,
                text:
                    'Do not post passwords, IDs, or private personal information.',
              ),
              _GuidelineItem(
                icon: Icons.verified_outlined,
                text: 'Share only information you can verify.',
              ),
              _GuidelineItem(
                icon: Icons.emergency_outlined,
                text: 'For urgent danger, use Emergency SOS or call 911.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMessages = _visibleMessages;
    final postingAreas = _chatAreas;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _trustBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.forum, color: _trustBlue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Chat',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Global updates organized by area',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Set my area',
                  icon: const Icon(Icons.my_location),
                  onSelected: (area) {
                    setState(() {
                      _myArea = area;
                      _postingArea = area;
                      _selectedArea = 'My Area';
                    });
                  },
                  itemBuilder: (context) => _chatAreas
                      .where((area) => area != 'Global')
                      .map(
                        (area) => PopupMenuItem(
                          value: area,
                          child: Row(
                            children: [
                              Icon(
                                area == _myArea
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 19,
                              ),
                              const SizedBox(width: 10),
                              Text(area),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                IconButton(
                  tooltip: 'Chat guidelines',
                  onPressed: _showChatInformation,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE1E4E8)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: _chatFilters.map((area) {
                  final selected = area == _selectedArea;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selected,
                      avatar: Icon(
                        area == 'All Areas' || area == 'Global'
                            ? Icons.public
                            : area == 'My Area'
                                ? Icons.my_location
                                : Icons.location_on_outlined,
                        size: 17,
                      ),
                      label: Text(
                        area == 'My Area' ? 'My Area ($_myArea)' : area,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedArea = area);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            color: const Color(0xFFFFF8E1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 17, color: Color(0xFFF57F17)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Local preview: connect Firestore for chat between different devices.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6D4C00)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleMessages.isEmpty
                ? _EmptyChatState(area: _selectedArea)
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                    itemCount: visibleMessages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = visibleMessages[index];
                      final isMine =
                          message.senderEmail == widget.currentUser.email;
                      return _ChatBubble(message: message, isMine: isMine);
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.paddingOf(context).bottom + 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: Color(0xFFE1E4E8)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Post to:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _postingArea,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        items: postingAreas
                            .map(
                              (area) => DropdownMenuItem(
                                value: area,
                                child: Text(area),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _postingArea = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Write a community update...',
                          prefixIcon: Icon(Icons.chat_bubble_outline),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 9),
                    IconButton.filled(
                      tooltip: 'Send message',
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final CommunityMessage message;
  final bool isMine;

  const _ChatBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final foreground = isMine ? Colors.white : const Color(0xFF18202B);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
          decoration: BoxDecoration(
            color: isMine ? _trustBlue : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(17),
              topRight: const Radius.circular(17),
              bottomLeft: Radius.circular(isMine ? 17 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 17),
            ),
            border: isMine ? null : Border.all(color: const Color(0xFFE1E4E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      isMine ? 'You' : message.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.18)
                          : _trustBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          message.area == 'Global'
                              ? Icons.public
                              : Icons.location_on,
                          size: 11,
                          color: isMine ? Colors.white70 : _trustBlue,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          message.area,
                          style: TextStyle(
                            color: isMine ? Colors.white70 : _trustBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(message.message, style: TextStyle(color: foreground)),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  message.timeLabel,
                  style: TextStyle(
                    color: isMine ? Colors.white60 : Colors.black45,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final String area;

  const _EmptyChatState({required this.area});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 58, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No messages for $area',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(
              'Be the first to share a useful community update.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GuidelineItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: _trustBlue),
          const SizedBox(width: 11),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _NationalAlertsScreen extends StatefulWidget {
  final LocalUser currentUser;
  final List<CommunityMessage> messages;
  final List<CommunityPost> communityPosts;
  final void Function(String area, String text) onSendPost;
  final DisasterAlertsSnapshot? disasterAlerts;
  final bool alertsLoading;
  final List<RemoteMessage> foregroundAlerts;
  final Future<void> Function() onRefreshAlerts;

  const _NationalAlertsScreen({
    required this.currentUser,
    required this.messages,
    required this.communityPosts,
    required this.onSendPost,
    required this.disasterAlerts,
    required this.alertsLoading,
    required this.foregroundAlerts,
    required this.onRefreshAlerts,
  });

  @override
  State<_NationalAlertsScreen> createState() => _NationalAlertsScreenState();
}

class _NationalAlertsScreenState extends State<_NationalAlertsScreen> {
  static const _allAreas = 'All areas (National)';
  static const _allTypes = 'All report types';

  String _selectedArea = _allAreas;
  String _selectedType = _allTypes;
  int _selectedView = 0;
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  List<String> get _reportTypes {
    final values = <String>{
      _allTypes,
      'National Advisory',
      'Medical Advisory',
      'Weather Advisory',
      ..._services.map((service) => service.name),
    };
    return values.toList();
  }

  List<CommunityMessage> get _visibleNotifications {
    return widget.messages.where((notification) {
      final matchesArea = _selectedArea == _allAreas ||
          notification.area == _selectedArea ||
          notification.area == 'National';
      final matchesType = _selectedType == _allTypes ||
          notification.reportType == _selectedType;
      return matchesArea && matchesType;
    }).toList();
  }

  List<CommunityPost> get _visibleCommunityPosts {
    if (_selectedArea == _allAreas) return widget.communityPosts;
    return widget.communityPosts
        .where(
          (post) => post.area == _selectedArea || post.area == 'National',
        )
        .toList();
  }

  String get _postingArea {
    return _selectedArea == _allAreas ? 'National' : _selectedArea;
  }

  void _sendPost() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    widget.onSendPost(_postingArea, text);
    _chatController.clear();
  }

  void _showInformation() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How the National Hub works',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 14),
              _GuidelineItem(
                icon: Icons.public,
                text:
                    'Notifications and Community Chat share one national area filter.',
              ),
              _GuidelineItem(
                icon: Icons.filter_alt_outlined,
                text:
                    'Choose an area once, then switch between alerts and community posts.',
              ),
              _GuidelineItem(
                icon: Icons.verified_outlined,
                text:
                    'Check the status before treating a report as verified information.',
              ),
              _GuidelineItem(
                icon: Icons.privacy_tip_outlined,
                text:
                    'Never post passwords, ID numbers, phone numbers, or private addresses in chat.',
              ),
              _GuidelineItem(
                icon: Icons.emergency_outlined,
                text: 'For immediate danger in the Philippines, contact 911.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final areaItems = <String>[_allAreas, ..._chatAreas];

    final areaField = DropdownButtonFormField<String>(
      initialValue: _selectedArea,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Area',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
      items: areaItems
          .map(
            (area) => DropdownMenuItem(value: area, child: Text(area)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedArea = value);
      },
    );

    if (_selectedView == 1) return areaField;

    final typeField = DropdownButtonFormField<String>(
      initialValue: _selectedType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Report type',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: _reportTypes
          .map(
            (type) => DropdownMenuItem(value: type, child: Text(type)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedType = value);
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              areaField,
              const SizedBox(height: 12),
              typeField,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: areaField),
            const SizedBox(width: 12),
            Expanded(child: typeField),
          ],
        );
      },
    );
  }

  Widget _buildNotifications(List<CommunityMessage> notifications) {
    return RefreshIndicator(
      onRefresh: widget.onRefreshAlerts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
        children: [
          _OfficialDisasterAlertsPanel(
            snapshot: widget.disasterAlerts,
            loading: widget.alertsLoading,
            foregroundAlerts: widget.foregroundAlerts,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text(
              'Community reports',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          if (notifications.isEmpty)
            const _EmptyNotificationState()
          else
            ...notifications.map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NationalAlertCard(
                  notification: notification,
                  isMine: notification.senderEmail == widget.currentUser.email,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityChat(List<CommunityPost> posts) {
    return Column(
      children: [
        Expanded(
          child: posts.isEmpty
              ? const _EmptyCommunityState()
              : ListView.separated(
                  reverse: false,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _CommunityPostBubble(
                      post: post,
                      isMine: post.senderEmail == widget.currentUser.email,
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            9,
            12,
            MediaQuery.paddingOf(context).bottom + 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: Color(0xFFE1E4E8)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 7),
                child: Text(
                  'Posting to: $_postingArea',
                  style: const TextStyle(
                    color: _trustBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Write a helpful community update...',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendPost(),
                    ),
                  ),
                  const SizedBox(width: 9),
                  IconButton.filled(
                    tooltip: 'Send community message',
                    onPressed: _sendPost,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _visibleNotifications;
    final posts = _visibleCommunityPosts;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _trustBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.public,
                    color: _trustBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'National Safety Hub',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Notifications and community chat in one place',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'About the National Hub',
                  onPressed: _showInformation,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.notifications_active_outlined),
                    label: Text('Notifications'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.forum_outlined),
                    label: Text('Community Chat'),
                  ),
                ],
                selected: {_selectedView},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _selectedView = selection.first);
                },
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E4E8)),
            ),
            child: _buildFilters(context),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            color: const Color(0xFFE8F1FF),
            child: Row(
              children: [
                Icon(
                  _selectedView == 0 ? Icons.campaign : Icons.forum,
                  size: 18,
                  color: _trustBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedView == 0
                        ? '${notifications.length} notifications • newest reports first'
                        : '${posts.length} community messages • posting to $_postingArea',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _trustBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedView == 0
                ? _buildNotifications(notifications)
                : _buildCommunityChat(posts),
          ),
        ],
      ),
    );
  }
}

class _OfficialDisasterAlertsPanel extends StatefulWidget {
  final DisasterAlertsSnapshot? snapshot;
  final bool loading;
  final List<RemoteMessage> foregroundAlerts;

  const _OfficialDisasterAlertsPanel({
    required this.snapshot,
    required this.loading,
    required this.foregroundAlerts,
  });

  @override
  State<_OfficialDisasterAlertsPanel> createState() =>
      _OfficialDisasterAlertsPanelState();
}

class _OfficialDisasterAlertsPanelState
    extends State<_OfficialDisasterAlertsPanel> {
  int _selectedHazard = 0;

  Future<void> _openSource(BuildContext context, Uri url) async {
    try {
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the official source.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the official source: $error')),
        );
      }
    }
  }

  Color _magnitudeColor(double magnitude) {
    if (magnitude >= 6) return const Color(0xFFFF8A65);
    if (magnitude >= 5) return const Color(0xFFFFD166);
    if (magnitude >= 4) return const Color(0xFF91F27A);
    return const Color(0xFF72EBD2);
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _hazardTab('Hazards', 0),
          _hazardTab('Earthquake', 1),
        ],
      ),
    );
  }

  Widget _hazardTab(String label, int index) {
    final selected = _selectedHazard == index;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          onTap: () => setState(() => _selectedHazard = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? _trustBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF263238),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color color = const Color(0xFFFFB74D),
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 1, 2, 10),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF292D32),
            ),
          ),
          const Spacer(),
          if (widget.loading)
            const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFFFFA726),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: Color(0xFF666C72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarthquakeWarnings() {
    final snapshot = widget.snapshot;
    if (snapshot == null) {
      return _buildStatusCard(
        icon: widget.loading ? Icons.hourglass_top : Icons.cloud_off_outlined,
        title: widget.loading
            ? 'Loading PHIVOLCS earthquake warnings'
            : 'PHIVOLCS earthquake feed unavailable',
        subtitle: widget.loading
            ? 'Checking the latest official information.'
            : 'Pull down to try again.',
      );
    }
    if (snapshot.earthquakeError case final error?) {
      return _buildStatusCard(
        icon: Icons.error_outline,
        title: 'PHIVOLCS earthquake feed unavailable',
        subtitle: error,
      );
    }
    if (snapshot.earthquakes.isEmpty) {
      return _buildStatusCard(
        icon: Icons.check_circle_outline,
        title: 'No earthquake records available',
        subtitle: 'Check the official PHIVOLCS page for updates.',
      );
    }

    return Column(
      children: snapshot.earthquakes.map((alert) {
        final magnitude = double.tryParse(alert.magnitude) ?? 0;
        return Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => _openSource(context, alert.sourceUrl),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    constraints: const BoxConstraints(minHeight: 47),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _magnitudeColor(magnitude),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          alert.magnitude,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.1,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF18202B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Magnitude',
                          style: TextStyle(
                            fontSize: 8,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.timeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF777D83),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alert.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF25292E),
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alert.details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1474C8),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHazards() {
    final snapshot = widget.snapshot;
    if (snapshot == null) {
      return _buildStatusCard(
        icon: widget.loading ? Icons.hourglass_top : Icons.cloud_off_outlined,
        title: widget.loading
            ? 'Loading PAGASA hazard bulletins'
            : 'PAGASA hazard feed unavailable',
        subtitle: widget.loading
            ? 'Checking the latest official information.'
            : 'Pull down to try again.',
      );
    }
    if (snapshot.typhoonError case final error?) {
      return _buildStatusCard(
        icon: Icons.error_outline,
        title: 'PAGASA typhoon bulletin unavailable',
        subtitle: error,
      );
    }
    if (snapshot.typhoon case final alert?) {
      return Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => _openSource(context, alert.sourceUrl),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFFFE7D7),
                  child: Icon(Icons.storm, color: Color(0xFFE65100)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        alert.details,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: Color(0xFF555B61),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Open official PAGASA bulletin',
                        style: TextStyle(
                          color: Color(0xFF1474C8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, size: 17, color: Colors.black45),
              ],
            ),
          ),
        ),
      );
    }
    return _buildStatusCard(
      icon: Icons.check_circle_outline,
      title: 'No active PAGASA typhoon bulletin',
      subtitle:
          'The latest official bulletin reports no active tropical cyclone in the Philippine Area of Responsibility.',
      iconColor: _successGreen,
    );
  }

  String _messageTitle(RemoteMessage message) {
    return message.notification?.title ??
        message.data['title']?.toString() ??
        'Disaster alert';
  }

  String _messageBody(RemoteMessage message) {
    return message.notification?.body ?? message.data['body']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabs(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F1F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(
                      icon: _selectedHazard == 0
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      title: _selectedHazard == 0
                          ? 'Hazard warnings'
                          : 'Earthquake warnings',
                    ),
                    _selectedHazard == 0
                        ? _buildHazards()
                        : _buildEarthquakeWarnings(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => _openSource(
                        context,
                        Uri.parse(phivolcsEarthquakeUrl),
                      ),
                      child: const Text('PHIVOLCS'),
                    ),
                    TextButton(
                      onPressed: () => _openSource(
                        context,
                        Uri.parse(pagasaCycloneBulletinUrl),
                      ),
                      child: const Text('PAGASA'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 7),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Live feed refreshes every 5 minutes while the app is open. Follow official agency instructions.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF646A70)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.foregroundAlerts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 14, 4, 4),
            child: Text(
              'Push alerts received',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          ...widget.foregroundAlerts.map(
            (message) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_active,
                  color: _trustBlue,
                ),
                title: Text(_messageTitle(message)),
                subtitle: Text(_messageBody(message)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommunityPostBubble extends StatelessWidget {
  final CommunityPost post;
  final bool isMine;

  const _CommunityPostBubble({
    required this.post,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isMine ? Colors.white : const Color(0xFF18202B);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
          decoration: BoxDecoration(
            color: isMine ? _trustBlue : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(17),
              topRight: const Radius.circular(17),
              bottomLeft: Radius.circular(isMine ? 17 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 17),
            ),
            border: isMine ? null : Border.all(color: const Color(0xFFE1E4E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      isMine ? 'You' : post.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (post.isModerator) ...[
                    const SizedBox(width: 5),
                    Icon(
                      Icons.verified,
                      size: 15,
                      color: isMine ? Colors.white70 : _trustBlue,
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.16)
                          : _trustBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.area == 'National'
                              ? Icons.public
                              : Icons.location_on,
                          size: 11,
                          color: isMine ? Colors.white70 : _trustBlue,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          post.area,
                          style: TextStyle(
                            color: isMine ? Colors.white70 : _trustBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.text,
                style: TextStyle(color: foreground, height: 1.35),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  post.timeLabel,
                  style: TextStyle(
                    color: isMine ? Colors.white60 : Colors.black45,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 58, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No community messages yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(
              'Share a helpful and verified update for this area.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NationalAlertCard extends StatelessWidget {
  final CommunityMessage notification;
  final bool isMine;

  const _NationalAlertCard({
    required this.notification,
    required this.isMine,
  });

  Color get _accentColor {
    if (notification.isOfficial) return _trustBlue;
    if (notification.status == 'Pending verification') {
      return const Color(0xFFF57F17);
    }
    return _emergencyRed;
  }

  IconData get _reportIcon {
    final type = notification.reportType.toLowerCase();
    if (type.contains('fire')) return Icons.local_fire_department;
    if (type.contains('flood') || type.contains('weather')) {
      return Icons.flood;
    }
    if (type.contains('medical') || type.contains('ambulance')) {
      return Icons.medical_services;
    }
    if (type.contains('police')) return Icons.local_police;
    if (type.contains('road')) return Icons.car_crash;
    return Icons.campaign;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.11),
                          foregroundColor: accent,
                          child: Icon(_reportIcon),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.reportType,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${notification.referenceId} • ${notification.timeLabel}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            notification.status,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    _ReportDetailRow(
                      icon: notification.area == 'National'
                          ? Icons.public
                          : Icons.map_outlined,
                      label: 'Area',
                      value: notification.area,
                    ),
                    const SizedBox(height: 7),
                    _ReportDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: notification.location,
                    ),
                    const Divider(height: 24),
                    Text(
                      notification.message,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          notification.isOfficial
                              ? Icons.verified
                              : Icons.person_outline,
                          size: 16,
                          color: notification.isOfficial
                              ? _trustBlue
                              : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isMine
                                ? 'Reported by you'
                                : 'Reported by ${notification.senderName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReportDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _trustBlue),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 58,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'No matching notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(
              'Change one of the two filters to view more area reports.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentReportScreen extends StatefulWidget {
  final Future<String?> Function(
    String service,
    String area,
    String location,
    String details,
  ) onSubmit;

  const _IncidentReportScreen({required this.onSubmit});

  @override
  State<_IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<_IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _detailsController = TextEditingController();
  String _service = _services.first.name;
  String _area = 'Panacan';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    final referenceId = await widget.onSubmit(
      _service,
      _area,
      _locationController.text.trim(),
      _detailsController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (referenceId == null) return;
    _locationController.clear();
    _detailsController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Report an Incident',
            subtitle:
                'One guided form creates a consistent, easy-to-read alert',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _service,
                      decoration: const InputDecoration(
                        labelText: 'Service needed',
                        prefixIcon: Icon(Icons.emergency_outlined),
                      ),
                      items: _services
                          .map(
                            (service) => DropdownMenuItem(
                              value: service.name,
                              child: Text(service.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _service = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _area,
                      decoration: const InputDecoration(
                        labelText: 'Area',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: _chatAreas
                          .map(
                            (area) => DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _area = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _locationController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Exact incident location',
                        hintText:
                            'Street, building, landmark, or nearby establishment',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Enter the incident location'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _detailsController,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'What happened?',
                        hintText:
                            'Describe the danger, people affected, and help needed',
                        helperText:
                            'Do not include passwords or private identification numbers.',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 10
                          ? 'Enter at least 10 characters'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    _IncidentPreviewCard(
                      service: _service,
                      area: _area,
                      location: _locationController.text.trim(),
                      details: _detailsController.text.trim(),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: _emergencyRed,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSubmitting
                            ? 'Saving report…'
                            : 'Submit incident report',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentPreviewCard extends StatelessWidget {
  final String service;
  final String area;
  final String location;
  final String details;

  const _IncidentPreviewCard({
    required this.service,
    required this.area,
    required this.location,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.preview_outlined, color: _emergencyRed, size: 19),
              SizedBox(width: 8),
              Text(
                'Report preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                'PENDING',
                style: TextStyle(
                  color: Color(0xFFF57F17),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          _ReportDetailRow(
            icon: Icons.emergency_outlined,
            label: 'Type',
            value: service,
          ),
          const SizedBox(height: 7),
          _ReportDetailRow(
            icon: Icons.map_outlined,
            label: 'Area',
            value: area,
          ),
          const SizedBox(height: 7),
          _ReportDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: location.isEmpty ? 'Enter an exact location' : location,
          ),
          const SizedBox(height: 10),
          Text(
            details.isEmpty
                ? 'Your incident description will appear here.'
                : details,
            style: TextStyle(
              height: 1.35,
              color: details.isEmpty ? Colors.black45 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactsScreen extends StatelessWidget {
  const _EmergencyContactsScreen();

  void _showCallDemo(BuildContext context, String contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$contact selected. Calling is disabled in this classroom prototype.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Emergency Contacts',
            subtitle: 'Quick access to essential safety hotlines',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.emergency, color: _emergencyRed),
                  ),
                  title: const Text(
                    'National Emergency Hotline',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('911'),
                  trailing: IconButton.filledTonal(
                    tooltip: 'Call 911',
                    onPressed: () => _showCallDemo(context, '911'),
                    icon: const Icon(Icons.call),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.security, color: _trustBlue),
                  ),
                  title: const Text(
                    'Organization Safety Officer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Contact number not configured'),
                  trailing: IconButton.filledTonal(
                    tooltip: 'Contact safety officer',
                    onPressed: () =>
                        _showCallDemo(context, 'Organization Safety Officer'),
                    icon: const Icon(Icons.call),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Contact form opened in demo mode.')),
              );
            },
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add trusted contact'),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SafetyAlertsScreen extends StatelessWidget {
  const _SafetyAlertsScreen();

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Safety Alerts',
            subtitle: 'Important updates and preparedness reminders',
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(label: Text('All'), selected: true, onSelected: null),
              FilterChip(
                  label: Text('Emergency'), selected: false, onSelected: null),
              FilterChip(
                  label: Text('Weather'), selected: false, onSelected: null),
            ],
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.check_circle, color: _successGreen),
              ),
              title: Text(
                'No active emergency alerts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Your area currently has no recorded alerts.'),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFFFF8E1),
                child: Icon(Icons.lightbulb_outline, color: Color(0xFFF57F17)),
              ),
              title: Text(
                'Preparedness tip',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Keep a charged phone, emergency kit, and trusted contact list ready.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  final LocalUser user;
  final bool firestoreEnabled;
  final Future<void> Function() onDeleteAccount;

  const _ProfileScreen({
    required this.user,
    required this.firestoreEnabled,
    required this.onDeleteAccount,
  });

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!widget.firestoreEnabled) {
      _nameController.text = widget.user.name;
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = await ApiService.getCurrentUserProfile();
      if (!mounted) return;
      _nameController.text = profile?.name ?? widget.user.name;
      _addressController.text = profile?.address ?? '';
      _phoneController.text = profile?.phoneNumber ?? '';
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _editProfile() async {
    final profile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(
          name: _nameController.text,
          email: widget.user.email,
          address: _addressController.text,
          phoneNumber: _phoneController.text,
        ),
      ),
    );
    if (profile == null || !mounted) return;
    setState(() {
      _nameController.text = profile.name;
      _addressController.text = profile.address;
      _phoneController.text = profile.phoneNumber;
      _error = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _nameController.text.isEmpty
                  ? '?'
                  : _nameController.text[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Full name'),
                          subtitle: Text(_nameController.text),
                        ),
                        if (_addressController.text.isNotEmpty) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.home_outlined),
                            title: const Text('Address'),
                            subtitle: Text(_addressController.text),
                          ),
                        ],
                        if (_phoneController.text.isNotEmpty) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Phone number'),
                            subtitle: Text(_phoneController.text),
                          ),
                        ],
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email address'),
                          subtitle: Text(widget.user.email),
                        ),
                        const ListTile(
                          leading: Icon(Icons.verified_user_outlined),
                          title: Text('Account status'),
                          subtitle: Text('Verified member'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.firestoreEnabled) ...[
            FilledButton.icon(
              onPressed: _loading || _error != null ? null : _editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _MyIncidentReportsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('My incident reports'),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onDeleteAccount,
            style: TextButton.styleFrom(foregroundColor: _emergencyRed),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete account'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phoneNumber;

  const _EditProfileScreen({
    required this.name,
    required this.email,
    required this.address,
    required this.phoneNumber,
  });

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.name);
  late final _addressController = TextEditingController(text: widget.address);
  late final _phoneController = TextEditingController(text: widget.phoneNumber);
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ApiService.saveProfile(
        name: _nameController.text.trim(),
        email: widget.email,
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        UserProfile(
          uid: '',
          name: _nameController.text.trim(),
          email: widget.email,
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: widget.email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyIncidentReportsScreen extends StatefulWidget {
  const _MyIncidentReportsScreen();

  @override
  State<_MyIncidentReportsScreen> createState() =>
      _MyIncidentReportsScreenState();
}

class _MyIncidentReportsScreenState extends State<_MyIncidentReportsScreen> {
  late final Future<List<Map<String, dynamic>>> _reports =
      IncidentReportsApi().getMyReports();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My incident reports')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load reports: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return const Center(child: Text('You have no saved reports yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.emergency_outlined,
                    color: _emergencyRed,
                  ),
                  title: Text(
                    report['service']?.toString() ?? 'Incident report',
                  ),
                  subtitle: Text(
                    '${report['area'] ?? ''} • ${report['location'] ?? ''}\n'
                    '${report['status'] ?? 'Pending verification'}\n'
                    '${report['details'] ?? ''}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  final bool notificationsEnabled;
  final bool earthquakePushEnabled;
  final bool typhoonPushEnabled;
  final bool pushConfigured;
  final bool locationEnabled;
  final Future<void> Function(bool) onNotificationsChanged;
  final Future<void> Function(bool) onEarthquakePushChanged;
  final Future<void> Function(bool) onTyphoonPushChanged;
  final ValueChanged<bool> onLocationChanged;
  final Future<void> Function() onSignOut;

  const _SettingsScreen({
    required this.notificationsEnabled,
    required this.earthquakePushEnabled,
    required this.typhoonPushEnabled,
    required this.pushConfigured,
    required this.onNotificationsChanged,
    required this.onEarthquakePushChanged,
    required this.onTyphoonPushChanged,
    required this.locationEnabled,
    required this.onLocationChanged,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return _ContentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Settings',
            subtitle: 'Manage your safety and notification preferences',
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Disaster push notifications'),
                  subtitle: Text(
                    pushConfigured
                        ? 'Receive official alerts when the app is closed'
                        : 'Configure Firebase and deploy the alert function to enable push',
                  ),
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.sensors_outlined),
                  title: const Text('Earthquake alerts'),
                  subtitle:
                      const Text('PHIVOLCS events of magnitude 4.0 or higher'),
                  value: earthquakePushEnabled,
                  onChanged:
                      notificationsEnabled ? onEarthquakePushChanged : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.storm_outlined),
                  title: const Text('Typhoon alerts'),
                  subtitle: const Text('New PAGASA tropical cyclone bulletins'),
                  value: typhoonPushEnabled,
                  onChanged: notificationsEnabled ? onTyphoonPushChanged : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.location_on_outlined),
                  title: const Text('Location assistance'),
                  subtitle:
                      const Text('Allow location during emergency reports'),
                  value: locationEnabled,
                  onChanged: onLocationChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _ContentPage extends StatelessWidget {
  final Widget child;

  const _ContentPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        ),
      ),
    );
  }
}
