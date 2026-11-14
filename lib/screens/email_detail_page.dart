import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_mailbox.dart';
import '../models/email.dart';
import '../widgets/watch_layout.dart';
import 'compose_page.dart';

/// 邮件详情页：正文 + 回复/归档/删除操作。
class EmailDetailPage extends StatefulWidget {
  const EmailDetailPage({
    super.key,
    required this.store,
    required this.emailId,
  });

  final MailStore store;
  final String emailId;

  @override
  State<EmailDetailPage> createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> {
  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final Email email = widget.store.byId(widget.emailId);

    return WatchScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 返回 + 收藏 + 归档 + 删除
          Row(
            children: <Widget>[
              M3EIconButton(
                icon: Icon(M3EIcons.arrow_back),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '返回',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              M3EIconButton(
                icon: Icon(email.starred
                    ? M3EIcons.star
                    : M3EIcons.star_border),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: email.starred ? '取消星标' : '加星标',
                onPressed: () =>
                    setState(() => widget.store.toggleStar(email.id)),
              ),
              M3EIconButton(
                icon: Icon(M3EIcons.archive),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '归档',
                onPressed: () {
                  widget.store.archive(email.id);
                  M3ESnackbar.show(context, message: '已归档');
                  Navigator.of(context).maybePop();
                },
              ),
              M3EIconButton(
                icon: Icon(M3EIcons.delete),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '删除',
                onPressed: () {
                  widget.store.delete(email.id);
                  M3ESnackbar.show(context, message: '已删除');
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 主题
                  Text(
                    email.subject,
                    style: theme.typeScale.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  // 发件人信息
                  Row(
                    children: <Widget>[
                      MailAvatar(name: email.sender, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(email.sender,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.typeScale.labelLarge),
                            Text(email.senderEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text(email.timeLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 正文卡片
                  M3ECard(
                    variant: M3ECardVariant.filled,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          email.body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (email.hasAttachment) ...<Widget>[
                          const SizedBox(height: 10),
                          M3EChip(
                            label: '报销明细.pdf',
                            type: M3EChipType.assist,
                            leading: Icon(M3EIcons.attach_file, size: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 回复按钮
                  Center(
                    child: M3EButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ComposePage(
                          store: widget.store,
                          replyTo: email,
                        ),
                      )),
                      icon: Icon(M3EIcons.reply, size: 16),
                      label: const Text('回复'),
                      style: M3EButtonStyle.filled,
                      size: M3EButtonSize.sm,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
