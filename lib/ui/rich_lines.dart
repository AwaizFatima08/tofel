import 'package:flutter/material.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Renders lesson and guide bodies: `## heading`, `- bullet`, `> example` (consecutive lines form one
/// box), `! tip`, or a paragraph.
class RichLines extends StatelessWidget {
  const RichLines(this.lines, {super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var example = <String>[];
    void flush() {
      if (example.isEmpty) return;
      children.add(_Box(lines: example, tip: false));
      example = [];
    }

    for (final line in lines) {
      if (line.startsWith('> ') || line == '>') {
        example.add(line.length > 2 ? line.substring(2) : '');
        continue;
      }
      flush();
      children.add(_line(context, line));
    }
    flush();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _line(BuildContext context, String line) {
    final theme = Theme.of(context).textTheme;
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.md, bottom: AppSpacing.xs),
        child: Text(line.substring(3), style: theme.titleMedium),
      );
    }
    if (line.startsWith('! ')) return _Box(lines: [line.substring(2)], tip: true);
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: Text(line.substring(2), style: const TextStyle(height: 1.45))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Text(line, style: const TextStyle(height: 1.45)),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.lines, required this.tip});

  final List<String> lines;
  final bool tip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tip ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: BorderDirectional(
          start: BorderSide(color: tip ? AppColors.amber : scheme.primary, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tip) ...[
            const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.amber),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Text(
                    line,
                    style: TextStyle(
                      height: 1.45,
                      color: tip ? scheme.onTertiaryContainer : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
