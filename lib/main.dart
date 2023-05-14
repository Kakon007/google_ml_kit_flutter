import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';

List<CameraDescription>? cameras;
CameraController? controller;
FaceDetector? faceDetector;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: EasyLoading.init(),
      home: CameraPreviewScreen(),
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
    List<Face> _faces = [];

  void showCapturedImage(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Face Detected'),
          content: Container(
            child: Image.file(imageFile),
          ),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void detectFaces() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }

    XFile imageFile = await controller!.takePicture();
    InputImage inputImage = InputImage.fromFile(File(imageFile.path));
    _faces = await faceDetector!.processImage(inputImage);

    if (_faces.isNotEmpty) {
      EasyLoading.showSuccess('Face detected, image captured');
      print('Face detected, image captured');
      showCapturedImage(File(imageFile.path));
    } else {
            EasyLoading.showSuccess('No face detected, trying again...');

      print('No face detected, trying again...');
      detectFaces();
    }
  }

  @override
  void initState() {
    super.initState();

    faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(enableClassification: true,enableContours: true,enableTracking: true,performanceMode: FaceDetectorMode.accurate),
    );

    controller = CameraController(cameras![1], ResolutionPreset.high);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      detectFaces();
    });
  }

  @override
  void dispose() {
    controller!.dispose();
    faceDetector!.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller!.value.isInitialized) {
      return Container();
    }
    // final size = MediaQuery.of(context).size;
    // final deviceRatio = size.width / size.height;
    return Scaffold(
      appBar: AppBar(title: Text('Face Detection Camera')),
      body:  CameraPreview(controller!),
    );
  }
}


class FacePainter extends CustomPainter {
  final List<Face> faces;
  final double deviceRatio;

  FacePainter(this.faces, this.deviceRatio);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (var face in faces) {
      final faceRect = Rect.fromLTRB(
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.right,
        face.boundingBox.bottom,
      );

      // Adjust the face rectangle based on the device ratio
      final scaledRect = Rect.fromLTRB(
        faceRect.left * deviceRatio,
        faceRect.top * deviceRatio,
        faceRect.right * deviceRatio,
        faceRect.bottom * deviceRatio,
      );

      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
