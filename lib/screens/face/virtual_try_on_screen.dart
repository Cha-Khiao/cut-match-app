import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cut_match_app/api/face_analysis_service.dart';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/utils/app_theme.dart';
import 'package:cut_match_app/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final File userImageFile;
  final String hairstyleOverlayUrl;

  const VirtualTryOnScreen({
    super.key,
    required this.userImageFile,
    required this.hairstyleOverlayUrl,
  });

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final FaceAnalysisService _aiService = FaceAnalysisService();
  Face? _detectedFace;
  Size? _imageSize;
  bool _isLoading = true;
  bool _isProcessing = false;

  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _rotation = 0.0;

  Offset _initialCalculatedOffset = Offset.zero;
  double _initialCalculatedScale = 1.0;
  bool _isHairstyleVisible = true;
  bool _isInitialized = false;

  Offset _initialFocalPoint = Offset.zero;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _analyzeFace();
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _analyzeFace() async {
    final decodedImage = await decodeImageFromList(
      widget.userImageFile.readAsBytesSync(),
    );
    _imageSize = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );
    final faces = await _aiService.analyzeImage(widget.userImageFile);
    if (mounted) {
      setState(() {
        _detectedFace = faces?.isNotEmpty == true ? faces!.first : null;
        _isLoading = false;
      });
    }
  }

  void _resetTransform() {
    setState(() {
      _offset = _initialCalculatedOffset;
      _scale = _initialCalculatedScale;
      _rotation = 0.0;
    });
  }

  Future<File?> _captureLook() async {
    if (_isProcessing) return null;
    setState(() => _isProcessing = true);
    try {
      RenderRepaintBoundary boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/captured_look.png',
        ).writeAsBytes(imageBytes);
        return file;
      }
    } catch (e) {
      print("Error capturing look: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
    return null;
  }

  Future<void> _saveLook() async {
    final imageFile = await _captureLook();
    if (imageFile == null) return;

    try {
      await Gal.putImage(imageFile.path, album: 'Cut Match');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.addLook(imageFile);

      if (mounted) {
        NotificationHelper.showSuccess(
          context,
          message: 'บันทึกรูปภาพลงในแกลเลอรีและโปรไฟล์แล้ว!',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context,
          message: 'ไม่สามารถบันทึกได้ กรุณาตรวจสอบสิทธิ์การเข้าถึง',
        );
      }
    }
  }

  Future<void> _shareLook() async {
    final imageFile = await _captureLook();
    if (imageFile == null) return;

    try {
      await Share.shareXFiles([
        XFile(imageFile.path),
      ], text: 'ฉันเพิ่งลองทรงผมใหม่ด้วยแอป Cut Match!');
    } catch (e) {
      print("Error sharing look: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkText,
      appBar: AppBar(
        title: const Text('ลองทรงผมเสมือนจริง'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppTheme.primary)
            : _detectedFace == null
            ? const Text(
                'ไม่สามารถตรวจจับใบหน้าได้',
                style: TextStyle(color: Colors.white),
              )
            : _buildTryOnWidget(),
      ),
      bottomNavigationBar: _isLoading || _detectedFace == null
          ? null
          : _buildControlPanel(theme),
    );
  }

  Widget _buildTryOnWidget() {
    return RepaintBoundary(
      key: _boundaryKey,
      child: AspectRatio(
        aspectRatio: _imageSize!.width / _imageSize!.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = constraints.biggest;
            final imageSize = _imageSize!;
            final scaleX = screenSize.width / imageSize.width;
            final scaleY = screenSize.height / imageSize.height;
            final faceBox = _detectedFace!.boundingBox;

            if (!_isInitialized) {
              _initialCalculatedOffset = Offset(
                faceBox.center.dx * scaleX,
                (faceBox.top - (faceBox.height * 0.25)) * scaleY,
              );
              _initialCalculatedScale = (faceBox.width * 1.5) / 200.0 * scaleX;
              _offset = _initialCalculatedOffset;
              _scale = _initialCalculatedScale;
              _isInitialized = true;
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(widget.userImageFile, fit: BoxFit.contain),
                Visibility(
                  visible: _isHairstyleVisible,
                  child: Positioned(
                    left: _offset.dx,
                    top: _offset.dy,
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _initialFocalPoint = details.localFocalPoint;
                        _initialScale = _scale;
                        _initialRotation = _rotation;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          final delta =
                              details.localFocalPoint - _initialFocalPoint;
                          _offset = _offset + delta;
                          _scale = _initialScale * details.scale;
                          _rotation = _initialRotation + details.rotation;
                          _initialFocalPoint = details.localFocalPoint;
                        });
                      },
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(100.0, 100.0)
                          ..scale(_scale)
                          ..rotateZ(_rotation)
                          ..translate(-100.0, -100.0),
                        child: Image.network(
                          widget.hairstyleOverlayUrl,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkText.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.replay,
                label: 'ตั้งค่าใหม่',
                onPressed: _resetTransform,
              ),
              _buildControlButton(
                icon: _isHairstyleVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                label: 'เปรียบเทียบ',
                onPressed: () =>
                    setState(() => _isHairstyleVisible = !_isHairstyleVisible),
              ),
              _buildControlButton(
                icon: Icons.share_outlined,
                label: 'แชร์',
                onPressed: _isProcessing ? null : _shareLook,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _saveLook,
              icon: const Icon(Icons.download),
              label: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('บันทึกรูปภาพ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 28,
          color: Colors.white,
          disabledColor: Colors.white38,
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}