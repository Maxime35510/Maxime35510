import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../history/presentation/viewmodels/history_providers.dart';

/// Search across captions, titles and hashtags.
///
/// Input is debounced so a fast typist does not re-filter the list on every
/// keystroke; the field itself stays fully responsive because the controller
/// is local and only the query provider is deferred.
class HistorySearchField extends ConsumerStatefulWidget {
  const HistorySearchField({super.key});

  @override
  ConsumerState<HistorySearchField> createState() => _HistorySearchFieldState();
}

class _HistorySearchFieldState extends ConsumerState<HistorySearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(historyQueryProvider));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(MotionConstants.searchDebounce, () {
      if (mounted) ref.read(historyQueryProvider.notifier).state = value;
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(historyQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      onChanged: (value) {
        _onChanged(value);
        // Rebuild only to toggle the clear affordance.
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.historySearchHint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: hasText
            ? IconButton(
                tooltip: context.l10n.actionClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: _clear,
              )
            : null,
      ),
    );
  }
}
