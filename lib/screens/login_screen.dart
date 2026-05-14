import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد وكلمة المرور')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (mounted && appState.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
            backgroundColor: Color(0xFFB22222),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: const Color(0xFFB22222),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDeep   = Color(0xFF0A1628);
    const Color bgCard   = Color(0xFF0D1F36);
    const Color accent   = Color(0xFF1A6FA8);
    const Color accentLt = Color(0xFF7AADCC);
    const Color textPrim = Color(0xFFE8F4FD);
    const Color textMuted= Color(0xFF5B8DB8);
    const Color borderClr= Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: bgDeep,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo ──────────────────────────────────────
                    const _TangerMedLogo(),
                    const SizedBox(height: 12),
                    const Text(
                      'TANGER MED',
                      style: TextStyle(
                        color: textPrim,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PORT AUTHORITY',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Divider ───────────────────────────────────
                    Container(height: 1, color: borderClr),
                    const SizedBox(height: 28),

                    const Text(
                      'CONNEXION OPÉRATEUR',
                      style: TextStyle(
                        color: accentLt,
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Email ─────────────────────────────────────
                    _buildField(
                      controller: _emailCtrl,
                      label: 'ADRESSE EMAIL',
                      hint: 'operateur@tangermed.ma',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      bgCard: bgCard,
                      borderClr: borderClr,
                      textPrim: textPrim,
                      textMuted: textMuted,
                      accent: accent,
                    ),
                    const SizedBox(height: 14),

                    // ── Password ──────────────────────────────────
                    _buildField(
                      controller: _passCtrl,
                      label: 'MOT DE PASSE',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      bgCard: bgCard,
                      borderClr: borderClr,
                      textPrim: textPrim,
                      textMuted: textMuted,
                      accent: accent,
                    ),
                    const SizedBox(height: 28),

                    // ── Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          disabledBackgroundColor: accent.withOpacity(0.4),
                          foregroundColor: textPrim,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'CONNEXION',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Forgot password ───────────────────────────
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color bgCard,
    required Color borderClr,
    required Color textPrim,
    required Color textMuted,
    required Color accent,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontSize: 10,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: textPrim, fontSize: 14),
          cursorColor: accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: textMuted.withOpacity(0.5), fontSize: 13),
            prefixIcon: Icon(icon, color: textMuted, size: 18),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textMuted,
                      size: 18,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: bgCard,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderClr),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Logo widget ────────────────────────────────────────────────────────────────
class _TangerMedLogo extends StatelessWidget {
  const _TangerMedLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 72),
      painter: _HexLogoPainter(),
    );
  }
}

class _HexLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r  = size.width / 2;

    // Hexagon background
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * pi / 180;
      final x = cx + r * 0.92 * cos(angle);
      final y = cy + r * 0.92 * sin(angle);
      i == 0 ? hexPath.moveTo(x, y) : hexPath.lineTo(x, y);
    }
    hexPath.close();

    canvas.drawPath(hexPath, Paint()..color = const Color(0xFF0D2E4F));
    canvas.drawPath(
      hexPath,
      Paint()
        ..color = const Color(0xFF1A6FA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Gate icon
    final gatePaint = Paint()
      ..color = const Color(0xFF7AADCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final gate = Path();
    final double l   = cx - 14;
    final double rm  = cx + 14;
    final double top = cy - 8;
    final double bot = cy + 10;
    final double mid = cy;
    gate.moveTo(l, bot);
    gate.lineTo(l, top + 4);
    gate.lineTo(cx - 6, top);
    gate.lineTo(cx - 6, mid);
    gate.lineTo(cx + 6, mid);
    gate.lineTo(cx + 6, top);
    gate.lineTo(rm, top + 4);
    gate.lineTo(rm, bot);
    canvas.drawPath(gate, gatePaint);

    // Wave
    final wavePaint = Paint()
      ..color = const Color(0xFF1A6FA8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final wave = Path();
    wave.moveTo(cx - 18, cy + 14);
    wave.quadraticBezierTo(cx, cy + 6, cx + 18, cy + 14);
    canvas.drawPath(wave, wavePaint);

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy + 10),
      2.5,
      Paint()..color = const Color(0xFF7AADCC),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}