import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  static const Color bgDeep    = Color(0xFF0A1628);
  static const Color bgCard    = Color(0xFF0D1F36);
  static const Color accent    = Color(0xFF1A6FA8);
  static const Color accentLt  = Color(0xFF7AADCC);
  static const Color textPrim  = Color(0xFFE8F4FD);
  static const Color textMuted = Color(0xFF5B8DB8);
  static const Color borderClr = Color(0xFF1E3A5F);

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

  Future<void> _showForgotPassword() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: borderClr),
      ),
      builder: (ctx) => _ForgotPasswordSheet(parentContext: context),
    );
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
            content: Text(
              'Compte désactivé ou identifiants incorrects',
              style: TextStyle(fontSize: 12),
            ),
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
    return Scaffold(
      backgroundColor: bgDeep,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                          color: textMuted, fontSize: 11, letterSpacing: 3),
                    ),
                    const SizedBox(height: 32),
                    Container(height: 1, color: borderClr),
                    const SizedBox(height: 28),
                    const Text(
                      'CONNEXION OPÉRATEUR',
                      style: TextStyle(
                          color: accentLt, fontSize: 11, letterSpacing: 3),
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      controller: _emailCtrl,
                      label: 'ADRESSE EMAIL',
                      hint: 'operateur@tangermed.ma',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _passCtrl,
                      label: 'MOT DE PASSE',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          disabledBackgroundColor:
                              accent.withValues(alpha: 0.4),
                          foregroundColor: textPrim,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'CONNEXION',
                                style: TextStyle(
                                    fontSize: 13,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _showForgotPassword,
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
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: textMuted, fontSize: 10, letterSpacing: 2.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: textPrim, fontSize: 14),
          cursorColor: accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: textMuted.withValues(alpha: 0.5), fontSize: 13),
            prefixIcon: Icon(icon, color: textMuted, size: 18),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textMuted, size: 18,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: bgCard,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderClr),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Forgot Password Sheet ─────────────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  final BuildContext parentContext;
  const _ForgotPasswordSheet({required this.parentContext});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  static const Color bgDeep    = Color(0xFF0A1628);
  static const Color accent    = Color(0xFF1A6FA8);
  static const Color accentLt  = Color(0xFF7AADCC);
  static const Color textPrim  = Color(0xFFE8F4FD);
  static const Color textMuted = Color(0xFF5B8DB8);
  static const Color borderClr = Color(0xFF1E3A5F);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) Navigator.pop(context);
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('Email envoyé à $email',
                style: const TextStyle(color: textPrim, fontSize: 12)),
            backgroundColor: const Color(0xFF0D3320),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF1A5C38)),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email introuvable',
                style: const TextStyle(color: textPrim, fontSize: 12)),
            backgroundColor: const Color(0xFF3D0000),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF7A0000)),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: borderClr,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'MOT DE PASSE OUBLIÉ',
            style: TextStyle(
              color: accentLt,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entrez votre email — vous recevrez un lien de réinitialisation automatiquement.',
            style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: textPrim, fontSize: 14),
            cursorColor: accent,
            decoration: InputDecoration(
              hintText: 'operateur@tangermed.ma',
              hintStyle: TextStyle(
                  color: textMuted.withValues(alpha: 0.5), fontSize: 13),
              prefixIcon: const Icon(Icons.alternate_email_rounded,
                  color: textMuted, size: 18),
              filled: true,
              fillColor: bgDeep,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: borderClr),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: accent.withValues(alpha: 0.4),
                foregroundColor: textPrim,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'ENVOYER LE LIEN',
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────
class _TangerMedLogo extends StatelessWidget {
  const _TangerMedLogo();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(72, 72), painter: _HexLogoPainter());
}

class _HexLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r  = size.width / 2;

    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * pi / 180;
      final x = cx + r * 0.92 * cos(angle);
      final y = cy + r * 0.92 * sin(angle);
      i == 0 ? hexPath.moveTo(x, y) : hexPath.lineTo(x, y);
    }
    hexPath.close();
    canvas.drawPath(hexPath, Paint()..color = const Color(0xFF0D2E4F));
    canvas.drawPath(hexPath,
        Paint()
          ..color = const Color(0xFF1A6FA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    final gatePaint = Paint()
      ..color = const Color(0xFF7AADCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final gate = Path();
    final l   = cx - 14, rm = cx + 14;
    final top = cy - 8,  bot = cy + 10, mid = cy;
    gate.moveTo(l, bot);
    gate.lineTo(l, top + 4);
    gate.lineTo(cx - 6, top);
    gate.lineTo(cx - 6, mid);
    gate.lineTo(cx + 6, mid);
    gate.lineTo(cx + 6, top);
    gate.lineTo(rm, top + 4);
    gate.lineTo(rm, bot);
    canvas.drawPath(gate, gatePaint);

    final wave = Path();
    wave.moveTo(cx - 18, cy + 14);
    wave.quadraticBezierTo(cx, cy + 6, cx + 18, cy + 14);
    canvas.drawPath(
        wave,
        Paint()
          ..color = const Color(0xFF1A6FA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    canvas.drawCircle(Offset(cx, cy + 10), 2.5,
        Paint()..color = const Color(0xFF7AADCC));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}