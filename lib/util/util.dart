import 'dart:convert';
import 'dart:io';

import 'package:record_example/util/pack/get_audio_from_text.dart';
import 'package:record_example/util/pack/get_text_from_audio.dart';
import 'package:record_example/util/pack/play_audio.dart';
import 'package:record_example/util/pack/random_chinese.dart';
import 'package:record_example/util/pack/random_english.dart';
import 'package:record_example/util/pack/refresh_token.dart';
import 'package:record_example/util/pack/text_diff.dart';

class Util {
  static Future<void> refreshToken() async {
    return await doRefreshToken();
  }

  static Future<String> getToken() async {
    return doGetToken();
  }

  static Future<void> getAudioFromText(String text, String saveFile) async {
    return doGetAudioFromText(text, saveFile, provider: TtsProvider.doubao);
  }

  static Future<void> getAudioFromTextFromQwen(String text, String saveFile, {TtsProvider provider = TtsProvider.aliyun}) async {
    return doGetAudioFromText(text, saveFile, provider: provider);
  }

  static Future<void> getAudioFromTextAliyun(String text, String saveFile) async {
    return doGetAudioFromTextAliyun(text, saveFile);
  }

  static Future<void> getAudioFromTextDoubao(String text, String saveFile) async {
    return doGetAudioFromTextDoubao(text, saveFile);
  }

  static Future<String> getTextFromAudio(String path) async {
    return doGetTextFromAudio(path);
  }

  static Future<void> playAudio(String path) async {
    return doPlayAudio(path);
  }

  static Future<bool> textIsSame(String original, String user) async {
    return doTextIsSame(original, user);
  }

  static Future<List<String>> randomEnglish(String cn, String en) async {
    return doRandomEnglish(cn, en);
  }

  static Future<List<String>> randomChinese(String en, String cn) async {
    return doRandomChinese(en, cn);
  }

  static Future<double> getWavDuration(String filePath) async {
    if (!File(filePath).existsSync()) {
      throw Exception("文件不存在: $filePath");
    }

    // 构建 FFmpeg 命令
    final command = ['ffprobe', '-i', filePath, '-show_entries', 'format=duration', '-v', 'quiet', '-of', 'csv=p=0'];

    // 使用 Process.run 执行命令
    final processResult = await Process.run(command[0], command.sublist(1));

    // 检查命令执行是否成功
    if (processResult.exitCode != 0) {
      throw Exception("ffprobe 执行失败: ${processResult.stderr}");
    }

    // 解析输出结果
    final output = processResult.stdout.toString().trim();

    try {
      final duration = double.parse(output);
      return duration;
    } catch (e) {
      throw Exception("无法解析 WAV 文件时长: $filePath, ffprobe output: $output, error: $e");
    }
  }

  static Future<double> getWavDurationAlternative(String filePath) async {
    if (!File(filePath).existsSync()) {
      throw Exception("文件不存在: $filePath");
    }

    final process = await Process.start('ffmpeg', ['-i', filePath, '-f', 'null', '-']);
    String stderrOutput = '';

    // 监听 stderr 流，因为 FFmpeg 通常将时长信息输出到 stderr
    process.stderr.transform(utf8.decoder).listen((data) {
      stderrOutput += data;
    });

    // 等待进程结束
    await process.exitCode;
    // 解析日志中的时长信息
    final regex = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)');
    final match = regex.firstMatch(stderrOutput);

    if (match != null) {
      final hours = double.parse(match.group(1)!);
      final minutes = double.parse(match.group(2)!);
      final seconds = double.parse(match.group(3)!);
      return hours * 3600 + minutes * 60 + seconds;
    }
    final regex2 = RegExp(r"time=(\d+):(\d+):(\d+\.\d+)");

    final match2 = regex2.firstMatch(stderrOutput);
    if (match2 != null) {
      final hours = double.parse(match2.group(1)!);
      final minutes = double.parse(match2.group(2)!);
      final seconds = double.parse(match2.group(3)!);
      return hours * 3600 + minutes * 60 + seconds;
    }

    throw Exception("无法解析 WAV 文件时长: $filePath");
  }
}
