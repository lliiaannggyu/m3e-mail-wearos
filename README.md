# M3E Mail — Wear OS 手表邮件客户端

基于 **M3E 组件库**（[material_3_expressive](https://pub.dev/packages/material_3_expressive)，
即 Material 3 Expressive 的 Flutter 实现）构建的 **真实可用的** Wear OS 手表邮件应用：
直接登录你的托管邮箱（IMAP/SMTP），在手表上收发邮件，并针对**圆形表盘**做了完整的布局重构。

## ✨ 功能

- **真实邮箱登录**：内置服务商预设（QQ 邮箱 / 163 / Gmail / Outlook / 自定义 IMAP），
  输入地址 + 授权码即可收信、发信；账号本地存储，下次启动免登录。
- **纯 Dart 实现的 IMAP/SMTP 客户端**（`lib/mail/`）：
  - IMAP 993 端口（TLS）：登录、INBOX 列表（FLAGS/ENVELOPE）、按需拉取正文、标记已读；
    自研词法器完整处理 IMAP 括号嵌套语法与 `{N}` 字面量（中文主题/发件人必须按字节解析）。
  - SMTP 465 端口（TLS）：AUTH LOGIN + UTF-8 编码发信。
- **圆形表盘布局**（v1.2.0 重构，不再是方形手机 UI）：
  - **弧形曲线列表** `CurvedList`：列表项沿圆周排布，越靠近上/下边缘，行宽按**圆的弦长**收窄、
    内容同步缩小并渐隐；视口中心一行最大最宽最亮。几何由 `WatchInsets.chordInset`（r − √(r²−d²)）计算，
    而非一刀切的固定 Padding。
  - **弧形滚动视图** `CurvedChildScrollView`：正文/表单随滚动位置在圆内左右收放。
  - **顶部窄弦区**紧凑居中页头 + **底部中央圆形动作栏**（账户 / 写邮件 / 搜索，星标 / 回复 / 归档），
    全部落在圆内最宽的弦上，符合手表单手拇指操作；
    去掉了手机式的宽行操作栏、左右铺满的标签栏与方形卡片列表。
  - 从左边缘**右滑返回**（Wear OS 手势惯例）、文件夹左右滑动分页 + 圆点指示、全局深色 OLED 主题。
- **应用内更新**（v1.2.0 新增）：
  - 启动时静默检查 GitHub 最新 Release，发现新版本在首页提示；
  - 账户页可手动「检查更新 → 下载并安装」，下载进度用 M3E 圆环展示；
  - 通过 Android `FileProvider` + `REQUEST_INSTALL_PACKAGES` 拉起系统安装器，
    首次需授予「安装未知应用」权限（自动跳转设置页）。
- **演示模式**（明确标注）：无账号时可用本地示例数据体验完整交互，
  界面全程显示「演示数据」标识，绝不冒充真实邮件。

全部 UI 基于 M3E 组件：`M3EMaterialApp` / `M3EFab` / `M3EButton` / `M3EIconButton` /
`M3EBadge` / `M3ECard` / `M3EChip` / `M3ETextField` / `M3ESearchBar` / `M3ESnackbar` /
`M3EProgressIndicator`（含确定值进度环）等；弧形几何组件为本项目自研。

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
├── update/
│   └── update_service.dart    # 应用内更新：GitHub Release 检查 / 下载 / 安装
├── widgets/
│   ├── curved_list.dart       # 弧形曲线列表 / 弧形滚动视图 / 底部圆形动作栏
│   ├── watch_layout.dart      # 圆屏弦长几何 / 右滑返回 / 居中页头 / 头像
│   └── watch_mail_row.dart    # 弧形列表行（大热区 + 圆形星标按钮）
└── screens/
    ├── login_page.dart        # 登录（预设 / 自定义服务器 / 演示入口）
    ├── home_page.dart         # 首页（弧形列表 + 分页圆点 + 底部动作栏）
    ├── email_detail_page.dart # 详情（弧形正文 + 底部动作栏）
    ├── compose_page.dart      # 写邮件 / 回复
    ├── search_page.dart       # 搜索（弧形结果列表）
    └── account_page.dart      # 账户 / 应用内更新 / 退出登录
```

Android 原生侧：`MainActivity.kt` 提供 `m3e_mail/update` 平台通道
（appVersion / cacheDir / canInstall / requestInstallPermission / installApk），
`AndroidManifest.xml` 声明 `android.hardware.type.watch` 与 FileProvider，
`res/xml/file_paths.xml` 暴露 `cache/apk/`。

## 🚀 运行 / 构建

```bash
cd m3e_mail
flutter pub get

# 运行（Wear OS 手表或模拟器）
flutter run

# 按架构分包的 Release（arm64 手表装 app-arm64-v8a-release.apk，约 8MB）
flutter build apk --release --obfuscate \
  --split-debug-info=build/app/outputs/symbols --split-per-abi \
  --target-platform android-arm64,android-arm
```

> 需要本机安装 Flutter ≥ 3.47（material_3_expressive 1.2.x 的要求）；
> 国内构建可参考仓库中的镜像配置（腾讯云 SDK 镜像 + 阿里云 Maven + flutter-io.cn）。
> minSdk = 25（Android 7.1 / Wear OS 2.0+），R8 压缩混淆 + 资源收缩 + Dart 混淆。

## 🔧 接入与扩展

- 数据层接口在 `lib/mail/mail_service.dart` 的 `MailSource` 抽象中，
  想接 Gmail XOAUTH2、Exchange 或自建网关，实现一个新 `MailSource` 即可，UI 零改动。
- IMAP 词法器与 ENVELOPE 解析有单测覆盖（中文主题、字面量、转义引号、地址列表），
  圆屏几何与 400×400 圆屏渲染、版本比较均有单测，见 `test/`。
- 应用内更新仓库/架构写死在 `lib/update/update_service.dart` 顶部常量，
  换仓库或加 armv7 选择逻辑改这里即可。

## ⚠️ 已知边界

- 未实现：MIME 附件解析、HTML 富文本渲染（正文以 text/plain 展示）、
  多文件夹切换（当前 INBOX）、邮件搜索走 IMAP SEARCH（当前本地过滤）。
- 登录凭据以 JSON 明文存于应用私有目录（`shared_preferences`）；
  后续可接入 `flutter_secure_storage` 加密。
- Release 包为 debug 演示签名；正式上架需换正式 keystore。
- 应用内更新下载的是 **arm64 分包**，且依赖系统允许「安装未知来源应用」。
