import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../mail/mail_service.dart';
import '../models/email.dart';
import '../widgets/curved_list.dart';
import '../widgets/watch_layout.dart';
import '../widgets/watch_mail_row.dart';
import 'email_detail_page.dart';

/// 搜索页 —— 圆形表盘布局：
/// 顶部窄弦区放搜索框，结果用弧形曲线列表呈现。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Email> _results = const <Email>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _results = MailService.instance.search(value));
  }

  @override
  Widget build(BuildContext context) {
    return WatchScreen(
      child: Column(
        children: <Widget>[
          WatchHeader(title: '搜索'),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: WatchInsets.horizontal(context)),
            child: M3ESearchBar(
              controller: _controller,
              hintText: '发件人 / 主题 / 正文',
              onChanged: _onChanged,
              onSubmitted: _onChanged,
              trailing: _controller.text.isEmpty
                  ? null
                  : <Widget>[
                      M3EIconButton(
                        icon: Icon(M3EIcons.close),
                        variant: M3EIconButtonVariant.standard,
                        size: M3EIconButtonSize.xs,
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                    ],
            ),
          ),
          Expanded(
            child: CurvedList(
              itemCount: _results.length,
              emptyText: _controller.text.isEmpty ? '输入关键字搜索' : '没有匹配的邮件',
              itemBuilder: (BuildContext context, int index) {
                final Email email = _results[index];
                return WatchMailRow(
                  email: email,
                  onTap: () {
                    if (email.unread) {
                      MailService.instance.markRead(email.id);
                    }
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => EmailDetailPage(emailId: email.id),
                    ));
                  },
                  onToggleStar: () => setState(
                      () => MailService.instance.toggleStar(email.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
