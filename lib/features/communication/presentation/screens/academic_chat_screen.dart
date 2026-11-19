import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../application/communication_providers.dart';
import '../../domain/chat_message.dart';

/// Two-way academic messaging screen for Teachers, Students, and Academy
/// Administrators (with read-only supervisory audit mode).
class AcademicChatScreen extends ConsumerStatefulWidget {
  const AcademicChatScreen({
    super.key,
    required this.academyId,
    required this.conversationId,
    required this.otherPartyName,
    this.otherPartySubtitle = '',
    this.otherPartyRole = 'student', // 'student' | 'teacher' | 'admin'
    this.readOnly = false,
    this.recipientId,
    this.recipientRole,
  });

  final String academyId;
  final String conversationId;
  final String otherPartyName;
  final String otherPartySubtitle;
  final String otherPartyRole;
  final bool readOnly;
  final String? recipientId;
  final String? recipientRole;

  @override
  ConsumerState<AcademicChatScreen> createState() => _AcademicChatScreenState();
}

class _AcademicChatScreenState extends ConsumerState<AcademicChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _hasText = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 220;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  String get _roleLabel {
    if (widget.otherPartySubtitle.isNotEmpty) return widget.otherPartySubtitle;
    if (widget.readOnly) return 'Supervisory Audit • Read-Only';
    return switch (widget.otherPartyRole) {
      'teacher' || 'staff' => 'Faculty Instructor',
      'admin' => 'Academy Administration',
      _ => 'Student',
    };
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(communicationRepositoryProvider);
    final auth = ref.watch(authControllerProvider);
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final currentUserId = currentUser?.id ?? '';
    final currentUserRole = currentUser?.role.name ?? 'user';
    final currentUserName = currentUser?.displayName.isNotEmpty == true
        ? currentUser!.displayName
        : (currentUserRole == 'staff' ? 'Faculty Teacher' : 'Student');

    final isStudentParty = widget.otherPartyRole == 'student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isStudentParty
                  ? AppColors.primaryLight
                  : AppColors.secondaryLight,
              child: Text(
                widget.otherPartyName.isNotEmpty
                    ? widget.otherPartyName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: isStudentParty
                      ? AppColors.primary
                      : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherPartyName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _roleLabel,
                    style: TextStyle(
                      color: widget.readOnly
                          ? AppColors.warning
                          : AppColors.textTertiary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, size: 20),
            tooltip: 'Export Transcript',
            onPressed: () => _printTranscript(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // Supervisory Notice Banner for Academy Admin
                if (widget.readOnly)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.warningLight,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Supervisory Audit Mode — Read-only oversight by Academy Administration',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Messages List
                Expanded(
                  child: Stack(
                    children: [
                      StreamBuilder<List<ChatMessage>>(
                        stream: repo.watchChatMessages(
                          widget.academyId,
                          widget.conversationId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            );
                          }

                          final messages =
                              snapshot.data ?? const <ChatMessage>[];

                          if (messages.isEmpty) {
                            return _EmptyChatState(
                              otherPartyName: widget.otherPartyName,
                            );
                          }

                          // Reverse list so index 0 is at bottom
                          final reversed = messages.reversed.toList();

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            itemCount: reversed.length,
                            itemBuilder: (context, index) {
                              final msg = reversed[index];
                              final isMe = _isMessageFromMe(
                                msg,
                                currentUserId,
                                currentUserRole,
                              );

                              // In reversed list:
                              // index + 1 is the chronologically PREVIOUS message (above)
                              // index - 1 is the chronologically NEXT message (below)
                              final prevMsg = index + 1 < reversed.length
                                  ? reversed[index + 1]
                                  : null;
                              final nextMsg =
                                  index - 1 >= 0 ? reversed[index - 1] : null;

                              final showDateHeader = prevMsg == null ||
                                  !_isSameDay(prevMsg.createdAt, msg.createdAt);

                              final isFirstInGroup = showDateHeader ||
                                  _isMessageFromMe(
                                        prevMsg,
                                        currentUserId,
                                        currentUserRole,
                                      ) !=
                                      isMe;

                              final isLastInGroup = nextMsg == null ||
                                  !_isSameDay(
                                    msg.createdAt,
                                    nextMsg.createdAt,
                                  ) ||
                                  _isMessageFromMe(
                                        nextMsg,
                                        currentUserId,
                                        currentUserRole,
                                      ) !=
                                      isMe;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showDateHeader)
                                    _DateSeparator(date: msg.createdAt),
                                  FadeSlideIn(
                                    key: ValueKey(msg.id),
                                    duration: const Duration(milliseconds: 180),
                                    offsetY: 6,
                                    child: _ChatBubble(
                                      message: msg,
                                      isMe: isMe,
                                      isFirstInGroup: isFirstInGroup,
                                      isLastInGroup: isLastInGroup,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      // Scroll-to-bottom pill
                      Positioned(
                        right: 16,
                        bottom: 12,
                        child: IgnorePointer(
                          ignoring: !_showScrollToBottom,
                          child: AnimatedOpacity(
                            opacity: _showScrollToBottom ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: AnimatedScale(
                              scale: _showScrollToBottom ? 1 : 0.85,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: Material(
                                color: AppColors.surface,
                                shape: const CircleBorder(
                                  side: BorderSide(color: AppColors.border),
                                ),
                                elevation: 2,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  tooltip: 'Scroll to latest',
                                  onPressed: _scrollToBottom,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky Bottom Composer
                if (!widget.readOnly)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                height: 1.35,
                              ),
                              maxLines: 5,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText:
                                    'Message ${widget.otherPartyName}...',
                                hintStyle: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(
                                currentUserId,
                                currentUserName,
                                currentUserRole,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_hasText && !_isSending)
                                ? AppColors.primary
                                : AppColors.surfaceMuted,
                            border: (_hasText && !_isSending)
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_upward_rounded,
                                    color: _hasText
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                            tooltip: 'Send message',
                            onPressed: (_isSending || !_hasText)
                                ? null
                                : () => _sendMessage(
                                      currentUserId,
                                      currentUserName,
                                      currentUserRole,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isMessageFromMe(
    ChatMessage msg,
    String currentUserId,
    String currentUserRole,
  ) {
    return msg.senderId == currentUserId ||
        (currentUserRole == 'staff' && msg.isFromTeacher) ||
        (currentUserRole == 'student' && msg.isFromStudent);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _sendMessage(
    String currentUserId,
    String currentUserName,
    String currentUserRole,
  ) async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      final isTeacher = currentUserRole == 'staff';
      final recipientId = widget.recipientId ?? widget.otherPartyName;
      final recipientRole =
          widget.recipientRole ?? (isTeacher ? 'student' : 'staff');

      final msg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversationId,
        academyId: widget.academyId,
        senderId: currentUserId,
        senderName: currentUserName,
        senderRole: isTeacher ? 'teacher' : 'student',
        text: text,
        createdAt: DateTime.now(),
      );

      await ref.read(communicationRepositoryProvider).sendChatMessage(
            msg,
            recipientId: recipientId,
            recipientRole: recipientRole,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deliver message: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _printTranscript(BuildContext context) async {
    final repo = ref.read(communicationRepositoryProvider);
    final messages = await repo
        .watchChatMessages(widget.academyId, widget.conversationId)
        .first;

    final doc = pw.Document();
    final timeFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ACADERIX ACADEMIC CONVERSATION TRANSCRIPT',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Participant: ${widget.otherPartyName}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.Text(
              'Role: ${widget.otherPartyRole.toUpperCase()}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Thread ID: ${widget.conversationId}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 12),
            ...messages.map((m) {
              final isTeacher = m.isFromTeacher;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: isTeacher ? PdfColors.blue50 : PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${m.senderName} (${m.senderRole.toUpperCase()})',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: isTeacher
                                ? PdfColors.blue800
                                : PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          timeFormat.format(m.createdAt),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(m.text, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'transcript_${widget.conversationId}.pdf',
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.otherPartyName});

  final String otherPartyName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(height: 14),
              Text(
                'Start a conversation with $otherPartyName',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Messages are recorded for academic continuity and administrative oversight.',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (d.year == now.year) return DateFormat('EEE, MMM d').format(d);
    return DateFormat('MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);
    final maxBubbleWidth =
        (MediaQuery.sizeOf(context).width * 0.74).clamp(220.0, 520.0);

    final radius = BorderRadius.only(
      topLeft: Radius.circular(!isMe && !isFirstInGroup ? 6 : 16),
      topRight: Radius.circular(isMe && !isFirstInGroup ? 6 : 16),
      bottomLeft: Radius.circular(!isMe && isLastInGroup ? 4 : (!isMe ? 6 : 16)),
      bottomRight: Radius.circular(isMe && isLastInGroup ? 4 : (isMe ? 6 : 16)),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: isLastInGroup ? 10 : 3),
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surface,
            borderRadius: radius,
            border: isMe ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe && isFirstInGroup && message.senderName.isNotEmpty) ...[
                Text(
                  message.senderName,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textMuted,
                      fontSize: 10.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 13.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
