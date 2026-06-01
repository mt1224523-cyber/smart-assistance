import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/suggestion.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Suggestion.defaultSuggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = Suggestion.defaultSuggestions[index];
          return ActionChip(
            avatar: Icon(
              suggestion.icon,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            label: Text(
              suggestion.text.length > 25
                  ? '${suggestion.text.substring(0, 25)}...'
                  : suggestion.text,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () {
              context.read<ChatProvider>().sendMessage(suggestion.text);
            },
          );
        },
      ),
    );
  }
}
