// 应用内更新：双源一致性测试。
// 引入静态 version.json 作为 GitHub API 限流时的备用源后，
// 最大风险是发版时忘记同步它。这里强制校验它与 pubspec/APK 命名一致。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_mail/update/update_service.dart';

void main() {
  test('version.json 是合法的 arm64 更新描述', () {
    final Map<String, dynamic> m =
        jsonDecode(File('version.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(m['version'], isA<String>());
    expect(m['apk'], isA<String>());
    expect(m['apk'] as String, contains('arm64'));
    expect(m['apk'] as String, endsWith('.apk'));
    expect(m['size'], isA<int>());
    expect(m['size'] as int, greaterThan(0));
  });

  test('version.json 版本与 pubspec.yaml 一致（防止发版漏同步）', () {
    final Map<String, dynamic> m =
        jsonDecode(File('version.json').readAsStringSync())
            as Map<String, dynamic>;
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match =
        RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
            .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml 必须有 version 字段');
    expect(m['version'], match!.group(1));
    // 下载链接里的 tag 也要与版本号一致
    expect(m['apk'] as String, contains('/v${m['version']}/'));
  });

  group('版本比较（应用内更新）', () {
    test('latest 更新时返回 true', () {
      expect(UpdateService.isNewer('1.3.0', '1.2.0'), isTrue);
      expect(UpdateService.isNewer('v1.2.10', '1.2.9'), isTrue);
      expect(UpdateService.isNewer('2.0.0', '1.9.9'), isTrue);
    });
    test('相同或更旧、或当前版本未知时返回 false', () {
      expect(UpdateService.isNewer('1.2.0', '1.2.0'), isFalse);
      expect(UpdateService.isNewer('1.1.9', '1.2.0'), isFalse);
      expect(UpdateService.isNewer('', '1.2.0'), isFalse);
      expect(UpdateService.isNewer('1.3.0', ''), isFalse);
    });
  });
}
