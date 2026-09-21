import 'package:flutter/material.dart';

import '../models/linger_models.dart';
import '../services/linger_controller.dart';
import '../services/motion_sensor.dart';

class LingerHomePage extends StatelessWidget {
  final LingerController controller;
  final DemoMotionSensor demoSensor;

  const LingerHomePage({
    super.key,
    required this.controller,
    required this.demoSensor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final stateColor = _stateColor(controller.state);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Linger'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _SessionBadge(
                  isRunning: controller.isSessionRunning,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 720
                    ? 720.0
                    : constraints.maxWidth;
                return Center(
                  child: SizedBox(
                    width: width,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        Text(
                          'Keep the flame alive.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A local-first motion session scaffold. The demo input below stands in for native sensors until the platform adapters are added.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 24),
                        _StatusPanel(
                          state: controller.state,
                          stateColor: stateColor,
                          graceRemaining: controller.graceRemaining,
                        ),
                        const SizedBox(height: 14),
                        _MetricsPanel(
                          controller: controller,
                        ),
                        const SizedBox(height: 22),
                        _SectionLabel(
                          title: 'Demo sensor',
                          detail: demoSensor.condition.label,
                        ),
                        const SizedBox(height: 10),
                        _DemoConditionPicker(
                          selected: demoSensor.condition,
                          onChanged: demoSensor.setCondition,
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: controller.toggleSession,
                          icon: Icon(
                            controller.isSessionRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            controller.isSessionRunning
                                ? 'Stop session'
                                : 'Start session',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: controller.isSessionRunning
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _SectionLabel(title: 'Event log'),
                        const SizedBox(height: 10),
                        _EventLog(events: controller.events),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color _stateColor(LingerState state) {
    switch (state) {
      case LingerState.burning:
        return const Color(0xFFD95F39);
      case LingerState.warning:
        return const Color(0xFFC4871A);
      case LingerState.paused:
        return const Color(0xFF397A91);
      case LingerState.extinguished:
        return const Color(0xFF68747A);
    }
  }
}

class _SessionBadge extends StatelessWidget {
  final bool isRunning;

  const _SessionBadge({required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final color = isRunning
        ? const Color(0xFF26734D)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 7),
        Text(
          isRunning ? 'LIVE' : 'READY',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final LingerState state;
  final Color stateColor;
  final int graceRemaining;

  const _StatusPanel({
    required this.state,
    required this.stateColor,
    required this.graceRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (state) {
      LingerState.burning => Icons.local_fire_department_rounded,
      LingerState.warning => Icons.warning_amber_rounded,
      LingerState.paused => Icons.pause_circle_outline_rounded,
      LingerState.extinguished => Icons.air_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stateColor.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: stateColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: stateColor),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.label,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: stateColor, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  state.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                if (state == LingerState.warning) ...[
                  const SizedBox(height: 10),
                  Text(
                    '$graceRemaining seconds remaining',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: stateColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  final LingerController controller;

  const _MetricsPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sample = controller.latestSample;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'Lifecycle',
              value: controller.lifecycle.label,
            ),
          ),
          Expanded(
            child: _Metric(
              label: 'Orientation',
              value: sample.orientation.label,
            ),
          ),
          Expanded(
            child: _Metric(
              label: 'Motion',
              value: sample.motionMagnitude.toStringAsFixed(3),
              detail: sample.isMoving ? 'Moving' : 'Still',
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;

  const _Metric({
    required this.label,
    required this.value,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (detail != null)
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? detail;

  const _SectionLabel({required this.title, this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (detail != null) ...[
          const Spacer(),
          Text(
            detail!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _DemoConditionPicker extends StatelessWidget {
  final DemoSensorCondition selected;
  final ValueChanged<DemoSensorCondition> onChanged;

  const _DemoConditionPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DemoSensorCondition.values.map((condition) {
        return ChoiceChip(
          avatar: Icon(
            condition == DemoSensorCondition.steady
                ? Icons.vertical_align_bottom_rounded
                : Icons.pan_tool_alt_rounded,
            size: 18,
          ),
          label: Text(condition.label),
          selected: condition == selected,
          onSelected: (_) => onChanged(condition),
        );
      }).toList(),
    );
  }
}

class _EventLog extends StatelessWidget {
  final List<LingerEvent> events;

  const _EventLog({required this.events});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 238,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: events.isEmpty
          ? Center(
              child: Text(
                'Events will appear here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: colorScheme.outlineVariant.withAlpha(100),
              ),
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  dense: true,
                  leading: Text(
                    _formatTime(event.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  title: Text(
                    event.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
