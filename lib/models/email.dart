/// 邮件相关的数据模型。
library;

/// 邮箱文件夹类型。
enum Folder { inbox, starred, sent, archive }

/// 一封邮件。
class Email {
  Email({
    required this.id,
    required this.sender,
    required this.senderEmail,
    required this.subject,
    required this.body,
    required this.time,
    this.unread = false,
    this.starred = false,
    this.archived = false,
    this.hasAttachment = false,
  });

  final String id;
  final String sender;
  final String senderEmail;
  final String subject;
  final String body;
  final DateTime time;
  bool unread;
  bool starred;
  bool archived;
  final bool hasAttachment;

  /// 相对时间显示，例如「3 分钟前」。
  String get timeLabel {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${time.month}/${time.day}';
  }

  Email copyWith({
    bool? unread,
    bool? starred,
    bool? archived,
  }) {
    return Email(
      id: id,
      sender: sender,
      senderEmail: senderEmail,
      subject: subject,
      body: body,
      time: time,
      unread: unread ?? this.unread,
      starred: starred ?? this.starred,
      archived: archived ?? this.archived,
      hasAttachment: hasAttachment,
    );
  }
}

/// 搜索过滤条件。
extension EmailFilter on List<Email> {
  List<Email> inFolder(Folder folder) {
    switch (folder) {
      case Folder.inbox:
        return where((e) => !e.archived).toList();
      case Folder.starred:
        return where((e) => e.starred && !e.archived).toList();
      case Folder.sent:
      case Folder.archive:
        return where((e) => e.archived).toList();
    }
  }

  List<Email> query(String keyword) {
    final k = keyword.trim().toLowerCase();
    if (k.isEmpty) return this;
    return where((e) =>
        e.sender.toLowerCase().contains(k) ||
        e.subject.toLowerCase().contains(k) ||
        e.body.toLowerCase().contains(k)).toList();
  }
}
