import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart'
    show BuildContext, Color, Colors, DragStartDetails, DragUpdateDetails, FlatButton, GestureDetector, MaterialApp, Scaffold, SizedBox, State, StatefulWidget, StatelessWidget, Text, TextStyle, Widget, runApp;
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;
import 'package:quiver/async.dart' show Metronome;
import 'package:recase/recase.dart' show ReCase;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Metronome',
      home: new MetronomeClass(),
    );
  }
}

class MetronomeClass extends StatefulWidget {
  @override
  createState() => new MetronomeState();
}

class MetronomeState extends State<MetronomeClass> {
  var sounds = ['tamborine', 'bottle', 'click'];
  int _soundIndex = 0;

  static int tempo = 100;

  //Initial Style
  Color _bkgColor = Colors.red;
  Color _txtColor = Colors.white;
  TextStyle _biggerFont = TextStyle(fontSize: 175.0);

  String displayTxt = '$tempo';
  ReCase rc;

  bool _isPlaying = false;
  bool _modeMetronome = true;

  Metronome _metronome =
  new Metronome.epoch(new Duration(milliseconds: (60000 / tempo).round()));
  StreamSubscription<DateTime> _subscription;

  void _toggleMode() {
    if (_modeMetronome) {
      _modeMetronome = false;
      if (_isPlaying) {
        _subscription.cancel();
        _isPlaying = false;
      }

      setState(() {
        _bkgColor = Colors.blue[800];
        _biggerFont = TextStyle(fontSize: 60.0);
        rc = ReCase(sounds[_soundIndex]);
        displayTxt = rc.pascalCase;
      });
    }
    else {
      _modeMetronome = true;

      setState(() {
        _bkgColor = Colors.red;
        _biggerFont = TextStyle(fontSize: 175.0);
        displayTxt = '$tempo';
      });
    }
  }

  void _switchSound() {
    _soundIndex = ++_soundIndex % 3;
    setState(() {
      rc = ReCase(sounds[_soundIndex]);
      displayTxt = rc.pascalCase;
    });
  }

  void _play() {
    setState(() {
      if (_isPlaying) {
        _subscription.cancel();
        _isPlaying = false;

        _bkgColor = Colors.red;
      } else {
        _subscription =
            _metronome.listen((d) => SystemSound.play(SystemSoundType.click));
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
      _metronome = new Metronome.epoch(
          new Duration(milliseconds: (60000 / tempo).round()));

      //Dynamically increases the tempo of the beat
      if (_isPlaying) {
        _subscription.cancel();
        _subscription =
            _metronome.listen((d) => SystemSound.play(SystemSoundType.click));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Metronome',
      home: new Scaffold(
        //Red or green depending on the state of playing
          backgroundColor: _bkgColor,
          body: new GestureDetector(

            onVerticalDragStart: (DragStartDetails startDetails) {
              if (!_modeMetronome) _switchSound;
            },

            onHorizontalDragStart: (DragStartDetails startDetails) {
              if (!_modeMetronome) _switchSound;
            },

            //Increase or decrease tempo based on swipe direction
            onVerticalDragUpdate: (DragUpdateDetails updateDetails) {
              if (_modeMetronome)
                _increaseTempo((updateDetails.primaryDelta / 6).floor());
            },
            onHorizontalDragUpdate: (DragUpdateDetails updateDetails) {
              if (_modeMetronome)
                _increaseTempo((updateDetails.primaryDelta / 6).floor());
            },

            onLongPress: _toggleMode,

            //SizedBox.expand means the button takes up the entire screen
            child: new SizedBox.expand(
              child: new FlatButton(
                child: new Text(
                  displayTxt,
                  style: _biggerFont,
                ),

                //White
                textColor: _txtColor,

                //Plays or pauses the metronome
                onPressed: () {
                  _modeMetronome ? _play() : _toggleMode();
                },
              ),
            ),
          )),
    );
  }
}
