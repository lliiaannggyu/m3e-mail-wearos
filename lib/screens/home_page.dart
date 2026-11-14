import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../models/email.dart';
import '../update/update_service.dart';
import '../widgets/curved_list.dart';
import '../widgets/watch_layout.dart';
import '../widgets/watch_mail_row.dart';
import 'account_page.dart';
import 'compose_page.dart';
import 'email_detail_page.dart';
import 'search_page.dart';

/// 首页 —— 圆形表盘布局：
/// 顶部窄弦区放「文件夹 + 未读数」与分页圆点；
/// 中部为弧形曲线列表（贴边缩放下沉）；
/// 底部中央一排圆形动作：账户 / 写邮件 / 搜索。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pager = PageController();
  bool _updateChecked = false;
  int _page = 0;

  static const List<String> _folderNames = <String>['收件箱', '星标', '归档'];

  @override
  void initState() {
    super.initState();
    // 静默检查 GitHub 新版本（每次会话一次）。
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    if (_updateChecked) return;
    _updateChecked = true;
    final UpdateState r = await UpdateService.instance.check();
    if (!mounted || r.kind != UpdateStateKind.available) return;
    M3ESnackbar.show(
      context,
      message: '发现新版本 v${r.latestVersion}，可在账户页更新',
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  List<Email> _folder(int index) {
    final svc = MailService.instance;
    switch (index) {
      case 1:
        return svc.starred;
      case 2:
        return svc.archived;
      default:
        return svc.inbox;
    }
  }

  void _openEmail(Email email) {
    if (email.unread) MailService.instance.markRead(email.id);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EmailDetailPage(emailId: email.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final svc = MailService.instance;

    return WatchScreen(
      child: Column(
        children: <Widget>[
          // 顶部窄弦区：文件夹名 + 未读数
          WatchHeader(
            title: svc.isDemo ? '演示模式' : _folderNames[_page],
            subtitle: svc.isDemo
                ? '数据为本地示例'
                : '${svc.unreadCount} 条未读',
          ),
          // 分页圆点（文件夹指示）
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var i = 0; i < _folderNames.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.circle,
                      size: i == _page ? 7 : 5,
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          // 弧形曲线列表（左右滑动切文件夹）
          Expanded(
            child: PageView(
              controller: _pager,
              onPageChanged: (int i) => setState(() => _page = i),
              children: <Widget>[
                for (var i = 0; i < _folderNames.length; i++)
                  CurvedList(
                    itemCount: _folder(i).length,
                    emptyText: svc.isDemo ? '演示列表为空' : '这里没有邮件',
                    itemBuilder: (BuildContext context, int index) {
                      final Email email = _folder(i)[index];
                      return WatchMailRow(
                        email: email,
                        onTap: () => _openEmail(email),
                        onToggleStar: () => setState(
                            () => MailService.instance.toggleStar(email.id)),
                      );
                    },
                  ),
              ],
            ),
          ),
          // 底部中央圆形动作栏：账户 / 写邮件 / 搜索
          WatchActionBar(
            actions: <Widget>[
              M3EIconButton(
                icon: Icon(svc.isDemo ? M3EIcons.science : M3EIcons.person),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.md,
                tooltip: '账户 / 更新',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const AccountPage(),
                )),
              ),
              M3EFab(
                icon: Icon(M3EIcons.edit),
                tooltip: '写邮件',
                size: M3EFabSize.small,
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ComposePage(),
                )),
              ),
              M3EIconButton(
                icon: Icon(M3EIcons.search),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.md,
                tooltip: '搜索',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const SearchPage(),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
