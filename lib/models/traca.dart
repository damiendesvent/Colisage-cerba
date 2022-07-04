class Traca {
  final int code;
  final String user;
  final int tournee;
  final int site;
  final String box;
  final String tube;
  final String action;
  final String correspondant;
  final String registeringTime;
  final String synchronizingTime;
  final String pgm;
  final int lettrage;
  final int car;
  final String comment;

  Traca({
    required this.code,
    required this.user,
    required this.tournee,
    required this.site,
    required this.box,
    required this.tube,
    required this.action,
    required this.correspondant,
    required this.registeringTime,
    required this.synchronizingTime,
    required this.pgm,
    required this.lettrage,
    required this.car,
    required this.comment,
  });

  factory Traca.fromSnapshot(Map<dynamic, dynamic> traca) {
    return Traca(
        code: int.parse(traca['CODE TRACABILITE']),
        user: traca['UTILISATEUR'],
        tournee: int.parse(traca['CODE TOURNEE'] ?? '0'),
        site: int.parse(traca['CODE SITE']),
        box: traca['BOITE'] ?? '',
        tube: traca['TUBE'] ?? '',
        action: traca['ACTION'],
        correspondant: traca['CORRESPONDANT'] ?? '',
        registeringTime: traca['DATE HEURE ENREGISTREMENT'],
        synchronizingTime: traca['DATE HEURE SYNCHRONISATION'],
        pgm: traca['CODE ORIGINE'],
        lettrage: int.parse(traca['NUMERO LETTRAGE'] ?? '0'),
        car: int.parse(traca['CODE VOITURE'] ?? '0'),
        comment: traca['COMMENTAIRE'] ?? '');
  }
}
