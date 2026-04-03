import 'package:flutter/material.dart';
import 'Styles/stilo.dart';

class ModernBadge extends StatelessWidget {
  final int count;
  final Color? color;
  const ModernBadge({required this.count, this.color, super.key});
  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        color: color ?? MyColors.badge,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: (color ?? MyColors.badge).withOpacity(0.10),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 12,
        minHeight: 12,
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ModernTabBar extends StatelessWidget {
  final TabController controller;
  final int availableCount;
  final int offerServiceCount;
  final int inProgressCount;
  final int completedCount;
  final Color mainColor;
  const ModernTabBar({
    super.key,
    required this.controller,
    required this.availableCount,
    required this.offerServiceCount,
    required this.inProgressCount,
    required this.completedCount,
    this.mainColor = MyColors.main,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: false,
      indicator: BoxDecoration(
        color: mainColor.withOpacity(0.15), // Un poco más visible
        borderRadius: BorderRadius.circular(12), // Bordes curveados
      ),
      labelColor: mainColor,
      unselectedLabelColor: Colors.black54,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
      tabs: [
        _buildTab(
          icon: Icons.task_alt_outlined,
          text: 'Disponibles',
          count: availableCount,
        ),
        _buildTab(
          icon: Icons.local_offer_outlined,
          text: 'Ofertados',
          count: offerServiceCount,
        ),
        _buildTab(
          icon: Icons.assignment_ind_outlined,
          text: 'Asignados',
          count: inProgressCount,
        ),
        _buildTab(
          icon: Icons.check_circle_outline,
          text: 'Completados',
          count: completedCount,
        ),
      ],
    );
  }

  Tab _buildTab(
      {required IconData icon, required String text, required int count}) {
    return Tab(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Ajusta el tamaño según el ancho disponible
          double iconSize = width > 90 ? 24 : (width > 70 ? 20 : 18);
          double fontSize = width > 90 ? 13 : (width > 70 ? 11 : 10);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: iconSize),
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: ModernBadge(count: count, color: mainColor),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize, height: 1.1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}