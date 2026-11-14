import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../widgets/watch_layout.dart';

/// 登录页（手表优先交互）：
/// - 服务商横向分页选择（圆表盘友好）
/// - 大号输入框 + 大热区连接按钮
/// - 底部明确提供「演示模式」入口，进入后界面全程标注演示数据
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
      M3ESnackbar.show(context, message: err, duration: const Duration(seconds: 6));
    } else {
      M3ESnackbar.show(context, message: '已连接 ${_accountOf(_email.text)}');
    }
  }

  String _accountOf(String email) => email.contains('@') ? email : email;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final svc = MailService.instance;

    return WatchScreen(
      child: ListenableBuilder(
        listenable: svc,
        builder: (BuildContext context, _) {
          return Column(
            children: <Widget>[
              // 标题
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text('M3E Mail 登录',
                    style: theme.typeScale.titleMedium),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // 服务商选择（横向滑动，圆屏友好）
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: MailProviderPreset.all.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (BuildContext context, int i) {
                            final selected = i == _presetIndex;
                            return M3EChip(
                              label: MailProviderPreset.all[i].name,
                              selected: selected,
                              onPressed: () => setState(() => _presetIndex = i),
                            );
                          },
                        ),
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
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: M3ETextField(
                                controller: _imapHost,
                                label: 'IMAP 服务器',
                                placeholder: 'imap.example.com',
                                variant: M3ETextFieldVariant.outlined,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: M3ETextField(
                                controller: _smtpHost,
                                label: 'SMTP 服务器',
                                placeholder: 'smtp.example.com',
                                variant: M3ETextFieldVariant.outlined,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (svc.loading)
                        const M3EProgressIndicator.circular()
                      else
                        M3EButton(
                          onPressed: _connect,
                          icon: Icon(M3EIcons.login, size: 16),
                          label: const Text('登录邮箱'),
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.md,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'QQ/163 需在邮箱网页端开启 IMAP 并使用授权码登录',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      M3EButton(
                        onPressed: () async {
                          await MailService.instance.enterDemoMode();
                        },
                        label: const Text('不用了，先看演示模式'),
                        style: M3EButtonStyle.text,
                        size: M3EButtonSize.sm,
                      ),
                      if (svc.error != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          svc.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
