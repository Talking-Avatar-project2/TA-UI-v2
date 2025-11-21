import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ta_ui_new/models/user_model.dart';
import 'package:ta_ui_new/services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  UserModel? _userProfile;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    try {
      final profile = await _userService.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      // Manejo silencioso o log
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: _signOut,
              tooltip: 'Cerrar Sesión',
            ),
          )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Saludo Personalizado
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hola,",
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    Text(
                      _userProfile?.fullName ?? "Bienvenido",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Tarjeta Principal con Animación Typewriter
              _buildProfileBentoCard(),

              const SizedBox(height: 20),

              // 3. Grid Bento
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1, 
                  children: [
                    _buildBentoItem(
                      title: "Chatbot",
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.blueAccent,
                      route: "/chatbot",
                    ),
                    _buildBentoItem(
                      title: "Avatar",
                      icon: Icons.face_retouching_natural_rounded,
                      color: Colors.green,
                      route: "/camera",
                    ),
                    _buildBentoItem(
                      title: "Para Ti",
                      subtitle: "Recomendaciones",
                      icon: Icons.favorite_border_rounded,
                      color: Colors.redAccent,
                      route: "/recommendations",
                    ),
                    _buildBentoItem(
                      title: "Progreso",
                      icon: Icons.bar_chart_rounded,
                      color: Colors.orange,
                      route: "/progress",
                    ),
                    _buildBentoItem(
                      title: "Evaluación",
                      icon: Icons.assignment_outlined,
                      color: Colors.purpleAccent,
                      route: "/evaluation",
                    ),
                    _buildBentoItem(
                      title: "Ajustes",
                      icon: Icons.settings_outlined,
                      color: Colors.teal,
                      route: "/profile",
                      isDark: true, 
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TARJETA PRINCIPAL ACTUALIZADA
  Widget _buildProfileBentoCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/chatbot'); // Quizás esto debería ir al chat?
      },
      child: Container(
        width: double.infinity,
        height: 120, // Altura fija para mantener consistencia
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2575FC).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: _userProfile?.photoUrl != null && _userProfile!.photoUrl!.isNotEmpty
                    ? NetworkImage(_userProfile!.photoUrl!)
                    : null,
                child: _userProfile?.photoUrl == '' || _userProfile?.photoUrl == null
                    ? const Icon(Icons.person, size: 30, color: Color(0xFF6A11CB))
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            
            // Texto Animado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "¿Quieres...",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  // Widget Personalizado de Máquina de Escribir
                  _TypewriterText(
                    texts: const [
                      "Hablar?",
                      "Cuestionar?",
                      "Desahogarte?",
                      "Está bien, aquí estoy."
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20, // Letra más grande para impacto
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoItem({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required String route,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, route);
        if (route == '/profile') _loadUserProfile();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D3436) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: isDark ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET PERSONALIZADO: Typewriter Text
// ==========================================
class _TypewriterText extends StatefulWidget {
  final List<String> texts;
  final TextStyle style;

  const _TypewriterText({required this.texts, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _currentText = "";
  int _currentIndex = 0;
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    // Velocidad de escritura: 100ms, Borrado: 50ms
    const typingSpeed = Duration(milliseconds: 100);
    const deletingSpeed = Duration(milliseconds: 50);
    const pauseDuration = Duration(milliseconds: 2000); // Pausa al terminar frase

    _timer = Timer.periodic(
      _isDeleting ? deletingSpeed : typingSpeed,
      (timer) {
        if (!mounted) return;

        final fullText = widget.texts[_currentIndex];

        setState(() {
          if (_isDeleting) {
            // Logica de borrado
            if (_charIndex > 0) {
              _charIndex--;
              _currentText = fullText.substring(0, _charIndex);
            } else {
              // Terminó de borrar, cambiar a siguiente palabra
              _isDeleting = false;
              _currentIndex = (_currentIndex + 1) % widget.texts.length;
              timer.cancel();
              _startTyping(); // Reiniciar timer
            }
          } else {
            // Lógica de escritura
            if (_charIndex < fullText.length) {
              _charIndex++;
              _currentText = fullText.substring(0, _charIndex);
            } else {
              // Terminó de escribir, esperar un momento
              _isDeleting = true;
              timer.cancel();
              Future.delayed(pauseDuration, () {
                if (mounted) _startTyping();
              });
            }
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentText,
          style: widget.style,
        ),
        // Cursor parpadeante simple
        _BlinkingCursor(style: widget.style),
      ],
    );
  }
}

// Cursor simple |
class _BlinkingCursor extends StatefulWidget {
  final TextStyle style;
  const _BlinkingCursor({required this.style});
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text("|", style: widget.style.copyWith(fontWeight: FontWeight.w100)),
    );
  }
}