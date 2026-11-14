import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../models/email.dart';
import '../widgets/watch_layout.dart';
import '../widgets/watch_mail_row.dart';
import 'account_page.dart';
import 'compose_page.dart';
import 'email_detail_page.dart';
import 'search_page.dart';

/// 首页：左右滑动切换文件夹（收件箱 / 星标 / 归档），
/// 圆点指示器 + 紧凑头部，符合手表单手滑动交互。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pager = PageController();
  int _page = 0;

  static const List<String> _folderNames = <String>['收件箱', '星标', '归档'];

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
      fab: M3EFab(
        icon: Icon(M3EIcons.edit),
        tooltip: '写邮件',
        size: M3EFabSize.small,
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ComposePage(),
        )),
      ),
      child: Column(
        children: <Widget>[
          // 头部：账号（点按进账户页）+ 未读数 + 搜索
          Row(
            children: <Widget>[
              M3EIconButton(
                icon: Icon(svc.isDemo ? M3EIcons.science : M3EIcons.person),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '账户',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const AccountPage(),
                )),
              ),
              Expanded(
                child: Text(
                  svc.isDemo ? '演示模式' : '${_folderNames[_page]} · ${svc.unreadCount} 未读',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typeScale.titleSmall
                      .copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
              M3EIconButton(
                icon: Icon(M3EIcons.search),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '搜索',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const SearchPage(),
                )),
              ),
            ],
          ),
          // 圆点分页指示器
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pager,
              onPageChanged: (int i) => setState(() => _page = i),
              children: <Widget>[
                for (var i = 0; i < _folderNames.length; i++)
                  _FolderList(
                    emails: _folder(i),
                    folderName: _folderNames[i],
                    isDemo: svc.isDemo,
                    onOpen: _openEmail,
                    onToggleStar: (String id) =>
                        MailService.instance.toggleStar(id),
                    onArchive: (String id) {
                      MailService.instance.archive(id);
                      M3ESnackbar.show(context, message: '已归档');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个文件夹的邮件列表页（嵌入 PageView）。
class _FolderList extends StatelessWidget {
  const _FolderList({
    required this.emails,
    required this.folderName,
    required this.isDemo,
    required this.onOpen,
    required this.onToggleStar,
    required this.onArchive,
  });

  final List<Email> emails;
  final String folderName;
  final bool isDemo;
  final ValueChanged<Email> onOpen;
  final ValueChanged<String> onToggleStar;
  final ValueChanged<String> onArchive;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    if (emails.isEmpty) {
      return Center(
        child: Text(
          isDemo ? '演示列表为空' : '这里没有邮件',
          style: TextStyle(
              fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      itemCount: emails.length,
      itemBuilder: (BuildContext context, int index) {
        final Email email = emails[index];
        return WatchMailRow(
          email: email,
          onTap: () => onOpen(email),
          onToggleStar: () => onToggleStar(email.id),
          onArchive: () => onArchive(email.id),
        );
      },
    );
  }
}
