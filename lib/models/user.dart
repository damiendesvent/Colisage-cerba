class User {
  final String code;
  final String lastname;
  final String firstname;
  final String function;
  final String password;
  final int siteRights;
  final int roadMapRights;
  final int boxRights;
  final int userRights;
  final bool sqlExecute;
  final bool settingsRights;

  User(
      {required this.code,
      required this.lastname,
      required this.firstname,
      required this.function,
      required this.password,
      required this.siteRights,
      required this.roadMapRights,
      required this.boxRights,
      required this.sqlExecute,
      required this.userRights,
      required this.settingsRights});

  factory User.fromSnapshot(Map<dynamic, dynamic> user) {
    return User(
        code: user['CODE UTILISATEUR'],
        lastname: user['NOM'],
        firstname: user['PRENOM'],
        function: user['FONCTION'],
        password: user['MOT DE PASSE'] ?? '',
        siteRights: int.parse(user['DROITS SITE']),
        roadMapRights: int.parse(user['DROITS FEUILLE DE ROUTE']),
        boxRights: int.parse(user['DROITS BOITE']),
        sqlExecute: user['EXECUTION SQL'] == '1',
        userRights: int.parse(user['DROITS UTILISATEUR']),
        settingsRights: user['ACCES PARAMETRES'] == '1');
  }
}
