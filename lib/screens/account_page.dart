import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../update/update_service.dart';
import '../widgets/curved_list.dart';
import '../widgets/watch_layout.dart';
import 'login_page.dart';

/// 账户页 —— 圆形表盘布局：
/// 中央头像与账号信息，下方更新区（检查/下载/安装），
/// 底部退出登录。所有内容沿圆弧收放。
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final UpdateService _updater = UpdateService.instance;

  Future<void> _check() async => await _updater.check();

  Future<void> _downloadAndInstall() async {
    await _updater.download();
    if (!mounted) return;
    final UpdateState s = _updater.state.value;
    if (s.kind != UpdateStateKind.ready) return;
    // Android 8+ 需要「安装未知应用」权限
    if (!await _updater.ensureInstallPermission()) {
      await _updater.requestInstallPermission();
      if (!mounted) return;
      M3ESnackbar.show(context,
          message: '请在系统设置中允许本应用安装，然后重试安装更新');
      return;
    }
    try {
      await _updater.install(s.apkPath!);
    } catch (_) {
      if (mounted) {
        M3ESnackbar.show(context, message: '安装失败，请重新下载');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final svc = MailService.instance;

    return WatchScreen(
      child: ValueListenableBuilder<UpdateState>(
        valueListenable: _updater.state,
        builder: (BuildContext context, UpdateState us, _) {
          return Column(
            children: <Widget>[
              WatchHeader(title: '账户'),
              Expanded(
                child: CurvedChildScrollView(
                  baseHorizontalInset: 20,
                  center: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      MailAvatar(
                        name: svc.isDemo ? '演' : svc.accountEmail,
                        size: 52,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        svc.isDemo ? '演示模式' : svc.accountEmail,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typeScale.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        svc.isDemo ? '本地示例数据' : 'IMAP / SMTP 直连 · TLS',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _UpdateCard(state: us, onCheck: _check, onInstall: _downloadAndInstall),
                    ],
                  ),
                ),
              ),
              WatchActionBar(
                actions: <Widget>[
                  M3EButton(
                    onPressed: () async {
                      await MailService.instance.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                            builder: (_) => const LoginPage()),
                        (Route<dynamic> r) => false,
                      );
                    },
                    icon: Icon(M3EIcons.logout, size: 16),
                    label: const Text('退出登录'),
                    style: M3EButtonStyle.outlined,
                    size: M3EButtonSize.sm,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 更新卡片：当前版本 + 检查/下载/安装状态流转。
class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.state,
    required this.onCheck,
    required this.onInstall,
  });

  final UpdateState state;
  final VoidCallback onCheck;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final String current = UpdateService.instance.currentVersion ?? '?';

    final Widget body;
    switch (state.kind) {
      case UpdateStateKind.checking:
        body = const Column(children: <Widget>[
          SizedBox(
              height: 22,
              width: 22,
              child: M3EProgressIndicator.circular(size: 22, strokeWidth: 2.5)),
          SizedBox(height: 4),
          Text('正在检查更新…', style: TextStyle(fontSize: 11)),
        ]);
        break;
      case UpdateStateKind.downloading:
        body = Column(children: <Widget>[
          M3EProgressIndicator.circular(
            value: state.progress,
            size: 30,
            strokeWidth: 3,
          ),
          const SizedBox(height: 4),
          Text('下载中 ${(state.progress * 100).round()}%',
              style: const TextStyle(fontSize: 11)),
        ]);
        break;
      case UpdateStateKind.available:
        body = Column(children: <Widget>[
          Text('新版本 v${state.latestVersion}',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600)),
          Text(
            state.latestSize > 0
                ? '${(state.latestSize / 1048576).toStringAsFixed(1)}MB · 当前 v$current'
                : '当前 v$current',
            style: TextStyle(
                fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          M3EButton(
            onPressed: onInstall,
            icon: Icon(M3EIcons.download, size: 15),
            label: const Text('下载并安装'),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
          ),
        ]);
        break;
      case UpdateStateKind.ready:
        body = Column(children: <Widget>[
          Icon(M3EIcons.download_done,
              size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          M3EButton(
            onPressed: onInstall,
            icon: Icon(M3EIcons.install_mobile, size: 15),
            label: const Text('安装更新'),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
          ),
        ]);
        break;
      case UpdateStateKind.error:
        body = Column(children: <Widget>[
          Text('检查失败',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.error)),
          const SizedBox(height: 6),
          M3EButton(
            onPressed: onCheck,
            icon: Icon(M3EIcons.refresh, size: 15),
            label: const Text('重试'),
            style: M3EButtonStyle.outlined,
            size: M3EButtonSize.sm,
          ),
        ]);
        break;
      case UpdateStateKind.upToDate:
        body = Text('已是最新版本 v$current',
            style: TextStyle(
                fontSize: 11, color: theme.colorScheme.onSurfaceVariant));
        break;
      case UpdateStateKind.idle:
        body = M3EButton(
          onPressed: onCheck,
          icon: Icon(M3EIcons.refresh, size: 15),
          label: const Text('检查更新'),
          style: M3EButtonStyle.outlined,
          size: M3EButtonSize.sm,
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('版本 v$current',
            style: TextStyle(
                fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        body,
      ],
    );
  }
}
