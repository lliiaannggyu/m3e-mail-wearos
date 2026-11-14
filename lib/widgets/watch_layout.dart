import 'dart:math' as math;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// 圆形表盘几何适配工具。
///
/// 所有尺寸都从「圆」本身推导：在距水平中线竖直距离 d 处，
/// 圆的可用弦宽 = 2·√(r² − d²)。内容放在哪，边距就算到哪，
/// 而不是一刀切的固定 Padding。
class WatchInsets {
  WatchInsets._();

  /// 判断当前屏幕是否为圆形（宽高相等即视为圆表盘）。
  static bool isRound(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return (size.width - size.height).abs() < 1;
  }

  /// 圆屏半径（非圆屏返回高度一半）。
  static double radius(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return math.min(size.width, size.height) / 2;
  }

  /// 在距竖直中心 [d] 处，圆可用的弦宽的一半（单侧内缩量）。
  static double chordInset(double radius, double d) {
    if (d >= radius) return radius;
    return radius - math.sqrt(math.max(0, radius * radius - d * d));
  }

  /// 内容位于竖直中心时的单侧安全内缩（固定基础值 + 圆形几何）。
  static double horizontal(BuildContext context) =>
      isRound(context) ? 16 : 12;

  /// 竖直方向基础内缩：圆屏上下极窄，收得多一些。
  static double vertical(BuildContext context) => isRound(context) ? 10 : 8;

  /// 底部动作栏距离底边的内缩（让按钮落在圆内最宽的弦上）。
  static double chordTopInset(BuildContext context) =>
      isRound(context) ? 12 : 8;
}

/// 手表页面统一容器：深色 surface 背景。
/// 内容层自己负责弧形几何（CurvedList / CurvedChildScrollView），
/// 容器只提供背景与右滑返回。
class WatchScreen extends StatelessWidget {
  const WatchScreen({
    super.key,
    required this.child,
    this.enableSwipeBack = true,
  });

  final Widget child;

  /// 启用 Wear OS 惯例的右滑返回手势。
  final bool enableSwipeBack;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    Widget body = Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: child,
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

/// 顶部居中的紧凑页头：为圆屏顶部的窄弦区设计。
/// 标题一行居中、小号；两侧留白按弦长自动收放。
class WatchHeader extends StatelessWidget {
  const WatchHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final double topInset = WatchInsets.vertical(context) + 4;
    return Padding(
      padding: EdgeInsets.only(top: topInset, bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.typeScale.titleSmall,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
