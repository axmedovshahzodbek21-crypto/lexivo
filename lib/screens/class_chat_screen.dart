// Class chat: one conversation per class + student, same as the web
// (lexivo-web lib/class-chat.ts + components/ChatThread.tsx). Teacher
// messages are class_notes rows, student messages are class_replies rows —
// see migration 20261020000001_class_chat.sql. No Realtime: an open chat
// polls for rows newer than the last one it has, which keeps this free.
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

const _pollEvery = Duration(seconds: 10);
const _studentMax = 500;
const _teacherMax = 1000;

class ChatMessage {
  final String id;
  final bool fromTeacher;
  final String message;
  final String createdAt; // ISO, compared as a string like the web
  String? readAt;
  ChatMessage(this.id, this.fromTeacher, this.message, this.createdAt, this.readAt);
}

// The conversation, oldest first — or only what's newer than [since].
Future<List<ChatMessage>> _loadThread(String classId, String studentId, [String? since]) async {
  var notes = supabase.from('class_notes').select('id, message, created_at, read_at')
      .eq('class_id', classId).eq('student_id', studentId);
  var replies = supabase.from('class_replies').select('id, message, created_at, read_at')
      .eq('class_id', classId).eq('student_id', studentId);
  if (since != null) {
    notes = notes.gt('created_at', since);
    replies = replies.gt('created_at', since);
  }
  final res = await Future.wait([
    notes.order('created_at', ascending: false).limit(200),
    replies.order('created_at', ascending: false).limit(200),
  ]);
  ChatMessage row(Map r, bool fromTeacher) => ChatMessage(
      r['id'] as String, fromTeacher, r['message'] as String? ?? '', r['created_at'] as String, r['read_at'] as String?);
  return [
    ...res[0].map((r) => row(r, true)),
    ...res[1].map((r) => row(r, false)),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

// Marks the other side's messages read: a student reads the teacher's
// notes, a teacher reads one student's replies.
void _markRead(String classId, String studentId, bool asTeacher) {
  (asTeacher
      ? supabase.rpc('mark_class_replies_read', params: {'p_class_id': classId, 'p_student_id': studentId})
      : supabase.rpc('mark_class_notes_read', params: {'p_class_id': classId}))
      .then((_) {})
      .catchError((e) { debugPrint('[ChatThread] mark read failed: $e'); });
}

String _timeLabel(String iso) {
  final d = DateTime.parse(iso).toLocal();
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(d.hour)}:${two(d.minute)}';
  final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
  return sameDay ? time : '${two(d.day)}.${two(d.month)} $time';
}

// Unread student messages for a teacher's class (the Messages badge).
Future<int> loadTeacherUnreadCount(String classId) async {
  final rows = await supabase.from('class_replies').select('id')
      .eq('class_id', classId).isFilter('read_at', null).limit(100);
  return (rows as List).length;
}

/// One class + student conversation. [canSend] is false when the student's
/// class has chat off (they can still read).
class ChatThread extends StatefulWidget {
  final String classId, studentId, otherName;
  final bool asTeacher, canSend;
  const ChatThread({super.key, required this.classId, required this.studentId, required this.asTeacher,
      required this.canSend, required this.otherName});

  @override
  State<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<ChatThread> {
  List<ChatMessage>? _messages;
  String? _last;
  String _state = 'idle'; // idle | sending | limit | failed
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;

  int get _max => widget.asTeacher ? _teacherMax : _studentMax;

  @override
  void initState() {
    super.initState();
    _loadThread(widget.classId, widget.studentId).then((all) {
      if (!mounted) return;
      setState(() => _messages = all);
      if (all.isNotEmpty) _last = all.last.createdAt;
      if (all.any((m) => m.fromTeacher != widget.asTeacher && m.readAt == null)) {
        _markRead(widget.classId, widget.studentId, widget.asTeacher);
      }
      _scrollToEnd();
    }).catchError((_) { if (mounted) setState(() => _messages = []); });
    _timer = Timer.periodic(_pollEvery, (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  void _merge(List<ChatMessage> fresh) {
    if (!mounted || fresh.isEmpty) return;
    _last = fresh.last.createdAt;
    final seen = {for (final m in _messages ?? <ChatMessage>[]) m.id};
    setState(() => _messages = [...?_messages, ...fresh.where((m) => !seen.contains(m.id))]);
    _scrollToEnd();
  }

  // Only rows newer than the last one we have — a poll is usually empty.
  Future<void> _poll() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    try {
      final fresh = await _loadThread(widget.classId, widget.studentId, _last);
      _merge(fresh);
      if (fresh.any((m) => m.fromTeacher != widget.asTeacher)) {
        _markRead(widget.classId, widget.studentId, widget.asTeacher);
      }
      // My messages not yet seen: ask only whether they've been read since.
      final unseen = (_messages ?? []).where((m) => m.fromTeacher == widget.asTeacher && m.readAt == null).map((m) => m.id).toList();
      if (unseen.isNotEmpty) {
        final rows = await supabase.from(widget.asTeacher ? 'class_notes' : 'class_replies')
            .select('id, read_at').inFilter('id', unseen).not('read_at', 'is', null);
        if (!mounted || (rows as List).isEmpty) return;
        final read = {for (final r in rows) r['id'] as String: r['read_at'] as String};
        setState(() { for (final m in _messages!) { if (read[m.id] != null) m.readAt = read[m.id]; } });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    final me = currentUser;
    if (body.isEmpty || _state == 'sending' || me == null) return;
    setState(() => _state = 'sending');
    try {
      if (widget.asTeacher) {
        await supabase.from('class_notes').insert({
          'class_id': widget.classId, 'student_id': widget.studentId, 'teacher_id': me.id,
          'message': body.length > _teacherMax ? body.substring(0, _teacherMax) : body,
        });
      } else {
        await supabase.from('class_replies').insert({
          'class_id': widget.classId, 'student_id': widget.studentId,
          'message': body.length > _studentMax ? body.substring(0, _studentMax) : body,
        });
      }
    } catch (e) {
      if (mounted) setState(() => _state = e.toString().contains('daily_message_limit') ? 'limit' : 'failed');
      return;
    }
    _ctrl.clear();
    if (mounted) setState(() => _state = 'idle');
    try { _merge(await _loadThread(widget.classId, widget.studentId, _last)); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    return Column(children: [
      Expanded(
        child: messages == null
            ? Center(child: CircularProgressIndicator(color: context.primary))
            : messages.isEmpty
                ? Center(child: Text(tr('chat_empty'), style: TextStyle(color: context.textMuted, fontSize: 13)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _bubble(messages[i]),
                  ),
      ),
      if (widget.canSend) _composer(),
    ]);
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.fromTeacher == widget.asTeacher;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? context.primary : context.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 6), bottomRight: Radius.circular(mine ? 6 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine)
            Padding(padding: const EdgeInsets.only(bottom: 2),
              child: Text(widget.otherName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textMuted))),
          Text(m.message, style: TextStyle(fontSize: 14, color: mine ? Colors.white : context.appText)),
          const SizedBox(height: 2),
          Align(alignment: Alignment.centerRight, child: Text(
            '${_timeLabel(m.createdAt)}${mine && m.readAt != null ? ' · ${tr('chat_seen')}' : ''}',
            style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : context.textMuted),
          )),
        ]),
      ),
    );
  }

  Widget _composer() {
    final hint = _state == 'limit' ? tr('chat_limit_reached') : _state == 'failed' ? tr('chat_send_failed') : tr('chat_updates_hint');
    final hintColor = _state == 'limit' || _state == 'failed' ? const Color(0xFFEF4444) : context.textMuted;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.border))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: _ctrl,
              minLines: 1, maxLines: 5, maxLength: _max,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              onChanged: (_) => setState(() { if (_state != 'sending') _state = 'idle'; }),
              style: TextStyle(fontSize: 14, color: context.appText),
              decoration: InputDecoration(
                hintText: tr('chat_placeholder'),
                hintStyle: TextStyle(color: context.textMuted),
                filled: true, fillColor: context.surface2, isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
              ),
            )),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _ctrl.text.trim().isEmpty || _state == 'sending' ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(tr('chat_send'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Text(hint, style: TextStyle(fontSize: 10, color: hintColor))),
            Text('${_ctrl.text.length}/$_max', style: TextStyle(fontSize: 10, color: context.textMuted)),
          ]),
        ]),
      ),
    );
  }
}

/// Student: the conversation with this class's teacher. Teacher notes are
/// part of it; writing back needs the teacher to have chat on for the class.
class ClassChatScreen extends StatelessWidget {
  final String classId, teacherName;
  final bool chatEnabled;
  const ClassChatScreen({super.key, required this.classId, required this.teacherName, required this.chatEnabled});

  @override
  Widget build(BuildContext context) {
    final me = currentUser;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: context.primary),
        title: Text('💬 ${tr('chat_with_teacher')}', style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 17)),
      ),
      body: me == null ? const SizedBox() : Column(children: [
        if (!chatEnabled)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(tr('chat_off_student'), style: TextStyle(fontSize: 12, color: context.textMuted))),
        Expanded(child: ChatThread(classId: classId, studentId: me.id, asTeacher: false, canSend: chatEnabled, otherName: teacherName)),
      ]),
    );
  }
}

/// Teacher: every student's conversation and the class's chat on/off
/// switch. The teacher can always write (that's a teacher note); students
/// can only write back when chat is on.
class ClassMessagesScreen extends StatefulWidget {
  final String classId;
  const ClassMessagesScreen({super.key, required this.classId});

  @override
  State<ClassMessagesScreen> createState() => _ClassMessagesScreenState();
}

class _InboxEntry {
  ChatMessage? last;
  int unread = 0;
}

class _ClassMessagesScreenState extends State<ClassMessagesScreen> {
  bool _loading = true;
  bool _enabled = false;
  bool _toggling = false;
  Map<String, String> _names = {};
  Map<String, _InboxEntry> _inbox = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) _loadInbox();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait<dynamic>([
        supabase.from('classes').select('chat_enabled').eq('id', widget.classId).maybeSingle(),
        supabase.rpc('get_class_dashboard', params: {'p_class_id': widget.classId}),
        supabase.from('class_members').select('student_id').eq('class_id', widget.classId).eq('status', 'approved'),
      ]);
      final approved = {for (final m in res[2] as List) (m as Map)['student_id'] as String};
      _enabled = (res[0] as Map?)?['chat_enabled'] == true;
      _names = {
        for (final m in res[1] as List)
          if (approved.contains((m as Map)['student_id'])) m['student_id'] as String: (m['name'] as String?) ?? '',
      };
      await _loadInbox();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // Last message and unread student messages per student.
  Future<void> _loadInbox() async {
    try {
      final res = await Future.wait([
        supabase.from('class_notes').select('id, student_id, message, created_at, read_at')
            .eq('class_id', widget.classId).order('created_at', ascending: false).limit(300),
        supabase.from('class_replies').select('id, student_id, message, created_at, read_at')
            .eq('class_id', widget.classId).order('created_at', ascending: false).limit(300),
      ]);
      final out = <String, _InboxEntry>{};
      void add(Map r, bool fromTeacher) {
        final e = out.putIfAbsent(r['student_id'] as String, _InboxEntry.new);
        final created = r['created_at'] as String;
        if (e.last == null || created.compareTo(e.last!.createdAt) > 0) {
          e.last = ChatMessage(r['id'] as String, fromTeacher, r['message'] as String? ?? '', created, r['read_at'] as String?);
        }
        if (!fromTeacher && r['read_at'] == null) e.unread++;
      }
      for (final r in res[0]) { add(r, true); }
      for (final r in res[1]) { add(r, false); }
      if (mounted) setState(() => _inbox = out);
    } catch (_) {}
  }

  Future<void> _toggle() async {
    setState(() => _toggling = true);
    try {
      await supabase.rpc('set_class_chat_enabled', params: {'p_class_id': widget.classId, 'p_enabled': !_enabled});
      _enabled = !_enabled;
    } catch (_) {}
    if (mounted) setState(() => _toggling = false);
  }

  String _nameOf(String sid) => (_names[sid] ?? '').isNotEmpty ? _names[sid]! : tr('student');

  void _open(String sid) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: context.primary),
        title: Text('💬 ${_nameOf(sid)}', style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 17)),
      ),
      body: Column(children: [
        if (!_enabled)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(tr('chat_off_hint'), style: TextStyle(fontSize: 12, color: context.textMuted))),
        Expanded(child: ChatThread(classId: widget.classId, studentId: sid, asTeacher: true, canSend: true, otherName: _nameOf(sid))),
      ]),
    )));
    _loadInbox();
  }

  @override
  Widget build(BuildContext context) {
    final ids = _names.keys.toList()..sort((a, b) {
      final ea = _inbox[a], eb = _inbox[b];
      final byUnread = (eb?.unread ?? 0).compareTo(ea?.unread ?? 0);
      if (byUnread != 0) return byUnread;
      final byLast = (eb?.last?.createdAt ?? '').compareTo(ea?.last?.createdAt ?? '');
      if (byLast != 0) return byLast;
      return _nameOf(a).compareTo(_nameOf(b));
    });
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: context.primary),
        title: Text('💬 ${tr('chat_title')}', style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 17)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.border)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_enabled ? tr('chat_enabled') : tr('chat_disabled'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _enabled ? const Color(0xFF22C55E) : context.appText)),
                    if (!_enabled) ...[
                      const SizedBox(height: 2),
                      Text(tr('chat_off_hint'), style: TextStyle(fontSize: 12, color: context.textMuted)),
                    ],
                  ])),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _toggling ? null : _toggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _enabled ? context.surface2 : context.primary,
                      foregroundColor: _enabled ? context.appText : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_enabled ? tr('chat_turn_off') : tr('chat_turn_on'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              if (ids.isEmpty)
                Text(tr('chat_no_students'), style: TextStyle(fontSize: 13, color: context.textMuted))
              else
                Container(
                  decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.border)),
                  child: Column(children: [
                    for (var i = 0; i < ids.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: context.border),
                      _studentRow(ids[i]),
                    ],
                  ]),
                ),
            ]),
    );
  }

  Widget _studentRow(String sid) {
    final e = _inbox[sid];
    final unread = e?.unread ?? 0;
    return InkWell(
      onTap: () => _open(sid),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_nameOf(sid), overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.bold, color: context.appText)),
            if (e?.last != null)
              Text('${e!.last!.fromTeacher ? '${tr('you_badge')}: ' : ''}${e.last!.message}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
          ])),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 6),
          Text('›', style: TextStyle(color: context.textMuted)),
        ]),
      ),
    );
  }
}
