class LeagueModel{
  final int leagueId;
  final String title;
  final String local;
  final String location;
  final DateTime date;
  final String imageUrl;
  final String link;
  final String sports;
  
  LeagueModel({
    required this.leagueId,
    required this.title,
    required this.location,
    required this.local,
    required this.date,
    required this.imageUrl,
    required this.link,
    required this.sports
  });
  
  
  factory LeagueModel.fromJson(Map map){
    return LeagueModel(
        leagueId: map['leagueId'],
        title: map['title'],
        location: map['location'],
        local: map['local'],
        date: DateTime.parse(map['date']).toLocal(),
        imageUrl: map['imageUrl'],
        link: map['link'],
        sports: map['sports']);
  }
}