class Site {
  final int code;
  final String correspondant;
  final String libelle;
  final String adress;
  final String cpltAdress;
  final int? cp;
  final String city;
  final bool collectionSite;
  final bool depositSite;
  final String comment;

  Site({
    this.code = 0,
    required this.correspondant,
    required this.libelle,
    required this.adress,
    required this.cpltAdress,
    this.cp,
    required this.city,
    required this.collectionSite,
    required this.depositSite,
    required this.comment,
  });

  factory Site.fromSnapshot(Map<dynamic, dynamic> site) {
    return Site(
        code: int.parse(site['CODE SITE']),
        correspondant: site['CORRESPONDANT'] ?? '',
        libelle: site['LIBELLE SITE'],
        adress: site['ADRESSE'],
        cpltAdress: site['COMPLEMENT ADRESSE'] ?? '',
        cp: (site['CP'] == null) ? 0 : int.parse(site['CP']),
        city: site['VILLE'] ?? '',
        collectionSite: site['SITE PRELEVEMENT'] == '1',
        depositSite: site['SITE DEPOT'] == '1',
        comment: site['COMMENTAIRES CORRESPONDANT'] ?? '');
  }

  factory Site.fromList(List site) {
    return Site(
        code: int.parse(site[0]['CODE SITE']),
        correspondant: site[0]['CORRESPONDANT'] ?? '',
        libelle: site[0]['LIBELLE SITE'],
        adress: site[0]['ADRESSE'],
        cpltAdress: site[0]['COMPLEMENT ADRESSE'] ?? '',
        cp: (site[0]['CP'] == null) ? 0 : int.parse(site[0]['CP']),
        city: site[0]['VILLE'] ?? '',
        collectionSite: site[0]['SITE PRELEVEMENT'] == '1',
        depositSite: site[0]['SITE DEPOT'] == '1',
        comment: site[0]['COMMENTAIRES CORRESPONDANT'] ?? '');
  }

}
