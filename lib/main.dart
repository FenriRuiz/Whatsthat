import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:rounded_floating_app_bar/rounded_floating_app_bar.dart';

import 'detector_painters.dart';
import 'utils.dart';

void main() => runApp(MaterialApp(
    home: _MyHomePage(),
    title: 'Whatsthat?',
    theme: ThemeData(
      // Define el Brightness y Colores por defecto
      brightness: Brightness.dark,
      primaryColor: Colors.grey[800],
      accentColor: Colors.cyan[800],
      backgroundColor: Colors.black,
      // Define la Familia de fuente por defecto
      fontFamily: 'Montserrat',

      // Define el TextTheme por defecto. Usa esto para espicificar el estilo de texto por defecto
      // para cabeceras, títulos, cuerpos de texto, y más.
      textTheme: TextTheme(
        headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
        title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
        body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
      ),
    )));

class _MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  dynamic _resultados;
  CameraController _camara;

  Detector _detectorActual = Detector.text;
  bool _detectando = false;
  bool _play = true;
  CameraLensDirection _posicion = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription descriptorCamara = await getCamera(_posicion);
    ImageRotation rotacion = rotationIntToImageRotation(
      descriptorCamara.sensorOrientation,
    );

    _camara = CameraController(
      descriptorCamara,
      defaultTargetPlatform == TargetPlatform.android
          ? ResolutionPreset.high
          : ResolutionPreset.high,
    );
    await _camara.initialize();

    _camara.startImageStream((CameraImage image) {
      if (_detectando) return;

      _detectando = true;

      detect(image, _getDetectionMethod(), rotacion).then(
        (dynamic result) {
          setState(() {
            _resultados = result;
          });

          _detectando = false;
        },
      ).catchError(
        (_) {
          _detectando = false;
        },
      );
    });
  }

  HandleDetection _getDetectionMethod() {
    final FirebaseVision mlVision = FirebaseVision.instance;

    switch (_detectorActual) {
      case Detector.text:
        return mlVision.textRecognizer().processImage;
      case Detector.barcode:
        return mlVision.barcodeDetector().detectInImage;
      case Detector.label:
        return mlVision.labelDetector().detectInImage;
      default:
        assert(_detectorActual == Detector.face);
        return mlVision.faceDetector().processImage;
    }
  }

  Widget _buildResults() {
    const Text sinResultados = const Text('Cargando módulo');
    if (_resultados == null ||
        _camara == null ||
        !_camara.value.isInitialized) {
      Toast.show("No hay coincidencias", context,
          duration: 1, gravity: Toast.BOTTOM);
      return null;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _camara.value.previewSize.height,
      _camara.value.previewSize.width,
    );

    switch (_detectorActual) {
      case Detector.barcode:
        if (_resultados is! List<Barcode>) {
          //Toast.show("No hay coincidencias", context, duration: 1, gravity:  Toast.BOTTOM);
          return sinResultados;
        }
        painter = BarcodeDetectorPainter(imageSize, _resultados);
        break;
      case Detector.face:
        if (_resultados is! List<Face>) {
          //Toast.show("No hay coincidencias", context, duration: 1, gravity:  Toast.BOTTOM);
          return sinResultados;
        }
        painter = FaceDetectorPainter(imageSize, _resultados);
        break;
      case Detector.label:
        if (_resultados is! List<Label>) {
          //Toast.show("No hay coincidencias", context, duration: 1, gravity:  Toast.BOTTOM);
          return sinResultados;
        }
        painter = LabelDetectorPainter(imageSize, _resultados);
        break;
      default:
        assert(_detectorActual == Detector.text);
        if (_resultados is! VisionText) {
          return sinResultados;
        }
        painter = TextDetectorPainter(imageSize, _resultados);
    }
    return CustomPaint(
      painter: painter,
    );
  }

  Widget _buildImage() {
    return Container(
      //padding: const EdgeInsets.fromLTRB(0, 25, 0, 100),
      //constraints: const BoxConstraints.expand(),
      child: _camara == null
          ? Center(
              child: Text(
              'Iniciando Camara',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 30.0,
              ),
            ))
          /*Image.asset(
              "assets\loader.gif",
              width: MediaQuery.of(context).size.width,
              )*/
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: new BorderRadius.circular(10.0),
                  child:CameraPreview(_camara),
                ),
                _buildResults(),
                //Toast.show("No hay coincidencias", context, duration: 1, gravity:  Toast.BOTTOM);
              ],
            ),
    );
  }

  void _toggleCameraDirection() async {
    if (_posicion == CameraLensDirection.back) {
      _posicion = CameraLensDirection.front;
    } else {
      _posicion = CameraLensDirection.back;
    }

    await _camara.stopImageStream();
    await _camara.dispose();

    setState(() {
      _camara = null;
    });

    _initializeCamera();
  }
  void _pauseRecording() async {
    if (_play == true){
      _play = false;
      await _camara.stopImageStream();
    }
    else{
      _play = true;
      _initializeCamera();
    }
  }

  Widget _getMenuFAB() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22),
      backgroundColor: Theme.of(context).accentColor,
      visible: true,
      curve: Curves.bounceIn,
      children: [
        // FAB 1
        SpeedDialChild(
            child: Icon(Icons.text_format),
            backgroundColor: Theme.of(context).accentColor,
            onTap: () {
              setState(() {
                _detectorActual = Detector.text;
              });
            },
            label: 'Texto',
            labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: Theme.of(context).accentColor),
        // FAB 2
        SpeedDialChild(
            child: Icon(Icons.category),
            backgroundColor: Theme.of(context).accentColor,
            onTap: () {
              setState(() {
                _detectorActual = Detector.label;
              });
            },
            label: 'Objetos',
            labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: Theme.of(context).accentColor),
        // Botón flotante
        SpeedDialChild(
            child: Icon(Icons.face),
            backgroundColor: Theme.of(context).accentColor,
            onTap: () {
              setState(() {
                _detectorActual = Detector.face;
              });
            },
            label: 'Caras',
            labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: Theme.of(context).accentColor),
        // FAB 4
        SpeedDialChild(
            child: Icon(Icons.view_week),
            backgroundColor: Theme.of(context).accentColor,
            onTap: () {
              setState(() {
                _detectorActual = Detector.barcode;
              });
            },
            label: 'Codigo de Barras',
            labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: Theme.of(context).accentColor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[800],
      body: NestedScrollView(
          headerSliverBuilder: (context, isInnerBoxScroll) {
            return [
              RoundedFloatingAppBar(
                floating: true,
                snap: true,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FlutterLogo(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10,5,10,5),
                      child: Text(
                        "Whatsthat?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.grey[800],
              ),
            ];
          },
          body: Stack(children: <Widget>[
            Container(
              height:  MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: new BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.3, 0.5],
                  colors: [Colors.cyan[800], Colors.grey[900]])),),
            Container(
              margin: EdgeInsets.fromLTRB(10, 20, 10, 75),
              child: _buildImage()),
            Container(
              padding: EdgeInsets.fromLTRB(10,0,0,10),
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton(
                onPressed: _toggleCameraDirection,
                child: _posicion == CameraLensDirection.back
                    ? const Icon(Icons.camera_front)
                    : const Icon(Icons.camera_rear),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(0,0,0,10),
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                onPressed: _pauseRecording,
                child: _posicion == CameraLensDirection.back
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0,0,10,10),
              child: _getMenuFAB(),
            ),
          ])),
    );
  }
}
