import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../widgets/watch_layout.dart';
import 'login_page.dart';

/// 账户页：查看当前账号 / 退出登录（退出后回到登录页）。
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final svc = MailService.instance;

    return WatchScreen(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              M3EIconButton(
                icon: Icon(M3EIcons.arrow_back),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '返回（也可右滑）',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              Text('账户', style: theme.typeScale.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          MailAvatar(
            name: svc.isDemo ? '演' : svc.accountEmail,
            size: 56,
          ),
          const SizedBox(height: 10),
          Text(
            svc.isDemo ? '演示模式（本地示例数据）' : svc.accountEmail,
            style: theme.typeScale.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            svc.isDemo
                ? '收发均为模拟行为'
                : 'IMAP / SMTP 直连 · 端到端 TLS',
            style: TextStyle(
                fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          M3EButton(
            onPressed: () async {
              await MailService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                (Route<dynamic> r) => false,
              );
            },
            icon: Icon(M3EIcons.logout, size: 16),
            label: const Text('退出登录'),
            style: M3EButtonStyle.outlined,
            size: M3EButtonSize.md,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
