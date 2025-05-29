import '../manager/project/Import_Manager.dart';

class NadalIconButton extends StatelessWidget {
  const NadalIconButton({super.key, this.icon, this.size, required this.onTap, this.image});
  final IconData? icon;
  final String? image;
  final double? size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: CircleBorder(),
      overlayColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      child: Padding(
          padding: EdgeInsets.all(4),
          child:
          icon != null ?
          Icon(icon, size: size ?? 24.r, color: Theme.of(context).colorScheme.onSurface,) :
          Image.asset(image!, color: Theme.of(context).colorScheme.onSurface, height: size ?? 24.r, width: size ?? 24.r, fit: BoxFit.cover,)
      ),
    );
  }
}

class NadalReportIcon extends StatelessWidget {
  const NadalReportIcon({super.key, this.onTap, this.size, this.color});
  final VoidCallback? onTap;
  final double? size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return  InkWell(
      onTap: onTap,
      customBorder: CircleBorder(),
      overlayColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Image.asset('assets/image/icon/siren.png', height: size ?? 24.r, width: size ?? 24.r,
            color: color ?? Theme.of(context).colorScheme.onSurface,
            colorBlendMode: BlendMode.srcIn,)
      ),
    );
  }
}

