import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../state/inventory_store.dart';
import '../widgets/inventory_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final InventoryStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late int _selectedColorIndex;
  late ThemeMode _selectedThemeMode;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final settings = widget.store.settings;
    _titleController = TextEditingController(text: settings.title);
    _selectedColorIndex = settings.colorIndex;
    _selectedThemeMode = settings.themeMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.store.saveSettings(
        AppSettings(
          title: _titleController.text.trim(),
          colorIndex: _selectedColorIndex,
          themeMode: _selectedThemeMode,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ajustes guardados')));
      }
    } catch (error, stackTrace) {
      debugPrint('No se pudieron guardar los ajustes: $error\n$stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudieron guardar los ajustes.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: const Text('Ajustes'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            onChanged: (_) => setState(() {}),
            controller: _titleController,
            enabled: !_isSaving,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Nombre del inventario',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribí un nombre.'
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Color principal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (
                var colorIndex = 0;
                colorIndex < appColors.length;
                colorIndex++
              )
                IconButton.filled(
                  tooltip: const [
                    'Terracota',
                    'Azul',
                    'Verde',
                    'Violeta',
                  ][colorIndex],
                  isSelected: _selectedColorIndex == colorIndex,
                  style: IconButton.styleFrom(
                    backgroundColor: appColors[colorIndex],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                          _selectedColorIndex = colorIndex;
                        }),
                  icon: Icon(
                    _selectedColorIndex == colorIndex
                        ? Icons.check
                        : Icons.circle_outlined,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Apariencia', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in ThemeMode.values)
                ChoiceChip(
                  label: Text(_themeModeLabel(mode)),
                  selected: _selectedThemeMode == mode,
                  onSelected: _isSaving
                      ? null
                      : (_) => setState(() => _selectedThemeMode = mode),
                ),
            ],
          ),
          const SizedBox(height: 28),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Text('Vista previa'),
          Card(
            color: appColors[_selectedColorIndex],
            child: ListTile(
              leading: const InventoryLogo(color: Colors.white),
              title: Text(
                _titleController.text.trim().isEmpty
                    ? 'Mi inventario'
                    : _titleController.text.trim(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? 'Guardando…' : 'Guardar ajustes'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Los datos están en este dispositivo. No se sincronizan ni tienen copia de seguridad en la nube. Desinstalar la app elimina sus datos.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Este nombre aparece dentro de la app; no cambia el ícono ni el nombre instalado en el teléfono.',
          ),
        ],
      ),
    ),
  );
}
