import 'package:flutter/material.dart';
import 'package:colisage_cerba/variables/env.sample.dart';
import 'package:colisage_cerba/variables/styles.dart';
import 'package:flutter/services.dart';
import '../variables/globals.dart' as globals;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Welcome());
  }
}

class Welcome extends StatefulWidget {
  const Welcome({Key? key}) : super(key: key);

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with SingleTickerProviderStateMixin {
  Timer? timer;
  int minTabWidth = 1030;
  int _widgetIndex = 1;
  late TabController _tabController;

  void initializeTimer() {
    timer?.cancel();
    timer = Timer(Duration(minutes: globals.inactivityTimeOut), handleTimeout);
  }

  void handleTimeout() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        globals.isAuthentified = false;
      });
    }
  }

  void logOut(BuildContext context) {
    globals.isAuthentified = false;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  void getConstants() async {
    String phpUriListConstants = Env.urlPrefix + 'Constants/list_constants.php';
    http.Response res = await http.get(Uri.parse(phpUriListConstants));
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        globals.shouldDisplaySyncButton = items[0]['Valeur'] == 'Oui';
        globals.pdaTrackInDirectory = items[1]['Valeur'];
        globals.milisecondWait = int.parse(items[2]['Valeur']);
        globals.shouldKeepAlive = items[3]['Valeur'] == 'Oui';
        globals.inactivityTimeOut = int.parse(items[4]['Valeur']);
        globals.maxCapacityBox = int.parse(items[6]['Valeur']);
      });
    }
  }

  void getIPandSite() async {
    String phpUriGetIP = Env.urlPrefix + 'Scripts/get_ip.php';
    http.Response res = await http.get(Uri.parse(phpUriGetIP));
    if (res.body.isNotEmpty) {
      var items = json.decode(res.body);
      setState(() {
        globals.ip = items['ip'];
        globals.currentSite = items['site'];
      });
    }
  }

  void changePassword() {
    String phpUriResetPassword =
        Env.urlPrefix + 'Users/reset_password_user.php';
    bool submited = false;
    String oldPassword = '';
    String newPassword = '';
    String repeatedPassword = '';
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
                elevation: 8,
                child: SizedBox(
                    width: 600,
                    height: 300,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'Changement de mot de passe',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade700),
                          )),
                      const Spacer(),
                      Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          defaultColumnWidth: const FractionColumnWidth(0.4),
                          children: [
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Ancien mot de passe :   ',
                                      style: defaultTextStyle)),
                              TableCell(
                                  child: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        textInputAction: TextInputAction.next,
                                        style: defaultTextStyle,
                                        textAlignVertical:
                                            TextAlignVertical.bottom,
                                        obscureText: true,
                                        onChanged: (newValue) => setState(() {
                                          oldPassword = newValue;
                                        }),
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontSize:
                                                    defaultTextStyle.fontSize! -
                                                        4,
                                                height: 0.3),
                                            hintText: 'ancien mot de passe',
                                            errorText: submited &&
                                                    globals.user.password !=
                                                        oldPassword
                                                ? 'Ancien mot de passe incorrect'
                                                : null),
                                      )))
                            ]),
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Nouveau mot de passe :   ',
                                      style: defaultTextStyle)),
                              TableCell(
                                  child: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        textInputAction: TextInputAction.next,
                                        style: defaultTextStyle,
                                        textAlignVertical:
                                            TextAlignVertical.bottom,
                                        obscureText: true,
                                        onChanged: (newValue) => setState(() {
                                          newPassword = newValue;
                                        }),
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(24)
                                        ],
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontSize:
                                                    defaultTextStyle.fontSize! -
                                                        4,
                                                height: 0.3),
                                            hintText: 'nouveau mot de passe',
                                            errorText: submited &&
                                                    newPassword.length < 4
                                                ? 'Veuillez entrer au moins 4 caractères'
                                                : null),
                                      )))
                            ]),
                            TableRow(children: [
                              const TableCell(
                                  child: Text(
                                      'Répéter le nouveau mot de passe :   ',
                                      style: defaultTextStyle)),
                              TableCell(
                                  child: SizedBox(
                                      width: 50,
                                      child: TextField(
                                        textInputAction: TextInputAction.done,
                                        style: defaultTextStyle,
                                        textAlignVertical:
                                            TextAlignVertical.bottom,
                                        obscureText: true,
                                        onChanged: (newValue) => setState(() {
                                          repeatedPassword = newValue;
                                        }),
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(24)
                                        ],
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontSize:
                                                    defaultTextStyle.fontSize! -
                                                        4,
                                                height: 0.3),
                                            hintText:
                                                'répéter le nouveau mot de passe',
                                            errorText: submited &&
                                                    repeatedPassword !=
                                                        newPassword
                                                ? 'Mots de passe différents'
                                                : null),
                                      )))
                            ])
                          ]),
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: SizedBox(
                                  width: 231,
                                  child: Row(children: [
                                    ElevatedButton(
                                        style: myButtonStyle,
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Row(children: const [
                                          Icon(Icons.clear),
                                          Text('Annuler')
                                        ])),
                                    const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10)),
                                    ElevatedButton(
                                      style: myButtonStyle,
                                      onPressed: () {
                                        setState(() {
                                          submited = true;
                                        });
                                        if (oldPassword ==
                                                globals.user.password &&
                                            newPassword.length > 3 &&
                                            newPassword == repeatedPassword) {
                                          http.post(
                                              Uri.parse(phpUriResetPassword),
                                              body: {
                                                'code': globals.user.code,
                                                'password': newPassword
                                              });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(mySnackBar(const Text(
                                                  ' Votre mot de passe a bien été modifié')));
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: Row(children: const [
                                        Icon(Icons.check),
                                        Text(' Valider')
                                      ]),
                                    )
                                  ])))),
                      const Spacer(),
                    ])));
          });
        });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: globals.mainWidgetTabs.length,
        vsync: this,
        initialIndex: _widgetIndex);
    _tabController.addListener(() {
      setState(() {
        _widgetIndex = _tabController.index;
      });
    });
    getConstants();
    getIPandSite();
    initializeTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => initializeTimer(),
        onPanDown: (_) => initializeTimer(),
        onPanUpdate: (_) => initializeTimer(),
        child: Scaffold(
          body: Center(
              child: (globals.isAuthentified)
                  ? Scaffold(
                      appBar: AppBar(
                        title: const Text(
                          'Colisage des prélèvements',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w100),
                        ),
                        leading: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              'assets/images/cerballiance_logo.png',
                            )),
                        backgroundColor: themeMainColor,
                        toolbarHeight: 38,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text('Bonjour ' + globals.user.firstname,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w100)),
                          centerTitle: true,
                          titlePadding: const EdgeInsets.fromLTRB(0, 0, 0,
                              55), //choisit la position de la zone de texte
                        ),
                        actions: <Widget>[
                          Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: IconButton(
                                  tooltip: 'Changer de mot de passe',
                                  onPressed: () {
                                    changePassword();
                                  },
                                  icon: const Icon(
                                    Icons.manage_accounts,
                                    size: 28,
                                  ))),
                          Padding(
                              padding: const EdgeInsets.only(right: 15, top: 5),
                              child: IconButton(
                                  tooltip: 'Se déconnecter',
                                  onPressed: () {
                                    logOut(context);
                                  },
                                  icon: const Icon(
                                    Icons.exit_to_app,
                                    size: 28,
                                    color: Colors.red,
                                  ))),
                        ],
                        bottom: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: themeSecondColor, width: 1),
                              borderRadius: BorderRadius.circular(8)),
                          labelColor: themeMainColor,
                          unselectedLabelColor: Colors.white,
                          labelStyle: TextStyle(
                              fontSize: defaultTextStyle.fontSize! + 2),
                          tabs: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.dock_outlined),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Traçabilité")
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.science),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Gestion tubes")
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.youtube_searched_for),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Détails tube")
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Réception boîte")
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Appels")
                              ],
                            ),
                            if (globals.user.siteRights +
                                    globals.user.roadMapRights +
                                    globals.user.boxRights +
                                    (globals.user.settingsRights ? 1 : 0) +
                                    (globals.user.sqlExecute ? 1 : 0) >
                                0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tune),
                                  if (MediaQuery.of(context).size.width >
                                      minTabWidth)
                                    const Text(" Gestion colisage")
                                ],
                              ),
                          ],
                        ),
                      ),
                      body: TabBarView(
                          controller: _tabController,
                          children: globals.mainWidgetTabs))
                  : Column(
                      //si la variable isAuthentified est égale à false, on affiche un message d'erreur
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Text('Vous n\'êtes pas connecté !',
                              style: TextStyle(
                                  fontSize: 40,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w100,
                                  letterSpacing: -0.5)),
                          Padding(
                              padding: const EdgeInsets.all(30),
                              child: ElevatedButton(
                                style: myButtonStyle,
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/');
                                },
                                child: const Text(
                                    'Revenir à la page de connexion'),
                              )),
                        ])),
        ));
  }
}
