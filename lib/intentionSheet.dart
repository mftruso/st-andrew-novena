import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens a bottom sheet to edit the prayer intention. Saving or clearing
/// writes the `intention` pref and returns the new value; dismissing the sheet
/// any other way returns null and changes nothing.
Future<String?> showIntentionSheet(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => IntentionSheet(current: current),
  );
}

class IntentionSheet extends StatefulWidget {
  IntentionSheet({Key? key, required this.current}) : super(key: key);
  final String current;

  @override
  _IntentionSheetState createState() => _IntentionSheetState();
}

class _IntentionSheetState extends State<IntentionSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final intention = _controller.text;
    final prefs = await SharedPreferences.getInstance();
    // stored as typed; blank means unset
    if (intention.trim().isEmpty) {
      await prefs.remove('intention');
    } else {
      await prefs.setString('intention', intention);
    }
    if (mounted) Navigator.pop(context, intention);
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('intention');
    if (mounted) Navigator.pop(context, '');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // sits above the keyboard, and scrolls when large text doesn't fit
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Your intention', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. for my family\'s health',
                  helperText: 'Saved only on this device.',
                  helperMaxLines: 3,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              // wraps onto more lines rather than overflowing at large text
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  if (widget.current.trim().isNotEmpty)
                    TextButton(onPressed: _clear, child: const Text('Clear')),
                  // the theme's FilledButton is the full-width Amen button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 40),
                      textStyle: textTheme.labelLarge,
                    ),
                    onPressed: _save,
                    child: const Text('Save'),
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
