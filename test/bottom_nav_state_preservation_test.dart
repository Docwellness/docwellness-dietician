// AI_EXECUTION_PLAN.md Phase 8, P8-02 - bottom navigation state
// preservation. bottom_navi_bar.dart's real BottomNaviBar depends on
// Get.put(HomeController()) (network services, GetX bindings, etc.), which
// isn't practical or desirable to stand up in a widget test. This exercises
// the exact lazy-build-then-IndexedStack mechanism it now uses (see
// bottom_navi_bar.dart's _screenAt/_screens, converted from a plain
// `screens[index]` lookup that rebuilt every tab from scratch on every
// switch) in an isolated harness: a tab's widget is only constructed the
// first time it's selected, and - this is the actual behavior being
// verified - switching away and back preserves that widget's State (a
// counter here) instead of resetting it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterTab extends StatefulWidget {
  final int index;
  final VoidCallback onBuilt;
  const _CounterTab({required this.index, required this.onBuilt});

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    widget.onBuilt();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Tab ${widget.index}: $count'),
        TextButton(
          onPressed: () => setState(() => count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _LazyIndexedStackNav extends StatefulWidget {
  const _LazyIndexedStackNav();

  @override
  State<_LazyIndexedStackNav> createState() => _LazyIndexedStackNavState();
}

class _LazyIndexedStackNavState extends State<_LazyIndexedStackNav> {
  int selectedIndex = 0;
  final List<Widget?> _screens = List<Widget?>.filled(5, null);
  final Set<int> builtIndices = {};

  Widget _screenAt(int index) {
    return _screens[index] ??= _CounterTab(
      index: index,
      onBuilt: () => builtIndices.add(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: List.generate(_screens.length, (index) {
          if (index != selectedIndex && _screens[index] == null) {
            return const SizedBox.shrink();
          }
          return _screenAt(index);
        }),
      ),
      bottomNavigationBar: Row(
        children: List.generate(
          5,
          (index) => TextButton(
            onPressed: () => setState(() => selectedIndex = index),
            child: Text('Tab $index'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'switching tabs preserves each tab\'s state instead of rebuilding it',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _LazyIndexedStackNav()),
      );

      // Only the initially-selected tab (0, Home) is built - matches
      // BottomNaviBar never eagerly building unvisited tabs (Patients,
      // Diet & Exercise, Performance, Chat).
      final state = tester.state<_LazyIndexedStackNavState>(
        find.byType(_LazyIndexedStackNav),
      );
      expect(state.builtIndices, {0});

      // Increment tab 0's counter.
      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('Tab 0: 1'), findsOneWidget);

      // Switch to tab 1 (Patients) - lazily builds it for the first time.
      await tester.tap(find.text('Tab 1'));
      await tester.pump();
      expect(state.builtIndices, {0, 1});
      expect(find.text('Tab 1: 0'), findsOneWidget);

      // Switch back to tab 0 - its counter must still read 1, not have
      // been reset by a rebuild.
      await tester.tap(find.text('Tab 0'));
      await tester.pump();
      expect(find.text('Tab 0: 1'), findsOneWidget);

      // Tabs 2-4 were never visited, so they were never built.
      expect(state.builtIndices, {0, 1});
    },
  );
}
