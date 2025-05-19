import '../manager/project/Import_Manager.dart';

class NadalAnnounceWidget extends StatelessWidget {
  const NadalAnnounceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final item = provider.morePageBanner;

        if(item == null){
          return Container();
        }

        return Stack(
          children: [
            SizedBox(
              height: 95.h,
              width: MediaQuery.of(context).size.width,
              child: CachedNetworkImage(
                cacheKey: item['image'],
                imageUrl: item['image'],
                imageBuilder: (context, imageProvider){
                  return InkWell(
                    onTap: (){

                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.r),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Theme.of(context).scaffoldBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  color: Theme.of(context).highlightColor
                              )
                            ],
                            image: DecorationImage(image: imageProvider,
                                fit: BoxFit.cover
                            )
                        ),
                      ),
                    ),
                  );
                },
                errorWidget: (context, err, provider){
                  return Container();
                },
              )
            ),
          ],
        );
      }
    );
  }
}
