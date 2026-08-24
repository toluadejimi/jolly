import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/color_data.dart';
import '../providers/auth_provider.dart';
import '../screens/order_conversations_list_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/track_order_screen.dart';
import '../services/api_service.dart';
import '../services/assistant_service.dart';
import '../ui/home/home_screen.dart';
import '../ui/login/login_screen.dart';

Future<void> showAiAssistantSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AiAssistantSheet(),
  );
}

class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<AssistantMessage> _messages = [];
  late final AssistantService _assistant;
  bool _busy = false;

  static const _quickPrompts = [
    'Help me order a gift',
    'Track my order',
    'Contact support',
  ];

  @override
  void initState() {
    super.initState();
    _assistant = AssistantService(context.read<ApiService>());
    _messages.add(
      AssistantMessage(
        text:
            'Hi! I’m Jolly Assistant. I can help you order gifts, track a delivery, or contact support. What do you need?',
        isUser: false,
        actions: const [
          AssistantAction(
            type: AssistantActionType.openProducts,
            label: 'Browse gifts',
          ),
          AssistantAction(
            type: AssistantActionType.openTrack,
            label: 'Track order',
          ),
          AssistantAction(
            type: AssistantActionType.openSupportChat,
            label: 'Contact support',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;

    setState(() {
      _messages.add(AssistantMessage(text: text, isUser: true));
      _busy = true;
      _input.clear();
    });
    _scrollToEnd();

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    final reply = await _assistant.reply(
      userText: text,
      isLoggedIn: isLoggedIn,
    );
    if (!mounted) return;

    setState(() {
      _messages.add(
        AssistantMessage(
          text: reply.text,
          isUser: false,
          actions: reply.actions,
        ),
      );
      _busy = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleAction(AssistantAction action) async {
    final navigator = Navigator.of(context);
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    navigator.pop();

    switch (action.type) {
      case AssistantActionType.openProducts:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const ProductListScreen()),
        );
        break;
      case AssistantActionType.openProduct:
        if (action.productId == null) return;
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: action.productId!),
          ),
        );
        break;
      case AssistantActionType.openTrack:
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => TrackOrderScreen(orderNumber: action.orderNumber),
          ),
        );
        break;
      case AssistantActionType.openSupportChat:
        if (!loggedIn) {
          await navigator.push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const OrderConversationsListScreen(),
          ),
        );
        break;
      case AssistantActionType.openLogin:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
      case AssistantActionType.openCart:
        await navigator.push(
          MaterialPageRoute(builder: (_) => HomeScreen(selectedTab: 2)),
        );
        break;
      case AssistantActionType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jolly Assistant',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Order · Track · Support',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: greyFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_busy ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_busy && index == _messages.length) {
                    return const _TypingBubble();
                  }
                  final msg = _messages[index];
                  return _ChatBubble(
                    message: msg,
                    onAction: _handleAction,
                  );
                },
              ),
            ),
            if (_messages.length <= 2)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final prompt = _quickPrompts[i];
                    return ActionChip(
                      label: Text(prompt),
                      onPressed: _busy ? null : () => _send(prompt),
                      backgroundColor: primaryColor.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                      labelStyle: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          hintText: 'Ask about orders, tracking, support…',
                          filled: true,
                          fillColor: const Color(0xFFF1F2F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _busy ? null : () => _send(_input.text),
                        borderRadius: BorderRadius.circular(16),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.onAction});

  final AssistantMessage message;
  final Future<void> Function(AssistantAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? primaryColor : const Color(0xFFF1F2F4);
    final fg = isUser ? Colors.white : fontBlack;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 18),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: fg,
                    height: 1.35,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (!isUser && message.actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.actions.map((action) {
                    return ActionChip(
                      label: Text(
                        action.label ?? 'Open',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => onAction(action),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.35),
                      ),
                      labelStyle: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
              child: _Dot(delayMs: i * 120),
            );
          }),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delayMs});

  final int delayMs;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: greyFont,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
