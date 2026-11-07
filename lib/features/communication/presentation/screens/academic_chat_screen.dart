import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../application/communication_providers.dart';
import '../../domain/chat_message.dart';

/// Professional, WhatsApp-style two-way text chat screen for Teachers, Students,
/// and Academy Administrators (with read-only supervisory audit mode).
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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.otherPartyRole == 'student'
                  ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                  : const Color(0xFF38BDF8).withValues(alpha: 0.25),
              child: Text(
                widget.otherPartyName.isNotEmpty
                    ? widget.otherPartyName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: widget.otherPartyRole == 'student'
                      ? const Color(0xFFA5B4FC)
                      : const Color(0xFF38BDF8),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherPartyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.otherPartySubtitle.isNotEmpty
                        ? widget.otherPartySubtitle
                        : (widget.readOnly
                            ? 'Supervisory Audit Mode • Read-Only'
                            : 'Online • Academic Chat'),
                    style: TextStyle(
                      color: widget.readOnly
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF34D399),
                      fontSize: 11,
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
        child: Column(
          children: [
            // Supervisory Notice Banner for Academy Admin
            if (widget.readOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Supervisory Audit Mode • Academy Administrator Oversight',
                        style: TextStyle(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages List (WhatsApp style reverse stream)
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: repo.watchChatMessages(
                  widget.academyId,
                  widget.conversationId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF38BDF8),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? const <ChatMessage>[];

                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF38BDF8),
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Start conversation with ${widget.otherPartyName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Academic text communication is end-to-end recorded and viewable by academy administration.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Reverse list so index 0 is at bottom
                  final reversed = messages.reversed.toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    itemCount: reversed.length,
                    itemBuilder: (context, index) {
                      final msg = reversed[index];
                      final isMe = msg.senderId == currentUserId ||
                          (currentUserRole == 'staff' && msg.isFromTeacher) ||
                          (currentUserRole == 'student' && msg.isFromStudent);

                      return _ChatBubble(
                        message: msg,
                        isMe: isMe,
                      );
                    },
                  );
                },
              ),
            ),

            // Sticky Bottom Input Bar
            if (!widget.readOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(
                    top: BorderSide(color: Color(0xFF1E293B), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type message to ${widget.otherPartyName}...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
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
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Color(0xFF0F172A), size: 19),
                        onPressed: _isSending
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
    );
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
      final recipientId = widget.recipientId ??
          (isTeacher ? widget.otherPartyName : widget.otherPartyName);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deliver message: $e'),
            backgroundColor: Colors.redAccent,
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
                  pw.Text('ACADERIX ACADEMIC CONVERSATION TRANSCRIPT',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Participant: ${widget.otherPartyName}',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.Text('Role: ${widget.otherPartyRole.toUpperCase()}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Thread ID: ${widget.conversationId}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
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
                              fontSize: 9, color: PdfColors.grey600),
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMe,
  });

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF0284C7)
              : const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: const Color(0xFF334155),
                  width: 0.8,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name header if incoming
            if (!isMe && message.senderName.isNotEmpty) ...[
              Text(
                message.senderName,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
            ],

            // Message text
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),

            // Timestamp + status double tick
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
