import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../models/email.dart';
import '../widgets/watch_layout.dart';

/// 写邮件页：真实 SMTP 发送（演示模式仅本地模拟），右滑返回。
class ComposePage extends StatefulWidget {
  const ComposePage({super.key, this.replyTo});

  final Email? replyTo;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  late final TextEditingController _to =
      TextEditingController(text: widget.replyTo?.senderEmail ?? '');
  late final TextEditingController _subject = TextEditingController(
      text: widget.replyTo == null ? '' : '回复：${widget.replyTo!.subject}');
  final TextEditingController _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final to = _to.text.trim();
    if (to.isEmpty || !to.contains('@')) {
      M3ESnackbar.show(context, message: '请填写有效的收件人邮箱');
      return;
    }
    setState(() => _sending = true);
    String? err;
    try {
      await MailService.instance.sendMail(
        to: to,
        subject: _subject.text.trim(),
        body: _body.text.trim(),
      );
    } catch (e) {
      err = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      M3ESnackbar.show(context, message: '发送失败：$err',
          duration: const Duration(seconds: 6));
      return;
    }
    M3ESnackbar.show(context, message: '邮件已发送');
    Navigator.of(context).pop();
  }

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
                icon: Icon(M3EIcons.close),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '关闭（也可右滑）',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              Text(svc.isDemo ? '写邮件（演示）' : '写邮件',
                  style: theme.typeScale.titleSmall),
            ],
          ),
          if (svc.isDemo)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('演示模式不会真实发信',
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.tertiary)),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  M3ETextField(
                    controller: _to,
                    label: '收件人',
                    placeholder: '收件人@example.com',
                    variant: M3ETextFieldVariant.outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  M3ETextField(
                    controller: _subject,
                    label: '主题',
                    variant: M3ETextFieldVariant.outlined,
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  M3ETextField(
                    controller: _body,
                    label: '正文',
                    placeholder: '语音或键盘输入…',
                    variant: M3ETextFieldVariant.outlined,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 14),
                  _sending
                      ? const M3EProgressIndicator.circular()
                      : M3EButton(
                          onPressed: _send,
                          icon: Icon(M3EIcons.send, size: 16),
                          label: const Text('发送'),
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.md,
                        ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
