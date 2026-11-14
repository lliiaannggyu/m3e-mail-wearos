import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mock_mailbox.dart';
import '../models/email.dart';
import '../widgets/watch_layout.dart';
import 'email_detail_page.dart';

/// 搜索页：实时过滤收件箱中的邮件。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.store});

  final MailStore store;

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
    setState(() => _results = widget.store.search(value));
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return WatchScreen(
      child: Column(
        children: <Widget>[
          M3ESearchBar(
            controller: _controller,
            hintText: '搜索发件人 / 主题 / 正文',
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
          const SizedBox(height: 8),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.isEmpty
                          ? '输入关键字开始搜索'
                          : '没有匹配的邮件',
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Email email = _results[index];
                      return M3EListItem(
                        headline: email.sender,
                        supportingText: email.subject,
                        trailingText: email.timeLabel,
                        leading:
                            MailAvatar(name: email.sender, unread: email.unread),
                        onTap: () {
                          if (email.unread) {
                            widget.store.markRead(email.id);
                          }
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(
                            builder: (_) => EmailDetailPage(
                              store: widget.store,
                              emailId: email.id,
                            ),
                          ));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
