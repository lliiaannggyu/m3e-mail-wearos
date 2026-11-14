// 圆屏布局测试：验证弧形几何按「圆」计算，且圆形屏幕尺寸下能正常渲染。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_mail/widgets/curved_list.dart';
import 'package:m3e_mail/widgets/watch_layout.dart';

void main() {
  group('圆屏几何（弦长收窄）', () {
    test('正中间的缺角为 0，越靠边越大', () {
      const r = 200.0;
      expect(WatchInsets.chordInset(r, 0), 0);
      // d=100 时缺角 = r - √(r²-100²)
      expect(WatchInsets.chordInset(r, 100),
          closeTo(r - math.sqrt(r * r - 100 * 100), 0.001));
      // 到达半径时缺角等于半径（该高度处圆已无宽度）
      expect(WatchInsets.chordInset(r, r), r);
    });

    test('缺角随距中心距离单调递增', () {
      const r = 200.0;
      var prev = -1.0;
      for (var d = 0.0; d <= r; d += 10) {
        final v = WatchInsets.chordInset(r, d);
        expect(v, greaterThanOrEqualTo(prev));
        prev = v;
      }
    });
  });

  testWidgets('400x400 圆屏下弧形列表正常渲染且有缩放', (WidgetTester tester) async {
    // 模拟圆形表盘：正方形视口 + 高 DPR
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: CurvedList(
              itemCount: 6,
              itemBuilder: (BuildContext context, int i) => ListTile(
                title: Text('邮件 $i'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    // 列表渲染成功
    expect(find.text('邮件 0'), findsOneWidget);
    // 弧形缩放生效（每行都被 Transform.scale 包裹）
    expect(find.byType(Transform), findsWidgets);
  });

  testWidgets('圆形尺寸被判定为圆屏', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late bool round;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (BuildContext context) {
        round = WatchInsets.isRound(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(round, isTrue);
  });
}
