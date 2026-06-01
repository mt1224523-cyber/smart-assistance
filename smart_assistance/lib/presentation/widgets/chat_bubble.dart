import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onSpeak;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSpeak,
  });

  Future<void> _showActions(BuildContext context) async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier le texte'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: message.content));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copié'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager'),
              onTap: () async {
                Navigator.pop(ctx);
                await Share.share(message.content);
              },
            ),
            if (!message.isUser && onSpeak != null)
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Écouter'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSpeak!();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final botBg = isDark ? AppTheme.botMessageColorDark : AppTheme.botMessageColor;
    final botText =
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final semanticLabel = message.isUser
        ? 'Vous avez dit : ${message.content}'
        : "L'assistant a répondu : ${message.content}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const ExcludeSemantics(
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 16,
                child: Icon(
                  Icons.smart_toy,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Semantics(
              label: semanticLabel,
              child: GestureDetector(
                onLongPress: () => _showActions(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        message.isUser ? AppTheme.userMessageColor : botBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : botText,
                          fontSize: 16,
                        ),
                      ),
                      if (!message.isUser && onSpeak != null) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          button: true,
                          label: 'Écouter la réponse',
                          child: GestureDetector(
                            onTap: onSpeak,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Écouter',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const ExcludeSemantics(
              child: CircleAvatar(
                backgroundColor: AppTheme.secondaryColor,
                radius: 16,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
