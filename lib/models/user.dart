class User {
  final String code;
  final String lastname;
  final String firstname;
  final String function;
  final String password;
  final bool siteEditing;
  final bool roadMapEditing;
  final bool boxEditing;
  final bool sqlExecute;
  final bool userEditing;

  User(
      {required this.code,
      required this.lastname,
      required this.firstname,
      required this.function,
      required this.password,
      required this.siteEditing,
      required this.roadMapEditing,
      required this.boxEditing,
      required this.sqlExecute,
      required this.userEditing});

  factory User.fromSnapshot(Map<dynamic, dynamic> user) {
    return User(
        code: user['CODE UTILISATEUR'],
        lastname: user['NOM'],
        firstname: user['PRENOM'],
        function: user['FONCTION'],
        password: user['MOT DE PASSE'] ?? '',
        siteEditing: user['EDITION SITE'] == '1',
        roadMapEditing: user['EDITION FEUILLE DE ROUTE'] == '1',
        boxEditing: user['EDITION BOITE'] == '1',
        sqlExecute: user['EXECUTION SQL'] == '1',
        userEditing: user['EDITION UTILISATEUR'] == '1');
  }
}
