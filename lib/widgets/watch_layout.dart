import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// 圆形表盘适配工具。
///
/// Wear OS 圆形屏幕四角会被裁掉，内容若铺满边缘，
/// 顶部/底部的文字会被切掉。这里根据屏幕形状给出安全内边距。
class WatchInsets {
  WatchInsets._();

  /// 判断当前屏幕是否为圆形（宽高相等即视为圆表盘）。
  static bool isRound(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return (size.width - size.height).abs() < 1;
  }

  /// 水平方向的安全内边距：圆屏时向内收。
  static double horizontal(BuildContext context) =>
      isRound(context) ? 26 : 12;

  /// 垂直方向的安全内边距。
  static double vertical(BuildContext context) => isRound(context) ? 14 : 8;
}

/// 手表页面统一容器：深色 surface 背景 + 圆屏安全边距 + 右滑返回。
class WatchScreen extends StatelessWidget {
  const WatchScreen({
    super.key,
    required this.child,
    this.fab,
    this.enableSwipeBack = true,
  });

  final Widget child;

  /// 右下角悬浮操作按钮（如「写邮件」）。
  final Widget? fab;

  /// 启用 Wear OS 惯例的右滑返回手势。
  final bool enableSwipeBack;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    Widget body = Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: WatchInsets.horizontal(context),
                vertical: WatchInsets.vertical(context),
              ),
              child: child,
            ),
          ),
          if (fab != null)
            Positioned(
              right: WatchInsets.horizontal(context) * 0.8,
              bottom: WatchInsets.vertical(context) * 1.2,
              child: fab!,
            ),
        ],
      ),
    );
    if (enableSwipeBack) {
      body = SwipeBackGesture(child: body);
    }
    return body;
  }
}

/// Wear OS 手势导航：从左边缘向右滑动返回上一页。
/// 这是手表上最常用的返回方式（表冠按钮之外的系统惯例）。
class SwipeBackGesture extends StatelessWidget {
  const SwipeBackGesture({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 只在屏幕左边缘起手，避免误触列表横滑操作
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (DragStartDetails d) =>
          _startX ??= d.globalPosition.dx,
      onHorizontalDragEnd: (DragEndDetails d) {
        final dx = (d.primaryVelocity ?? 0);
        if (_startX != null &&
            _startX! < MediaQuery.sizeOf(context).width * 0.3 &&
            dx > 600) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }
        _startX = null;
      },
      child: child,
    );
  }

  static double? _startX;
}

/// 发件人头像：取名字首字符，按名字散列配色。
class MailAvatar extends StatelessWidget {
  const MailAvatar({
    super.key,
    required this.name,
    this.unread = false,
    this.size = 36,
  });

  final String name;
  final bool unread;
  final double size;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final List<Color> palette = <Color>[
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];
    final Color color = palette[name.hashCode.abs() % palette.length];

    final Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: unread ? 0.9 : 0.35),
      foregroundColor: theme.colorScheme.onPrimary,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w600),
      ),
    );

    if (!unread) return avatar;
    // 未读邮件加未读圆点徽标。
    return M3EBadge(
      showDot: true,
      child: avatar,
    );
  }
}
