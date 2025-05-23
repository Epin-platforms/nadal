import 'package:flutter/cupertino.dart';
import 'package:kpostal/kpostal.dart';
import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/provider/schedule/Schedule_Create_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Switch_Button.dart';

import '../../../manager/project/Import_Manager.dart';

class ScheduleCreate extends StatefulWidget {
  const ScheduleCreate({super.key});

  @override
  State<ScheduleCreate> createState() => _ScheduleCreateState();
}

class _ScheduleCreateState extends State<ScheduleCreate> {
  late ScheduleCreateProvider provider;

  _upTagSheet() async{
    showCupertinoModalPopup(context: context, builder: (context){
      return NadalSheet(
          title: '태그를 선택해주세요',
          actions: List.generate(provider.tags.length, (index)=> CupertinoActionSheetAction(
          onPressed: (){
            Navigator.pop(context);
            provider.setTag(index);
          },
          child: Text(provider.tags[index], style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).secondaryHeaderColor),)
      )));
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_)=> _upTagSheet());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_)=> ScheduleCreateProvider(GoRouterState.of(context).extra as ScheduleParams),
      builder: (context, child) {
        provider = Provider.of<ScheduleCreateProvider>(context);
        return IosPopGesture(
            child: Scaffold(
              appBar: NadalAppbar(
                title: '스케줄 생성',
              ),
              body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                SizedBox(height: 24,),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: (){
                                        _upTagSheet();
                                      },
                                      child: SizedBox(
                                        width: 100,
                                        child: NadalSolidContainer(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(provider.tag, style: theme.textTheme.bodyMedium,),
                                              Icon(CupertinoIcons.chevron_down, size: 18,)
                                            ],
                                          ),
                                        ),
                                      )
                                    ),
                                    SizedBox(width: 8,),
                                    Expanded(
                                        child: NadalTextField(controller: provider.titleController, label: '일정 제목', maxLength: 30,)
                                    )
                                  ],
                                ),
                                SizedBox(height: 16,),

                                if(provider.tag == "게임")
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.sports_tennis_rounded, size: 18, color: theme.hintColor,),
                                            SizedBox(width: 8,),
                                            Text(
                                              '진행방식', style:  theme.textTheme.titleMedium,
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 16,),
                                        Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                    child: InkWell(
                                                      onTap: ()=> provider.setIsKDK(true),
                                                      child: NadalSelectableBox(
                                                          selected: provider.isKDK == true,
                                                          text: '대진표'
                                                      ),
                                                    )
                                                ),
                                                SizedBox(width: 8,),
                                                Flexible(
                                                    child: InkWell(
                                                      onTap: ()=> provider.setIsKDK(false),
                                                      child: NadalSelectableBox(
                                                          selected: provider.isKDK == false,
                                                          text: '토너먼트'
                                                      ),
                                                    )
                                                )
                                              ],
                                            )
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 16,),
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.people_alt_outlined, size: 18, color: theme.hintColor,),
                                            SizedBox(width: 8,),
                                            Text(
                                              '참가형태', style:  theme.textTheme.titleMedium,
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 16,),
                                        Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                    child: InkWell(
                                                      onTap: ()=> provider.setIsSingle(true),
                                                      child: NadalSelectableBox(
                                                          selected: provider.isSingle == true,
                                                          text: '단식'
                                                      ),
                                                    )
                                                ),
                                                SizedBox(width: 8,),
                                                Flexible(
                                                    child: InkWell(
                                                      onTap: ()=> provider.setIsSingle(false),
                                                      child: NadalSelectableBox(
                                                          selected: provider.isSingle == false,
                                                          text: '복식'
                                                      ),
                                                    )
                                                )
                                              ],
                                            )
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 16,)
                                  ],
                                ),


                                //일정
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(BootstrapIcons.clock, size: 18, color: theme.hintColor,),
                                        SizedBox(width: 8,),
                                        Text(
                                          '하루 종일', style:  theme.textTheme.titleMedium,
                                        ),
                                      ],
                                    ),

                                    NadalSwitchButton(value: provider.isAllDay, onChanged: (val){
                                      provider.setAllDay(val);
                                    })
                                  ],
                                ),
                                SizedBox(height: 10,),
                                Row(
                                  children: [
                                    Flexible(
                                      child: InkWell(
                                        onTap: () async{
                                            final res = await PickerManager.dateTimePicker(provider.startDate, visibleTime: !provider.isAllDay);

                                            if(res != null){
                                              provider.setStartDate(res);
                                            }
                                        },
                                        child: NadalSolidContainer(
                                            fitted: true,
                                            padding: EdgeInsets.all(12),
                                            child: Text(TextFormManager.createFormToScheduleDate(provider.startDate, provider.isAllDay), style: theme.textTheme.bodyMedium,textAlign: TextAlign.center,)
                                        ),
                                      ),
                                    ),
                                    if(!provider.isAllDay)
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(CupertinoIcons.arrow_right)
                                    ),
                                    if(!provider.isAllDay)
                                    Flexible(
                                      child: InkWell(
                                        onTap: () async{
                                          final res = await PickerManager.dateTimePicker(provider.endDate);

                                          if(res != null){
                                            provider.setEndDate(res);
                                          }
                                        },
                                        child: NadalSolidContainer(
                                            color: provider.endDate.isBefore(provider.startDate) ? theme.colorScheme.error : null,
                                            fitted: true,
                                            padding: EdgeInsets.all(12),
                                            child: Text(TextFormManager.createFormToScheduleDate(provider.endDate, provider.isAllDay), style: theme.textTheme.bodyMedium,textAlign: TextAlign.center,)
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16,),


                                //장소
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(BootstrapIcons.geo_alt, size: 18, color: theme.hintColor,),
                                        SizedBox(width: 8,),
                                        Text(
                                          '장소', style:  theme.textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 16,),
                                    Expanded(
                                        child: InkWell(
                                          onTap: () async{
                                            if(provider.address == null){
                                              Kpostal? address = await Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => KpostalView(),
                                              ));

                                              if(address != null){
                                                provider.setAddress(address.address, address.sido);
                                              }
                                            }else{
                                              provider.setAddress(null, null);
                                            }
                                          },
                                          child: NadalSolidContainer(
                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                            child: Row(
                                              children: [
                                                Expanded(child: Text(provider.address ?? '', style: theme.textTheme.bodyMedium,)),

                                                if(provider.address == null)
                                                Icon(CupertinoIcons.chevron_forward, size: 18,)
                                                else
                                                Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: CupertinoColors.destructiveRed,)
                                              ],
                                            ),
                                          ),
                                        )
                                    ),
                                  ],
                                ),
                                if(provider.address != null)
                                  Padding(padding: EdgeInsets.only(top: 10),
                                    child: NadalTextField(controller: provider.addressDetailController, label: '장소 상세', maxLength: 30, ),
                                  ),

                                SizedBox(height: 16,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(BootstrapIcons.person_badge, size: 18, color: theme.hintColor,),
                                        SizedBox(width: 8,),
                                        Text(
                                          '참가 신청 받기', style:  theme.textTheme.titleMedium,
                                        ),
                                      ],
                                    ),

                                    NadalSwitchButton(value: provider.useParticipation, onChanged: (val){
                                      if(provider.tag == "게임"){
                                        DialogManager.showBasicDialog(title: '게임을 시작할 준비 중!', content: '게임을 시작하려면 참가자를 반드시 받아야 해요', confirmText: "확인");
                                        return;
                                      }

                                      if(val == false){ //참가기능 끌 경우
                                        provider.setUseGenderLimit(false); //성별제한 동시 종료
                                      }

                                      provider.setUseParticipation(val);
                                    })
                                  ],
                                ),

                               // if(provider.useParticipation && provider.roomId != null)
                                Padding(
                                    padding: EdgeInsets.only(top: 16),
                                    child:  Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(BootstrapIcons.gender_ambiguous, size: 18, color: theme.hintColor,),
                                                SizedBox(width: 8,),
                                                Text(
                                                  '참가 성별 제한', style:  theme.textTheme.titleMedium,
                                                ),
                                              ],
                                            ),

                                            NadalSwitchButton(value: provider.useGenderLimit, onChanged: (val){
                                              if(!provider.canUseGenderLimit){
                                                DialogManager.showBasicDialog(title: '성별 참가 기능 제한', content: '본명 기반으로 운영되는 클럽에서만 이 기능을 이용할 수 있어요', confirmText: "확인");
                                                return;
                                              }else if(provider.isKDK == false && provider.isSingle == false){
                                                DialogManager.showBasicDialog(title: '성별 참가 기능 제한', content: '복식 토너먼트는 팀 단위 참가로\n성별 기능을 사용할 수 없어요', confirmText: "확인");
                                                return;
                                              }
                                              provider.setUseGenderLimit(val);
                                            })
                                          ],
                                        ),
                                        if(provider.useGenderLimit)
                                          SizedBox(
                                            height: 80,
                                            child: Row(
                                              children: [
                                                Flexible(
                                                    child: Row(
                                                      children: [
                                                        Text('남자', style: theme.textTheme.titleMedium,),
                                                        SizedBox(width: 8,),
                                                        Expanded(
                                                          child: ListWheelScrollView(
                                                              itemExtent: 33,
                                                              onSelectedItemChanged: (value){
                                                                provider.setMaleGenderLimit(value);
                                                              },
                                                              children: List.generate(99, (index)=> Text('$index', style: theme.textTheme.bodyLarge?.copyWith(
                                                                color : provider.maleLimit == index ?  theme.colorScheme.primary : theme.highlightColor, fontWeight: provider.maleLimit == index ? FontWeight.w600 : FontWeight.w400
                                                              ),))
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                ),
                                                SizedBox(width: 8,),
                                                Flexible(
                                                    child: Row(
                                                      children: [
                                                        Text('여자', style: theme.textTheme.titleMedium,),
                                                        SizedBox(width: 8,),
                                                        Expanded(
                                                          child: ListWheelScrollView(
                                                              itemExtent: 30,
                                                              onSelectedItemChanged: (value){
                                                                provider.setFemaleGenderLimit(value);
                                                              },
                                                              children: List.generate(99, (index)=> Text('$index', style: theme.textTheme.bodyLarge?.copyWith(
                                                                  color : provider.femaleLimit == index ?  theme.colorScheme.primary : theme.highlightColor, fontWeight: provider.femaleLimit == index ? FontWeight.w600 : FontWeight.w400
                                                              ),))
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                ),
                                              ],
                                            ),
                                          ),
                                        if(provider.tag == "게임" && provider.isKDK != null && provider.isSingle != null)
                                         Padding(
                                             padding: EdgeInsets.only(top: 8),
                                             child: Text(
                                               (provider.isKDK == true) && (provider.isSingle == true) ?
                                                '대진표 단식 - 최소 ${GameManager.min_kdk_single_member}명 / 최대 ${GameManager.max_kdk_single_member}명' :
                                               (provider.isKDK == true) && (provider.isSingle == false) ?
                                                '대진표 복식 - 최소 ${GameManager.min_kdk_double_member}명 / 최대 ${GameManager.max_kdk_double_member}명' :
                                               (provider.isKDK == false) && (provider.isSingle == true) ?
                                                '토너먼트 단식 - 최소 ${GameManager.min_tour_single_member}명 / 최대 ${GameManager.max_tour_single_member}' :
                                                '토너먼트 복식 - 최소 ${GameManager.min_tour_double_member}명 / 최대 ${GameManager.max_tour_double_member}'
                                               ,style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),)),
                                      ],
                                    ),
                                ),
                                SizedBox(height: 16,),

                                //계좌
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: FittedBox(
                                                  child: Text('₩', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600),)),
                                            ),
                                            SizedBox(width: 8,),
                                            Text(
                                              '계좌첨부', style:  theme.textTheme.titleMedium,
                                            ),
                                          ],
                                        ),

                                        NadalSwitchButton(value: provider.useAccount, onChanged: (val){
                                          if(context.read<UserProvider>().user!['verificationCode'] == null){
                                            DialogManager.showBasicDialog(title: '계좌첨부 제한', content: '계좌 등록은 카카오 연결을\n완료한 사용자만 가능해요.', confirmText: "확인");
                                            return;
                                          }

                                          if(provider.account != null && val == false){
                                            provider.setAccount(null);
                                          }

                                          provider.setUseAccount(val);
                                        })
                                      ],
                                    ),
                                    if(provider.useAccount)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: InkWell(
                                          onTap: () async{
                                            final res = await context.push('/select/account');

                                            if(res != null){
                                              provider.setAccount(res);
                                            }
                                          },
                                          child: NadalSolidContainer(
                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                            child: Row(
                                              children: [
                                                Expanded(child: Text(provider.account?['accountTitle'] ?? '계좌를 선택해주세요', style: theme.textTheme.bodyMedium,)),
                                                Icon(CupertinoIcons.chevron_forward, size: 18,)
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                                SizedBox(height: 16,),

                                //메모
                                NadalTextField(controller: provider.descriptionController, label: '메모', isMaxLines: true, keyboardType: TextInputType.multiline,),
                                SizedBox(height: 50,)
                              ],
                            ),
                          ),
                        ),
                      ),
                      NadalButton(
                        isActive: true,
                        title: '스케줄 만들기',
                        onPressed: () async{
                          final router = GoRouter.of(context);
                          final res = await provider.create();
                          if(res != null && res != 404){
                            router.pushReplacement('/schedule/$res');
                          }
                        },
                      )
                    ],
                  )
              )
            )
        );
      }
    );
  }

}
