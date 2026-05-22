import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/api_client.dart';
import '../bloc/call_bloc.dart';

class PostCallPage extends StatefulWidget {
  const PostCallPage({super.key, required this.endedState});
  final CallEnded endedState;

  @override
  State<PostCallPage> createState() => _PostCallPageState();
}

class _PostCallPageState extends State<PostCallPage> {
  int? _rating;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isTrainer => widget.endedState.userId == widget.endedState.trainerId;

  String get _durationLabel {
    final m = widget.endedState.durationSec ~/ 60;
    final s = widget.endedState.durationSec % 60;
    return '${m}m ${s}s';
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final api = context.read<ApiClient>();

    final body = <String, dynamic>{};
    if (_isTrainer) {
      if (_notesCtrl.text.trim().isNotEmpty) {
        body['trainerNotes'] = _notesCtrl.text.trim();
      }
    } else {
      if (_rating != null) body['rating'] = _rating;
      if (_notesCtrl.text.trim().isNotEmpty) {
        body['memberNotes'] = _notesCtrl.text.trim();
      }
    }

    if (body.isNotEmpty) {
      await api.patch(
        '/session-logs/${widget.endedState.sessionLogId}',
        body: body,
      );
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _submitted,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Session Complete'),
          automaticallyImplyLeading: false,
        ),
        body: _submitted ? _buildDone(context) : _buildForm(context),
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Session saved to your logs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: $_durationLabel',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                // Pop back to root — pop twice (post_call + in_call already replaced pre_join)
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.videocam_rounded, size: 48, color: Colors.black38),
                const SizedBox(height: 8),
                Text(
                  'Call ended',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Duration: $_durationLabel',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (!_isTrainer) ...[
            Text('How was the session?',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _StarRating(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            _isTrainer ? 'Session notes' : 'Add a note (optional)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: _isTrainer
                  ? 'Notes for this session…'
                  : 'Share your thoughts…',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isTrainer ? 'Mark as complete' : 'Submit'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting
                ? null
                : () {
                    setState(() => _submitted = true);
                  },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, required this.onChanged});
  final int? value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              star <= (value ?? 0) ? Icons.star : Icons.star_border,
              size: 36,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }
}
