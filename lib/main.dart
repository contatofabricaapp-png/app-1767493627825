import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

void main() {
  runApp(TattooStudioApp());
}

class TattooStudioApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tattoo Studio Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          background: Color(0xFF0D0D0D),
          surface: Color(0xFF1A1A1A),
          primary: Color(0xFF8B4CF7),
          secondary: Color(0xFFE53E3E),
          onBackground: Colors.white,
          onSurface: Colors.white70,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Color(0xFF1A1A1A),
          elevation: 8,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8B4CF7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    
    _checkLicenseStatus();
  }

  void _checkLicenseStatus() async {
    await Future.delayed(Duration(seconds: 3));
    
    final prefs = await SharedPreferences.getInstance();
    final licenseKey = prefs.getString('license_key');
    final isActivated = prefs.getBool('is_activated') ?? false;
    
    if (isActivated && licenseKey != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      final trialStart = prefs.getInt('trial_start');
      if (trialStart == null) {
        await prefs.setInt('trial_start', DateTime.now().millisecondsSinceEpoch);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        final trialStartDate = DateTime.fromMillisecondsSinceEpoch(trialStart);
        final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
        
        if (daysSinceStart >= 5) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LicenseBlockScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B4CF7), Color(0xFFE53E3E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.brush,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Tattoo Studio',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Manager',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF8B4CF7),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 40),
                    CircularProgressIndicator(
                      color: Color(0xFF8B4CF7),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class LicenseBlockScreen extends StatefulWidget {
  @override
  _LicenseBlockScreenState createState() => _LicenseBlockScreenState();
}

class _LicenseBlockScreenState extends State<LicenseBlockScreen> {
  final TextEditingController _licenseController = TextEditingController();
  bool _isValidating = false;
  String _errorMessage = '';

  String _generateValidLicenseKey() {
    final now = DateTime.now();
    final seed = '${now.year}${now.month}${now.day}TATTOO_STUDIO';
    final bytes = utf8.encode(seed);
    final digest = sha256.convert(bytes);
    final hash = digest.toString().toUpperCase();
    
    return '${hash.substring(0, 4)}-${hash.substring(4, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}';
  }

  bool _validateLicenseKey(String key) {
    if (key.length != 19) return false;
    if (!RegExp(r'^[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}$').hasMatch(key)) return false;
    
    final validKey = _generateValidLicenseKey();
    return key == validKey;
  }

  void _validateLicense() async {
    if (_licenseController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, insira uma chave de licença';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = '';
    });

    await Future.delayed(Duration(seconds: 2));

    if (_validateLicenseKey(_licenseController.text)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('license_key', _licenseController.text);
      await prefs.setBool('is_activated', true);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Chave de licença inválida. Verifique e tente novamente.';
      });
    }

    setState(() {
      _isValidating = false;
    });
  }

  void _showValidLicense() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Chave de Licença Válida', style: TextStyle(color: Colors.white)),
        content: SelectableText(
          _generateValidLicenseKey(),
          style: TextStyle(
            color: Color(0xFF8B4CF7),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar', style: TextStyle(color: Color(0xFF8B4CF7))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE53E3E).withOpacity(0.2),
              ),
              child: Icon(
                Icons.lock_outline,
                color: Color(0xFFE53E3E),
                size: 50,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Trial Expirado',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Seu período de trial de 5 dias expirou.\nPara continuar usando o app, insira sua chave de licença.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _licenseController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Chave de Licença',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'XXXX-XXXX-XXXX-XXXX',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF8B4CF7)),
                        ),
                        prefixIcon: Icon(Icons.vpn_key, color: Color(0xFF8B4CF7)),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 19,
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Color(0xFFE53E3E),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _validateLicense,
                        child: _isValidating
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Validando...'),
                                ],
                              )
                            : Text('Ativar Licença'),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _showValidLicense,
                      child: Text(
                        'Ver chave válida (Demo)',
                        style: TextStyle(color: Color(0xFF8B4CF7)),
                      ),
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

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    DashboardScreen(),
    ClientsScreen(),
    ScheduleScreen(),
    StylesScreen(),
    GalleryScreen(),
    BudgetScreen(),
    FinancialScreen(),
    SuppliesScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
    BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Agenda'),
    BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Estilos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Column(
        children: [
          TrialBanner(),
          Expanded(
            child: PageView(
              controller: _pageController,
              children: _screens,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _currentIndex < 4 
          ? BottomNavigationBar(
              backgroundColor: Color(0xFF1A1A1A),
              selectedItemColor: Color(0xFF8B4CF7),
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {