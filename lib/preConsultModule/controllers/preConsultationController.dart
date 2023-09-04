import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:medongosupport/preConsultModule/view/faceDetectionModules/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:medongosupport/preConsultModule/consts/screenSize.dart';
import 'package:medongosupport/preConsultModule/controllers/attachmentsController.dart';
import 'package:medongosupport/preConsultModule/controllers/questionsController.dart';
import 'package:medongosupport/preConsultModule/controllers/userController.dart';
import 'package:medongosupport/preConsultModule/models/androidNativeDataTransferModel.dart';
import 'package:medongosupport/preConsultModule/view/questionModules/questionsScreen.dart';
import 'package:medongosupport/preConsultModule/widgets/fullScreenImage.dart';
import 'package:medongosupport/preConsultModule/widgets/toastMessage.dart';
import 'package:light/light.dart';
import 'package:image/image.dart' as img;

import '../widgets/alertDialogs.dart';

final PCPreConsultationController preConsultationController =
Get.find<PCPreConsultationController>();

class PCPreConsultationController extends GetxController {
  ///IMAGE FILE PATH FOR UI
  RxString imageForDisplayInTheDevice = "".obs;

  ///LOADING STATUS FOR CAPTURE IMAGE AND VIDEO CAMERA SCREEN
  RxBool isLoadingFaceDetectorPage = false.obs;

  RxBool isLoadingPermissionsPage = true.obs;

  ///GIVES US THE DESCRIPTION WHAT CAMERA IS DOING WITH RESPECT TO DIRECTION AND MAGNITUDE
  // List<CameraDescription> cameras = [];
  CameraDescription cameraDescriptionMain = const CameraDescription(
      name: "0",
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90);

  ///PreConsultationServices Instance
  ///TODO uncomment after filling the code in the preConsultation services
  // PreConsultationServices preConsultationServices = PreConsultationServices();

  ///CAMERA CONTROLLER FOR CAPTURING IMAGE AND VIDEO
  //late CameraController captureImageController;

  ///CALL BACK METHOD TO HANDLE STATE OF CAPTURING IMAGE AND VIDEO
  late Future<void> initializeFutureCameraController;

  ///MANAGES STATE OF RECORDING
  RxBool isRecording = false.obs;

  ///USED IN DETECTOR
  RxBool canProcess = true.obs;

  ///USED IN DETECTOR
  RxBool isBusy = false.obs;

  ///USED IN DETECTOR
  RxString? text = ''.obs;

  ///USED IN DETECTOR
  RxInt faceCount = 0.obs;

  ///USED IN DETECTOR
  CustomPaint? customPaint;

  ///USED IN CAMERA
  // Timer? timer;

  ///USED IN DETECTOR
  RxInt frameCounter = 0.obs;

  resetFrameCounter() async {
    preConsultationController.frameCounter.value = 0;
    update();
  }

  int frameInterval = 3;

  ///USED IN CAMERA
  RxBool hideButton = false.obs;

  ///USED IN CAMERA TO SEE IF RESOURCE RELEASE OR NOT
  RxBool isReleased = false.obs;

  ///GET VIDEO QUALITY PARAMETERS
  RxDouble grayScale = (0.0).obs;
  RxBool lowLight = false.obs;
  RxBool badQuality = false.obs;
  RxInt lux = 0.obs;


  ///VIKAS CHANGES
  void calculateAverageGrayscaleBrightnessNew(CameraImage image) {
    try {
      int left = preConsultationController.left.value;
      int top = preConsultationController.top.value;
      int right = preConsultationController.right.value;
      int bottom = preConsultationController.bottom.value;

      if (left != 0 && top != 0 && right != 0 && bottom != 0) {
        double btSumInside = 0;
        double btSumOutside = 0;
        int totalPixelsInside = 0;
        int totalPixelsOutside = 0;

        final plane = image.planes[0];
        final bytes = plane.bytes;

        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            int index = y * plane.bytesPerRow + x;
            if (x >= left && x <= right && y >= top && y <= bottom) {
              if (index < bytes.length) {
                final yValue = bytes[index];
                btSumInside += yValue;
                totalPixelsInside++;
              }
            } else {
              if (index < bytes.length) {
                final yValue = bytes[index];
                btSumOutside += yValue;
                totalPixelsOutside++;
              }
            }
          }
        }

        double averageGrayscaleInside = btSumInside / totalPixelsInside;
        double averageGrayscaleOutside = btSumOutside / totalPixelsOutside;

        debugPrint('Average grayscale inside Bounding box: $averageGrayscaleInside');
        debugPrint('Average grayscale outside Bounding box: $averageGrayscaleOutside');

        preConsultationController.grayScale.value = averageGrayscaleInside;
        preConsultationController.grayScale.value < 135
            ? preConsultationController.badQuality.value = true
            : preConsultationController.badQuality.value = false;
      }
    } catch (e) {
      debugPrint('Error calculating average grayscale brightness: $e');
    }
  }

  ///VIDEO QUALITY PARAMETER (GRAYSCALE BRIGHTNESS)
  void calculateAverageGrayscaleBrightness(CameraImage image) {

    // try{
    //   /// GET THE VALUE OF BOUNDING BOX COORDINATES
    //   int left = preConsultationController.left.value;
    //   int top = preConsultationController.top.value;
    //   int right = preConsultationController.right.value;
    //   int bottom = preConsultationController.bottom.value;
    //
    //
    //   if (left != 0 && top != 0 && right != 0 && bottom != 0) {
    //     double btSum = 0;
    //     double btSm = 0;
    //     int totalPixels = 0;
    //     ///
    //     int tpix=image.width * image.height;
    //     ///
    //     final plane =
    //     image.planes[0]; // Assuming Y component is stored in the first plane
    //     final bytes = plane.bytes;
    //     for (int y = top; y <= bottom; y++) {
    //       for (int x = left; x <= right; x++) {
    //         // Calculate the index in the bytes array for the current (x, y) pixel
    //         int index = y * plane.bytesPerRow + x;
    //
    //         // Ensure that the index is within bounds
    //         if (index < bytes.length) {
    //           final yValue = bytes[index];
    //           btSum += yValue;
    //           totalPixels++;
    //         }
    //       }
    //     }
    //     ///
    //     final bts = plane.bytes;
    //     for (int j = 0; j < bts.length; j++) {
    //       final yVle = bts[j];
    //       btSm += yVle;
    //     }
    //
    //     preConsultationController.grayScale.value = btSm / tpix;
    //     print('Grayscale : ${preConsultationController.grayScale.value}');
    //
    //     ///
    //
    //
    //     double averageGrayscale = btSum / totalPixels;
    //     print('Average grayscale inside Bounding box : $averageGrayscale');
    //     preConsultationController.grayScale.value = averageGrayscale;
    //     preConsultationController.grayScale.value < 135 ?
    //     preConsultationController.badQuality.value = true
    //         :
    //     preConsultationController.badQuality.value = false;
    //
    //     /// RESETTING THE BOUNDING BOX PARAMETERS
    //     preConsultationController.left.value=0;
    //     preConsultationController.top.value=0;
    //     preConsultationController.right.value=0;
    //     preConsultationController.bottom.value=0;
    //
    //   }
    //   else{
    //     double btSum = 0;
    //     int totalPixels = image.width * image.height;
    //
    //     final plane = image.planes[0];
    //
    //     final bytes = plane.bytes;
    //     for (int i = 0; i < bytes.length; i++) {
    //       final yValue = bytes[i];
    //       btSum += yValue;
    //     }
    //
    //     preConsultationController.grayScale.value = btSum / totalPixels;
    //     print('Grayscale : ${preConsultationController.grayScale.value}');
    //     preConsultationController.grayScale.value < 135 ?
    //     preConsultationController.badQuality.value = true
    //         :
    //     preConsultationController.badQuality.value = false;
    //   }
    // } catch (e) {
    //   if (kDebugMode) {
    //     print('An error occurred: $e');
    //   }
    // }
    return;
  }


  void calculateAverageGrayscaleBrightnessForVideo(CameraImage image) {
    double btSum = 0;
    int totalPixels = image.width * image.height;

    final plane =
    image.planes[0]; // Assuming Y component is stored in the first plane

    final bytes = plane.bytes;
    for (int i = 0; i < bytes.length; i++) {
      final yValue = bytes[i];
      btSum += yValue;
    }

    preConsultationController.grayScale.value = btSum / totalPixels;
    print(
        "GRAYSCALE WHILE RECORDING : ${preConsultationController.grayScale.value}");
    if (preConsultationController.grayScale.value < 135) {
      preConsultationController.badQuality.value = true;
      // if(preConsultationController.isRecording.value==true) {
      //   preConsultationController.errorTime=[DateTime.now().millisecondsSinceEpoch];
      //   if (preConsultationController.errorTime.isNotEmpty) {
      //     var errorDuration = preConsultationController.errorTime[0] - preConsultationController.startTime[0];
      //     preConsultationController.errorLog.add({"badLight": errorDuration/1000});
      //   }
      // }
    } else {
      preConsultationController.badQuality.value = false;
    }
  }

  ///VIDEO QUALITY PARAMETER (LIGHT LUX VALUE FROM LIGHT SENSOR AT FRONT OF DEVICE)
  void calculateLight() {
    try {
      Light().lightSensorStream.listen((int luxValue) {
        preConsultationController.lux.value = luxValue;
        preConsultationController.lux.value < 9
            ? preConsultationController.lowLight.value = true
            : preConsultationController.lowLight.value = false;
      });
    } on LightException catch (exception) {
      if (kDebugMode) {
        print(exception);
      }
    }
  }

  void calculateLightForVideo() {
    try {
      Light().lightSensorStream.listen((int luxValue) {
        preConsultationController.lux.value = luxValue;
        if (preConsultationController.lux.value < 9) {
          preConsultationController.lowLight.value = true;
          // if(preConsultationController.isRecording.value==true) {
          //   preConsultationController.errorTime=[DateTime.now().millisecondsSinceEpoch];
          //   if (preConsultationController.errorTime.isNotEmpty) {
          //     var errorDuration = preConsultationController.errorTime[0] - preConsultationController.startTime[0];
          //     preConsultationController.errorLog.add({"lowLight": errorDuration/1000});
          //   }
          //}
        } else {
          preConsultationController.lowLight.value = false;
        }
      });
    } on LightException catch (exception) {
      if (kDebugMode) {
        print(exception);
      }
    }
  }

  ///ERROR LOGGING
  List<Map<dynamic, dynamic>> errorLog = [];
  List startTime = [];
  List errorTime = [];
  int prevFaceError = 0;
  int prevBadLightError = 0;
  int prevLowLightError = 0;

  RxBool detectionError = false.obs;

  resetDetectionError() async {
    preConsultationController.detectionError.value = false;
    update();
  }

  updateDetectionError() async {
    preConsultationController.detectionError.value = true;
    update();
  }

  RxBool alertDialogShown = false.obs;

  resetAlertDialogShown() async {
    preConsultationController.alertDialogShown.value = false;
    update();
  }

  updateAlertDialogShown() async {
    preConsultationController.alertDialogShown.value = true;
    update();
  }

  ///THESE ARE USED IN START VIDEO RECORDING

  ///COUNTER USED TO TRACK IF THE PATIENT IS VISIBLE OR NOT VISIBLE IN THE FRAME
  List faceOffTime = [];
  RxBool gotOffTime = false.obs;

  resetGotOffTimeError() async {
    preConsultationController.gotOffTime.value = false;
    update();
  }

  updateGotOffTimeError() async {
    preConsultationController.gotOffTime.value = true;
    update();
  }

  RxBool isFaceDetected = false.obs;
  RxBool isImageCaptured = false.obs;
  RxBool isVideoRecorded = false.obs;

  CameraSingleton cameraSingleton = CameraSingleton();

  ///FACE DETECTION CONTROLLER FIELDS
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  ///MAIN CAMERA CONTROLLER FOR IMAGE DETECTION - CAMERA CONTROLLERS
  //CameraController? cameraControllerInstance;

  ///CAMERA INDEX FOR ORIENTATION OF CAMERA - FRONT AND BACK - USED IN CAMERA.DART
  int cameraIndex = -1;

  RxString bottomMessage = "PLEASE START THE RECORDING".obs;

  ///VIKAS CHANGES DONE

  RxInt imageheight = 0.obs;
  RxInt imagewidth = 0.obs;
  RxInt left = 0.obs;
  RxInt top = 0.obs;
  RxInt right = 0.obs;
  RxInt bottom = 0.obs;

  ///ANDROID NATIVE DATA TRANSFER MODEL
  AndroidNativeDataTransferModel androidNativeDataTransferModel =
  AndroidNativeDataTransferModel(
      clinicId: "",
      colorCode: "",
      appName: "",
      instituteId: "",
      partyId: "",
      tabCode: "",
      shift: 0,
      bucketName: "",
      accessName: "",
      regionId: "",
      keyName: "");

  ///UPDATE VALUES FROM NATIVE METHOD INSIDE THE FLUTTER MODULE
  updateValueFromNativeMethod({var json}) async {
    androidNativeDataTransferModel =
        AndroidNativeDataTransferModel.fromJson(json);
    update();
  }

  ///STARTS THE RECORDING BY UPDATING STATUS TO TRUE
  updateRecordingStatus() async {
    preConsultationController.isRecording.value = true;
    update();
  }

  ///RESETS THE RECORDING STATUS TO FALSE
  resetRecordingStatus() async {
    preConsultationController.isRecording.value = false;
    //preConsultationController.gotStartTime=false;
    update();
  }

  ///UPDATES AVAILABLE CAMERA STATUS - IMPORTANT
  // updateAvailableCamera() async {
  //   //cameras = await availableCameras();
  //   update();
  // }

  ///CAPTURES IMAGE AND SAVES IT
  captureImageAndStartRecording() async {
    try {
      ///STOP IMAGE STREAM WHICH IS DETECTING FACES
      await cameraSingleton.cameraController.stopImageStream();

      // Future.delayed(const Duration(milliseconds: 10));
      ///TAKE IMAGE
      final XFile imageFile =
      await cameraSingleton.cameraController.takePicture();
      final File capturedImage = File(imageFile.path);

      ///   VIKAS CHANGES DONE
      final originalImage = img.decodeImage(await capturedImage!.readAsBytes());
      final faceImage = img.copyCrop(originalImage!,
          x: preConsultationController.left.value,
          y: preConsultationController.top.value,
          width: preConsultationController.right.value,
          height: preConsultationController.bottom.value);
      // width: preConsultationController.imagewidth.value,
      //     height: preConsultationController.imageheight.value);
      final croppedPath = capturedImage.path;
      //.replaceFirst('.jpg', '_cropped.jpg');
      final croppedImage =
      File(croppedPath).writeAsBytes(img.encodeJpg(faceImage));

      ///ADDS FILE TO _profileImage folder
      // Get the app's external files directory
      Directory? appDir = await getExternalStorageDirectory();

      if (appDir == null) {
        throw PlatformException(
            code: 'DIR_ERROR', message: 'Failed to get the app directory.');
      }

      /// Create the "ADK" and "_profileImage" subdirectories if they don't exist
      Directory adkDir = Directory(path.join(appDir.path, 'ADK'));
      Directory profileImageDir =
      Directory(path.join(adkDir.path, '_profileImage'));

      if (!adkDir.existsSync()) {
        adkDir.createSync(recursive: true);
      }
      if (!profileImageDir.existsSync()) {
        profileImageDir.createSync(recursive: true);
      }

      /// Generate a unique filename for the image
      String fileName = '${questionsController.patientId}.jpg';

      /// Copy the image file to the desired location
      File finalImage =
      await capturedImage.copy(path.join(profileImageDir.path, fileName));

      // Future.delayed(const Duration(milliseconds: 10));

      imageForDisplayInTheDevice.value = finalImage.path;

      ///UPDATES IMAGE PATH
      userController.updateUserPersonalDetails(
          field: "image", response: finalImage.path);

      ///ADDING TO MAIN ATTACHMENTS LIST IN ATTACHMENT CONTROLLER
      attachmentsController.addDataToMainAttachments(
          key: "PROFILE_IMAGE", path: finalImage.path);

      ///UPDATES STATUS OF IMAGE CAPTURED
      isImageCaptured.value = true;

      update();
    } catch (error) {
      Future.delayed(const Duration(seconds: 2));
      try {
        ///STOP IMAGE STREAM WHICH IS DETECTING FACES
        await cameraSingleton.cameraController.stopImageStream();

        //Future.delayed(const Duration(milliseconds: 10));
        ///TAKE IMAGE
        final XFile imageFile =
        await cameraSingleton.cameraController.takePicture();

        final File capturedImage = File(imageFile.path);

        ///ADDS FILE TO _profileImage folder
        // Get the app's external files directory
        Directory? appDir = await getExternalStorageDirectory();

        if (appDir == null) {
          throw PlatformException(
              code: 'DIR_ERROR', message: 'Failed to get the app directory.');
        }

        /// Create the "ADK" and "_profileImage" subdirectories if they don't exist
        Directory adkDir = Directory(path.join(appDir.path, 'ADK'));
        Directory profileImageDir =
        Directory(path.join(adkDir.path, '_profileImage'));

        if (!adkDir.existsSync()) {
          adkDir.createSync(recursive: true);
        }
        if (!profileImageDir.existsSync()) {
          profileImageDir.createSync(recursive: true);
        }

        /// Generate a unique filename for the image
        String fileName = '${questionsController.patientId}.jpg';

        /// Copy the image file to the desired location
        File finalImage =
        await capturedImage.copy(path.join(profileImageDir.path, fileName));

        Future.delayed(const Duration(milliseconds: 10));

        ///UPDATES IMAGE PATH
        userController.updateUserPersonalDetails(
            field: "image", response: finalImage.path);

        ///ADDING TO MAIN ATTACHMENTS LIST IN ATTACHMENT CONTROLLER
        attachmentsController.addDataToMainAttachments(
            key: "PROFILE_IMAGE", path: finalImage.path);

        ///UPDATES STATUS OF IMAGE CAPTURED
        isImageCaptured.value = true;
        update();
      } catch (error2) {
        showToast("FAILED TO CAPTURE IMAGE", ToastGravity.TOP);
      }
    }
  }

  ///STOPS RECORDING, SAVES FILE PATH AND THEN NAVIGATES TO NEXT PAGE
  stopRecordingAndNavigatesToNextPage() async {
    preConsultationController.updateLoadingStatusFaceDetectorPage();
    try {
      /// Future.delayed(const Duration(seconds: 3));

      ///STOPS RECORDING AND UPDATES VIDEO TO FILE
      final XFile videoFile =
      await cameraSingleton.cameraController.stopVideoRecording();
      if (kDebugMode) {
        print("hi from stopVideoRecording");
      }
      await preConsultationController.resetRecordingStatus();

      ///ASSIGNING X-FILE TO FILE
      final File capturedVideo = File(videoFile.path);

      ///ADDS FILE TO _profileImage folder
      // Get the app's external files directory
      Directory? appDir = await getExternalStorageDirectory();

      if (appDir == null) {
        throw PlatformException(
            code: 'DIR_ERROR', message: 'Failed to get the app directory.');
      }

      /// Create the "ADK" and "_profileImage" subdirectories if they don't exist
      Directory adkDir = Directory(path.join(appDir.path, 'ADK'));
      Directory profileImageDir =
      Directory(path.join(adkDir.path, '_Documents'));

      if (!adkDir.existsSync()) {
        adkDir.createSync(recursive: true);
      }
      if (!profileImageDir.existsSync()) {
        profileImageDir.createSync(recursive: true);
      }

      /// Generate a unique filename for the image
      String fileName =
          '${questionsController.appointmentId}_PROFILE_VIDEO.mp4';

      /// Copy the image file to the desired location
      File finalVideo =
      await capturedVideo.copy(path.join(profileImageDir.path, fileName));

      if (kDebugMode) {
        print("hi from finalVIdeo save");
      }

      ///UPDATES IMAGE PATH
      userController.updateUserPersonalDetails(
          field: "video", response: finalVideo.path);

      ///ADDING TO MAIN ATTACHMENTS LIST IN ATTACHMENT CONTROLLER
      attachmentsController.addDataToMainAttachments(
          key: "PROFILE_VIDEO", path: finalVideo.path);
      print("hi from adding to main attachment list");

      ///UPDATES THE FACE COUNT VALUE
      preConsultationController.faceCount.value = 0;

      cameraSingleton.releaseCamera();
      update();
    } catch (error) {
      print("hi from stoprecording and navigate catch block");
      debugPrint("$error");
    }
  }

  ///GETS CURRENT IMAGE OR VIDEO FILE PATH
  // Future<String> getFilePath({required bool isImage}) async {
  //   final directory = await getTemporaryDirectory();
  //   return isImage
  //       ? '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpeg'
  //       : '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
  // }

  ///UPDATES LOADING STATUS FOR THE ANIMATION
  updateLoadingStatusPermissionsPage() async {
    isLoadingPermissionsPage.value = true;
    update();
  }

  ///RESETS LOADING STATUS FOR THE ANIMATION
  resetLoadingStatusPermissionsPage() async {
    isLoadingPermissionsPage.value = false;
    update();
  }

  ///UPDATES LOADING STATUS FOR THE ANIMATION
  updateLoadingStatusFaceDetectorPage() async {
    isLoadingFaceDetectorPage.value = true;
    update();
  }

  ///RESETS LOADING STATUS FOR THE ANIMATION
  resetLoadingStatusFaceDetectorPage() async {
    isLoadingFaceDetectorPage.value = false;
    update();
  }

  ///UPDATES THE BOTTOM SHEET MESSAGE
  updateTheMessage({required int status}) {
    switch (status) {
      case 0:
        bottomMessage.value =
        "PLEASE START THE RECORDING BY FOCUSING ON THE PATIENT'S FACE.";
        break;
      case 1:
        bottomMessage.value = "PLEASE HOLD THE CAMERA STRAIGHT FOR 5 SECONDS.";
        break;
      case 2:
        bottomMessage.value = "FACE DETECTED. FOCUS ON THE PATIENT'S FACE.";
        break;
      case 3:
        bottomMessage.value = "FACE NOT DETECTED. PLEASE FOCUS ON PATIENT.";
        break;
      case 4:
        bottomMessage.value =
        "FACE NOT DETECTED FOR TOO LONG. RESTART THE PROCEDURE.";
        break;
      case 5:
        bottomMessage.value = "RECORDED THE VIDEO SUCCESSFULLY.";
        break;
      case 6:
        bottomMessage.value = "RESTART THE RECORDING.";
        break;
      case 7:
        bottomMessage.value = "PLEASE BRING THE PATIENT IN FRAME.";
        break;
      case 8:
        bottomMessage.value =
        "MULTIPLE FACES DETECTED. FOCUS ONLY ON ONE PATIENT";
        break;
      default:
        bottomMessage.value = "ERROR - RESTART THE RECORDING.";
        break;
    }

    update();
  }

  showFullScreenImagePage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          content: SizedBox(
            height: ScreenSize.height(context) * 0.5,
            width: ScreenSize.width(context) * 0.75,
            // constraints: BoxConstraints.expand(),
            child: FullScreenImagePage(
              imagePath: userController.personalQuestionsModel.image!,
              onConfirm: (File image) {
                ///UPDATES IMAGE PATH
                userController.updateUserPersonalDetails(
                    field: "image", response: image.path);

                ///ADDING TO MAIN ATTACHMENTS LIST IN ATTACHMENT CONTROLLER
                attachmentsController.addDataToMainAttachments(
                    key: "PROFILE_IMAGE", path: image.path);

                //GET BACK - NAVIGATES BACK
                Get.back();
              },
            ),
          ),
        );
      },
    );
  }
}
