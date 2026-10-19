import 'dart:async';

/// Schedules Riverpod state writes outside the current widget build phase.
void deferProviderWrite(void Function() write) {
  scheduleMicrotask(write);
}
