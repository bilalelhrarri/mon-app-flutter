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
import '../widgets/custom_button.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  CameraController? _cameraController;
  final MlKitService _mlKit = MlKitService();
  final StorageService _storage = StorageService();
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _plateCtrl = TextEditingController();

  bool _isProcessing = false;
  String _eventType = 'entry';
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _mlKit.dispose();
    _plateCtrl.dispose();
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
      final picture = await _cameraController!.takePicture();
      final imageFile = File(picture.path);
      _capturedImage = imageFile;
      final plate = await _mlKit.extractPlateFromImage(imageFile);
      if (plate != null) {
        _plateCtrl.text = plate;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم التعرف على اللوحة، الرجاء الإدخال يدوياً')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصوير: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _submitLog() async {
    final plate = _plateCtrl.text.trim();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم اللوحة')),
      );
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
      _plateCtrl.clear();
      _capturedImage = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل ${_eventType == 'entry' ? 'دخول' : 'خروج'} الشاحنة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشغل - تسجيل دخول/خروج'),
        actions: [
          IconButton(
            onPressed: () => Provider.of<AppState>(context, listen: false).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                cameraReady
                    ? CameraView(controller: _cameraController!)
                    : const LoadingWidget(message: 'جاري تشغيل الكاميرا...'),
                if (cameraReady) const PlateOverlay(),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _plateCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, letterSpacing: 4),
                    decoration: const InputDecoration(
                      labelText: 'رقم اللوحة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('دخول'),
                        selected: _eventType == 'entry',
                        selectedColor: Colors.green,
                        onSelected: (_) => setState(() => _eventType = 'entry'),
                      ),
                      const SizedBox(width: 20),
                      ChoiceChip(
                        label: const Text('خروج'),
                        selected: _eventType == 'exit',
                        selectedColor: Colors.red,
                        onSelected: (_) => setState(() => _eventType = 'exit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'تصوير',
                          icon: Icons.camera_alt,
                          isLoading: _isProcessing,
                          onPressed: _captureAndRecognize,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          label: 'تسجيل',
                          icon: Icons.save,
                          isLoading: _isProcessing,
                          color: _eventType == 'entry' ? Colors.green : Colors.red,
                          onPressed: _submitLog,
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
    );
  }
}