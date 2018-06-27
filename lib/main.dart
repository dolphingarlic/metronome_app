import 'dart:async' show Future, StreamSubscription;
import 'dart:io' show File;

import 'package:audioplayers/audioplayer.dart' show AudioPlayer;
import 'package:flutter/material.dart'
    show BuildContext, Color, Colors, FlatButton, GestureDetector, MaterialApp,
    Scaffold, SizedBox, State, StatefulWidget, StatelessWidget, Text, TextStyle,
    Widget, runApp;
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
        title: 'Beet',
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
  Color _bkgColor = Colors.black;
  Color _txtColor = Colors.white;
  TextStyle _biggerFont = const TextStyle(fontSize: 175.0);

  /// List of possible sounds of metronome
  final List<String> _sounds = ['bottle', 'click', 'tamborine', 'meow'
  ]; // ignore: always_specify_types
  int _soundIndex = 0;

  /// Metronome tempo
  static int tempo = 100;

  /// Text that displays on the screen, i.e. tempo or current sound
  String displayTxt = '$tempo';
  ReCase _rc;

  /// Whether the metronome is playing or not
  bool _isPlaying = false;

  /// The current mode
  bool _modeMetronome = true;

  /// Metronome with a tempo
  Metronome _metronome =
  Metronome.periodic(Duration(milliseconds: (60000 / tempo).floor()));

  StreamSubscription<DateTime> _subscription;

  Future<ByteData> _loadSound() async =>
      await rootBundle.load('assets/${_sounds[_soundIndex]}.mp3');

  void _writeSound() async {
    _soundFile = File(
        '${(await getTemporaryDirectory()).path}/${_sounds[_soundIndex]}.mp3');
    await _soundFile.writeAsBytes((await _loadSound()).buffer.asUint8List());
  }

  void _playLocal() async {
    final AudioPlayer _audioPlayer = AudioPlayer(); // ignore: omit_local_variable_types
    AudioPlayer.logEnabled = false;
    await _audioPlayer.play(_soundFile.path, isLocal: true);
  }

  /// Toggles between Metronome Mode and Not Metronome Mode
  void toggleMode() {
    if (_modeMetronome) {
      _modeMetronome = false;

      //Stops the metronome if it is playing
      if (_isPlaying) {
        _subscription.cancel();
        _isPlaying = false;
      }

      //Displays the current sound
      setState(() {
        _bkgColor = Colors.white;
        _txtColor = Colors.black;
        _biggerFont = const TextStyle(fontSize: 65.0);
        _rc = ReCase(_sounds[_soundIndex]);
        displayTxt = _rc.pascalCase;
      });
    }
    else {
      _modeMetronome = true;
      setState(() {
        _bkgColor = Colors.black;
        _txtColor = Colors.white;
        _biggerFont = const TextStyle(fontSize: 175.0);
        displayTxt = '$tempo';
      });
    }
  }

  /// Switches between the sound options (Not Metronome Mode)
  void switchSound() {
    //Cycles through possible sounds
    _soundIndex = ++_soundIndex % _sounds.length;
    setState(() {
      _rc = ReCase(_sounds[_soundIndex]);
      displayTxt = _rc.pascalCase;
    });

    _writeSound();
  }

  /// Plays the sound of the metronome (Metronome Mode)
  void playMetronome() {
    if (_soundFile == null) {
      _writeSound();
    }

    //Toggles between playing and not
    setState(() {
      if (_isPlaying) {
        _subscription.cancel();
        _isPlaying = false;

        _bkgColor = Colors.black;
      } else {
        _subscription =
            _metronome.listen((d) =>
                _playLocal()); // ignore: always_specify_types
        _isPlaying = true;
        changeColor();
      }
    });
  }

  /// Increases the tempo based on the swipe direction, capping at 40 and 300
  void increaseTempo(int decrease) {
    if (!((tempo > 299 && decrease < 0) || (tempo < 41 && decrease > 0))) {
      setState(() {
        tempo -= decrease;
        displayTxt = '$tempo';
      });
      _metronome = Metronome.periodic(
          Duration(milliseconds: (60000 / tempo).floor()));

      //Dynamically increases the tempo of the beat
      if (_isPlaying) {
        _subscription.cancel();
        _subscription =
            _metronome.listen((d) =>
                _playLocal()); // ignore: always_specify_types
        changeColor();
      }
    }
    if (tempo > 300) {
      setState(() {
        tempo = 300;
        displayTxt = '$tempo';
      });
    }
    if (tempo < 40) {
      setState(() {
        tempo = 40;
        displayTxt = '$tempo';
      });
    }
  }

  void changeColor() {
    setState(() {
      _bkgColor = Color.fromARGB(
          255,
          ((tempo - 40) * 255 / 260).floor(),
          208 - (((tempo - 40) * 255 / 260).floor() - 105).abs(),
          (221 - ((tempo - 40) * 255 / 260).floor()).abs()
      );
    });
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
                  increaseTempo((updateDetails.primaryDelta / 20).round());
              },
              onHorizontalDragUpdate: (
                  updateDetails) { // ignore: always_specify_types
                if (_modeMetronome)
                  increaseTempo((updateDetails.primaryDelta / 20).round());
              },

              onLongPress: toggleMode,

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
                    _modeMetronome ? playMetronome() : switchSound();
                  },
                ),
              ),
            )),
    );
}
