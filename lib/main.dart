import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ble_scan_page.dart';
import 'iphone_preview.dart';

void main() {
  IPhone14ProPreview.applyPlatformOverride();
  runApp(
    IPhone14ProPreview.enabled
        ? const IPhone14ProPreview(child: DemoApp())
        : const DemoApp(),
  );
}

/// Name of the platform the app is currently running on.
String get platformName {
  if (kIsWeb) return 'Web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.windows => 'Windows',
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.fuchsia => 'Fuchsia',
  };
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 三平台範例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: HomeShell(
        dark: _dark,
        onDarkChanged: (v) => setState(() => _dark = v),
      ),
    );
  }
}

/// Responsive shell: bottom NavigationBar on narrow screens (phone),
/// side NavigationRail on wide screens (desktop / browser).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.dark, required this.onDarkChanged});

  final bool dark;
  final ValueChanged<bool> onDarkChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.add_circle_outline, label: '計數器'),
    (icon: Icons.list_alt, label: '待辦清單'),
    (icon: Icons.bluetooth, label: '藍牙'),
    (icon: Icons.settings_outlined, label: '設定'),
  ];

  @override
  Widget build(BuildContext context) {
    final page = switch (_index) {
      0 => const CounterPage(),
      1 => const TodoPage(),
      2 => const BleScanPage(),
      _ => SettingsPage(dark: widget.dark, onDarkChanged: widget.onDarkChanged),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        return Scaffold(
          appBar: AppBar(
            title: Text('Flutter 範例 · $platformName'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
              if (wide) const VerticalDivider(width: 1),
              Expanded(child: page),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(icon: Icon(d.icon), label: d.label),
                  ],
                ),
        );
      },
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('按了幾次', style: theme.textTheme.titleMedium),
          Text('$_count', style: theme.textTheme.displayLarge),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _count = 0),
                icon: const Icon(Icons.refresh),
                label: const Text('歸零'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => setState(() => _count++),
                icon: const Icon(Icons.add),
                label: const Text('加一'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _controller = TextEditingController();
  final _items = <({String text, bool done})>[
    (text: '安裝 Flutter SDK', done: true),
    (text: '跑起 Web 版', done: false),
    (text: '跑起 Windows 版', done: false),
  ];

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _items.add((text: text, done: false)));
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '新增待辦事項',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _add, child: const Text('新增')),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              return CheckboxListTile(
                value: item.done,
                title: Text(
                  item.text,
                  style: item.done
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                onChanged: (v) => setState(
                  () => _items[i] = (text: item.text, done: v ?? false),
                ),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.dark, required this.onDarkChanged});

  final bool dark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('深色模式'),
          value: dark,
          onChanged: onDarkChanged,
          secondary: const Icon(Icons.dark_mode_outlined),
        ),
        ListTile(
          leading: const Icon(Icons.devices),
          title: const Text('執行平台'),
          subtitle: Text(platformName),
        ),
        ListTile(
          leading: const Icon(Icons.aspect_ratio),
          title: const Text('視窗大小'),
          subtitle: Text('${size.width.round()} × ${size.height.round()}'),
        ),
      ],
    );
  }
}
