import 'package:bootstrap_icons/bootstrap_icons.dart';

import '../../manager/project/Import_Manager.dart';

class NadalBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const NadalBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.circle),
          activeIcon: Icon(BootstrapIcons.person_circle),
          label: 'MY',
        ),
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.lightning),
          activeIcon: Icon(BootstrapIcons.lightning_fill),
          label: '번개챗',
        ),
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.trophy),
          activeIcon: Icon(BootstrapIcons.trophy_fill),
          label: '대회',
        ),
        BottomNavigationBarItem(
          icon: Icon(BootstrapIcons.three_dots),
          activeIcon: Icon(BootstrapIcons.three_dots),
          label: '더보기',
        ),
      ],
    );
  }
}
