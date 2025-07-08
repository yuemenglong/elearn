import 'dart:async';
import 'dart:ui';

class TimeRecorder {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _maxTimer;
  double _maxDuration = 100000.0; // 默认最大时间
  int _recordMs = 0;
  VoidCallback? onPauseCallback; // 新增回调

  /// 开始记录时间。
  void start({double max = 100000.0, VoidCallback? onPause}) {
    if (_stopwatch.isRunning) {
      pause();
    }

    _maxDuration = max;
    _stopwatch.start();
    onPauseCallback = onPause;

    _maxTimer = Timer(Duration(milliseconds: (_maxDuration * 1000).toInt()), () {
      pause();
      if (onPauseCallback != null) {
        onPauseCallback!();
      }
    });
  }

  /// 暂停记录时间。
  void pause() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _recordMs += _stopwatch.elapsedMilliseconds;
      print('Paused: _recordMs = $_recordMs');
      _stopwatch.reset();
      _maxTimer?.cancel();
      _maxTimer = null;
    }
  }

  /// 重置记录时间。
  void reset() {
    pause();
    _recordMs = 0;
    print('Reset: _recordMs = $_recordMs');
  }

  /// 获取当前记录的持续时间（单位：秒）。
  int getTotalMs() {
    if (_stopwatch.isRunning) {
      return _recordMs + (_stopwatch.elapsedMilliseconds);
    } else {
      return _recordMs;
    }
  }

  String getTotalTimeStr() {
    int totalSeconds = getTotalMs() ~/ 1000;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}分:${seconds.toString().padLeft(2, '0')}秒';
  }
}