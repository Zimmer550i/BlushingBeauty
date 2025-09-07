import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ree_social_media_app/views/base/custom_button.dart';
import 'package:ree_social_media_app/views/screen/Message/AllSubScreen/AllSubScreen/fram_selection_screen.dart';
import 'package:video_player/video_player.dart';

class SendOrTrimVideoScreen extends StatefulWidget {
  final String videoUrl;

  const SendOrTrimVideoScreen({super.key, required this.videoUrl});

  @override
  State<SendOrTrimVideoScreen> createState() => _SendOrTrimVideoScreenState();
}

class _SendOrTrimVideoScreenState extends State<SendOrTrimVideoScreen> {
  CameraController? _frontCam;
  VideoPlayerController? _video;

  bool _isRecording = false;
  XFile? _recordedFile;

  Duration _videoDuration = Duration.zero;
  Duration _position = Duration.zero;
  late final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    await _requestPermissions();
    await _initFrontCamera();
    await _initVideo();
    await _startBackgroundVideo(); // Directly start video
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera & Microphone permission required'),
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _initFrontCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _frontCam = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _frontCam!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initVideo() async {
    if (widget.videoUrl.startsWith('http')) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    } else {
      _video = VideoPlayerController.file(File(widget.videoUrl));
    }
    await _video!.initialize();
    _videoDuration = _video!.value.duration;
    _video!.setLooping(false);

    _video!.addListener(() {
      if (!mounted) return;
      setState(() {
        _position = _video!.value.position;
      });
      _isPlaying.value = _video!.value.isPlaying;
    });
    if (mounted) setState(() {});
  }

  Future<void> _startBackgroundVideo() async {
    if (_video != null && _video!.value.isInitialized) {
      await _video!.play();
    }
  }

  @override
  void dispose() {
    _video?.removeListener(() {});
    _video?.dispose();

    () async {
      try {
        if (_frontCam?.value.isRecordingVideo == true) {
          await _frontCam?.stopVideoRecording();
    }
    } catch (_) {}
    _frontCam?.dispose();
    }();
    super.dispose();
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                Get.back();
              },
              child: Icon(Icons.arrow_back, color: Color(0xFF0D1C12)),
            ),
            SizedBox(width: 12),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage("assets/images/dummy.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Mr.John",
              style: TextStyle(
                color: Color(0xFF413E3E),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          /// ====== Video Area ======
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _video!.value.size.width,
                      height: _video!.value.size.height,
                      child: VideoPlayer(_video!),
                    ),
                  ),
                ),

                /// Top-right front camera preview (PiP)
                if (_frontCam?.value.isInitialized == true)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 129,
                      height: 159,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFFFFF).withValues(alpha: 0.24),
                        border: Border.all(
                          color: Color(0xFFABD4A7),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: CameraPreview(
                        _frontCam!,
                      ),
                    ),
                  ),

                /// Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomControls(),
                ),
              ],
            ),
          ),
       Container(
         width: double.infinity,
         color: Color(0xFFFFFFFF),
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
           child: Column(
             children: [
               Container(
                 width: double.infinity,
                 decoration: BoxDecoration(
                   color: Colors.white,
                 ),
                 child: Column(
                   children: [
                     InkWell(
                       onTap: (){
                         Get.to(()=> FramSelectionScreen(videoUrl: widget.videoUrl));
                       },
                       child: Container(
                         width: double.infinity,
                         height: 52,
                         decoration: BoxDecoration(
                           color: Colors.white,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(
                               color: Color(0xFFC4C3C3),
                               width: 0.5,
                             ),
                             boxShadow: [
                               BoxShadow(
                                 color: Color(0xFF002329).withValues(alpha: 0.07),
                                 offset: Offset(0, 2),
                                 blurRadius: 4,
                                 spreadRadius: 0,
                               )
                             ]
                         ),
                         child: Center(child: Text("Trim or Select Image",
                         style: TextStyle(
                           color: Color(0xFF413E3E),
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                         ),)),
                       ),
                     )

                   ],
                 ),
               ),
               SizedBox(height: 20,),
               CustomButton(onTap: (){},
                   text: "Send Now"),
             ],
           ),
         ),
       )


        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final total = _videoDuration.inMilliseconds.toDouble().clamp(
      1,
      double.infinity,
    );
    final value = _position.inMilliseconds.toDouble().clamp(0, total);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Progress / Seek
          Row(
            children: [
              Text(
                "${_fmt(_position)} sec",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: total.toDouble(),
                  activeColor: Color(0xFF413E3E),
                  inactiveColor: Color(0xFF413E3E),
                  thumbColor: Color(0xFFD9D9D9),
                  onChanged: (v) {
                    final pos = Duration(milliseconds: v.toInt());
                    _video?.seekTo(pos);
                  },
                ),
              ),
              Text(
                "${_fmt(_videoDuration)} sec",
                style: TextStyle(
                  color: Color(0xFF413E3E),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 12),
              ValueListenableBuilder<bool>(
                valueListenable: _isPlaying,
                builder: (_, playing, __) {
                  return CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        color: Color(0xFF9CC198),
                      ),
                      onPressed: () async {
                        if (playing) {
                          await _video?.pause();
                        } else {
                          await _video?.play();
                        }
                        _isPlaying.value = _video?.value.isPlaying ?? false;
                      },
                    ),
                  );
                },
              ),

            ],
          ),
        ],
      ),
    );
  }
}
