import 'package:flutter/cupertino.dart';
import '../../../manager/project/Import_Manager.dart';

class GetLocal extends StatelessWidget {
  const GetLocal({super.key, required this.local, required this.onTap});
  final String local;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NadalSolidContainer(
      onTap: onTap,
      padding: EdgeInsets.only(left: 12, right: 2),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(local.isEmpty ? '지역 선택' : local, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:  local.isEmpty ? Theme.of(context).hintColor : null
          ),),
          Icon(CupertinoIcons.forward, size: 20, color: Theme.of(context).hintColor,),
        ],
      ),
    );
  }
}

