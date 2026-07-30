import 'package:flutter/material.dart';
import 'Styles/stilo.dart';

class ModernBadge extends StatelessWidget {
  final bool isDot;
  final int count;
  const ModernBadge({required this.count, this.isDot = true, super.key});
  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    
    // Si es un simple punto rojo, como pide el boceto:
    if (isDot) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ModernTabBar extends StatelessWidget {
  final TabController controller;
  final int waitCount;
  final int inProgressCount;
  final int completedCount;
  final Color mainColor;

  const ModernTabBar({
    super.key,
    required this.controller,
    required this.waitCount,
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
        color: mainColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      labelColor: mainColor,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      tabs: [
        _buildTab(
          icon: Icons.hourglass_empty_rounded,
          text: 'En espera',
          count: waitCount,
        ),
        _buildTab(
          icon: Icons.construction_rounded,
          text: 'En proceso',
          count: inProgressCount,
        ),
        _buildTab(
          icon: Icons.check_circle_outline_rounded,
          text: 'Finalizados',
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
          double iconSize = width > 90 ? 24 : 20;
          double fontSize = width > 90 ? 13 : 11;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: iconSize),
                  if (count > 0)
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: ModernBadge(count: 1, isDot: true),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, height: 1.1),
              ),
            ],
          );
        },
      ),
    );
  }
}