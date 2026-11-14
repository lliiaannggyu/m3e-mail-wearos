/// 最小可用的 IMAP4rev1 客户端（SSL 993 端口）。
///
/// 只实现手表邮件客户端需要的能力：
/// 登录 → 读取 INBOX 邮件列表（FLAGS/ENVELOPE）→ 拉取正文 → 登出。
/// ENVELOPE 解析基于 IMAP 的括号嵌套语法，正确处理 {N} 字面量
/// （中文主题/发件人通常以字面量传输，必须按字节解析）。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// IMAP 信封解析出的邮件头。
class ImapEnvelope {
  ImapEnvelope({
    required this.fromName,
    required this.fromEmail,
    required this.subject,
    required this.date,
    this.to = '',
  });

  final String fromName;
  final String fromEmail;
  final String subject;
  final DateTime date;
  final String to;
}

/// IMAP 信封 + 标志的抓取结果。
class ImapMessageHead {
  ImapMessageHead({
    required this.sequence,
    required this.envelope,
    this.seen = false,
  });

  final int sequence;
  final ImapEnvelope envelope;
  final bool seen;
}

/// IMAP 词法单元（树状）。
class Tok {
  Tok.atom(this.text) : kind = 'atom', bytes = null, children = null;
  Tok.quoted(this.text) : kind = 'quoted', bytes = null, children = null;
  Tok.literal(Uint8List b) : kind = 'literal', text = null, bytes = b, children = null;
  Tok.list(this.children) : kind = 'list', text = null, bytes = null;

  final String kind; // atom | quoted | literal | list
  final String? text;
  final Uint8List? bytes;
  final List<Tok>? children;

  String get str {
    if (kind == 'literal') return utf8.decode(bytes!, allowMalformed: true);
    if (kind == 'NIL') return '';
    return text ?? '';
  }

  bool get isNil => kind == 'atom' && text == 'NIL';
}

/// 把一行 IMAP 响应（String 段 + 字面量字节段混合）切成词法树。
/// 整行由调用方组织为 [String|Uint8List] 段列表；第一个 String 段
/// 应已去掉 "* 3 FETCH " 前缀并以 "(" 开头。
List<Tok> lexLine(List<dynamic> segs) {
  final _Cursor cur = _Cursor();
  final out = <Tok>[];
  _lexInto(segs, cur, out);
  return out;
}

/// 词法游标：跨 String/字面量段共享推进。
class _Cursor {
  int seg = 0;
  int pos = 0;
}

/// 括号哨兵单元。
final Tok _lpTok = Tok.atom('(');
final Tok _rpTok = Tok.atom(')');

/// 递归下降：把 token 追加到 [out]，遇到本层的 ')' 返回。
/// 顶层调用遇 ')' 同样返回（调用方保证配对）。
void _lexInto(List<dynamic> segs, _Cursor cur, List<Tok> out) {
  while (true) {
    final Tok? t = _readToken(segs, cur);
    if (t == null) return; // 输入结束
    if (identical(t, _rpTok)) return; // 本层结束
    if (identical(t, _lpTok)) {
      final children = <Tok>[];
      _lexInto(segs, cur, children);
      out.add(Tok.list(children));
      continue;
    }
    out.add(t);
  }
}

/// 跳过空白；返回是否还有内容。
bool _skipSpaces(List<dynamic> segs, _Cursor cur) {
  while (cur.seg < segs.length) {
    final s = segs[cur.seg];
    if (s is Uint8List) return true;
    final str = s as String;
    while (cur.pos < str.length && str[cur.pos] == ' ') {
      cur.pos++;
    }
    if (cur.pos < str.length) return true;
    cur.seg++;
    cur.pos = 0;
  }
  return false;
}

/// 读取下一个 token；输入结束返回 null。
Tok? _readToken(List<dynamic> segs, _Cursor cur) {
  if (!_skipSpaces(segs, cur)) return null;
  final s = segs[cur.seg];
  if (s is Uint8List) {
    cur.seg++;
    cur.pos = 0;
    return Tok.literal(s);
  }
  final c = s[cur.pos];
  if (c == '(') {
    cur.pos++;
    _advanceCursor(segs, cur);
    return _lpTok;
  }
  if (c == ')') {
    cur.pos++;
    _advanceCursor(segs, cur);
    return _rpTok;
  }
  if (c == '"') {
    cur.pos++;
    _advanceCursor(segs, cur);
    final sb = StringBuffer();
    while (_ensureChar(segs, cur)) {
      final segStr = segs[cur.seg] as String;
      final ch = segStr[cur.pos];
      if (ch == '"') {
        cur.pos++;
        _advanceCursor(segs, cur);
        return Tok.quoted(sb.toString());
      }
      if (ch == '\\') {
        cur.pos++;
        _advanceCursor(segs, cur);
        if (_ensureChar(segs, cur)) {
          sb.write((segs[cur.seg] as String)[cur.pos]);
          cur.pos++;
          _advanceCursor(segs, cur);
        }
        continue;
      }
      sb.write(ch);
      cur.pos++;
      _advanceCursor(segs, cur);
    }
    return Tok.quoted(sb.toString()); // 未闭合引号：容错收尾
  }
  // atom
  final sb = StringBuffer();
  while (_ensureChar(segs, cur)) {
    final segStr = segs[cur.seg] as String;
    final ch = segStr[cur.pos];
    if (ch == ' ' || ch == '(' || ch == ')' || ch == '"') break;
    sb.write(ch);
    cur.pos++;
    _advanceCursor(segs, cur);
  }
  return Tok.atom(sb.toString());
}

/// 确保当前游标落在某个 String 段的可用字符上；
/// 跳过字面量段与已耗尽的段。返回是否成功。
bool _ensureChar(List<dynamic> segs, _Cursor cur) {
  while (cur.seg < segs.length) {
    final s = segs[cur.seg];
    if (s is Uint8List) return false; // atom/引号内不应跨越字面量
    if (cur.pos < (s as String).length) return true;
    cur.seg++;
    cur.pos = 0;
  }
  return false;
}

/// pos 前进一格；若耗尽当前段则移到下一段。
void _advanceCursor(List<dynamic> segs, _Cursor cur) {
  if (cur.seg < segs.length && segs[cur.seg] is String) {
    final str = segs[cur.seg] as String;
    if (cur.pos >= str.length) {
      cur.seg++;
      cur.pos = 0;
    }
  }
}

/// IMAP 客户端。
class ImapClient {
  ImapClient({
    required this.host,
    this.port = 993,
    this.allowSelfSignedCertificate = false,
  });

  final String host;
  final int port;
  final bool allowSelfSignedCertificate;

  late SecureSocket _socket;
  StreamIterator<List<int>>? _iter;
  List<int> _pending = <int>[];
  int _tagSeq = 0;
  bool _loggedIn = false;
  int inboxExists = 0;

  Future<void> connect(
    String user,
    String password, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _socket = await SecureSocket.connect(
      host,
      port,
      timeout: timeout,
      onBadCertificate: allowSelfSignedCertificate ? (_) => true : null,
    );
    _iter = StreamIterator<List<int>>(_socket);
    await _readLine(); // 服务器问候
    final (ok, data) = await _command('LOGIN ${_quote(user)} ${_quote(password)}');
    if (!ok) {
      throw Exception('IMAP 登录失败（检查邮箱地址与授权码）：${data.isEmpty ? '被服务器拒绝' : _plain(data.last)}');
    }
    _loggedIn = true;
    final (okSel, dataSel) = await _command('SELECT INBOX');
    if (!okSel) throw Exception('打开 INBOX 失败：${dataSel.isEmpty ? '' : _plain(dataSel.last)}');
    for (final segs in dataSel) {
      final m = RegExp(r'^\*\s+(\d+)\s+EXISTS').firstMatch(_plain(segs));
      if (m != null) inboxExists = int.parse(m.group(1)!);
    }
  }

  bool get loggedIn => _loggedIn;

  /// 拉取 INBOX 最近 [limit] 封邮件的头信息（按时间新→旧）。
  Future<List<ImapMessageHead>> listRecent({int limit = 30}) async {
    if (inboxExists == 0) return <ImapMessageHead>[];
    final from = inboxExists - limit + 1 < 1 ? 1 : inboxExists - limit + 1;
    final (ok, data) = await _command('FETCH $from:$inboxExists (FLAGS ENVELOPE)');
    if (!ok) throw Exception('FETCH 失败：${data.isEmpty ? '' : _plain(data.last)}');
    final heads = <ImapMessageHead>[];
    for (final segs in data) {
      final head = _parseFetchLine(segs);
      if (head != null) heads.add(head);
    }
    heads.sort((a, b) => b.sequence.compareTo(a.sequence));
    return heads;
  }

  /// 拉取某封邮件的正文（BODY[TEXT]）。
  Future<String> fetchText(int sequence) async {
    final (ok, data) = await _command('FETCH $sequence (BODY.PEEK[TEXT])');
    if (!ok) throw Exception('拉取正文失败：${data.isEmpty ? '' : _plain(data.last)}');
    for (final segs in data) {
      final toks = lexLine(_stripFetchPrefix(segs));
      final top = toks.isNotEmpty && toks.first.kind == 'list'
          ? toks.first.children ?? <Tok>[]
          : toks;
      for (var i = 0; i < top.length; i++) {
        final t = top[i];
        if ((t.kind == 'atom') && t.text!.toUpperCase().startsWith('BODY[')) {
          if (i + 1 < top.length && top[i + 1].kind == 'literal') {
            return utf8.decode(top[i + 1].bytes!, allowMalformed: true);
          }
        }
      }
    }
    return '';
  }

  Future<void> markSeen(int sequence) async {
    if (!_loggedIn) return;
    try {
      await _command('STORE $sequence +FLAGS (\\Seen)');
    } catch (_) {}
  }

  Future<void> logout() async {
    if (!_loggedIn) return;
    _loggedIn = false;
    try {
      await _command('LOGOUT');
      _socket.destroy();
    } catch (_) {}
  }

  // ---------- 解析 ----------

  ImapMessageHead? _parseFetchLine(List<dynamic> segs) {
    final first = segs.first as String;
    final m = RegExp(r'^\*\s+(\d+)\s+FETCH\s+').firstMatch(first);
    if (m == null) return null;
    final seq = int.parse(m.group(1)!);
    final cleaned = <dynamic>[...segs];
    cleaned[0] = first.substring(m.end - 1); // 保留 '('
    final toks = lexLine(cleaned);
    // 新词法器把整行包成一个外层 list，解包后扫描
    final top = toks.isNotEmpty && toks.first.kind == 'list'
        ? toks.first.children ?? <Tok>[]
        : toks;

    Tok? flags;
    Tok? envelope;
    for (var i = 0; i < top.length; i++) {
      final t = top[i];
      if (t.kind == 'atom' && t.text!.toUpperCase() == 'FLAGS' &&
          i + 1 < top.length && top[i + 1].kind == 'list') {
        flags = top[i + 1];
      }
      if (t.kind == 'atom' && t.text!.toUpperCase() == 'ENVELOPE' &&
          i + 1 < top.length && top[i + 1].kind == 'list') {
        envelope = top[i + 1];
      }
    }
    if (envelope == null) return null;

    // ENVELOPE: (date subject (from) (sender) (reply-to) (to) (cc) (bcc) in-reply-to message-id)
    final items = envelope.children!;
    String subj = _valOf(items.length > 1 ? items[1] : null);
    final from = items.length > 2 ? _firstAddress(items[2]) : null;
    final toList = items.length > 5 ? _addressListText(items[5]) : '';
    final seen = flags != null && _flat(flags).contains('Seen');

    return ImapMessageHead(
      sequence: seq,
      envelope: ImapEnvelope(
        fromName: from?.$1 ?? '',
        fromEmail: from?.$2 ?? '',
        subject: subj,
        date: _parseImapDate(items.isNotEmpty ? _valOf(items[0]) : ''),
        to: toList,
      ),
      seen: seen,
    );
  }

  static String _valOf(Tok? t) {
    if (t == null || t.isNil) return '';
    return t.str;
  }

  /// 从地址列表 Tok（list of list）取第一个地址。
  (String, String)? _firstAddress(Tok listTok) {
    final addrs = listTok.children ?? <Tok>[];
    for (final a in addrs) {
      if (a.kind != 'list') continue;
      final quad = a.children!;
      final name = quad.isNotEmpty ? _valOf(quad[0]) : '';
      final mailbox = quad.length > 2 ? _valOf(quad[2]) : '';
      final hostPart = quad.length > 3 ? _valOf(quad[3]) : '';
      final email = hostPart.isEmpty ? mailbox : '$mailbox@$hostPart';
      if (email.isNotEmpty && email != '@') {
        return (name.isEmpty ? mailbox : name, email);
      }
    }
    return null;
  }

  String _addressListText(Tok listTok) {
    final parts = <String>[];
    for (final a in listTok.children ?? <Tok>[]) {
      if (a.kind != 'list') continue;
      final one = _firstAddress(Tok.list([a]));
      if (one != null) parts.add(one.$2);
    }
    return parts.join(', ');
  }

  static String _flat(Tok t) {
    if (t.children == null) return t.str;
    return t.children!.map(_flat).join(' ');
  }

  static DateTime _parseImapDate(String s) {
    final m = RegExp(
      r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(s);
    if (m == null) return DateTime.now();
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return DateTime(
      int.parse(m.group(3)!),
      months[m.group(2)!]!,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
  }

  static List<dynamic> _stripFetchPrefix(List<dynamic> segs) {
    final first = segs.first as String;
    final m = RegExp(r'^\*\s+\d+\s+FETCH\s+').firstMatch(first);
    final cleaned = <dynamic>[...segs];
    cleaned[0] = m == null ? first : first.substring(m.end - 1);
    return cleaned;
  }

  static String _plain(List<dynamic> segs) =>
      segs.map((s) => s is String ? s : '<literal>').join();

  // ---------- 底层：按行读取（含 {N} 字面量分段） ----------

  Future<List<dynamic>> _readLine() async {
    while (true) {
      final idx = _findCrlf(_pending);
      if (idx >= 0) {
        final lineBytes = _pending.sublist(0, idx);
        _pending = _pending.sublist(idx + 2);
        final lit = _literalAtEnd(lineBytes);
        if (lit != null) {
          final segs = <dynamic>[
            utf8.decode(lineBytes.sublist(0, lit.$1), allowMalformed: true),
            Uint8List.fromList(await _readExact(lit.$2)),
          ];
          segs.addAll(await _readLine());
          return segs;
        }
        return <dynamic>[utf8.decode(lineBytes, allowMalformed: true)];
      }
      await _fill();
    }
  }

  Future<void> _fill() async {
    final got = await _iter!.moveNext();
    if (!got) throw Exception('IMAP 连接被关闭');
    _pending = [..._pending, ..._iter!.current];
  }

  Future<List<int>> _readExact(int n) async {
    while (_pending.length < n) {
      await _fill();
    }
    final out = _pending.sublist(0, n);
    _pending = _pending.sublist(n);
    return out;
  }

  static int _findCrlf(List<int> b) {
    for (var i = 0; i + 1 < b.length; i++) {
      if (b[i] == 13 && b[i + 1] == 10) return i;
    }
    return -1;
  }

  static (int, int)? _literalAtEnd(List<int> b) {
    var i = b.length - 1;
    if (i < 1 || b[i] != 125) return null; // '}'
    var num = 0;
    var mul = 1;
    i--;
    while (i >= 0 && b[i] >= 48 && b[i] <= 57) {
      num += (b[i] - 48) * mul;
      mul *= 10;
      i--;
    }
    if (i < 0 || b[i] != 123) return null; // '{'
    return (i, num);
  }

  Future<(bool, List<List<dynamic>>)> _command(String cmd) async {
    final tag = 'A${_tagSeq++}';
    _socket.add(utf8.encode('$tag $cmd\r\n'));
    final data = <List<dynamic>>[];
    while (true) {
      final segs = await _readLine();
      final first = segs.first as String;
      if (first.startsWith('$tag ')) {
        return (first.substring(tag.length + 1).startsWith('OK'), data);
      }
      data.add(segs);
    }
  }

  static String _quote(String s) =>
      '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
}
