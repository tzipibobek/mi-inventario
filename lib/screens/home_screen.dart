import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../state/inventory_store.dart';
import '../widgets/inventory_logo.dart';
import 'inventory_screen.dart';
import 'movements_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final InventoryStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _expandedTitle;

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();

    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _expandedTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store.settingsListenable,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = widget.store.settings.title;
        final theme = Theme.of(context);
        final style =
            theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge!;
        final padding = MediaQuery.paddingOf(context);

        const leadingWidth = 56.0;
        const spacing = 16.0;
        const arrowWidth = 32.0;

        final width =
            (constraints.maxWidth -
                    padding.horizontal -
                    leadingWidth -
                    2 * spacing)
                .clamp(1.0, double.infinity)
                .toDouble();

        final measure = TextPainter(
          text: TextSpan(text: title, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        )..layout(maxWidth: width);

        final overflows = measure.computeLineMetrics().length > 1;
        final expanded = overflows && _expandedTitle == title;

        if (expanded) {
          measure.layout(
            maxWidth: (width - arrowWidth).clamp(1.0, width).toDouble(),
          );
        }

        final textHeight = expanded
            ? measure.height
            : measure.preferredLineHeight;

        final titleLines = expanded ? measure.computeLineMetrics().length : 1;

        measure.dispose();

        final label = Text(
          title,
          softWrap: expanded,
          maxLines: titleLines,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        );

        return Scaffold(
          appBar: AppBar(
            leadingWidth: leadingWidth,
            titleSpacing: spacing,
            toolbarHeight: (textHeight.ceilToDouble() + 16)
                .clamp(kToolbarHeight, double.infinity)
                .toDouble(),
            leading: const Center(child: InventoryLogo()),
            title: overflows
                ? Semantics(
                    button: true,
                    expanded: expanded,
                    hint: expanded
                        ? 'Contraer nombre'
                        : 'Mostrar nombre completo',
                    child: InkWell(
                      onTap: () => setState(
                        () => _expandedTitle = expanded ? null : title,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            Expanded(child: label),
                            SizedBox(
                              width: arrowWidth,
                              child: Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : label,
          ),
          resizeToAvoidBottomInset: false,
          body: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (expanded &&
                  notification.metrics.axis == Axis.vertical &&
                  notification.direction != ScrollDirection.idle) {
                setState(() => _expandedTitle = null);
              }

              return false;
            },
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                InventoryScreen(
                  store: widget.store,
                  onCustomize: () => _selectTab(3),
                ),
                MovementsScreen(store: widget.store),
                SummaryScreen(store: widget.store),
                SettingsScreen(store: widget.store),
              ],
            ),
          ),
          bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectTab,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      label: 'Inventario',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.swap_horiz_rounded),
                      label: 'Movimientos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_rounded),
                      label: 'Resumen',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Ajustes',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
