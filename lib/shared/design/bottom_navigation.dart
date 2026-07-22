import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppNavigationDestination {
  home('Главная', Icons.home_outlined, Icons.home_rounded),
  sessions('Серии', Icons.view_timeline_outlined, Icons.view_timeline_rounded),
  history('История', Icons.history_rounded, Icons.history_rounded),
  device(
    'Устройство',
    Icons.bluetooth_outlined,
    Icons.bluetooth_connected_rounded,
  );

  const AppNavigationDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  }) : assert(currentIndex >= 0 && currentIndex < 4);

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
            child: Row(
              children: [
                for (
                  var index = 0;
                  index < AppNavigationDestination.values.length;
                  index++
                )
                  Expanded(
                    child: _NavigationItem(
                      destination: AppNavigationDestination.values[index],
                      selected: index == currentIndex,
                      onTap: () => onTap(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.gps : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: selected ? AppColors.accentSubtle : Colors.transparent,
        borderRadius: AppRadii.smallBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: foreground,
                size: 20,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.navigation.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
