import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';

Future<void> doPlayAudio(String path) async {
  var completer = Completer<void>();
  final audioPlayer = ap.AudioPlayer();

  audioPlayer.onPlayerComplete.listen((_) {
    audioPlayer.dispose();
    completer.complete();
  });

  final source = kIsWeb ? ap.UrlSource(path) : ap.DeviceFileSource(path);

  await audioPlayer.play(source);
  return completer.future;
}
