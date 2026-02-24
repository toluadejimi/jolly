import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../models/api_response.dart';
import '../models/order_conversation.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class OrderConversationScreen extends StatefulWidget {
  const OrderConversationScreen({
    super.key,
    required this.orderRef,
    required this.orderNumber,
  });

  /// Order id or order_number for API
  final dynamic orderRef;
  final String orderNumber;

  @override
  State<OrderConversationScreen> createState() => _OrderConversationScreenState();
}

class _OrderConversationScreenState extends State<OrderConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ApiResponse<OrderConversationData>? _result;
  bool _sending = false;

  Future<void> _load() async {
    final api = context.read<ApiService>();
    final res = await api.getOrderConversation(widget.orderRef);
    if (mounted) setState(() => _result = res);
  }

  Future<void> _sendMessage({String? message, String? attachmentPath}) async {
    if (_sending) return;
    if ((message == null || message.trim().isEmpty) && (attachmentPath == null || attachmentPath.isEmpty)) return;
    setState(() => _sending = true);
    final api = context.read<ApiService>();
    final res = await api.sendOrderConversationMessage(
      orderRef: widget.orderRef,
      message: message?.trim(),
      attachmentPath: attachmentPath,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.success && res.data != null) {
      _messageController.clear();
      setState(() {
        _result = ApiResponse.success(OrderConversationData(
          conversationId: _result!.data!.conversationId,
          orderId: _result!.data!.orderId,
          orderNumber: _result!.data!.orderNumber,
          messages: [..._result!.data!.messages, res.data!.message],
        ));
      });
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to send')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile != null && mounted) await _sendMessage(attachmentPath: xfile.path);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - #${widget.orderNumber}'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: res == null
                ? const Center(child: CircularProgressIndicator())
                : !res.success
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(res.error ?? 'Failed to load chat'),
                              const SizedBox(height: 16),
                              FilledButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : res.data!.messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet. Send a message or attach a photo below.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: res.data!.messages.length,
                            itemBuilder: (context, index) {
                              final msg = res.data!.messages[index];
                              return _MessageBubble(message: msg);
                            },
                          ),
          ),
          if (res != null && res.success)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: _sending ? null : _pickImage,
                      tooltip: 'Attach photo',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) => _sendMessage(message: text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                      onPressed: _sending
                          ? null
                          : () {
                              final text = _messageController.text;
                              _sendMessage(message: text);
                            },
                      tooltip: 'Send',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Seller',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (message.message != null && message.message!.isNotEmpty)
              Text(
                message.message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                ),
              ),
            if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildAttachment(context, theme, isUser),
            ],
            const SizedBox(height: 2),
            Text(
              message.createdAt,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUser ? theme.colorScheme.onPrimary.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, ThemeData theme, bool isUser) {
    final url = message.attachmentUrl!;
    final name = message.attachmentName ?? 'Attachment';
    final ext = name.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
    if (isImage) {
      return GestureDetector(
        onTap: () async {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 160,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 160,
              height: 120,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 160,
              height: 80,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_drive_file, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, size: 18, color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
