// 应用冒烟测试：收件箱能正常构建、模拟数据过滤搜索正确。
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_mail/data/mock_mailbox.dart';
import 'package:m3e_mail/main.dart';
import 'package:m3e_mail/models/email.dart';

void main() {
  testWidgets('收件箱页面可以构建并显示标题', (WidgetTester tester) async {
    await tester.pumpWidget(M3EMailApp());
    await tester.pumpAndSettle();

    expect(find.text('收件箱 · 2 未读'), findsOneWidget);
  });

  test('模拟邮箱数据：文件夹过滤与搜索', () {
    final store = MailStore();
    expect(store.folder(Folder.inbox), isNotEmpty);
    expect(store.folder(Folder.starred), isNotEmpty);
    expect(store.search('手表'), isNotEmpty);
    expect(store.search('不存在的关键字xyz'), isEmpty);
  });
}
