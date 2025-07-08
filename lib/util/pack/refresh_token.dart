import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../const/key.dart';

class AccessToken {
  static String _encodeText(String text) {
    return Uri.encodeComponent(text).replaceAll('+', '%20').replaceAll('*', '%2A').replaceAll('%7E', '~');
  }

  static String _encodeMap(Map<String, String> map) {
    var sortedKeys = map.keys.toList()..sort();
    var encodedPairs = sortedKeys.map((key) => '$key=${_encodeText(map[key]!)}');
    return encodedPairs.join('&');
  }

  static Future<Map<String, String>?> createToken(String accessKeyId, String accessKeySecret) async {
    var parameters = {
      'AccessKeyId': accessKeyId,
      'Action': 'CreateToken',
      'Format': 'JSON',
      'RegionId': 'cn-shanghai',
      'SignatureMethod': 'HMAC-SHA1',
      'SignatureNonce': Uuid().v1(),
      'SignatureVersion': '1.0',
      'Timestamp': DateTime.now().toUtc().toString().substring(0, 19) + 'Z',
      'Version': '2019-02-28'
    };

    // 构造规范化的请求字符串
    var queryString = _encodeMap(parameters);
    print('规范化的请求字符串: $queryString');

    // 构造待签名字符串
    var stringToSign = 'GET&${_encodeText('/')}&${_encodeText(queryString)}';
    print('待签名的字符串: $stringToSign');

    // 计算签名
    var key = utf8.encode(accessKeySecret + '&');
    var bytes = utf8.encode(stringToSign);
    var hmacSha1 = Hmac(sha1, key);
    var digest = hmacSha1.convert(bytes);
    var signature = base64Encode(digest.bytes);
    print('签名: $signature');

    // 进行URL编码
    var encodedSignature = _encodeText(signature);
    print('URL编码后的签名: $encodedSignature');

    // 调用服务
    var fullUrl = 'http://nls-meta.cn-shanghai.aliyuncs.com/?Signature=$encodedSignature&$queryString';
    print('url: $fullUrl');

    // 提交HTTP GET请求
    var response = await http.get(Uri.parse(fullUrl));
    if (response.statusCode == 200) {
      var rootObj = jsonDecode(response.body);
      var key = 'Token';
      if (rootObj.containsKey(key)) {
        var token = rootObj[key]['Id'];
        var expireTime = rootObj[key]['ExpireTime'];
        return {'token': token, 'expireTime': expireTime.toString()};
      }
    }
    print(response.body);
    return null;
  }
}

Map<String, String> store = {"token": ""};

String doGetToken() {
  return store['token']!;
}

Future<void> doRefreshToken() async {
  var accessKeyId = Key.AccessKeyId; // 替换为你的AccessKey ID
  var accessKeySecret = Key.AccessKeySecret; // 替换为你的AccessKey Secret

  var tokenData = await AccessToken.createToken(accessKeyId, accessKeySecret);
  if (tokenData != null) {
    var token = tokenData['token'];
    var expireTime = tokenData['expireTime'];
    print('token: $token, expire time(s): $expireTime');
    if (expireTime != null) {
      var expireDate = DateTime.fromMillisecondsSinceEpoch(int.parse(expireTime) * 1000);
      print('token有效期的北京时间：${expireDate.toLocal()}');
    }
    store['token'] = token!;
  }
}

void main() async {
  await doRefreshToken();
}
