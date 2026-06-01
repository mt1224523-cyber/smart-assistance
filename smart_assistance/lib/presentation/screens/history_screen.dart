import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/message.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              if (provider.messages.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: "Effacer l'historique",
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmClear(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (provider.messages.isEmpty) {
            return _EmptyState(theme: Theme.of(context));
          }

          final userMessages =
              provider.messages.where((m) => m.isUser).toList().reversed.toList();
          final filtered = _query.isEmpty
              ? userMessages
              : userMessages
                  .where((m) =>
                      m.content.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Semantics(
                  label: "Rechercher dans l'historique",
                  textField: true,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Effacer la recherche',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun résultat',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final message = filtered[index];
                          final response =
                              _findResponse(provider.messages, message.id);
                          return _HistoryCard(
                            message: message,
                            response: response,
                            onPlay: response != null
                                ? () => provider.speakMessage(response.content)
                                : null,
                            onDelete: () {
                              provider.deleteMessage(message.id);
                              if (response != null) {
                                provider.deleteMessage(response.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, ChatProvider provider) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Effacer l'historique ?"),
        content: const Text(
          'Cette action supprimera toutes vos conversations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Effacer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Message? _findResponse(List<Message> messages, String userMessageId) {
    final userIndex = messages.indexWhere((m) => m.id == userMessageId);
    if (userIndex == -1 || userIndex == messages.length - 1) return null;
    for (int i = userIndex + 1; i < messages.length; i++) {
      if (!messages[i].isUser) {
        return messages[i];
      }
    }
    return null;
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: theme.hintColor),
          const SizedBox(height: 16),
          Text(
            'Aucun historique',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Vos conversations apparaîtront ici',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Message message;
  final Message? response;
  final VoidCallback? onPlay;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.message,
    required this.response,
    required this.onPlay,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return "Aujourd'hui ${DateFormat.Hm().format(date)}";
    } else if (difference.inDays == 1) {
      return 'Hier ${DateFormat.Hm().format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(date);
    } else {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.content,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (response != null) ...[
                const SizedBox(height: 8),
                Text(
                  response!.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(message.timestamp),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (onPlay != null)
                    const Icon(
                      Icons.volume_up,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
