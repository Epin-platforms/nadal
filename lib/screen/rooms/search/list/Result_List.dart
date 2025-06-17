import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';
import 'package:my_sports_calendar/widget/Nadal_Room_Frame.dart';

import '../../../../manager/project/Import_Manager.dart';

class ResultList extends StatelessWidget {
  const ResultList({super.key, required this.provider});
  final SearchRoomProvider provider;

  @override
  Widget build(BuildContext context) {
    final resultRooms = provider.resultRooms;
    final isSubmitted = provider.submitted;
    final lastSearch = provider.lastSearch;

    // 검색 결과가 없는 경우
    if (resultRooms.isEmpty && isSubmitted) {
      return _buildEmptyResult(lastSearch);
    }

    // 검색 결과가 있는 경우
    if (resultRooms.isNotEmpty) {
      return _buildResultList(context, resultRooms);
    }

    // 아직 검색하지 않은 경우
    return _buildInitialState();
  }

  Widget _buildEmptyResult(String searchQuery) {
    return SizedBox(
      height: 300.h,
      child: NadalEmptyList(
        title: "\"$searchQuery\" 관련 클럽을 찾을 수 없어요",
        subtitle: "다른 키워드로 다시 검색해볼까요?",
      ),
    );
  }

  Widget _buildInitialState() {
    return Container(
      height: 200.h,
      alignment: Alignment.center,
      child: Text(
        '검색어를 입력해주세요',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildResultList(BuildContext context, List<Map> results) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildResultItem(context, item, index);
      },
    );
  }

  Widget _buildResultItem(BuildContext context, Map item, int index) {
    final theme = Theme.of(context);
    final roomData = _sanitizeRoomData(item);

    if (roomData == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: _buildItemDecoration(theme),
      child: _buildItemContent(context, theme, roomData),
    );
  }

  BoxDecoration _buildItemDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildItemContent(
      BuildContext context,
      ThemeData theme,
      Map<String, dynamic> roomData,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => _handleRoomTap(context, roomData),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildRoomImage(roomData),
            SizedBox(width: 14.w),
            _buildRoomInfo(theme, roomData),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomImage(Map<String, dynamic> roomData) {
    return Container(
      width: 70.r,
      height: 70.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: NadalRoomFrame(
          imageUrl: roomData['roomImage'] as String?,
          size: 70.r,
        ),
      ),
    );
  }

  Widget _buildRoomInfo(ThemeData theme, Map<String, dynamic> roomData) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRoomName(theme, roomData),
          SizedBox(height: 5.h),
          _buildRoomDescription(theme, roomData),
          SizedBox(height: 8.h),
          _buildRoomMeta(theme, roomData),
        ],
      ),
    );
  }

  Widget _buildRoomName(ThemeData theme, Map<String, dynamic> roomData) {
    print(roomData);
    return Row(
      children: [
        Expanded(
          child: Text(
            roomData['roomName'] as String,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if(roomData['isJoined'] == 1)
        ...[
          SizedBox(width: 8.w,),
          Container(
            padding: EdgeInsetsGeometry.symmetric(vertical: 3.h, horizontal: 6.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('참가중', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.sp, color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700),),
          )
        ]
      ],
    );
  }

  Widget _buildRoomDescription(ThemeData theme, Map<String, dynamic> roomData) {
    return Text(
      roomData['description'] as String,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRoomMeta(ThemeData theme, Map<String, dynamic> roomData) {
    return Row(
      children: [
        _buildRoomTag(theme, roomData),
        SizedBox(width: 8.w),
        _buildMemberCount(theme, roomData),
      ],
    );
  }

  Widget _buildRoomTag(ThemeData theme, Map<String, dynamic> roomData) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          roomData['tag'] as String,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildMemberCount(ThemeData theme, Map<String, dynamic> roomData) {
    final memberCount = roomData['memberCount'] as int;

    return Row(
      children: [
        Icon(
          Icons.people_alt_rounded,
          size: 14.r,
          color: Colors.grey,
        ),
        SizedBox(width: 4.w),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$memberCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: '/200',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleRoomTap(BuildContext context, Map<String, dynamic> roomData) {
    try {
      final roomId = roomData['roomId'];
      if (roomId == null) return;

      // 햅틱 피드백
      HapticFeedback.lightImpact();

      // 참가 여부에 따른 라우팅
      final roomsProvider = context.read<RoomsProvider>();
      final hasJoined = roomsProvider.rooms?.containsKey(roomId) ?? false;

      if (hasJoined) {
        context.push('/room/$roomId');
      } else {
        context.push('/previewRoom/$roomId');
      }
    } catch (e) {
      debugPrint('방 이동 실패: $e');
    }
  }

  Map<String, dynamic>? _sanitizeRoomData(Map item) {
    try {
      return {
        'roomId': item['roomId'],
        'roomName': _sanitizeString(item['roomName'] ?? ''),
        'description': _sanitizeString(item['description'] ?? ''),
        'tag': _sanitizeString(item['tag'] ?? ''),
        'roomImage': item['roomImage'] as String?,
        'memberCount': _sanitizeInt(item['memberCount']),
      };
    } catch (e) {
      debugPrint('방 데이터 정제 실패: $e');
      return null;
    }
  }

  String _sanitizeString(String input) {
    if (input.isEmpty) return '';

    final sanitized = input.trim();
    return sanitized.length > 200 ? '${sanitized.substring(0, 197)}...' : sanitized;
  }

  int _sanitizeInt(dynamic input) {
    if (input is int) return input.clamp(0, 999);
    if (input is String) {
      final parsed = int.tryParse(input);
      return parsed?.clamp(0, 999) ?? 0;
    }
    return 0;
  }
}