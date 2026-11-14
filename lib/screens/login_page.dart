import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../widgets/curved_list.dart';
import '../widgets/watch_layout.dart';

/// 登录页 —— 圆形表盘布局：
/// 标题居中在顶部窄弦区，表单沿圆弧滚动收放，
/// 服务商以居中换行的圆形芯片呈现。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _imapHost = TextEditingController();
  final TextEditingController _smtpHost = TextEditingController();
  int _presetIndex = 0;

  MailProviderPreset get _preset => MailProviderPreset.all[_presetIndex];

  @override
  void initState() {
    super.initState();
    _email.addListener(_autoPickPreset);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _imapHost.dispose();
    _smtpHost.dispose();
    super.dispose();
  }

  void _autoPickPreset() {
    final domain = _email.text.split('@').last.trim();
    if (domain.isEmpty) return;
    const byDomain = <String, int>{
      'qq.com': 0,
      'foxmail.com': 0,
      '163.com': 1,
      '126.com': 1,
      'gmail.com': 2,
      'outlook.com': 3,
      'hotmail.com': 3,
    };
    final idx = byDomain[domain.toLowerCase()];
    if (idx != null && idx != _presetIndex) {
      setState(() => _presetIndex = idx);
    }
  }

  Future<void> _connect() async {
    final preset = _preset;
    final imapHost =
        preset.imapHost.isEmpty ? _imapHost.text.trim() : preset.imapHost;
    final smtpHost =
        preset.smtpHost.isEmpty ? _smtpHost.text.trim() : preset.smtpHost;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      M3ESnackbar.show(context, message: '请填写邮箱地址和密码/授权码');
      return;
    }
    if (imapHost.isEmpty || smtpHost.isEmpty) {
      M3ESnackbar.show(context, message: '请填写 IMAP/SMTP 服务器地址');
      return;
    }
    await MailService.instance.login(
      email: _email.text.trim(),
      password: _password.text,
      imapHost: imapHost,
      imapPort: preset.imapPort,
      smtpHost: smtpHost,
      smtpPort: preset.smtpPort,
    );
    final err = MailService.instance.error;
    if (!mounted) return;
    if (err != null) {
      M3ESnackbar.show(context,
          message: err, duration: const Duration(seconds: 6));
    } else {
      M3ESnackbar.show(context, message: '已连接 ${_email.text.trim()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final svc = MailService.instance;

    return WatchScreen(
      enableSwipeBack: false, // 登录页是根页，右滑无效
      child: Column(
        children: <Widget>[
          const WatchHeader(title: 'M3E Mail', subtitle: '登录你的真实邮箱'),
          Expanded(
            child: CurvedChildScrollView(
              baseHorizontalInset: 20,
              center: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // 服务商选择：居中换行的芯片组
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      for (var i = 0; i < MailProviderPreset.all.length; i++)
                        M3EChip(
                          label: MailProviderPreset.all[i].name,
                          selected: i == _presetIndex,
                          onPressed: () => setState(() => _presetIndex = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  M3ETextField(
                    controller: _email,
                    label: '邮箱地址',
                    placeholder: 'you@example.com',
                    variant: M3ETextFieldVariant.outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  M3ETextField(
                    controller: _password,
                    label: _presetIndex <= 1 ? '授权码' : '密码 / 应用专用密码',
                    variant: M3ETextFieldVariant.outlined,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    maxLines: 1,
                  ),
                  // 自定义服务器：展开高级设置
                  if (_preset.imapHost.isEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    M3ETextField(
                      controller: _imapHost,
                      label: 'IMAP 服务器',
                      placeholder: 'imap.example.com',
                      variant: M3ETextFieldVariant.outlined,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    M3ETextField(
                      controller: _smtpHost,
                      label: 'SMTP 服务器',
                      placeholder: 'smtp.example.com',
                      variant: M3ETextFieldVariant.outlined,
                      maxLines: 1,
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (svc.loading)
                    const M3EProgressIndicator.circular(
                        size: 26, strokeWidth: 3)
                  else
                    M3EButton(
                      onPressed: _connect,
                      icon: Icon(M3EIcons.login, size: 16),
                      label: const Text('登录邮箱'),
                      style: M3EButtonStyle.filled,
                      size: M3EButtonSize.md,
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'QQ/163 需在邮箱网页端开启 IMAP 并使用授权码',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  M3EButton(
                    onPressed: () async {
                      await MailService.instance.enterDemoMode();
                    },
                    label: const Text('先看演示模式'),
                    style: M3EButtonStyle.text,
                    size: M3EButtonSize.sm,
                  ),
                  if (svc.error != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      svc.error!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
