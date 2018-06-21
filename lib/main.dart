import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiver/async.dart';

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
  static int tempo = 100;

  //Initial Style
  Color _bkgColor = Colors.red;
  Color _txtColor = Colors.white;
  final _biggerFont = const TextStyle(fontSize: 175.0);

  bool _isPlaying = false;

  Metronome _metronome =
      new Metronome.epoch(new Duration(milliseconds: (60000 / tempo).round()));
  StreamSubscription<DateTime> _subscription;

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
      });
      _metronome = new Metronome.epoch(
          new Duration(milliseconds: (60000 / tempo).round()));

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
            //Increase or decrease tempo based on swipe direction
            onVerticalDragUpdate: (DragUpdateDetails updateDetails) {
              _increaseTempo((updateDetails.primaryDelta / 6).floor());
            },
            onHorizontalDragUpdate: (DragUpdateDetails updateDetails) {
              _increaseTempo(-(updateDetails.primaryDelta / 6).floor());
            },

            //SizedBox.expand means the button takes up the entire screen
            child: new SizedBox.expand(
              child: new FlatButton(
                child: new Text(
                  "$tempo",
                  style: _biggerFont,
                ),

                //White
                textColor: _txtColor,

                //Plays or pauses the metronome
                onPressed: () {
                  _play();
                },
              ),
            ),
          )),
    );
  }
}
