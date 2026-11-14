import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_mailbox.dart';
import '../models/email.dart';
import '../widgets/watch_layout.dart';

/// 写邮件页：支持从详情页一键带入回复上下文。
class ComposePage extends StatefulWidget {
  const ComposePage({super.key, required this.store, this.replyTo});

  final MailStore store;
  final Email? replyTo;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  late final TextEditingController _to = TextEditingController(
      text: widget.replyTo?.senderEmail ?? '');
  late final TextEditingController _subject = TextEditingController(
      text: widget.replyTo == null
          ? ''
          : '回复：${widget.replyTo!.subject}');
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
    if (_to.text.trim().isEmpty) {
      M3ESnackbar.show(context, message: '请先填写收件人');
      return;
    }
    setState(() => _sending = true);
    // 模拟网络发送耗时；接入真实 SMTP/API 后替换此处。
    await Future<void>.delayed(const Duration(milliseconds: 900));
    widget.store.send(
      to: _to.text.trim(),
      subject: _subject.text.trim(),
      body: _body.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    M3ESnackbar.show(context, message: '邮件已发送');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return WatchScreen(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              M3EIconButton(
                icon: Icon(M3EIcons.close),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              Text('写邮件',
                  style: theme.typeScale.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  M3ETextField(
                    controller: _to,
                    label: '收件人',
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
                    placeholder: '用语音或键盘输入…',
                    variant: M3ETextFieldVariant.outlined,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  _sending
                      ? const M3EProgressIndicator.circular()
                      : M3EButton(
                          onPressed: _send,
                          icon: Icon(M3EIcons.send, size: 16),
                          label: const Text('发送'),
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.sm,
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
