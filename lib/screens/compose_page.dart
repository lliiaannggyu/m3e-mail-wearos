import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../models/email.dart';
import '../widgets/curved_list.dart';
import '../widgets/watch_layout.dart';

/// 写邮件页 —— 圆形表盘布局：
/// 顶部居中标题，表单沿圆弧滚动收放，
/// 底部中央圆形「发送」按钮。
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
    final svc = MailService.instance;
    return WatchScreen(
      child: Column(
        children: <Widget>[
          WatchHeader(
            title: widget.replyTo == null ? '写邮件' : '回复邮件',
            subtitle: svc.isDemo ? '演示模式 · 不会真实发信' : null,
          ),
          Expanded(
            child: CurvedChildScrollView(
              baseHorizontalInset: 18,
              center: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),
          ),
          WatchActionBar(
            actions: <Widget>[
              _sending
                  ? const M3EProgressIndicator.circular(size: 30, strokeWidth: 3)
                  : M3EFab(
                      icon: Icon(M3EIcons.send),
                      tooltip: '发送',
                      size: M3EFabSize.small,
                      onPressed: _send,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
