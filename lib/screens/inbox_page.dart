import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_mailbox.dart';
import '../models/email.dart';
import '../widgets/watch_layout.dart';
import 'compose_page.dart';
import 'email_detail_page.dart';
import 'search_page.dart';

/// 收件箱页：文件夹切换 + 邮件列表 + 下拉刷新 + 写邮件入口。
class InboxPage extends StatefulWidget {
  const InboxPage({super.key, required this.store});

  final MailStore store;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  int _folderIndex = 0;

  static const List<Folder> _folders = <Folder>[
    Folder.inbox,
    Folder.starred,
    Folder.archive,
  ];

  List<Email> get _emails =>
      widget.store.folder(_folders[_folderIndex]);

  int get _unreadCount => widget.store
      .folder(Folder.inbox)
      .where((Email e) => e.unread)
      .length;

  void _openEmail(Email email) {
    if (email.unread) {
      widget.store.markRead(email.id);
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EmailDetailPage(store: widget.store, emailId: email.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);

    return WatchScreen(
      fab: M3EFab(
        icon: Icon(M3EIcons.edit),
        tooltip: '写邮件',
        size: M3EFabSize.small,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ComposePage(store: widget.store),
        )),
      ),
      child: Column(
        children: <Widget>[
          // 顶部：应用名 + 未读数 + 搜索
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _unreadCount > 0 ? '收件箱 · $_unreadCount 未读' : '收件箱',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typeScale.titleMedium
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
                    builder: (_) => SearchPage(store: widget.store),
                  )),
                ),
              ],
            ),
          ),
          // 文件夹切换
          M3ETabs(
            tabs: const <M3ETab>[
              M3ETab(label: '收件箱'),
              M3ETab(label: '星标'),
              M3ETab(label: '归档'),
            ],
            selectedIndex: _folderIndex,
            variant: M3ETabsVariant.secondary,
            onTabSelected: (int i) => setState(() => _folderIndex = i),
          ),
          const SizedBox(height: 4),
          // 邮件列表
          Expanded(
            child: M3ERefreshIndicator(
              onRefresh: widget.store.refresh,
              child: _emails.isEmpty
                  ? _EmptyFolder(folder: _folders[_folderIndex])
                  : ListView.builder(
                      itemCount: _emails.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Email email = _emails[index];
                        return _EmailRow(
                          email: email,
                          onTap: () => _openEmail(email),
                          onArchive: () {
                            widget.store.archive(email.id);
                            M3ESnackbar.show(context,
                                message: '已归档「${email.subject}」');
                          },
                          onToggleStar: () =>
                              widget.store.toggleStar(email.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单行邮件：左滑显示归档/星标操作。
class _EmailRow extends StatelessWidget {
  const _EmailRow({
    required this.email,
    required this.onTap,
    required this.onArchive,
    required this.onToggleStar,
  });

  final Email email;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onToggleStar;

  @override
  Widget build(BuildContext context) {
    return M3EListItem(
      headline: email.sender,
      supportingText: email.subject,
      trailingText: email.timeLabel,
      leading: MailAvatar(name: email.sender, unread: email.unread),
      trailing: Icon(
        email.starred ? M3EIcons.star : M3EIcons.star_border,
        size: 16,
        color: email.starred
            ? M3ETheme.of(context).colorScheme.primary
            : M3ETheme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      swipe: M3EListItemSwipe(
        mode: M3EListSwipeMode.reveal,
        trailing: <M3EListSwipeAction>[
          M3EListSwipeAction(
            icon: Icon(M3EIcons.star),
            backgroundColor:
                M3ETheme.of(context).colorScheme.tertiaryContainer,
            onPressed: onToggleStar,
          ),
          M3EListSwipeAction(
            icon: Icon(M3EIcons.archive),
            backgroundColor: M3ETheme.of(context).colorScheme.primary,
            onPressed: onArchive,
          ),
        ],
      ),
    );
  }
}

/// 空文件夹占位。
class _EmptyFolder extends StatelessWidget {
  const _EmptyFolder({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final (IconData, String) info = switch (folder) {
      Folder.starred => (M3EIcons.star_border, '还没有星标邮件'),
      Folder.archive => (M3EIcons.inventory_2, '归档是空的'),
      _ => (M3EIcons.inbox, '收件箱已清空，好样的！'),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(info.$1, size: 32, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(info.$2,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}
