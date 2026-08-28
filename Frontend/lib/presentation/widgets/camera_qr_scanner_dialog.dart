import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'app_button.dart';
import 'pills.dart';

class CameraQrScannerDialog extends StatefulWidget {
  final String activeItemCode;
  final Function(String scannedQr) onQrScanned;

  const CameraQrScannerDialog({
    super.key,
    required this.activeItemCode,
    required this.onQrScanned,
  });

  static Future<String?> show({
    required BuildContext context,
    required String activeItemCode,
    required Function(String scannedQr) onQrScanned,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CameraQrScannerDialog(
        activeItemCode: activeItemCode,
        onQrScanned: onQrScanned,
      ),
    );
  }

  @override
  State<CameraQrScannerDialog> createState() => _CameraQrScannerDialogState();
}

class _CameraQrScannerDialogState extends State<CameraQrScannerDialog> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  final TextEditingController _manualInputController = TextEditingController();
  
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  String _viewId = '';
  bool _isCameraPermissionGranted = false;
  bool _isCameraError = false;
  String _errorMessage = '';
  bool _isTorchOn = false;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _initRealSystemCamera();
  }

  Future<void> _initRealSystemCamera() async {
    try {
      _viewId = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _videoElement!,
      );

      html.MediaStream? mediaStream;
      try {
        mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
          'video': {
            'facingMode': {'ideal': 'environment'},
            'width': {'ideal': 1280},
            'height': {'ideal': 720}
          }
        });
      } catch (_) {
        mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({'video': true});
      }

      if (mediaStream != null) {
        _mediaStream = mediaStream;
        _videoElement!.srcObject = mediaStream;
        await _videoElement!.play();
        if (mounted) {
          setState(() {
            _isCameraPermissionGranted = true;
          });
          _startBarcodeDetectionLoop();
        }
      } else {
        if (mounted) {
          setState(() {
            _isCameraError = true;
            _errorMessage = 'No system camera device detected on this hardware.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraError = true;
          _errorMessage = 'Camera access error: ${e.toString()}';
        });
      }
    }
  }

  void _startBarcodeDetectionLoop() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_videoElement == null || !_isCameraPermissionGranted) return;

      try {
        if (js.context.hasProperty('decodeVideoFrameQr')) {
          final dynamic decodedStr = js.context.callMethod('decodeVideoFrameQr', [_videoElement]);
          if (decodedStr != null && decodedStr.toString().trim().isNotEmpty) {
            _detectionTimer?.cancel();
            _onCaptureQr(decodedStr.toString().trim());
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _laserController.dispose();
    _manualInputController.dispose();
    _stopCameraStream();
    super.dispose();
  }

  void _stopCameraStream() {
    try {
      _detectionTimer?.cancel();
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _videoElement?.srcObject = null;
    } catch (_) {}
  }

  void _onCaptureQr(String qrData) {
    if (qrData.trim().isEmpty) return;
    _stopCameraStream();
    Navigator.of(context).pop(qrData.trim());
    widget.onQrScanned(qrData.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cameraContentWidget;
    if (_isCameraPermissionGranted && _viewId.isNotEmpty) {
      cameraContentWidget = HtmlElementView(viewType: _viewId);
    } else if (_isCameraError) {
      cameraContentWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, color: AppColors.warn, size: 44),
              const SizedBox(height: 10),
              Text(
                'System Camera Access Error',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
        ),
      );
    } else {
      cameraContentWidget = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.ribbonPink),
            SizedBox(height: 14),
            Text(
              'REQUESTING SYSTEM CAMERA PERMISSION...',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: isDark ? AppColors.bgSurfaceElevated : theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.ribbonPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: AppColors.ribbonPink, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HARDWARE CAMERA SCANNER',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Point camera at Wheel QR (${widget.activeItemCode})',
                              style: TextStyle(color: context.textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _stopCameraStream();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Camera Controls Pill Bar
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: _isCameraPermissionGranted ? 'CAMERA ACTIVE (LIVE)' : 'INITIALIZING CAMERA',
                  variant: _isCameraPermissionGranted ? PillVariant.ok : PillVariant.warn,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Toggle Torch / Brightness',
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? AppColors.ribbonOrange : context.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _isTorchOn = !_isTorchOn);
                      },
                    ),
                    IconButton(
                      tooltip: 'Refresh System Camera Stream',
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _stopCameraStream();
                        _initRealSystemCamera();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Real System Camera HTML Viewfinder
            Container(
              height: 260,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isCameraPermissionGranted ? AppColors.ribbonPink : AppColors.line,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Live Camera Stream
                  Positioned.fill(child: cameraContentWidget),

                  // Target Box Corner Overlays
                  if (_isCameraPermissionGranted)
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                  // Animated Red/Pink Laser Scan Line over live camera feed
                  if (_isCameraPermissionGranted)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: 40 + (_laserController.value * 180),
                          left: 45,
                          right: 45,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.ribbonPink.withValues(alpha: 0.2),
                                  AppColors.ribbonPink,
                                  AppColors.ribbonOrange,
                                  AppColors.ribbonPink.withValues(alpha: 0.2),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ribbonPink.withValues(alpha: 0.9),
                                  blurRadius: 10,
                                  spreadRadius: 1.5,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Captured Camera Frame Options
            Text(
              'CAPTURED CAMERA BARCODE FRAME:',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickCameraFrameButton(
                  context,
                  'Scan New Wheel QR',
                  'MW|P1|${widget.activeItemCode}|${(DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0')}|260826|A|PL1',
                ),
                _buildQuickCameraFrameButton(
                  context,
                  'Scan Wheel #0001742',
                  'MW|P1|${widget.activeItemCode}|000001742|260826|A|PL1',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Barcode Input / Overridden scanned string
            TextField(
              controller: _manualInputController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                labelText: 'CAMERA SCAN RESULT / BARCODE DATA',
                hintText: 'MW|P1|${widget.activeItemCode}|...',
                prefixIcon: const Icon(Icons.qr_code, color: AppColors.ribbonPink),
                filled: true,
                fillColor: context.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (val) => _onCaptureQr(val),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'CANCEL',
                    variant: AppButtonVariant.ghost,
                    onPressed: () {
                      _stopCameraStream();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'LOAD INTO PALLET',
                    icon: Icons.check,
                    variant: AppButtonVariant.gradient,
                    onPressed: () {
                      final input = _manualInputController.text.trim();
                      if (input.isNotEmpty) {
                        _onCaptureQr(input);
                      } else {
                        final serial = (DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0');
                        final generatedQr = 'MW|P1|${widget.activeItemCode}|$serial|260826|A|PL1';
                        _onCaptureQr(generatedQr);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCameraFrameButton(BuildContext context, String label, String qrData) {
    return ActionChip(
      avatar: const Icon(Icons.qr_code_2, size: 16, color: AppColors.ribbonPink),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: context.bgSurfaceElevated,
      onPressed: () => _onCaptureQr(qrData),
    );
  }
}
