import 'package:flutter/cupertino.dart';
import 'package:kpostal/kpostal.dart';
import 'package:my_sports_calendar/manager/game/Game_Manager.dart';
import 'package:my_sports_calendar/manager/picker/Number_Picker.dart';
import 'package:my_sports_calendar/provider/schedule/Schedule_Edit_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Switch_Button.dart';


import '../../../manager/project/Import_Manager.dart';

class ScheduleEditPage extends StatefulWidget {
  const ScheduleEditPage({super.key});

  @override
  State<ScheduleEditPage> createState() => _ScheduleEditPageState();
}

class _ScheduleEditPageState extends State<ScheduleEditPage> {
  late ScheduleEditProvider provider;

   void _upTagSheet(){
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
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
        create: (_)=> ScheduleEditProvider(scheduleProvider.schedule, scheduleProvider.scheduleMembers!.isNotEmpty),
        builder: (context, child){
          provider = Provider.of<ScheduleEditProvider>(context);
          return IosPopGesture(
              child: Scaffold(
                appBar: NadalAppbar(
                  title: '스케줄 수정',
                ),
                body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                children: [
                                  SizedBox(height: 24.h,),
                                  Row(
                                    children: [
                                      InkWell(
                                          onTap: (){
                                            _upTagSheet();
                                          },
                                          child: SizedBox(
                                            width: 100.w,
                                            child: NadalSolidContainer(
                                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(provider.tag, style: theme.textTheme.bodyMedium,),
                                                  Icon(CupertinoIcons.chevron_down, size: 18.r,)
                                                ],
                                              ),
                                            ),
                                          )
                                      ),
                                      SizedBox(width: 8.w,),
                                      Expanded(
                                          child: NadalTextField(controller: provider.titleController, label: '일정 제목', maxLength: 30, initText: provider.schedule['title'],)
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 16.h,),

                                  if(provider.tag == "게임")
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.sports_tennis_rounded, size: 18.r, color: theme.hintColor,),
                                                SizedBox(width: 8.w,),
                                                Text(
                                                  '진행방식', style:  theme.textTheme.titleMedium,
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 16.w,),
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
                                                    SizedBox(width: 8.w,),
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
                                        SizedBox(height: 16.h,),
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.people_alt_outlined, size: 18.r, color: theme.hintColor,),
                                                SizedBox(width: 8.w,),
                                                Text(
                                                  '참가형태', style:  theme.textTheme.titleMedium,
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 16.w,),
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
                                                    SizedBox(width: 8.w,),
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
                                        SizedBox(height: 16.h,)
                                      ],
                                    ),


                                  //일정
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(BootstrapIcons.clock, size: 18.r, color: theme.hintColor,),
                                          SizedBox(width: 8.w,),
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
                                  SizedBox(height: 10.h,),
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
                                              padding: EdgeInsets.all(12.r),
                                              child: Text(TextFormManager.createFormToScheduleDate(provider.startDate, provider.isAllDay), style: theme.textTheme.bodyMedium,textAlign: TextAlign.center,)
                                          ),
                                        ),
                                      ),
                                      if(!provider.isAllDay)...[
                                        Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                                            child: Icon(CupertinoIcons.arrow_right)
                                        ),
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
                                                padding: EdgeInsets.all(12.r),
                                                child: Text(TextFormManager.createFormToScheduleDate(provider.endDate, provider.isAllDay), style: theme.textTheme.bodyMedium,textAlign: TextAlign.center,)
                                            ),
                                          ),
                                        ),
                                       ]
                                    ],
                                  ),
                                  SizedBox(height: 16.h,),


                                  //장소
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(BootstrapIcons.geo_alt, size: 18.r, color: theme.hintColor,),
                                          SizedBox(width: 8.w,),
                                          Text(
                                            '장소', style:  theme.textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 16.w,),
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
                                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                                              child: Row(
                                                children: [
                                                  Expanded(child: Text(provider.address ?? '', style: theme.textTheme.bodyMedium,)),

                                                  if(provider.address == null)
                                                    Icon(CupertinoIcons.chevron_forward, size: 18.r,)
                                                  else
                                                    Icon(CupertinoIcons.xmark_circle_fill, size: 18.r, color: CupertinoColors.destructiveRed,)
                                                ],
                                              ),
                                            ),
                                          )
                                      ),
                                    ],
                                  ),
                                  if(provider.address != null)
                                    Padding(padding: EdgeInsets.only(top: 10.h),
                                      child: NadalTextField(controller: provider.addressDetailController, label: '장소 상세', maxLength: 30, ),
                                    ),

                                  SizedBox(height: 16.h,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(BootstrapIcons.person_badge, size: 18.r, color: theme.hintColor,),
                                          SizedBox(width: 8.w,),
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
                                    padding: EdgeInsets.only(top: 16.h),
                                    child:  Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(BootstrapIcons.gender_ambiguous, size: 18.r, color: theme.hintColor,),
                                                SizedBox(width: 8.w,),
                                                Text(
                                                  '참가 성별 제한', style:  theme.textTheme.titleMedium,
                                                ),
                                              ],
                                            ),

                                            NadalSwitchButton(value: provider.useGenderLimit, onChanged: (val){
                                              if(provider.schedule['useNickname'] != 0){
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
                                        if(provider.useGenderLimit)...[
                                          SizedBox(height: 8.h,),
                                          Row(
                                            children: [
                                              Flexible(
                                                  child: Row(
                                                    children: [
                                                      Text('최대 남자 참가', style: theme.textTheme.titleMedium,),
                                                      SizedBox(width: 8.w,),
                                                      Expanded(
                                                          child: InkWell(
                                                            onTap: (){
                                                              Navigator.of(context).push(
                                                                  MaterialPageRoute(builder: (_)=> NumberPicker(
                                                                    onSelect: (value){
                                                                      provider.setMaleGenderLimit(value);
                                                                    },
                                                                    title: '최대 남자 참가자 수',
                                                                    unit: '명',
                                                                    initialValue: provider.maleLimit ?? 0,
                                                                  ))
                                                              );
                                                            },
                                                            child: Container(
                                                              alignment: Alignment.center,
                                                              decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(3),
                                                                  border: Border.all(
                                                                    color: theme.highlightColor,
                                                                    width: 1.2,
                                                                  )
                                                              ),
                                                              child: Text('${provider.maleLimit ?? 0} 명', style: theme.textTheme.bodyLarge?.copyWith(
                                                                  color: theme.colorScheme.secondary,
                                                                  fontWeight: FontWeight.w500
                                                              ),),
                                                            ),
                                                          )
                                                      ),
                                                    ],
                                                  )
                                              ),
                                              SizedBox(width: 8.w,),
                                              Flexible(
                                                  child: Row(
                                                      children: [
                                                        Text('최대 여자 참가', style: theme.textTheme.titleMedium,),
                                                        SizedBox(width: 8.w,),
                                                        Expanded(
                                                            child: InkWell(
                                                              borderRadius: BorderRadius.circular(3),
                                                              onTap: (){
                                                                Navigator.of(context).push(
                                                                    MaterialPageRoute(builder: (_)=> NumberPicker(
                                                                      onSelect: (value){
                                                                        provider.setFemaleGenderLimit(value);
                                                                      },
                                                                      title: '최대 여자 참가자 수',
                                                                      unit: '명',
                                                                      initialValue: provider.femaleLimit ?? 0,
                                                                    ))
                                                                );
                                                              },
                                                              child: Container(
                                                                alignment: Alignment.center,
                                                                decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(3),
                                                                    border: Border.all(
                                                                      color: theme.highlightColor,
                                                                      width: 1.2,
                                                                    )
                                                                ),
                                                                child: Text('${provider.femaleLimit ?? 0} 명', style: theme.textTheme.bodyLarge?.copyWith(
                                                                    color: theme.colorScheme.secondary,
                                                                    fontWeight: FontWeight.w500
                                                                ),),
                                                              ),
                                                            ))
                                                      ]
                                                  )
                                              ),
                                            ],
                                          ),
                                        ],

                                        if(provider.tag == "게임" && provider.isKDK != null && provider.isSingle != null)
                                          Padding(
                                              padding: EdgeInsets.only(top: 8.h),
                                              child: Text(
                                                (provider.isKDK == true) && (provider.isSingle == true) ?
                                                '대진표 단식 - 최소 ${GameManager.min_kdk_single_member}명 - 최대 ${GameManager.max_kdk_single_member}명' :
                                                (provider.isKDK == true) && (provider.isSingle == false) ?
                                                '대진표 복식 - 최소 ${GameManager.min_kdk_double_member}명 - 최대 ${GameManager.max_kdk_single_member}명' :
                                                (provider.isKDK == false) && (provider.isSingle == true) ?
                                                '토너먼트 단식 - 최소 ${GameManager.min_tour_single_member}명 - 최대 ${GameManager.max_tour_single_member}명' :
                                                '토너먼트 복식 - 최소 ${GameManager.min_tour_double_member}팀 - 최대 ${GameManager.max_tour_double_member}팀'
                                                ,style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary),)),
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
                                                height: 18.r,
                                                width: 18.r,
                                                child: FittedBox(
                                                    child: Text('₩', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600),)),
                                              ),
                                              SizedBox(width: 8.w,),
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
                                          padding: EdgeInsets.only(top: 8.h),
                                          child: InkWell(
                                            onTap: () async{
                                              final res = await context.push('/select/account');

                                              if(res != null){
                                                provider.setAccount(res);
                                              }
                                            },
                                            child: NadalSolidContainer(
                                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                                              child: Row(
                                                children: [
                                                  Expanded(child: Text(provider.account?['accountTitle'] ?? '계좌를 선택해주세요', style: theme.textTheme.bodyMedium,)),
                                                  Icon(CupertinoIcons.chevron_forward, size: 18.r,)
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                  SizedBox(height: 16,),

                                  //메모
                                  NadalTextField(controller: provider.descriptionController, label: '메모', isMaxLines: true, keyboardType: TextInputType.multiline, initText: provider.schedule['description']),
                                  SizedBox(height: 50,)
                                ],
                              ),
                            ),
                          ),
                        ),
                        NadalButton(
                          isActive: true,
                          title: '스케줄 수정하기',
                          onPressed: () {
                              provider.updateSchedule();
                          },
                        )
                      ],
                    )
                ),
              )
          );
        },
    );
  }
}
