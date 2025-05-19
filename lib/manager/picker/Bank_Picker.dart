import '../project/Import_Manager.dart';

class BankPicker extends StatelessWidget {
  const BankPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> bank = ListPackage.banks.entries
        .where((entry) => entry.value['type'] == 0)
        .map((entry) => entry.key)
        .toList();

    final List<String> notBank = ListPackage.banks.entries
        .where((entry) => entry.value['type'] == 1)
        .map((entry) => entry.key)
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: CustomScrollView(
        slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 24),
              sliver: SliverToBoxAdapter(
                child: Text('은행', style: theme.textTheme.titleSmall),
              ),
            ),
            SliverGrid.builder(
                itemCount: bank.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5
                ),
                itemBuilder: (context, index){
                  final item = bank[index];
                  return InkWell(
                    onTap: ()=> Navigator.of(context).pop(item),
                    child: Column(
                      children: [
                        Image.asset(
                          ListPackage.banks[item]!['logo'], height: 45, width: 45,
                        ),
                        SizedBox(height: 8,),
                        Text(item, style: Theme.of(context).textTheme.labelLarge,)
                      ],
                    ),
                  );
                }),
          SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 24),
            sliver: SliverToBoxAdapter(
              child: Text('증권사', style: theme.textTheme.titleSmall),
            ),
          ),
          SliverGrid.builder(
              itemCount: notBank.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5
              ),
              itemBuilder: (context, index){
                final item = notBank[index];
                return InkWell(
                  onTap: ()=> Navigator.of(context).pop(item),
                  child: Column(
                    children: [
                      Image.asset(
                        ListPackage.banks[item]!['logo'], height: 45, width: 45,
                      ),
                      SizedBox(height: 8,),
                      Text(item, style: Theme.of(context).textTheme.labelLarge,)
                    ],
                  ),
                );
              }),
          SliverPadding(padding: EdgeInsets.only(top: 50))
          ],
      ),
    );

  }
}
