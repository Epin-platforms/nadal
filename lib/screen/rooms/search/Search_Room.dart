import 'package:my_sports_calendar/provider/room/Search_Room_Provider.dart';
import 'package:my_sports_calendar/screen/rooms/search/list/Auto_List.dart';
import 'package:my_sports_calendar/screen/rooms/search/list/Recently_List.dart';
import 'package:my_sports_calendar/screen/rooms/search/list/Result_List.dart';
import 'package:my_sports_calendar/widget/Search_Text_Field.dart';

import '../../../manager/project/Import_Manager.dart';

class SearchRoom extends StatelessWidget {
  const SearchRoom({super.key, required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().user;

    // 사용자 데이터 검증
    if (user == null) {
      return _buildErrorScaffold('사용자 정보를 불러올 수 없습니다.');
    }

    return ChangeNotifierProvider(
      create: (_) => SearchRoomProvider(user, isOpen),
      child: _SearchRoomContent(isOpen: isOpen),
    );
  }

  Widget _buildErrorScaffold(String message) {
    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '${isOpen ? '번개방' : '클럽'} 검색',
        ),
        body: Center(
          child: Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SearchRoomContent extends StatelessWidget {
  const _SearchRoomContent({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return IosPopGesture(
      child: Scaffold(
        appBar: NadalAppbar(
          title: '${isOpen ? '번개방' : '클럽'} 검색',
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(16.w, 4.h, 0, 8.h),
                  child: Row(
                    children: [
                      Icon(BootstrapIcons.question_circle, size: 14.r, color: Theme.of(context).colorScheme.secondary,),
                      SizedBox(width: 4.w,),
                      Text('가입된 채팅방은 검색되지 않습니다', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.secondary),),
                    ],
                  ),
              ),
              _buildSearchContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Consumer<SearchRoomProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: SearchTextField(
            controller: provider.searchController,
            node: provider.searchNode,
            onSubmit: provider.onSubmit,
          ),
        );
      },
    );
  }

  Widget _buildSearchContent() {
    return Expanded(
      child: Consumer<SearchRoomProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchList(provider),
                SizedBox(height: 50.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchList(SearchRoomProvider provider) {
    switch (provider.mode) {
      case SearchMode.recently:
        return _buildRecentlyList(provider);
      case SearchMode.auto:
        return _buildAutoList(provider);
      case SearchMode.result:
        return _buildResultList(provider);
    }
  }

  Widget _buildRecentlyList(SearchRoomProvider provider) {
    if (provider.recentlySearch.isEmpty) {
      return _buildEmptyState('최근 검색 기록이 없습니다.');
    }
    return RecentlyList(provider: provider);
  }

  Widget _buildAutoList(SearchRoomProvider provider) {
    if (provider.autoTextSearch.isEmpty) {
      return _buildEmptyState('검색 결과가 없습니다.');
    }
    return AutoList(provider: provider);
  }

  Widget _buildResultList(SearchRoomProvider provider) {
    return ResultList(provider: provider);
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200.h,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}