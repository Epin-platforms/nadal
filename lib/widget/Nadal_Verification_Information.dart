import 'package:animate_do/animate_do.dart';

import '../manager/project/Import_Manager.dart';

class NadalVerificationInformation extends StatelessWidget {
  const NadalVerificationInformation({super.key, this.isVerification = true});
  final bool isVerification;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      from: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isVerification ? Colors.green.shade50 : Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isVerification ? Colors.green : Colors.redAccent),
        ),
        child: Row(
          children: [
            Icon(isVerification ? Icons.verified : Icons.block_outlined, color: isVerification ? Colors.green : Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(isVerification ? '프로필 인증을 마쳤어요.' : '프로필 인증이 필요해요', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: isVerification ? Colors.green.shade800 : Colors.redAccent.shade700),))
          ],
        ),
      ),
    );
  }
}
