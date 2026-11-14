import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'mail/mail_service.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'widgets/watch_layout.dart';

void main() => runApp(const M3EMailApp());

/// M3E Mail — 运行在 Wear OS 手表上的邮件客户端。
///
/// 登录真实邮箱（IMAP/SMTP 直连）后收发邮件；
/// 无账号时可进入明确标注的「演示模式」。
/// 深色主题适配 OLED 圆形表盘。
class M3EMailApp extends StatelessWidget {
  const M3EMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return M3EMaterialApp(
      title: 'M3E Mail',
      debugShowCheckedModeBanner: false,
      data: M3EThemeData.dark(seedColor: const Color(0xFF00BFA5)),
      initialTheme: Brightness.dark,
      home: const _RootPage(),
    );
  }
}

/// 根路由：已保存账号 → 直接进首页；否则进登录页。
class _RootPage extends StatefulWidget {
  const _RootPage();

  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    MailService.instance.tryRestore().then((bool ok) {
      if (mounted) setState(() => _restoring = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const WatchScreen(
        child: Center(child: M3EProgressIndicator.circular()),
      );
    }
    return ListenableBuilder(
      listenable: MailService.instance,
      builder: (BuildContext context, _) {
        return MailService.instance.loggedIn
            ? const HomePage()
            : const LoginPage();
      },
    );
  }
}
