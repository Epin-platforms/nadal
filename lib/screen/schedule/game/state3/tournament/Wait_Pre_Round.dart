
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WaitPreRound extends StatelessWidget {
  const WaitPreRound({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return  Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.lock_circle, size: 24, color: theme.hintColor,),
          SizedBox(width: 4,),
          Text('전 라운드 진행중...', style: TextStyle(fontSize: 11, color: theme.hintColor),)
        ],
      ),
    );
  }
}
