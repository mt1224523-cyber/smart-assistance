import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/suggestion_chips.dart';
import '../widgets/voice_button.dart';
import '../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      if (provider.messages.isEmpty) {
        _addWelcomeMessage();
      }
    });
  }

  void _addWelcomeMessage() {
    final provider = context.read<ChatProvider>();
    if (provider.messages.isEmpty) {
      provider.addLocalBotMessage(
        'Bonjour ! Je suis votre assistant intelligent. '
        'Posez-moi une question sur le business, la santé, '
        "l'agriculture ou la vie quotidienne en Côte d'Ivoire.",
        speak: true,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(text);
      _textController.clear();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        context.read<ChatProvider>().sendMessage(
          'Analyse cette image',
          imagePaths: [image.path],
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Intelligent'),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.ttsEnabled ? Icons.volume_up : Icons.volume_off,
                ),
                onPressed: () {
                  if (provider.ttsEnabled) {
                    provider.stopSpeaking();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 80,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Posez-moi votre question!',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Je suis là pour vous aider',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      provider.messages.length + (provider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (provider.isLoading &&
                        index == provider.messages.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.botMessageColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final message = provider.messages[index];
                    return ChatBubble(
                      message: message,
                      onSpeak: () {
                        provider.speakMessage(message.content);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              if (provider.errorMessage != null) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SuggestionChips(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showImageSourceDialog,
                    tooltip: 'Envoyer une image',
                    icon: const Icon(Icons.camera_alt),
                    color: AppTheme.primaryColor,
                    iconSize: 28,
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Champ de question',
                      textField: true,
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Écrivez votre question...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendTextMessage,
                    tooltip: 'Envoyer la question',
                    icon: const Icon(Icons.send),
                    color: AppTheme.primaryColor,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const VoiceButton(),
    );
  }
}
