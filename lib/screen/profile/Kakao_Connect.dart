import 'package:animate_do/animate_do.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/auth/profile/Kakao_Provider.dart';

import '../../manager/project/Import_Manager.dart';

class KakaoConnect extends StatefulWidget {
  const KakaoConnect({super.key});

  @override
  State<KakaoConnect> createState() => _KakaoConnectState();
}

class _KakaoConnectState extends State<KakaoConnect> {
  late UserProvider userProvider;

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user!;
    return ChangeNotifierProvider(
      create: (_)=> KakaoProvider(user),
      builder: (context, child) {
        final provider = Provider.of<KakaoProvider>(context);
        final isConnected = provider.kakaoId != null ? true : provider.originUser?['verificationCode'] != null ? true : false;
        return IosPopGesture(
          child: Scaffold(
             appBar: NadalAppbar(
               title: '카카오 연결',
             ),
            body: SafeArea(child: Column(
              children: [
                SizedBox(height: 40,),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ElasticIn(
                        child: Icon(
                          isConnected ? BootstrapIcons.person_fill_check : BootstrapIcons.person_fill_exclamation,
                          color: isConnected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                          size: 50,
                        ),
                      ),
                      SizedBox(width: 8,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${user['name']}님은 카카오 계정이', style: Theme.of(context).textTheme.titleLarge,),
                          Text( isConnected ? '연결되어 있어요' : '아직 연결되지 않았어요' , style: Theme.of(context).textTheme.titleLarge,),
                        ],
                      ),
                    ],
                  ),
                ),

                if(isConnected)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24,),
                      Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('카카오 가입자가 아니라면 이메일을 변경할 수 없어요.', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.secondary),)),
                      NadalReadOnlyContainer(label: '이메일', value: user['email']),
                      SizedBox(height: 16,),
                      NadalReadOnlyContainer(label: '이름', value: user['name']),
                      SizedBox(height: 16,),
                      NadalReadOnlyContainer(label: '출생연도', value: '${user['birthYear']}'),
                      SizedBox(height: 16,),
                      NadalReadOnlyContainer(label: '성별', value: user['gender'] == 'M' ? '남자' : user['gender'] == 'F' ? '여자' : '알수없음'),
                      SizedBox(height: 16,),
                      NadalReadOnlyContainer(label: '연락처', value: '${user['phone'] ?? '없음'}'),
                    ],
                  ),
                )
                else
                  Expanded(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                height: 200, width: 200,
                                child: Image.asset("assets/image/social/kakao_disconnect.png", color: Theme.of(context).colorScheme.secondary,)),
                            Text('지금 카카오를 연결해보세요', style: Theme.of(context).textTheme.titleLarge,),
                            SizedBox(height: 16,),
                            Text('카카오로 간편 연결하고,\n본인 기반 활동과 채팅방을 자유롭게 이용해보세요!', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
                            SizedBox(height: 60,)
                          ],
                        )
                    ),
                  ),
                if(isConnected)
                Spacer(),
                NadalButton(
                    onPressed: isConnected ? (){
                      //다시 불러오기
                      provider.resetKakao();
                    } : (){
                      provider.getKakao();
                    },
                    isActive: true, title: isConnected ? '다시 불러오기' : '카카오 연결하기')
              ],
            )),
          ),
        );
      }
    );
  }
}

