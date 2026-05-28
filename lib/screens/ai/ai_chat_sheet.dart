import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/ai_provider.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';

const List<Map<String, String>> quickActions = [
  {'icon': '🔮', 'label': 'Recommend', 'query': 'recommend some music for me'},
  {'icon': '🎭', 'label': 'My Mood', 'query': 'what should I listen to based on my mood?'},
  {'icon': '🎤', 'label': 'Lyrics', 'query': 'find songs with great lyrics'},
  {'icon': '🎸', 'label': 'Artists', 'query': 'suggest similar artists'},
  {'icon': '📊', 'label': 'Genres', 'query': 'what genres should I explore?'},
];

class AIChatSheet extends ConsumerStatefulWidget {
  const AIChatSheet({super.key});

  @override
  ConsumerState<AIChatSheet> createState() => _AIChatSheetState();
}

class _AIChatSheetState extends ConsumerState<AIChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _controller.clear();
    _focusNode.unfocus();
  }

  void _quickAction(String query) {
    ref.read(aiChatProvider.notifier).quickAction(query);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final messages = chatState.messages;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AuroraTheme.oledBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              if (messages.isEmpty)
                Expanded(child: _buildQuickActions())
              else
                Expanded(
                  child: _buildMessages(messages, chatState.isTyping),
                ),
              _buildInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AuroraTheme.textMuted,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SonicAI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
              Text('Your music intelligence', style: TextStyle(fontSize: 12, color: AuroraTheme.textMuted)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AuroraTheme.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Try asking me about...', style: TextStyle(fontSize: 14, color: AuroraTheme.textSecondary)),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return GlassContainer(
                  borderRadius: 20, color: AuroraTheme.glassLight, padding: const EdgeInsets.all(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _quickAction(action['query']!),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(action['icon']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(action['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(List<ChatMessage> messages, bool isTyping) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser)
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
          if (!msg.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: msg.isUser ? AuroraTheme.accentCyan.withValues(alpha: 0.2) : AuroraTheme.glassLight,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: msg.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !msg.isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(msg.text, style: TextStyle(fontSize: 14, height: 1.5, color: msg.isUser ? AuroraTheme.textPrimary : AuroraTheme.textSecondary)),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuroraTheme.glassLight,
              borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: const Radius.circular(4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(),
                const SizedBox(width: 4),
                _dot(delay: 300),
                const SizedBox(width: 4),
                _dot(delay: 600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({int delay = 0}) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: AuroraTheme.accentCyan, shape: BoxShape.circle),
    ).animate(delay: delay.ms).fadeIn().scaleXY(begin: 0, end: 1, duration: 400.ms);
  }

  Widget _buildInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
      child: GlassContainer(
        borderRadius: 28, color: AuroraTheme.glassLight, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Ask SonicAI...',
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 15, color: AuroraTheme.textPrimary),
              ),
            ),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AuroraTheme.accentCyan, borderRadius: BorderRadius.circular(22)),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: AuroraTheme.oledBlack, size: 22),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
