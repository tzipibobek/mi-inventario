import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Marca decorativa: caja con lista, sin fondo y con el color del contexto.
class InventoryLogo extends StatelessWidget {
  const InventoryLogo({super.key, this.size = 28, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      'assets/inventory_logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
