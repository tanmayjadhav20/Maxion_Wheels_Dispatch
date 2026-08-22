// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'app_button.dart';

class CameraScannerDialog extends StatefulWidget {
  final String scanType;
  final List<dynamic> pendingItems;
  final ValueChanged<String> onScanComplete;

  const CameraScannerDialog({
    super.key,
    required this.scanType,
    required this.pendingItems,
    required this.onScanComplete,
  });

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog> {
  final _customScanController = TextEditingController();
  html.MediaStream? _mediaStream;
  html.VideoElement? _videoElement;
  String _viewId = '';
  bool _cameraActive = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _viewId = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';
    _initSystemCamera();
  }

  void _initSystemCamera() async {
    try {
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..setAttribute('playsinline', 'true');

      _videoElement = video;

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => video);

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices != null) {
        final stream = await mediaDevices.getUserMedia({
          'video': {
            'facingMode': 'environment',
            'width': {'ideal': 1280},
            'height': {'ideal': 720}
          }
        });

        _mediaStream = stream;
        video.srcObject = stream;
        if (mounted) {
          setState(() {
            _cameraActive = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cameraError = 'Camera access not supported on this browser device.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera permission denied or camera device not found.';
        });
      }
    }
  }

  void _stopCamera() {
    try {
      if (_mediaStream != null) {
        for (var track in _mediaStream!.getTracks()) {
          track.stop();
        }
      }
      if (_videoElement != null) {
        _videoElement!.srcObject = null;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopCamera();
    _customScanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.bgSurfaceElevated,
      title: Row(
        children: [
          const Icon(Icons.camera_alt_outlined, color: AppColors.ribbonPink),
          const SizedBox(width: 8),
          Text(
            widget.scanType == 'LOCATION' ? 'SCAN RACK LOCATION BARCODE' : 'SCAN PALLET MASTER QR',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live System Camera Viewport Box
              Container(
                height: 220,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _cameraActive ? AppColors.ok : AppColors.ribbonPink,
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_cameraActive)
                      HtmlElementView(viewType: _viewId)
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _cameraError != null ? Icons.videocam_off_outlined : Icons.photo_camera,
                                color: AppColors.ribbonPink,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _cameraError ?? 'Requesting System Camera Access...',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Laser Viewfinder Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.ribbonPink,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ribbonPink.withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _cameraActive ? 'LIVE SYSTEM CAMERA FEED ACTIVE' : 'CAMERA STANDBY / HARDWARE SCAN',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Barcode Quick Action Chips
              Text(
                'Pending Picklist Items (Quick Tap or Auto Detect):',
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (widget.pendingItems.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.pendingItems.map((i) {
                    final val = widget.scanType == 'LOCATION' ? (i['locationCode'] ?? '') : (i['palletNumber'] ?? '');
                    return ActionChip(
                      avatar: Icon(widget.scanType == 'LOCATION' ? Icons.place : Icons.qr_code, size: 14, color: AppColors.ribbonPink),
                      label: Text(val, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      backgroundColor: AppColors.ribbonPink.withValues(alpha: 0.1),
                      onPressed: () {
                        _stopCamera();
                        widget.onScanComplete(val);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                )
              else
                Text(
                  'No pending items in active picklist.',
                  style: TextStyle(color: context.textMuted, fontSize: 12),
                ),
              const SizedBox(height: 14),

              // Manual Input / Hardware Scanner Focus Field
              TextField(
                controller: _customScanController,
                autofocus: true,
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: widget.scanType == 'LOCATION' ? 'Or Scan/Type Location Barcode' : 'Or Scan/Type Pallet QR Code',
                  hintText: widget.scanType == 'LOCATION' ? 'e.g. WH1-A-01-A1' : 'e.g. P26000101',
                  prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.ribbonPink),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _stopCamera();
                    widget.onScanComplete(val.trim());
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _stopCamera();
            Navigator.pop(context);
          },
          child: const Text('CANCEL'),
        ),
        AppButton(
          text: 'SUBMIT SCAN',
          variant: AppButtonVariant.gradient,
          onPressed: () {
            final text = _customScanController.text.trim();
            if (text.isNotEmpty) {
              _stopCamera();
              widget.onScanComplete(text);
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
