import 'dart:async' show Future, StreamSubscription;
import 'dart:io' show File;

import 'package:audioplayers/audioplayer.dart';
import 'package:flutter/material.dart'
    show BuildContext, Color, Colors, DragUpdateDetails, FlatButton, GestureDetector, MaterialApp, Scaffold, SizedBox, State, StatefulWidget, StatelessWidget, Text, TextStyle, Widget, runApp;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:quiver/async.dart' show Metronome;
import 'package:recase/recase.dart' show ReCase;

void main() => runApp(MyApp());

/// MyApp
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      MaterialApp(
      title: 'Metronome',
        home: MetronomeClass(),
    );
}

/// Metronome Class
class MetronomeClass extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MetronomeState();
}

/// MetronomeState builds main widget
class MetronomeState extends State<MetronomeClass> {

  File _soundFile;

  //Initial Style
  Color _bkgColor = Colors.red;
  final Color _txtColor = Colors.white;
  TextStyle _biggerFont = const TextStyle(fontSize: 175.0);

  /// List of possible sounds of metronome
  List<String> sounds = ['bottle', 'click', 'tamborine'
  ]; // ignore: always_specify_types
  int _soundIndex = 0;

  /// Metronome tempo
  static int tempo = 100;

  /// Text that displays on the screen, i.e. tempo or current sound
  String displayTxt = '$tempo';
  ReCase _rc;

  //Mode and isPlaying
  bool _isPlaying = false;
  bool _modeMetronome = true;

  Metronome _metronome =
  Metronome.epoch(Duration(milliseconds: (60000 / tempo).round()));
  StreamSubscription<DateTime> _subscription;

  Future<ByteData> _loadSound() async =>
      await rootBundle.load('assets/${sounds[_soundIndex]}.mp3');

  void _writeSound() async {
    _soundFile = File(
        '${(await getTemporaryDirectory()).path}/${sounds[_soundIndex]}.mp3');
    await _soundFile.writeAsBytes((await _loadSound()).buffer.asUint8List());
  }

  void _playLocal() async {
    final AudioPlayer _audioPlayer = AudioPlayer(); // ignore: omit_local_variable_types
    AudioPlayer.logEnabled = false;
    await _audioPlayer.play(_soundFile.path, isLocal: true);
  }

  void _toggleMode() {
    if (_modeMetronome) {
      _modeMetronome = false;

      //Stops the metronome if it is playing
      if (_isPlaying) {
        _subscription.cancel();
        _isPlaying = false;
      }

      //Displays the current sound
      setState(() {
        _bkgColor = Colors.blue[800];
        _biggerFont = const TextStyle(fontSize: 65.0);
        _rc = ReCase(sounds[_soundIndex]);
        displayTxt = _rc.pascalCase;
      });
    }
    else {
      _modeMetronome = true;

      setState(() {
        _bkgColor = Colors.red;
        _biggerFont = const TextStyle(fontSize: 175.0);
        displayTxt = '$tempo';
      });
    }
  }

  void _switchSound() {
    //Cycles through possible sounds
    _soundIndex = ++_soundIndex % 3;
    setState(() {
      _rc = ReCase(sounds[_soundIndex]);
      displayTxt = _rc.pascalCase;
    });

    _writeSound();
  }

  void _play() {
    if (_soundFile == null) {
      _writeSound();
    }

    //Toggles between playing and not
    setState(() {
      if (_isPlaying) {
        _subscription.cancel();
        _isPlaying = false;

        _bkgColor = Colors.red;
      } else {
        _subscription =
            _metronome.listen((d) =>
                _playLocal()); // ignore: always_specify_types
        _isPlaying = true;

        _bkgColor = Colors.green;
      }
    });
  }

  void _increaseTempo(int decrease) {
    if (!((tempo > 299 && decrease < 0) || (tempo < 41 && decrease > 0))) {
      setState(() {
        tempo -= (decrease / 4).ceil();
        displayTxt = '$tempo';
      });
      _metronome = Metronome.epoch(
          Duration(milliseconds: (60000 / tempo).round()));

      //Dynamically increases the tempo of the beat
      if (_isPlaying) {
        _subscription.cancel();
        _subscription =
            _metronome.listen((d) =>
                _playLocal()); // ignore: always_specify_types
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      MaterialApp(
      title: 'Metronome',

        home: Scaffold(
          //Red, green, or dark blue depending on the state of playing and mode
            backgroundColor: _bkgColor,

            body: GestureDetector(
              //Increase or decrease tempo based on swipe direction
              onVerticalDragUpdate: (
                  updateDetails) { // ignore: always_specify_types
                if (_modeMetronome)
                  _increaseTempo((updateDetails.primaryDelta / 6).floor());
              },
              onHorizontalDragUpdate: (
                  updateDetails) { // ignore: always_specify_types
                if (_modeMetronome)
                  _increaseTempo((updateDetails.primaryDelta / 6).floor());
              },

              onLongPress: _toggleMode,

              //SizedBox.expand means the button takes up the entire screen
              child: SizedBox.expand(
                child: FlatButton(
                  child: Text(
                    displayTxt,
                    style: _biggerFont,
                  ),

                  textColor: _txtColor,

                  //Plays or pauses the metronome if metronome mode, else switches sound
                  onPressed: () {
                    _modeMetronome ? _play() : _switchSound();
                  },
                ),
              ),
            )),
    );
}
