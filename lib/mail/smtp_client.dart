/// 最小可用的 SMTP 客户端（SSL 465 端口）。
///
/// 支持 EHLO → AUTH LOGIN → 发信，满足手表上快速回复/发信的需求。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SmtpClient {
  SmtpClient({
    required this.host,
    this.port = 465,
    this.allowSelfSignedCertificate = false,
  });

  final String host;
  final int port;
  final bool allowSelfSignedCertificate;

  late SecureSocket _socket;
  StreamIterator<List<int>>? _iter;
  List<int> _pending = <int>[];

  Future<void> send({
    required String username,
    required String password,
    required String from,
    required String to,
    required String subject,
    required String body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _socket = await SecureSocket.connect(
      host,
      port,
      timeout: timeout,
      onBadCertificate: allowSelfSignedCertificate ? (_) => true : null,
    );
    _iter = StreamIterator<List<int>>(_socket);

    await _expect('220', '服务器问候');
    await _say('EHLO watch-mail');
    await _expect('250', 'EHLO');
    await _say('AUTH LOGIN');
    await _expect('334', 'AUTH LOGIN');
    await _say(base64.encode(utf8.encode(username)));
    await _expect('334', '用户名');
    await _say(base64.encode(utf8.encode(password)));
    final (authOk, authMsg) = await _expect('235', '鉴权');
    if (!authOk) {
      throw Exception('SMTP 鉴权失败（检查邮箱地址与授权码）：$authMsg');
    }
    await _say('MAIL FROM:<$from>');
    await _expect('250', 'MAIL FROM');
    await _say('RCPT TO:<$to>');
    final (rcptOk, rcptMsg) = await _expect('250', 'RCPT TO');
    if (!rcptOk) throw Exception('收件人被拒绝：$rcptMsg');
    await _say('DATA');
    await _expect('354', 'DATA');

    // 邮件头 + 正文（点填充规则防提前结束）
    final message = <String>[
      'From: $from',
      'To: $to',
      'Subject: =?UTF-8?B?${base64.encode(utf8.encode(subject))}?=',
      'MIME-Version: 1.0',
      'Content-Type: text/plain; charset=UTF-8',
      'Content-Transfer-Encoding: base64',
      '',
      _chunkB64(base64.encode(utf8.encode(body))),
      '.',
    ].join('\r\n');
    _socket.add(utf8.encode('$message\r\n'));
    await _expect('250', '投递');
    await _say('QUIT');
    _socket.destroy();
  }

  /// base64 按 76 列换行（SMTP 行长限制）。
  static String _chunkB64(String b64) {
    final sb = StringBuffer();
    for (var i = 0; i < b64.length; i += 76) {
      sb.write(b64.substring(i, i + 76 > b64.length ? b64.length : i + 76));
      sb.write('\r\n');
    }
    return sb.toString();
  }

  Future<void> _say(String line) async {
    _socket.add(utf8.encode('$line\r\n'));
  }

  Future<(bool, String)> _expect(String code, String stage) async {
    // 读取多行响应（2xx 响应可能多行，最后一行才是终态）
    while (true) {
      final line = await _readLine();
      // 多行响应形如 250-xxx，250 空格结尾表示结束
      final m = RegExp(r'^(\d{3})([ -])').firstMatch(line);
      if (m == null) continue;
      if (m.group(2) == ' ') {
        final ok = line.startsWith(code);
        return (ok, line);
      }
    }
  }

  Future<String> _readLine() async {
    while (true) {
      for (var i = 0; i + 1 < _pending.length; i++) {
        if (_pending[i] == 13 && _pending[i + 1] == 10) {
          final line = utf8.decode(_pending.sublist(0, i), allowMalformed: true);
          _pending = _pending.sublist(i + 2);
          return line;
        }
      }
      final got = await _iter!.moveNext();
      if (!got) throw Exception('SMTP 连接被关闭');
      _pending = [..._pending, ..._iter!.current];
    }
  }
}
