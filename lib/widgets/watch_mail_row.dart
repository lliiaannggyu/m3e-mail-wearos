import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../models/email.dart';
import 'watch_layout.dart';

/// 手表邮件行 —— 为圆形表盘设计：
/// 左侧头像 + 右侧两行文本（发件人 / 主题），
/// 星标作为可点按的圆形热区（≥44px）。
/// 行本身由 CurvedList 负责弧形收放与下沉渐隐。
class WatchMailRow extends StatelessWidget {
  const WatchMailRow({
    super.key,
    required this.email,
    required this.onTap,
    required this.onToggleStar,
  });

  final Email email;
  final VoidCallback onTap;
  final VoidCallback onToggleStar;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: <Widget>[
            MailAvatar(name: email.sender, unread: email.unread, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          email.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: email.unread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        email.timeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 星标：圆形大热区按钮
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleStar,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  email.starred ? M3EIcons.star : M3EIcons.star_border,
                  size: 18,
                  color: email.starred
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
