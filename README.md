# M3E Mail — Wear OS 手表邮件客户端

基于 **M3E 组件库**（[material_3_expressive](https://pub.dev/packages/material_3_expressive)，
即 Material 3 Expressive 的 Flutter 实现）构建的 **真实可用的** Wear OS 手表邮件应用：
直接登录你的托管邮箱（IMAP/SMTP），在手表上收发邮件。

## ✨ 功能

- **真实邮箱登录**：内置服务商预设（QQ 邮箱 / 163 / Gmail / Outlook / 自定义 IMAP），
  输入地址 + 授权码即可收信、发信；账号本地加密存储，下次启动免登录。
- **纯 Dart 实现的 IMAP/SMTP 客户端**（`lib/mail/`）：
  - IMAP 993 端口（TLS）：登录、INBOX 列表（FLAGS/ENVELOPE）、按需拉取正文、标记已读；
    自研词法器完整处理 IMAP 括号嵌套语法与 `{N}` 字面量（中文主题/发件人必须按字节解析）。
  - SMTP 465 端口（TLS）：AUTH LOGIN + UTF-8 编码发信。
- **手表优先交互**（v1.1 重做）：
  - 从左边缘**右滑返回**（Wear OS 手势惯例），所有二级页面生效；
  - 文件夹用**左右滑动分页**（收件箱/星标/归档）+ 圆点指示器，不再用手机式标签栏；
  - 列表行大热区、正文 14sp/1.5 行高适配圆屏；
  - 圆形表盘安全边距（`WatchInsets` 自动识别圆屏）；
  - 全局深色主题（OLED 省电）。
- **演示模式**（明确标注）：无账号条件时可用本地示例数据体验完整交互，
  界面全程显示「演示数据」标识，绝不冒充真实邮件。
- 星标 / 归档为本地覆盖层，随账号会话保持。

全部 UI 由 M3E 组件构成：`M3EMaterialApp` / `M3EListItem` / `M3EBadge` /
`M3EFab` / `M3EButton` / `M3EIconButton` / `M3ECard` / `M3EChip` /
`M3ETextField` / `M3ESearchBar` / `M3ESnackbar` / `M3EProgressIndicator` 等。

## 📮 授权码获取（登录真实邮箱必读）

| 服务商 | IMAP | SMTP | 授权码 |
| --- | --- | --- | --- |
| QQ 邮箱 | imap.qq.com:993 | smtp.qq.com:465 | 设置 → 账号 → 开启 IMAP → 生成授权码 |
| 163 邮箱 | imap.163.com:993 | smtp.163.com:465 | 设置 → POP3/IMAP/SMTP → 开启并设置授权码 |
| Gmail | imap.gmail.com:993 | smtp.gmail.com:465 | 需两步验证 + 应用专用密码 |
| Outlook | outlook.office365.com:993 | smtp.office365.com:465 | 账号密码或应用密码 |

## 🗂 目录结构

```
lib/
├── main.dart                  # 入口：账号恢复 → 首页 / 登录页
├── models/email.dart          # 邮件数据模型
├── mail/
│   ├── imap_client.dart       # 最小 IMAP4rev1 客户端（TLS，含词法器与 ENVELOPE 解析）
│   ├── smtp_client.dart       # 最小 SMTP 客户端（TLS，AUTH LOGIN）
│   └── mail_service.dart      # 服务商预设 + 状态中枢 + 演示数据源
├── widgets/
│   ├── watch_layout.dart      # 圆表盘安全边距 / 右滑返回 / 头像
│   └── watch_mail_row.dart    # 手表邮件列表行（大热区 + 滑动操作）
└── screens/
    ├── login_page.dart        # 登录（服务商预设 / 自定义服务器 / 演示入口）
    ├── home_page.dart         # 首页（文件夹滑动分页 + 圆点指示）
    ├── email_detail_page.dart # 详情（正文按需拉取）
    ├── compose_page.dart      # 写邮件 / 回复
    ├── search_page.dart       # 搜索
    └── account_page.dart      # 账户 / 退出登录
```

## 🚀 运行 / 构建

```bash
cd m3e_mail
flutter pub get

# 运行（Wear OS 手表或模拟器）
flutter run

# 按架构分包的 Release（arm64 手表装 app-arm64-v8a-release.apk，约 7.7MB）
flutter build apk --release --obfuscate \
  --split-debug-info=build/app/outputs/symbols --split-per-abi
```

> 需要本机安装 Flutter ≥ 3.47（material_3_expressive 1.2.x 的要求）；
> 国内构建可参考仓库中的镜像配置（腾讯云 SDK 镜像 + 阿里云 Maven + flutter-io.cn）。

## 🔧 接入与扩展

- 数据层接口在 `lib/mail/mail_service.dart` 的 `MailSource` 抽象中，
  想接 Gmail XOAUTH2、Exchange 或自建网关，实现一个新 `MailSource` 即可，UI 零改动。
- IMAP 词法器与 ENVELOPE 解析有单测覆盖（中文主题、字面量、转义引号、地址列表），
  见 `test/widget_test.dart`。
- 星标/归档目前是本地覆盖层；如需同步到服务器，可在 `ImapMailSource` 中
  调 `STORE +FLAGS`（已读）同样方式扩展。

## ⚠️ 已知边界

- 未实现：MIME 附件解析、HTML 富文本渲染（正文以 text/plain 展示）、
  多文件夹切换（当前 INBOX）、邮件搜索走 IMAP SEARCH（当前本地过滤）。
- 登录凭据以 JSON 明文存于应用私有目录（`shared_preferences`）；
  后续可接入 `flutter_secure_storage` 加密。
