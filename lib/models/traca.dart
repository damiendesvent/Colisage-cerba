class Traca {
  final int code;
  final String user;
  final String tournee;
  final String site;
  final String box;
  final String tube;
  final String action;
  final String registeringTime;
  final String synchronizingTime;
  final String pgm;
  final int lettrage;
  final int car;
  final String picture;
  final String signing;
  final String contact;
  final String prelevement;
  final bool ok;
  final String comment;

  Traca({
    required this.code,
    required this.user,
    required this.tournee,
    required this.site,
    required this.box,
    required this.tube,
    required this.action,
    required this.registeringTime,
    required this.synchronizingTime,
    required this.pgm,
    required this.lettrage,
    required this.car,
    required this.picture,
    required this.signing,
    required this.contact,
    required this.prelevement,
    required this.ok,
    required this.comment,
  });

  factory Traca.fromSnapshot(Map<dynamic, dynamic> traca) {
    return Traca(
        code: int.parse(traca['CODE TRACABILITE']),
        user: traca['UTILISATEUR'],
        tournee: traca['LIBELLE TOURNEE'] ?? '',
        site: traca['LIBELLE SITE'],
        box: traca['BOITE'] ?? '',
        tube: traca['TUBE'] ?? '',
        action: traca['ACTION'],
        registeringTime: traca['DATE HEURE ENREGISTREMENT'],
        synchronizingTime: traca['DATE HEURE SYNCHRONISATION'],
        pgm: traca['CODE ORIGINE'],
        lettrage: int.parse(traca['NUMERO LETTRAGE'] ?? '0'),
        car: int.parse(traca['CODE VOITURE'] ?? '0'),
        picture: traca['PHOTO'] ?? '',
        signing: traca['SIGNATURE'] ?? '',
        contact: traca['CONTACT'] ?? '',
        prelevement: traca['PRELEVEMENT'] ?? '',
        ok: traca['OK'] == '1',
        comment: traca['COMMENTAIRE'] ?? '');
  }
}
