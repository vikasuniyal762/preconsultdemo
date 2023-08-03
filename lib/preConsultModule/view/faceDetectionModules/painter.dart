import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:medongosupport/preConsultModule/controllers/preConsultationController.dart';
import 'package:medongosupport/preConsultModule/widgets/coordinatesTranslator.dart';


class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.faces, this.absoluteImageSize, this.rotation);

  final List<Face> faces;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final Face face in faces) {
      // preConsultationController.imgBottom.value= translateY(face.boundingBox.bottom, rotation, size, absoluteImageSize); preConsultationController.imgLeft.value= translateX(face.boundingBox.left, rotation, size, absoluteImageSize);
      // preConsultationController.imgRight.value= translateX(face.boundingBox.right, rotation, size, absoluteImageSize);
      // preConsultationController.imgTop.value= translateY(face.boundingBox.top, rotation, size, absoluteIma
      canvas.drawRect(
        Rect.fromLTRB(
          translateX(face.boundingBox.left, rotation, size, absoluteImageSize),
          translateY(face.boundingBox.top, rotation, size, absoluteImageSize),
          translateX(face.boundingBox.right, rotation, size, absoluteImageSize),
          translateY(
              face.boundingBox.bottom, rotation, size, absoluteImageSize),
        ),
        paint,
      );
      // for (final Face face in faces) {
      //   final Rect boundingBox = face.boundingBox;
      //   final double left =
      //   translateX(boundingBox.left, rotation, size, absoluteImageSize);
      //   final double top =
      //   translateY(boundingBox.top, rotation, size, absoluteImageSize);
      //
      //   final double right =
      //   translateX(boundingBox.right, rotation, size, absoluteImageSize);
      //   final double bottom =
      //   translateY(boundingBox.bottom, rotation, size, absoluteImageSize);
      //
      //
      //   canvas.drawRect(
      //     Rect.fromLTRB(left, top, right, bottom),
      //     paint,
      //   );
      // }
      ///

    }
  }
  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}