import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'data/mock_mailbox.dart';
import 'screens/inbox_page.dart';

void main() => runApp(const M3EMailApp());

/// M3E Mail — 运行在 Wear OS 手表上的邮件客户端。
///
/// 全局使用深色主题（OLED 表盘省电 + 圆屏观感更佳），
/// 所有 UI 均由 material_3_expressive 组件库构建。
class M3EMailApp extends StatelessWidget {
  const M3EMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return M3EMaterialApp(
      title: 'M3E Mail',
      debugShowCheckedModeBanner: false,
      // 手表默认深色；data 用 dark 工厂，initialTheme 固定为 dark。
      data: M3EThemeData.dark(seedColor: const Color(0xFF00BFA5)),
      initialTheme: Brightness.dark,
      home: InboxPage(store: MailStore()),
    );
  }
}
