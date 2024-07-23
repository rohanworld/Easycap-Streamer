// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<FileSystemEntity> videoFiles = [];
  VideoPlayerController? _controller;
  bool isUsbConnected = false;
  bool _showExtraButtons = false;
  bool isRecording = false;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupUsbListener();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  void _setupUsbListener() {
    UsbSerial.usbEventStream!.listen((UsbEvent event) {
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        _checkUsbDevice();
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        setState(() {
          isUsbConnected = false;
          if (_controller != null) {
            _controller!.dispose();
            _controller = null;
          }
          videoFiles.clear();
        });
      }
    });
  }

  void _checkUsbDevice() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    for (var device in devices) {
      if (device.vid == 0x534d && device.pid == 0x0021) {
        setState(() {
          isUsbConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('EasyCAP device connected: ${device.deviceName}')),
        );
        _scanUsbForVideos();
        return;
      }
    }
    setState(() {
      isUsbConnected = false;
    });
  }

  Future<void> _scanUsbForVideos() async {
    Directory? usbDir = await _getUsbDirectory();
    if (usbDir != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stream directory found: ${usbDir.path}')),
        );
        List<FileSystemEntity> files = usbDir.listSync(recursive: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Files found: ${files.map((f) => f.path).toList()}")),
        );
        setState(() {
          videoFiles = files.where((file) => file.path.endsWith('.mp4')).toList();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading files: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stream directory not found')),
      );
    }
  }

  Future<Directory?> _getUsbDirectory() async {
    try {
      const usbPath = '/mnt/media_rw/7B50-B4A8'; // You might need to adjust this path
      final usbDir = Directory(usbPath);
      if (await usbDir.exists()) {
        return usbDir;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing Stream directory: $e')),
      );
    }
    return null;
  }

  void _playVideo(String filePath) {
    _controller = VideoPlayerController.file(File(filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller!.play();
      });
  }

  void _handleScreenRecord() {
    if (isUsbConnected) {
      setState(() {
        isRecording = !isRecording;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed due to error: Stream not supported')),
      );
    }
  }

  Future<void> _handleScreenCapture() async {
    if (isUsbConnected) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        screenshotController.captureAndSave(directory.path, fileName: path).then((String? imagePath) {
          if (imagePath != null) {
            Fluttertoast.showToast(
              msg: "Screenshot saved: $imagePath",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0
            );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing screenshot: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed due to error: Stream not supported')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Screenshot(
        controller: screenshotController,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 7, 94, 255),
            title: const Text('Easycap Stream'),
          ),
          body: isUsbConnected
              ? videoFiles.isNotEmpty
                  ? ListView.builder(
                      itemCount: videoFiles.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(videoFiles[index].path.split('/').last),
                          onTap: () {
                            _playVideo(videoFiles[index].path);
                          },
                        );
                      },
                    )
                  : const Center(child: Text('No video files'))
              : const Center(child: Text('Connect a Stream device')),
          floatingActionButton: Stack(
            children: [
              if (_showExtraButtons) ...[
                Positioned(
                  bottom: 100,
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: _handleScreenRecord,
                    tooltip: 'Screen Record',
                    child: Icon(isRecording ? Icons.pause : Icons.videocam),
                  ),
                ),
                Positioned(
                  bottom: 180,
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: _handleScreenCapture,
                    tooltip: 'Screen Capture',
                    child:const Icon(Icons.camera_alt),
                  ),
                ),
                Positioned(
                  bottom: 260,
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _showExtraButtons = false;
                      });
                    },
                    tooltip: 'Exit',
                    child:const Icon(Icons.exit_to_app),
                  ),
                ),
              ],
              Positioned(
                bottom: 20,
                right: 10,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _showExtraButtons = !_showExtraButtons;
                    });
                  },
                  tooltip: 'Menu',
                  child: Icon(_showExtraButtons ? Icons.close : Icons.menu),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
