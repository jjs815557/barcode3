import 'package:barcodescan3/SettingsProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:mlkit_scanner/mlkit_scanner.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int displayCount = 0;
  String displayBarcode = '';

  var _zoomValues = [0.0, 0.33, 0.66];
  var _actualZoomIndex = 0;
  static const _delayOptions = {
    "0 milliseconds": 0,
    "100 milliseconds": 100,
    "500 milliseconds": 500,
    "2000 milliseconds": 2000,
  };
  BarcodeScannerController? _controller;
  List<IosCamera> _iosCameras = [];

  var _cameraIndex = -1;
  var _cameraType = '';
  var _cameraPosition = '';
  var scanCount = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadData();
  }

  void _setNextIosCamera() {
    _cameraIndex = (_cameraIndex + 1) % _iosCameras.length;
    _controller!.setIosCamera(
        position: _iosCameras[_cameraIndex].position,
        type: _iosCameras[_cameraIndex].type);
    _resetZoom();
    setState(() {
      _cameraType = _iosCameras[_cameraIndex].type.name;
      _cameraPosition = _iosCameras[_cameraIndex].position.name;
    });
  }

  void _resetZoom() {
    _actualZoomIndex = 0;
    _controller?.setZoom(_zoomValues[_actualZoomIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: const Text(
              '바코드 카운트 스캔',
            ),
          ),
          body: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 200,
                    child: BarcodeScanner(
                      cropOverlay:
                          const CropRect(scaleHeight: 0.7, scaleWidth: 0.7),
                      onScan: (code) {
                        if (!_barcode.containsKey(code)) {
                          // new barcode scan
                          _barcode[code] = 1;
                          setState(() {
                            displayBarcode = code;
                            displayCount = _barcode[code]!;
                          });
                        } else {
                          _barcode.forEach(
                            (key, value) {
                              if (code == key) {
                                _barcode[code] = ++value;
                              }
                              setState(() {
                                displayBarcode = code;
                                displayCount = _barcode[code]!;
                              });
                            },
                          );
                        }
                        FlutterBeep.beep();
                        Vibrate.feedback(FeedbackType.success);
                        _saveData(_barcode);
                      },
                      onScannerInitialized: (controller) async {
                        _controller = controller;
                        if (defaultTargetPlatform == TargetPlatform.iOS) {
                          _iosCameras =
                              await controller.getIosAvailableCameras()!;
                          _setNextIosCamera();
                        }
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "터치해서 화면 초점 맞추기 / 초점 고정시 길게 누르기",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$displayBarcode + $displayCount',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: SizedBox(
                      width: 88,
                      child: Text(
                        'Start scan',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onPressed: //() => _controller?.startScan(100),
                        () {
                      _controller?.startScan(100);
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    child: SizedBox(
                      width: 88,
                      child: Text(
                        'Cancel scan',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onPressed: () async {
                      _controller?.cancelScan();

                      setState(() {
                        displayBarcode = '초기화 되었습니다';
                        displayCount = 0;
                      });
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: SizedBox(
                      width: 88,
                      child: Text(
                        'Pause camera',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onPressed: () => _controller?.pauseCamera(),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    child: SizedBox(
                      width: 88,
                      child: Text(
                        'Resume camera',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onPressed: () => _controller?.resumeCamera(),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: SizedBox(
                      width: 88,
                      child: Text(
                        'Toggle flash',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    onPressed: () => _controller?.toggleFlash(),
                  ),
                  const SizedBox(width: 8),
                  _buildDelayButton(),
                ],
              ),
              TextButton(
                child: SizedBox(
                  width: 88,
                  child: Text(
                    'Zoom',
                    textAlign: TextAlign.center,
                  ),
                ),
                onPressed: () {
                  _actualZoomIndex = _actualZoomIndex + 1 < _zoomValues.length
                      ? _actualZoomIndex + 1
                      : 0;
                  _controller?.setZoom(_zoomValues[_actualZoomIndex]);
                },
              ),
              if (defaultTargetPlatform == TargetPlatform.iOS)
                TextButton(
                  child: Text(
                    '$_cameraIndex: $_cameraPosition, $_cameraType',
                    textAlign: TextAlign.center,
                  ),
                  onPressed: _setNextIosCamera,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDelayButton() {
    return TextButton(
      child: SizedBox(
        width: 88,
        child: PopupMenuButton<int>(
          onSelected: (delay) => _controller?.setDelay(delay),
          child: Text(
            'Set Delay',
            textAlign: TextAlign.center,
          ),
          itemBuilder: (context) {
            return _delayOptions.entries
                .map(
                  (entry) => PopupMenuItem(
                    value: entry.value,
                    child: Text(entry.key),
                  ),
                )
                .toList();
          },
        ),
      ),
      onPressed: () {},
    );
  }
}
