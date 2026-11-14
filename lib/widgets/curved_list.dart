import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'watch_layout.dart';

/// 弧形曲线列表 —— Wear OS 圆形表盘的标准列表形态。
///
/// 列表项沿屏幕圆周弯曲呈现：越靠近上下边缘，
/// 行宽按圆的弦长收窄、内容轻微缩小下沉并渐隐；
/// 视口中心一行最大、最亮、最宽。这是圆表盘上
/// 「可用区域随高度变化」的正确答案，而非方形屏的等宽 ListView。
class CurvedList extends StatefulWidget {
  const CurvedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.itemExtent = 72,
    this.baseHorizontalInset = 14,
    this.extraHorizontalInset = EdgeInsets.zero,
    this.emptyText,
  });

  final int itemCount;

  /// 返回固定高度 [itemExtent] 的行 widget。
  final IndexedWidgetBuilder itemBuilder;

  final ScrollController? controller;

  /// 行高固定，弧形几何按行中心计算。
  final double itemExtent;

  /// 中心行的左右基础留白。
  final double baseHorizontalInset;

  /// 额外左右留白（如两侧悬浮按钮占位）。
  final EdgeInsets extraHorizontalInset;

  final String? emptyText;

  @override
  State<CurvedList> createState() => _CurvedListState();
}

class _CurvedListState extends State<CurvedList> {
  ScrollController? _own;

  ScrollController get _effective =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return Center(
        child: Text(
          widget.emptyText ?? '暂无内容',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFFB0BEC5),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportH = constraints.maxHeight;
        return ListView.builder(
          controller: _effective,
          itemCount: widget.itemCount,
          itemExtent: widget.itemExtent,
          padding: const EdgeInsets.symmetric(vertical: 4),
          clipBehavior: Clip.none,
          itemBuilder: (BuildContext context, int index) {
            return AnimatedBuilder(
              animation: _effective,
              builder: (BuildContext context, Widget? child) {
                final double offset =
                    _effective.hasClients ? _effective.offset : 0;
                final double itemCenter =
                    index * widget.itemExtent + 4 - offset + widget.itemExtent / 2;
                final double d = (itemCenter - viewportH / 2).abs();
                // 圆屏时半径 = 屏宽的一半；非圆屏退化为按视口高的柔和效果。
                final double r =
                    math.max(viewportH / 2, MediaQuery.sizeOf(context).width / 2);
                final double t = (d / r).clamp(0.0, 1.0);
                // 弦长收窄：inset = r - √(r² − d²)，即圆在该高度处的缺角。
                final double chord =
                    r - math.sqrt(math.max(0, r * r - d * d));
                final double inset = widget.baseHorizontalInset +
                    chord +
                    (d < viewportH / 2 ? widget.extraHorizontalInset.horizontal : 0);
                final double scale = 1 - 0.16 * t;
                final double opacity = 1 - 0.55 * t;
                return IgnorePointer(
                  ignoring: opacity < 0.45,
                  child: Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: math.max(0, inset)),
                      child: Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          height: widget.itemExtent,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: widget.itemBuilder(context, index),
            );
          },
        );
      },
    );
  }
}

/// 弧形滚动视图：给详情正文、登录、写邮件这类非列表页用。
/// 内容随滚动位置在圆屏内左右收放——滚到顶/底时按弦长收窄，
/// 停在中间时最宽，模拟内容沿圆周滑动的观感。
class CurvedChildScrollView extends StatefulWidget {
  const CurvedChildScrollView({
    super.key,
    required this.child,
    this.controller,
    this.baseHorizontalInset = 16,
    this.maxCurveInset = 26,
    this.center = true,
  });

  final Widget child;
  final ScrollController? controller;

  /// 视口中心（未滚动）时的左右留白。
  final double baseHorizontalInset;

  /// 滚到顶/底时的额外收窄量。
  final double maxCurveInset;

  /// 是否让子内容水平居中。
  final bool center;

  @override
  State<CurvedChildScrollView> createState() => _CurvedChildScrollViewState();
}

class _CurvedChildScrollViewState extends State<CurvedChildScrollView> {
  ScrollController? _own;

  ScrollController get _effective =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        return SingleChildScrollView(
          controller: _effective,
          child: AnimatedBuilder(
            animation: _effective,
            builder: (BuildContext context, Widget? child) {
              double t = 0;
              // 首帧内容尺寸尚未确定，maxScrollExtent 不可访问。
              if (_effective.hasClients &&
                  _effective.position.hasContentDimensions &&
                  _effective.position.maxScrollExtent > 0) {
                final double range = _effective.position.maxScrollExtent;
                t = ((_effective.offset / range) * 2 - 1).abs().clamp(0.0, 1.0);
              }
              final double inset =
                  widget.baseHorizontalInset + widget.maxCurveInset * t;
              final double chord =
                  w - 2 * inset; // 可用宽度按圆内最大弦近似
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: chord,
                    maxWidth: chord,
                  ),
                  child: child,
                ),
              );
            },
            child: widget.center
                ? Center(widthFactor: 1, child: widget.child)
                : widget.child,
          ),
        );
      },
    );
  }
}

/// 底部中央圆形动作栏：手表页面的主要操作区。
/// 位于圆表盘下缘内一点的位置（下缘弦长最宽处偏上），
/// 动作按钮一律圆形、间距大热区。
class WatchActionBar extends StatelessWidget {
  const WatchActionBar({
    super.key,
    required this.actions,
    this.verticalPadding = 10,
  });

  /// 圆形动作按钮，2–4 个为宜。
  final List<Widget> actions;

  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final double topInset = WatchInsets.chordTopInset(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(topInset * 0.6, verticalPadding,
          topInset * 0.6, verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < actions.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 18),
            actions[i],
          ],
        ],
      ),
    );
  }
}
