import 'package:my_sports_calendar/provider/auth/profile/My_Profile_Provider.dart';


import '../../../manager/project/Import_Manager.dart';

class MyProfileCard extends StatefulWidget {
  const MyProfileCard({super.key, required this.provider});
  final MyProfileProvider provider;

  @override
  State<MyProfileCard> createState() => _MyProfileCardState();
}

class _MyProfileCardState extends State<MyProfileCard> {
  late UserProvider userProvider;

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user!;
    final theme = Theme.of(context);
    final double size = 40;
    final double columnSize = 44;
    final num level = user['level'];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          InkWell(
              borderRadius: BorderRadius.circular(50),
              child: NadalProfileFrame(imageUrl: user['profileImage'], size: 70,)),
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              children: [
                Text(user['name'],style: theme.textTheme.bodyLarge),
                Text('${user['roomName'] ?? '대표 클럽이 아직 없어요'}', style: theme.textTheme.bodySmall,)
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: columnSize,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: size, width: size,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          ),
                          child: Text(level.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w700, fontSize: size/2.5, height: 1),),
                        ),
                        Positioned(
                            top: 0, left: 0, right: 0, bottom: 0,
                            child: CircularProgressIndicator(
                              value: level/10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              strokeWidth: 5,
                              color: Theme.of(context).colorScheme.primary,
                            ))
                      ],
                    ),
                    SizedBox(height: 4,),
                    Text('레벨',  style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              SizedBox(
                width: columnSize,
                child: Column(
                  children: [
                    Container(
                      height: size, width: size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
                      ),
                      padding: EdgeInsets.all(size/4),
                      child: FittedBox(child: Text(AuthFormManager.careerDateToYearText(user['career']), style: theme.textTheme.bodyMedium,))
                    ),
                    SizedBox(height: 4,),
                    Text('구력',  style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              SizedBox(
                width: columnSize,
                child: Column(
                  children: [
                    NadalGenderIcon(gender: user['gender'], size: size,),
                    SizedBox(height: 4),
                    Text('성별',  style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              SizedBox(
                width: columnSize,
                child: Column(
                  children: [
                    NadalVerification(isConnected: user['verificationCode'] != null),
                    SizedBox(height: 4),
                    Text( user['verificationCode'] != null ? '인증완료' : '인증필요',  style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
