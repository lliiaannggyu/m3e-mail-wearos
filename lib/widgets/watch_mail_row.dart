import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../models/email.dart';
import 'watch_layout.dart';

/// 手表邮件列表行：圆屏安全宽内边距 + 大热区（≥ 56dp 高）+
/// 左滑露出星标/归档两个大目标操作。
class WatchMailRow extends StatelessWidget {
  const WatchMailRow({
    super.key,
    required this.email,
    required this.onTap,
    required this.onToggleStar,
    required this.onArchive,
  });

  final Email email;
  final VoidCallback onTap;
  final VoidCallback onToggleStar;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);

    return M3EListItem(
      headline: email.sender,
      supportingText: email.subject,
      trailingText: email.timeLabel,
      leading: MailAvatar(name: email.sender, unread: email.unread, size: 32),
      trailing: Icon(
        email.starred ? M3EIcons.star : M3EIcons.star_border,
        size: 16,
        color: email.starred
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      swipe: M3EListItemSwipe(
        mode: M3EListSwipeMode.reveal,
        trailing: <M3EListSwipeAction>[
          M3EListSwipeAction(
            icon: Icon(M3EIcons.star),
            backgroundColor: theme.colorScheme.tertiaryContainer,
            onPressed: onToggleStar,
          ),
          M3EListSwipeAction(
            icon: Icon(M3EIcons.archive),
            backgroundColor: theme.colorScheme.primary,
            onPressed: onArchive,
          ),
        ],
      ),
    );
  }
}
