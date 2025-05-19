import 'package:flutter/cupertino.dart';
import '../../../manager/project/Import_Manager.dart';
import '../../../widget/Nadal_Container.dart';

class GetCity extends StatelessWidget {
  const GetCity({super.key, required this.city, required this.onTap, required this.local, });
  final String city;
  final String local;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return  NadalSolidContainer(
      onTap: onTap,
      padding: EdgeInsets.only(left: 12, right: 2),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(city.isEmpty ? '시/구/군 선택' : city,style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: city.isEmpty ? Theme.of(context).hintColor : null
          ),),
          Icon(CupertinoIcons.forward, size: 20, color: Theme.of(context).hintColor,),
        ],
      ),
    );
  }
}
