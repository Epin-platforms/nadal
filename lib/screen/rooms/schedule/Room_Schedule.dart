import 'package:intl/intl.dart';
import 'package:my_sports_calendar/provider/room/Room_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Simple_Schedule_List.dart';
import '../../../manager/project/Import_Manager.dart';
import 'package:my_sports_calendar/screen/rooms/schedule/widget/Room_Calendar.dart';
class RoomSchedule extends StatefulWidget {
  const RoomSchedule({super.key, required this.roomId});
  final int roomId;

  @override
  State<RoomSchedule> createState() => _RoomScheduleState();
}

class _RoomScheduleState extends State<RoomSchedule> {
  late RoomScheduleProvider provider;

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<RoomScheduleProvider>(context);
    final roomsProvider = Provider.of<RoomsProvider>(context);
    final isOpen = !roomsProvider.rooms!.containsKey(widget.roomId);
    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '일정',
          actions: [
            NadalIconButton(icon: BootstrapIcons.calendar2_plus, size: 22, onTap: (){
              final date = provider.selectedDay;
              final roomId = provider.roomId;
              final canUseGenderLimit = context.read<RoomProvider>().room?['useNickname'] == 0;
              print(canUseGenderLimit);
              context.push('/create/schedule', extra: ScheduleParams(date: date, roomId: roomId,
                  canUseGenderLimit: canUseGenderLimit));
            })
          ],
        ),
        body: SafeArea(
            child:
                provider.schedules == null ? Center(child: NadalCircular()) :
            RefreshIndicator(
              onRefresh: ()=> provider.fetchRoomSchedule(provider.selectedDay),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                        padding: EdgeInsets.fromLTRB(16,24,16,24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                                text: TextSpan(
                                    text: '${isOpen ? '번개챗' : '클럽'} ',
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                    children: [
                                      TextSpan(
                                        text: DateFormat('M월').format(provider.selectedDay),
                                        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: ' 일정',
                                        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                      )
                                    ]
                                )
                            ),
                          ],
                        )
                    ),
                    RoomCalendar(provider: provider,),
                    Divider(),
                    if(provider.getEventsForDay(provider.selectedDay).isEmpty)
                      SizedBox(
                        height: 300,
                        child: NadalEmptyList(title: '이 날은 아직 비어 있어요', subtitle: '일정을 하나 추가해볼까요?', onAction: () async{
                          final date = provider.selectedDay;
                          final roomId = provider.roomId;
                          final canUseGenderLimit = context.read<RoomProvider>().room?['useNickname'] == 0;
                          final DateTime? res = await context.push('/create/schedule', extra: ScheduleParams(date: date, roomId: roomId, canUseGenderLimit: canUseGenderLimit));

                          if(res != null){
                            provider.fetchRoomSchedule(res);
                          }
                        },actionText: '일정 추가하기',),
                      )
                    else
                      ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                          itemCount: provider.getEventsForDay(provider.selectedDay).length,
                          itemBuilder: (context, index){
                            final item = provider.getEventsForDay(provider.selectedDay)[index];
                            return NadalSimpleScheduleList(schedule: item, onTap: () async{
                              await context.push('/schedule/${item['scheduleId']}');
                              provider.updateSchedule(scheduleId: item['scheduleId']);
                            },);
                          }, separatorBuilder: (BuildContext context, int index)=> Divider(height: 0.5, color: Theme.of(context).highlightColor,),
                      )
                  ],
                ),
              ),
            )
        ),
      ),
    );
  }
}
