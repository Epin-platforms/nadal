import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_sports_calendar/provider/auth/profile/Affiliation_Provider.dart';
import 'package:my_sports_calendar/widget/Overlab_Carousel.dart';

import '../../manager/project/Import_Manager.dart';

class AffiliationEdit extends StatelessWidget {
  const AffiliationEdit({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user!;
    return ChangeNotifierProvider(
      create: (_)=> AffiliationProvider(user['affiliationId']),
        lazy: true,
        builder: (context, child) {
        final provider = Provider.of<AffiliationProvider>(context);

        if(provider.myRooms == null){
          return Material(
            child: Center(
              child: NadalCircular(),
            ),
          );
        }

        return IosPopGesture(
          child: Scaffold(
            appBar: NadalAppbar(
              title: '대표클럽 설정',
            ),
            body: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 40.h,),
                    if(provider.myRooms == null)
                      Expanded(child: LoadingBlock())
                    else if(provider.myRooms!.isNotEmpty)
                    Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: EdgeInsets.only(left: 16.w),
                                child: Text('${user['name']}님이 참가 중인 클럽이에요\n어느 클럽을 대표로 할까요?', style: Theme.of(context).textTheme.titleLarge,)),
                            SizedBox(height: 24.h,),
                            Expanded(
                                child: CarouselOverlap(
                                  affiliationRoom: userProvider.user!['affiliationId'],
                                  onChanged: (int index){
                                    final roomId = provider.myRooms![index]['roomId'];
                                    provider.setRoomId(roomId);
                                  },
                                  items: provider.myRooms!
                                )
                            )
                          ],
                        )
                    )
                    else
                    Expanded(child: NadalEmptyList(
                        title: '참가중인 클럽이 없어요',
                        subtitle: '지금 바로 클럽을 찾아볼까요?',
                        actionText: '클럽 찾으러가기',
                        icon: Icon(CupertinoIcons.search),
                        onAction: ()=> context.push('/searchRoom'),
                    )),
                    SizedBox(height: 24.h,),
                    if(provider.myRooms != null && provider.myRooms!.isNotEmpty)
                    NadalButton(
                      onPressed: (){
                        if(provider.originAffiliationId != provider.selectedRoomId){
                          provider.saveAffiliation(context);
                        }
                      },
                      isActive: provider.originAffiliationId != provider.selectedRoomId, title: '대표클럽으로 설정',),
                    if(Platform.isIOS)
                    SizedBox(height: 15.h,)
                  ],
                )
            ),
          ),
        );
      }
    );
  }
}
