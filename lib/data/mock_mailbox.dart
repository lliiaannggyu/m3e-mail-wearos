import 'package:flutter/foundation.dart';

import '../models/email.dart';

/// 模拟邮箱数据仓库。
///
/// 真机接入时，把 [MailStore] 中的方法替换为 IMAP/SMTP 或后端 API 即可，
/// UI 层只依赖这个类的接口。
class MailStore extends ChangeNotifier {
  MailStore() {
    _seed();
  }

  final List<Email> _emails = [];

  List<Email> get emails => List.unmodifiable(_emails);

  /// 文件夹邮件列表。
  List<Email> folder(Folder folder) => _emails.inFolder(folder);

  /// 搜索（在未归档邮件中查找）。
  List<Email> search(String keyword) =>
      _emails.inFolder(Folder.inbox).query(keyword);

  /// 模拟下拉刷新：随机把一封邮件标为未读，制造新邮件效果。
  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (_emails.isNotEmpty) {
      final i = DateTime.now().millisecondsSinceEpoch % _emails.length;
      _emails[i] = _emails[i].copyWith(unread: true);
    }
    notifyListeners();
  }

  Email byId(String id) => _emails.firstWhere((e) => e.id == id);

  void markRead(String id, {bool read = true}) {
    _replace(byId(id).copyWith(unread: !read));
  }

  void toggleStar(String id) {
    final e = byId(id);
    _replace(e.copyWith(starred: !e.starred));
  }

  void archive(String id) {
    _replace(byId(id).copyWith(archived: true, unread: false));
  }

  void delete(String id) {
    _emails.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// 模拟发送：发送后放入已归档（代替「已发送」演示数据）。
  Email send({
    required String to,
    required String subject,
    required String body,
  }) {
    final email = Email(
      id: 'sent-${DateTime.now().millisecondsSinceEpoch}',
      sender: '我',
      senderEmail: 'me@watch.example',
      subject: subject.isEmpty ? '(无主题)' : subject,
      body: body,
      time: DateTime.now(),
    );
    _emails.insert(0, email);
    notifyListeners();
    return email;
  }

  void _replace(Email updated) {
    final i = _emails.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      _emails[i] = updated;
      notifyListeners();
    }
  }

  void _seed() {
    final now = DateTime.now();
    Email m({
      required String id,
      required String sender,
      required String senderEmail,
      required String subject,
      required String body,
      required int minutesAgo,
      bool unread = false,
      bool starred = false,
      bool hasAttachment = false,
    }) =>
        Email(
          id: id,
          sender: sender,
          senderEmail: senderEmail,
          subject: subject,
          body: body,
          time: now.subtract(Duration(minutes: minutesAgo)),
          unread: unread,
          starred: starred,
          hasAttachment: hasAttachment,
        );

    _emails.addAll([
      m(
        id: 'e1',
        sender: '产品组 · 林小舟',
        senderEmail: 'xiaozhou@team.example',
        subject: '手表版邮件客户端评审会改到 15:00',
        body: '各位好，原定 14:00 的手表版邮件客户端评审会因会议室冲突改到 15:00，'
            '地点不变，还是在 3F 泰山厅。议程不变：\n'
            '1. 表盘快捷入口方案\n'
            '2. 圆屏列表的滚动与点击热区\n'
            '3. 语音回复的落地优先级\n'
            '请大家准时参加。',
        minutesAgo: 3,
        unread: true,
      ),
      m(
        id: 'e2',
        sender: 'GitHub',
        senderEmail: 'noreply@github.example',
        subject: '[material_3_expressive] Issue #128: 圆形表盘下的 FAB 遮挡问题',
        body: '有人在 Round 表盘上反馈底部 FAB 会压到列表最后一项，'
            '建议在 circular 布局下给列表尾部追加 safe-area inset。'
            '详情见仓库 issue 页面。',
        minutesAgo: 42,
        unread: true,
      ),
      m(
        id: 'e3',
        sender: '云服务告警',
        senderEmail: 'alert@cloud.example',
        subject: '预警：mail-api 今晚 23:00 灰度发布',
        body: 'mail-api 将于今晚 23:00 - 23:40 进行灰度发布，期间手表端同步可能有 1-2 分钟延迟，'
            '请相关同学留意监控大盘。如遇异常请回滚至 v2.4.1。',
        minutesAgo: 130,
        starred: true,
      ),
      m(
        id: 'e4',
        sender: '妈妈',
        senderEmail: 'mom@family.example',
        subject: '周末回家吃饭吗',
        body: '这周末回来吃饭吗？你上次说想吃的糖醋排骨，妈这周给你做。回个消息就行。',
        minutesAgo: 320,
      ),
      m(
        id: 'e5',
        sender: '出差报销 · 人事行政',
        senderEmail: 'hr-admin@company.example',
        subject: '10 月差旅报销已到账',
        body: '您 10 月提交的差旅报销单（金额 ¥1,286.00）已完成审核并打款，'
            '请注意查收银行卡到账短信。附件为报销明细，如有疑问请回复本邮件。',
        minutesAgo: 1500,
        hasAttachment: true,
      ),
      m(
        id: 'e6',
        sender: '设计周报 · 阿珂',
        senderEmail: 'ke@design.example',
        subject: 'M3E 表盘组件视觉走查结论',
        body: '走查了 6 块圆屏/方屏表盘：圆形裁切下圆角卡片的边距整体 OK；'
            '两处小问题：1) 徽标未读数在 2 位数字时外圈被裁掉 1px；'
            '2) 深色模式下描边卡片对比度不足，建议提升描边透明度到 38%。',
        minutesAgo: 2900,
      ),
    ]);
  }
}
