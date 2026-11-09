import 'package:flutter/material.dart';
import 'package:inventory_bkm_desktop/screens/login_screen.dart';
import 'package:inventory_bkm_desktop/screens/dashboard_screen.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.init();

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INVENTORY BLOKM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthGate(apiService: apiService),
    );
  }
}

class AuthGate extends StatefulWidget {
  final ApiService apiService;

  const AuthGate({super.key, required this.apiService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    final token = widget.apiService.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isChecking = false;
        _isAuthenticated = false;
      });
      return;
    }

    try {
      await widget.apiService.getMe();
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isAuthenticated = true;
      });
    } catch (_) {
      await widget.apiService.clearToken();
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isAuthenticated = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await widget.apiService.clearToken();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      return DashboardScreen(apiService: widget.apiService, onLogout: _handleLogout);
    }

    return LoginScreen(apiService: widget.apiService, onAuthenticated: () {
      setState(() {
        _isAuthenticated = true;
      });
    });
  }
}
