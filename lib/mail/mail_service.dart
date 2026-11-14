/// 统一邮件服务：真实邮箱（IMAP/SMTP）与演示模式共用一套接口。
///
/// - 登录真实邮箱后，收件箱数据来自 IMAP 服务器；
///   加星/归档为本地覆盖层（本地状态叠加显示）。
/// - 「演示模式」使用本地下发的示例数据，界面上明确标注，
///   用于没有登录条件时体验交互。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/email.dart';
import 'imap_client.dart';
import 'smtp_client.dart';

/// 常用邮箱服务商的服务器预设。
class MailProviderPreset {
  const MailProviderPreset(this.name, this.imapHost, this.imapPort, this.smtpHost, this.smtpPort);

  final String name;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;

  static const List<MailProviderPreset> all = <MailProviderPreset>[
    MailProviderPreset('QQ 邮箱（需授权码）', 'imap.qq.com', 993, 'smtp.qq.com', 465),
    MailProviderPreset('163 网易邮箱（需授权码）', 'imap.163.com', 993, 'smtp.163.com', 465),
    MailProviderPreset('Gmail（需应用专用密码）', 'imap.gmail.com', 993, 'smtp.gmail.com', 465),
    MailProviderPreset('Outlook / Microsoft 365', 'outlook.office365.com', 993, 'smtp.office365.com', 465),
    MailProviderPreset('自定义服务器', '', 993, '', 465),
  ];
}

/// 邮件服务抽象：真实 IMAP 服务与演示数据源都实现它。
abstract class MailSource {
  List<Email> get inbox;

  /// 建立会话（真实服务）/ 初始化（演示）。
  Future<void> open();

  Future<String> bodyOf(Email email);

  Future<void> send({
    required String from,
    required String to,
    required String subject,
    required String body,
  });

  Future<void> close();
}

/// 真实邮箱数据源。
class ImapMailSource implements MailSource {
  ImapMailSource({
    required this.email,
    required this.password,
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
  });

  final String email;
  final String password;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;

  late ImapClient _imap;
  final List<Email> _inbox = <Email>[];

  @override
  List<Email> get inbox => List.unmodifiable(_inbox);

  @override
  Future<void> open() async {
    _imap = ImapClient(host: imapHost, port: imapPort);
    await _imap.connect(email, password);
    final heads = await _imap.listRecent(limit: 30);
    _inbox
      ..clear()
      ..addAll(heads.map((ImapMessageHead h) => Email(
            id: 'imap-${h.sequence}',
            sender: h.envelope.fromName.isEmpty
                ? h.envelope.fromEmail
                : h.envelope.fromName,
            senderEmail: h.envelope.fromEmail,
            subject: h.envelope.subject.isEmpty ? '(无主题)' : h.envelope.subject,
            body: '', // 正文按需加载
            time: h.envelope.date,
            unread: !h.seen,
          )));
  }

  @override
  Future<String> bodyOf(Email email) async {
    if (email.body.isNotEmpty) return email.body;
    final seq = int.tryParse(email.id.replaceFirst('imap-', ''));
    if (seq == null) return '';
    final text = await _imap.fetchText(seq);
    if (text.isNotEmpty) await _imap.markSeen(seq);
    return text;
  }

  @override
  Future<void> send({
    required String from,
    required String to,
    required String subject,
    required String body,
  }) async {
    final smtp = SmtpClient(host: smtpHost, port: smtpPort);
    await smtp.send(
      username: email,
      password: password,
      from: from,
      to: to,
      subject: subject,
      body: body,
    );
  }

  @override
  Future<void> close() => _imap.logout();
}

/// 演示模式数据源（本地示例数据，界面明确标注）。
class DemoMailSource implements MailSource {
  DemoMailSource(this._emails);

  final List<Email> _emails;

  @override
  List<Email> get inbox => List.unmodifiable(_emails);

  @override
  Future<void> open() async {}

  @override
  Future<String> bodyOf(Email email) async => email.body;

  @override
  Future<void> send({
    required String from,
    required String to,
    required String subject,
    required String body,
  }) async {
    // 演示模式：只做本地投递模拟
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> close() async {}
}

/// 应用级邮件服务（状态中枢）。
class MailService extends ChangeNotifier {
  MailService._();

  static final MailService instance = MailService._();

  MailSource? _source;
  String _accountEmail = '';
  bool _isDemo = false;
  bool _loading = false;
  String? _error;
  final Set<String> _starred = <String>{};
  final Set<String> _archived = <String>{};

  bool get loading => _loading;
  String? get error => _error;
  bool get isDemo => _isDemo;
  bool get loggedIn => _source != null;
  String get accountEmail => _accountEmail;

  /// 登录真实邮箱。
  Future<void> login({
    required String email,
    required String password,
    required String imapHost,
    required int imapPort,
    required String smtpHost,
    required int smtpPort,
    bool remember = true,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final source = ImapMailSource(
        email: email,
        password: password,
        imapHost: imapHost,
        imapPort: imapPort,
        smtpHost: smtpHost,
        smtpPort: smtpPort,
      );
      await source.open();
      await _activate(source, email, demo: false);
      if (remember) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('m3e_account', jsonEncode(<String, dynamic>{
          'type': 'imap',
          'email': email,
          'password': password,
          'imapHost': imapHost,
          'imapPort': imapPort,
          'smtpHost': smtpHost,
          'smtpPort': smtpPort,
        }));
      }
    } on SocketException catch (e) {
      _error = '网络连接失败：${e.message}';
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 进入演示模式（本地示例数据，界面会明确标注）。
  Future<void> enterDemoMode() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('m3e_account');
      await _activate(DemoMailSource(demoEmails()), '演示账号', demo: true);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 启动时恢复已保存的账号（失败则留在登录页）。
  Future<bool> tryRestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('m3e_account');
      if (raw == null) return false;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != 'imap') return false;
      _loading = true;
      notifyListeners();
      try {
        final source = ImapMailSource(
          email: map['email'] as String,
          password: map['password'] as String,
          imapHost: map['imapHost'] as String,
          imapPort: map['imapPort'] as int,
          smtpHost: map['smtpHost'] as String,
          smtpPort: map['smtpPort'] as int,
        );
        await source.open();
        await _activate(source, map['email'] as String, demo: false);
        return true;
      } finally {
        _loading = false;
        notifyListeners();
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _source?.close();
    _source = null;
    _accountEmail = '';
    _isDemo = false;
    _starred.clear();
    _archived.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('m3e_account');
    notifyListeners();
  }

  Future<void> _activate(MailSource source, String account, {required bool demo}) async {
    await _source?.close();
    _source = source;
    _accountEmail = account;
    _isDemo = demo;
    _starred.clear();
    _archived.clear();
    notifyListeners();
  }

  // ---------- 列表/详情/发信 ----------

  List<Email> get inbox {
    final src = _source;
    if (src == null) return <Email>[];
    return src.inbox
        .where((e) => !_archived.contains(e.id))
        .map((e) => e.copyWith(
              starred: _starred.contains(e.id) || e.starred,
            ))
        .toList();
  }

  List<Email> get starred => inbox.where((e) => e.starred).toList();
  List<Email> get archived {
    final src = _source;
    if (src == null) return <Email>[];
    return src.inbox
        .where((e) => _archived.contains(e.id))
        .map((e) => e.copyWith(starred: _starred.contains(e.id) || e.starred))
        .toList();
  }

  int get unreadCount => inbox.where((e) => e.unread).length;

  Email? byId(String id) {
    for (final e in inbox) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<String> loadBody(Email email) async {
    final text = await _source!.bodyOf(email);
    if (text.isNotEmpty) {
      notifyListeners();
    }
    return text;
  }

  void markRead(String id) {
    final e = _rawById(id);
    if (e != null && e.unread) {
      e.unread = false;
      notifyListeners();
    }
  }

  void toggleStar(String id) {
    _starred.contains(id) ? _starred.remove(id) : _starred.add(id);
    notifyListeners();
  }

  void archive(String id) {
    _archived.add(id);
    notifyListeners();
  }

  Email? _rawById(String id) {
    for (final e in _source?.inbox ?? <Email>[]) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> sendMail({
    required String to,
    required String subject,
    required String body,
  }) async {
    await _source!.send(
      from: _accountEmail,
      to: to,
      subject: subject,
      body: body,
    );
  }

  List<Email> search(String keyword) {
    final k = keyword.trim().toLowerCase();
    if (k.isEmpty) return inbox;
    return inbox
        .where((e) =>
            e.sender.toLowerCase().contains(k) ||
            e.subject.toLowerCase().contains(k) ||
            e.senderEmail.toLowerCase().contains(k))
        .toList();
  }

  /// 自动补全：从收件人历史里按前缀建议地址。
  List<String> suggestionsFor(String input) {
    final k = input.trim().toLowerCase();
    if (k.isEmpty) return <String>[];
    final seen = <String>{};
    final out = <String>[];
    for (final e in inbox) {
      final addr = e.senderEmail;
      if (addr.contains(k) && seen.add(addr)) out.add(addr);
      if (out.length >= 3) break;
    }
    return out;
  }
}

/// 演示模式示例数据（界面上会标注「演示数据」）。
List<Email> demoEmails() {
  final now = DateTime.now();
  Email m({
    required String id,
    required String sender,
    required String senderEmail,
    required String subject,
    required String body,
    required int minutesAgo,
    bool unread = false,
    bool starred = false,
  }) =>
      Email(
        id: 'demo-$id',
        sender: sender,
        senderEmail: senderEmail,
        subject: subject,
        body: body,
        time: now.subtract(Duration(minutes: minutesAgo)),
        unread: unread,
        starred: starred,
      );

  return <Email>[
    m(
      id: 'd1',
      sender: '演示数据 · 产品组',
      senderEmail: 'demo@team.example',
      subject: '这是演示模式的一封示例邮件',
      body: '你当前处于演示模式，数据全部为本机示例，不是真实邮件。\n\n'
          '要收发真实邮件，请退出后在登录页选择你的邮箱服务商'
          '（QQ 邮箱 / 163 / Gmail / Outlook / 自定义 IMAP 服务器），'
          '使用邮箱地址和授权码登录。',
      minutesAgo: 2,
      unread: true,
    ),
    m(
      id: 'd2',
      sender: '演示数据 · 服务器告警',
      senderEmail: 'demo@ops.example',
      subject: '示例：mail-api 今晚灰度发布',
      body: '（演示数据）mail-api 将于今晚 23:00 灰度发布，期间手表端同步可能有 1-2 分钟延迟。',
      minutesAgo: 90,
      starred: true,
    ),
    m(
      id: 'd3',
      sender: '演示数据 · 人事行政',
      senderEmail: 'demo@hr.example',
      subject: '示例：10 月差旅报销已到账',
      body: '（演示数据）您 10 月提交的差旅报销单已完成审核并打款，请注意查收。',
      minutesAgo: 1500,
    ),
  ];
}
