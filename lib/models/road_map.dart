class RoadMap {
  final int code;
  final String libelle;
  final String tel;
  final String comment;
  final int sortingNumer;

  RoadMap({
    this.code = 0,
    required this.libelle,
    required this.tel,
    required this.comment,
    required this.sortingNumer,
  });

  factory RoadMap.fromSnapshot(Map<dynamic, dynamic> roadMap) {
    return RoadMap(
        code: int.parse(roadMap['CODE TOURNEE']),
        libelle: roadMap['LIBELLE TOURNEE'],
        tel: roadMap['TEL CHAUFFEUR'] ?? '',
        comment: roadMap['COMMENTAIRE'] ?? '',
        sortingNumer: int.parse(roadMap['ORDRE AFFICHAGE PDA']));
  }

  factory RoadMap.fromList(List roadMap) {
    return RoadMap(
        code: int.parse(roadMap[0]['CODE TOURNEE']),
        libelle: roadMap[0]['LIBELLE TOURNEE'],
        tel: roadMap[0]['TEL CHAUFFEUR'] ?? '',
        comment: roadMap[0]['COMMENTAIRE'] ?? '',
        sortingNumer: int.parse(roadMap[0]['ORDRE AFFICHAGE PDA']));
  }
}
