// 测试：IMAP 响应解析（中文/字面量/嵌套）+ 应用冒烟（登录页构建）。
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_mail/mail/imap_client.dart';
import 'package:m3e_mail/mail/mail_service.dart';
import 'package:m3e_mail/main.dart';
import 'package:m3e_mail/update/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('IMAP ENVELOPE 解析', () {
    test('中文主题以字面量传输时正确解析', () {
      final subject = '手表版邮件客户端评审会改到 15:00';
      final subjectB64 = utf8.encode(subject);
      // 模拟服务器响应：* 3 FETCH (FLAGS (\Seen) ENVELOPE (date subject ...))
      final line = <dynamic>[
        // 真实协议中 {N} 标记由 ImapClient._readLine 剥离，
        // 这里直接给出剥离后的段：字符串头 + 字面量字节 + 尾部
        '* 3 FETCH (FLAGS (\\Seen) ENVELOPE ("Mon, 07 Feb 2026 09:00:00 +0800" ',
        Uint8List.fromList(subjectB64),
        ' (("小舟" NIL "xiaozhou" "team.example")) NIL NIL NIL NIL NIL NIL))',
      ];
      final toks = lexLine(_stripFetch(line));
      final env = _envelopeOf(toks);
      expect(env.subject, subject);
      expect(env.fromName, '小舟');
      expect(env.fromEmail, 'xiaozhou@team.example');
    });

    test('引号内含转义与括号的主题', () {
      final line = <dynamic>[
        '* 5 FETCH (ENVELOPE ("Mon, 07 Feb 2026 10:00:00 +0800" "Re: 评审 (更新 v2 \\"终稿\\")" (("GitHub" NIL "noreply" "github.example")) NIL NIL (("我" NIL "me" "watch.example")) NIL NIL NIL NIL))',
      ];
      final toks = lexLine(_stripFetch(line));
      final env = _envelopeOf(toks);
      expect(env.subject, 'Re: 评审 (更新 v2 "终稿")');
      expect(env.fromEmail, 'noreply@github.example');
      expect(env.to, 'me@watch.example');
    });
  });

  test('演示数据源可初始化且明确标注演示', () {
    final demo = DemoMailSource(demoEmails());
    expect(demo.inbox, isNotEmpty);
    expect(demo.inbox.first.sender.startsWith('演示数据'), isTrue);
  });

  testWidgets('未登录时显示登录页', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const M3EMailApp());
    // M3E 组件有常驻微动画，不能用 pumpAndSettle
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('M3E Mail'), findsOneWidget);
    expect(find.text('登录邮箱'), findsOneWidget);
    expect(find.text('先看演示模式'), findsOneWidget);
  });

  group('版本比较（应用内更新）', () {
    test('latest 更新时返回 true', () {
      expect(UpdateService.isNewer('1.3.0', '1.2.0'), isTrue);
      expect(UpdateService.isNewer('v1.2.10', '1.2.9'), isTrue);
      expect(UpdateService.isNewer('2.0.0', '1.9.9'), isTrue);
    });
    test('相同或更旧时返回 false', () {
      expect(UpdateService.isNewer('1.2.0', '1.2.0'), isFalse);
      expect(UpdateService.isNewer('1.1.9', '1.2.0'), isFalse);
      expect(UpdateService.isNewer('', '1.2.0'), isFalse);
    });
  });
}

List<dynamic> _stripFetch(List<dynamic> line) {
  final first = line.first as String;
  final m = RegExp(r'^\*\s+\d+\s+FETCH\s+').firstMatch(first)!;
  final cleaned = <dynamic>[...line];
  cleaned[0] = first.substring(m.end - 1);
  return cleaned;
}

ImapEnvelope _envelopeOf(List<Tok> toks) {
  // 新词法器把整行包成一个外层 list，解包后扫描
  final top = toks.isNotEmpty && toks.first.kind == 'list'
      ? toks.first.children ?? <Tok>[]
      : toks;
  for (var i = 0; i < top.length; i++) {
    final t = top[i];
    if (t.kind == 'atom' && t.text!.toUpperCase() == 'ENVELOPE' &&
        i + 1 < top.length && top[i + 1].kind == 'list') {
      final items = top[i + 1].children!;
      String val(Tok? t) => (t == null || t.isNil) ? '' : t.str;
      final from = items.length > 2 ? items[2] : null;
      final quad = from != null && from.children!.isNotEmpty
          ? from.children!.first.children!
          : <Tok>[];
      final to = items.length > 5 ? items[5] : null;
      String toText = '';
      if (to != null && to.children != null && to.children!.isNotEmpty) {
        final quad = to.children!.first.children ?? <Tok>[];
        String val2(Tok? t) => (t == null || t.isNil) ? '' : t.str;
        toText = quad.length > 3
            ? '${val2(quad.length > 2 ? quad[2] : null)}@${val2(quad[3])}'
            : '';
      }
      return ImapEnvelope(
        fromName: quad.isNotEmpty ? val(quad[0]) : '',
        fromEmail:
            '${quad.length > 2 ? val(quad[2]) : ''}@${quad.length > 3 ? val(quad[3]) : ''}',
        subject: val(items.length > 1 ? items[1] : null),
        date: DateTime(2026),
        to: toText,
      );
    }
  }
  throw StateError('没有 ENVELOPE');
}
