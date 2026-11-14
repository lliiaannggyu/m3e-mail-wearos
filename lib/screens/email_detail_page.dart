import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../models/email.dart';
import '../widgets/curved_list.dart';
import '../widgets/watch_layout.dart';
import 'compose_page.dart';

/// 邮件详情页 —— 圆形表盘布局：
/// 顶部窄弦区居中放主题；中部弧形滚动正文；
/// 底部中央圆形动作（星标 / 回复 / 归档）。右滑返回。
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
        children: <Widget>[
          // 顶部：主题居中（窄弦区一行）
          WatchHeader(
            title: email.subject,
            subtitle: demo ? '演示数据 · 非真实邮件' : email.sender,
          ),
          // 正文：弧形滚动
          Expanded(
            child: CurvedChildScrollView(
              baseHorizontalInset: 18,
              center: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  MailAvatar(name: email.sender, size: 34),
                  const SizedBox(height: 4),
                  Text(
                    '${email.sender} · ${email.timeLabel}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  M3ECard(
                    variant: M3ECardVariant.filled,
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: body.isEmpty
                          ? SizedBox(
                              height: 44,
                              child: Center(
                                child: _body == null
                                    ? const M3EProgressIndicator.circular(
                                        size: 20, strokeWidth: 2.5)
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
                                fontSize: 13,
                                height: 1.5,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 底部中央动作栏
          WatchActionBar(
            actions: <Widget>[
              M3EIconButton(
                icon: Icon(
                    email.starred ? M3EIcons.star : M3EIcons.star_border),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.md,
                tooltip: email.starred ? '取消星标' : '加星标',
                onPressed: () => setState(
                    () => MailService.instance.toggleStar(email.id)),
              ),
              M3EFab(
                icon: Icon(M3EIcons.reply),
                tooltip: '回复',
                size: M3EFabSize.small,
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ComposePage(replyTo: email),
                )),
              ),
              M3EIconButton(
                icon: Icon(M3EIcons.archive),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.md,
                tooltip: '归档',
                onPressed: () {
                  MailService.instance.archive(email.id);
                  M3ESnackbar.show(context, message: '已归档');
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
