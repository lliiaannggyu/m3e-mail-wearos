# M3E Mail — Wear OS 手表邮件客户端

基于 **M3E 组件库**（[material_3_expressive](https://pub.dev/packages/material_3_expressive)，
即 Material 3 Expressive 的 Flutter 实现）构建的 Wear OS 手表邮件应用。

全部 UI 由 M3E 组件构成：`M3EMaterialApp` / `M3ETabs` / `M3EListItem` /
`M3EBadge` / `M3ERefreshIndicator` / `M3EFab` / `M3EButton` / `M3EIconButton` /
`M3ECard` / `M3EChip` / `M3ETextField` / `M3ESearchBar` / `M3ESnackbar` /
`M3EProgressIndicator` 等，并启用 M3E 的深色主题（OLED 表盘省电）。

## 功能

| 页面 | 说明 | 用到的 M3E 组件 |
| --- | --- | --- |
| 收件箱 | 收件箱 / 星标 / 归档三个文件夹切换，下拉刷新，未读徽标，列表左滑归档/加星 | `M3ETabs`、`M3EListItem`、`M3EBadge`、`M3ERefreshIndicator`、`M3EFab`、`M3ESnackbar` |
| 邮件详情 | 正文卡片展示、附件展示、回复 / 加星 / 归档 / 删除 | `M3ECard`、`M3EButton`、`M3EIconButton`、`M3EChip`、`M3ESnackbar` |
| 写邮件 | 收件人 / 主题 / 正文，回复自动带入上下文，发送进度指示 | `M3ETextField`、`M3EButton`、`M3EProgressIndicator.circular` |
| 搜索 | 按发件人 / 主题 / 正文实时过滤 | `M3ESearchBar` |

**手表适配**：

- 圆形表盘安全边距（`WatchInsets`）：自动识别圆屏并给四周加大内边距，
  避免内容被圆形边缘裁切。
- 深色优先：全局 `M3EThemeData.dark`，适合 OLED 表盘。
- 大热区组件 + 简化的单列导航（左右滑动 / 上下滚动），无复杂导航栏。

## 目录结构

```
lib/
├── main.dart                  # 应用入口，M3EMaterialApp + 深色主题
├── models/email.dart          # 邮件数据模型
├── data/mock_mailbox.dart     # 模拟邮箱数据仓库（真实接入时替换此处）
├── widgets/watch_layout.dart  # 圆表盘安全边距、统一页面容器、头像组件
└── screens/
    ├── inbox_page.dart        # 收件箱
    ├── email_detail_page.dart # 邮件详情
    ├── compose_page.dart      # 写邮件
    └── search_page.dart       # 搜索
```

## 运行 / 构建

```bash
cd m3e_mail
flutter pub get

# 直接运行（连接 Wear OS 设备或手表模拟器）
flutter devices
flutter run

# 打 Release APK（Wear OS 手表可直接安装）
flutter build apk --release
```

> 需要本机安装 Flutter ≥ 3.47（material_3_expressive 1.2.x 的要求）。

## 接入真实邮箱

`lib/data/mock_mailbox.dart` 中的 `MailStore` 是唯一的数据来源（模拟数据）。
接入真实邮箱时只需实现一个新的数据类替换它，接口为：

- `folder(Folder)` — 按文件夹取列表
- `search(keyword)` — 搜索
- `refresh()` — 拉取新邮件
- `markRead / toggleStar / archive / delete / send` — 单封邮件操作

UI 层不感知数据实现，替换后无需改动任何界面代码。
