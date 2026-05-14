import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ml_kit_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../models/plate_event.dart';
import '../utils/plate_validator.dart';
import '../providers/app_state.dart';
import '../widgets/camera_view.dart';
import '../widgets/plate_overlay.dart';
import '../widgets/loading_widget.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen>
    with SingleTickerProviderStateMixin {
  // ── Colors ────────────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFF0A1628);
  static const Color bgCard    = Color(0xFF0D1F36);
  static const Color accent    = Color(0xFF1A6FA8);
  static const Color accentLt  = Color(0xFF7AADCC);
  static const Color textPrim  = Color(0xFFE8F4FD);
  static const Color textMuted = Color(0xFF5B8DB8);
  static const Color borderClr = Color(0xFF1E3A5F);
  static const Color colorGreen= Color(0xFF2ECC71);
  static const Color colorRed  = Color(0xFFE74C3C);

  CameraController? _cameraController;
  final MlKitService    _mlKit     = MlKitService();
  final StorageService  _storage   = StorageService();
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _plateCtrl = TextEditingController();

  bool    _isProcessing = false;
  bool    _cameraExpanded = false;
  String  _eventType = 'entry';
  File?   _capturedImage;
  String? _lastPlate;
  String? _lastEvent;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _mlKit.dispose();
    _plateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _isProcessing = true);
    try {
      final picture   = await _cameraController!.takePicture();
      final imageFile = File(picture.path);
      _capturedImage  = imageFile;
      final plate     = await _mlKit.extractPlateFromImage(imageFile);
      if (plate != null) {
        _plateCtrl.text = plate;
        setState(() => _cameraExpanded = false);
      } else {
        if (mounted) {
          _showSnack('لم يتم التعرف على اللوحة — أدخل يدوياً', colorRed);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('خطأ في التصوير: $e', colorRed);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _submitLog() async {
    final plate = _plateCtrl.text.trim();
    if (plate.isEmpty) {
      _showSnack('أدخل رقم اللوحة', colorRed);
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final user = Provider.of<AppState>(context, listen: false).user!;
      String photoUrl = '';
      if (_capturedImage != null) {
        photoUrl = await _storage.uploadPhoto(_capturedImage!, plate);
      }
      final event = PlateEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plateNumber: plate,
        plateNormalized: PlateValidator.normalizePlate(plate),
        eventType: _eventType,
        timestamp: DateTime.now(),
        gateId: user.gateId,
        operatorId: user.uid,
        operatorName: user.displayName,
        photoUrl: photoUrl,
        ocrConfidence: 0.8,
        manuallyCorrected: false,
      );
      await _firestore.addPlateEvent(event);

      setState(() {
        _lastPlate = plate;
        _lastEvent = _eventType;
      });
      _plateCtrl.clear();
      _capturedImage = null;

      _showSnack(
        '${_eventType == 'entry' ? 'ENTRÉE' : 'SORTIE'} enregistrée — $plate',
        _eventType == 'entry' ? colorGreen : colorRed,
      );
    } catch (e) {
      if (mounted) _showSnack('خطأ: $e', colorRed);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: textPrim, fontSize: 12, letterSpacing: 0.5)),
      backgroundColor: bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user       = Provider.of<AppState>(context).user;
    final cameraReady =
        _cameraController != null && _cameraController!.value.isInitialized;
    final isEntry    = _eventType == 'entry';

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: _buildAppBar(user?.displayName ?? ''),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Gate info chip ────────────────────────────────
            if (user != null) _buildGateChip(user.gateId),

            const SizedBox(height: 14),

            // ── Camera section ────────────────────────────────
            _buildCameraSection(cameraReady),

            const SizedBox(height: 14),

            // ── Plate input ───────────────────────────────────
            _buildPlateInput(),

            const SizedBox(height: 14),

            // ── Entry / Exit toggle ───────────────────────────
            _buildEventToggle(isEntry),

            const SizedBox(height: 14),

            // ── Submit button ─────────────────────────────────
            _buildSubmitButton(isEntry),

            const SizedBox(height: 14),

            // ── Last registered card ──────────────────────────
            if (_lastPlate != null) _buildLastCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────
  AppBar _buildAppBar(String name) => AppBar(
    backgroundColor: bgCard,
    elevation: 0,
    titleSpacing: 16,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OPÉRATEUR',
            style: TextStyle(
                color: textPrim, fontSize: 14,
                fontWeight: FontWeight.w700, letterSpacing: 2)),
        const Text('TANGER MED · GATE OPS',
            style: TextStyle(
                color: textMuted, fontSize: 9, letterSpacing: 2)),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: GestureDetector(
          onTap: () =>
              Provider.of<AppState>(context, listen: false).logout(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgDeep,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderClr),
            ),
            child: const Row(
              children: [
                Text('QUITTER',
                    style: TextStyle(
                        color: textMuted, fontSize: 9, letterSpacing: 1.5)),
                SizedBox(width: 6),
                Icon(Icons.logout_rounded, color: textMuted, size: 13),
              ],
            ),
          ),
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: borderClr),
    ),
  );

  // ── Gate chip ─────────────────────────────────────────────────────────
  Widget _buildGateChip(String gateId) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderClr),
    ),
    child: Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                color: colorGreen, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('EN SERVICE', style: TextStyle(
            color: colorGreen.withOpacity(0.8),
            fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w600)),
        const Spacer(),
        const Icon(Icons.location_on_rounded, color: textMuted, size: 12),
        const SizedBox(width: 4),
        Text(gateId,
            style: const TextStyle(
                color: textMuted, fontSize: 11, letterSpacing: 1)),
      ],
    ),
  );

  // ── Camera section ────────────────────────────────────────────────────
  Widget _buildCameraSection(bool cameraReady) => Container(
    decoration: BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderClr),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        // Header row
        InkWell(
          onTap: () => setState(() => _cameraExpanded = !_cameraExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_rounded, color: accentLt, size: 16),
                const SizedBox(width: 10),
                const Text('SCANNER PLAQUE',
                    style: TextStyle(
                        color: textPrim, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                const Spacer(),
                Icon(
                  _cameraExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: textMuted, size: 18,
                ),
              ],
            ),
          ),
        ),
        // Camera preview (collapsible)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _cameraExpanded
              ? Column(
                  children: [
                    Container(height: 1, color: borderClr),
                    SizedBox(
                      height: 220,
                      child: Stack(
                        children: [
                          cameraReady
                              ? CameraView(controller: _cameraController!)
                              : const LoadingWidget(
                                  message: 'جاري تشغيل الكاميرا...'),
                          if (cameraReady) const PlateOverlay(),
                        ],
                      ),
                    ),
                    Container(height: 1, color: borderClr),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 38,
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: accent, strokeWidth: 2),
                              ),
                            )
                          : GestureDetector(
                              onTap: _captureAndRecognize,
                              child: Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accent),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_rounded,
                                        color: accentLt, size: 16),
                                    SizedBox(width: 8),
                                    Text('CAPTURER',
                                        style: TextStyle(
                                            color: accentLt,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  // ── Plate input ───────────────────────────────────────────────────────
  Widget _buildPlateInput() => Container(
    decoration: BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderClr),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    child: Row(
      children: [
        const Icon(Icons.directions_car_rounded, color: textMuted, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _plateCtrl,
            textAlign: TextAlign.left,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                color: textPrim,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 3),
            cursorColor: accent,
            decoration: const InputDecoration(
              hintText: 'NUMÉRO DE PLAQUE',
              hintStyle: TextStyle(
                  color: Color(0xFF3A6A8E),
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.normal),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        if (_plateCtrl.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: textMuted, size: 16),
            onPressed: () {
              _plateCtrl.clear();
              setState(() {});
            },
          ),
      ],
    ),
  );

  // ── Event toggle ──────────────────────────────────────────────────────
  Widget _buildEventToggle(bool isEntry) => Row(
    children: [
      Expanded(child: _toggleChip('ENTRÉE', 'entry', colorGreen,
          const Color(0xFF0D3320), const Color(0xFF1A5C38), isEntry)),
      const SizedBox(width: 10),
      Expanded(child: _toggleChip('SORTIE', 'exit', colorRed,
          const Color(0xFF3D0000), const Color(0xFF7A0000), !isEntry)),
    ],
  );

  Widget _toggleChip(String label, String type, Color fg, Color bg,
      Color border, bool active) =>
      GestureDetector(
        onTap: () => setState(() => _eventType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active ? bg : bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? border : borderClr, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == 'entry'
                    ? Icons.login_rounded
                    : Icons.logout_rounded,
                color: active ? fg : textMuted,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? fg : textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Submit button ─────────────────────────────────────────────────────
  Widget _buildSubmitButton(bool isEntry) => GestureDetector(
    onTap: _isProcessing ? null : _submitLog,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      decoration: BoxDecoration(
        color: isEntry
            ? const Color(0xFF0D3320)
            : const Color(0xFF3D0000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEntry
              ? const Color(0xFF1A5C38)
              : const Color(0xFF7A0000),
          width: 1.5,
        ),
      ),
      child: Center(
        child: _isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isEntry ? colorGreen : colorRed,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEntry ? Icons.login_rounded : Icons.logout_rounded,
                    color: isEntry ? colorGreen : colorRed,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEntry
                        ? 'ENREGISTRER ENTRÉE'
                        : 'ENREGISTRER SORTIE',
                    style: TextStyle(
                      color: isEntry ? colorGreen : colorRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );

  // ── Last registered card ──────────────────────────────────────────────
  Widget _buildLastCard() {
    final isEnt = _lastEvent == 'entry';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderClr),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isEnt ? const Color(0xFF0D3320) : const Color(0xFF3D0000),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isEnt
                      ? const Color(0xFF1A5C38)
                      : const Color(0xFF7A0000)),
            ),
            child: Icon(
              isEnt ? Icons.login_rounded : Icons.logout_rounded,
              color: isEnt ? colorGreen : colorRed,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DERNIER ENREGISTREMENT',
                    style: TextStyle(
                        color: textMuted, fontSize: 8, letterSpacing: 2)),
                const SizedBox(height: 3),
                Text(_lastPlate!,
                    style: const TextStyle(
                        color: textPrim,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEnt
                  ? const Color(0xFF0D3320)
                  : const Color(0xFF3D0000),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: isEnt
                      ? const Color(0xFF1A5C38)
                      : const Color(0xFF7A0000)),
            ),
            child: Text(
              isEnt ? 'ENTRÉE' : 'SORTIE',
              style: TextStyle(
                  color: isEnt ? colorGreen : colorRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

}