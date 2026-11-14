import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../models/email.dart';
import '../widgets/watch_layout.dart';
import 'compose_page.dart';

/// 邮件详情页：按需从服务器拉取正文，右滑返回。
class EmailDetailPage extends StatefulWidget {
  const EmailDetailPage({super.key, required this.emailId});

  final String emailId;

  @override
  State<EmailDetailPage> createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> {
  String? _body;

  @override
  void initState() {
    super.initState();
    _loadBody();
  }

  Future<void> _loadBody() async {
    final email = MailService.instance.byId(widget.emailId);
    if (email == null) return;
    final text = await MailService.instance.loadBody(email);
    if (mounted) setState(() => _body = text);
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final Email? email = MailService.instance.byId(widget.emailId);
    if (email == null) {
      return const WatchScreen(child: Center(child: Text('邮件不存在')));
    }
    final bool demo = MailService.instance.isDemo;
    final String body = _body ?? email.body;

    return WatchScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 操作行：返回 / 星标 / 归档 / 删除
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
              M3EIconButton(
                icon: Icon(
                    email.starred ? M3EIcons.star : M3EIcons.star_border),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '星标',
                onPressed: () => setState(
                    () => MailService.instance.toggleStar(email.id)),
              ),
              M3EIconButton(
                icon: Icon(M3EIcons.archive),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '归档',
                onPressed: () {
                  MailService.instance.archive(email.id);
                  M3ESnackbar.show(context, message: '已归档');
                  Navigator.of(context).maybePop();
                },
              ),
              M3EIconButton(
                icon: Icon(M3EIcons.delete),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '从列表移除',
                onPressed: () {
                  MailService.instance.archive(email.id);
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (demo)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '演示数据（本机示例，非真实邮件）',
                style: TextStyle(
                    fontSize: 11, color: theme.colorScheme.tertiary),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(email.subject, style: theme.typeScale.titleMedium),
                  const SizedBox(height: 10),
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
                  M3ECard(
                    variant: M3ECardVariant.filled,
                    padding: const EdgeInsets.all(12),
                    child: body.isEmpty
                        ? SizedBox(
                            height: 48,
                            child: Center(
                              child: _body == null
                                  ? const M3EProgressIndicator.circular()
                                  : Text('（无正文或正文为空）',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.onSurfaceVariant)),
                            ),
                          )
                        : Text(
                            body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: M3EButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ComposePage(replyTo: email),
                      )),
                      icon: Icon(M3EIcons.reply, size: 16),
                      label: const Text('回复'),
                      style: M3EButtonStyle.filled,
                      size: M3EButtonSize.md,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
