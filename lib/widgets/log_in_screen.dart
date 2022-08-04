import 'dart:convert';
import 'package:colisage_cerba/widgets/call_screen.dart';
import 'package:flutter/material.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/user.dart';
import 'site_screen.dart';
import 'user_screen.dart';
import 'road_map_screen.dart';
import 'boxes_print_screen.dart';
import 'sql_screen.dart';
import 'settings_screen.dart';
import 'tube_screen.dart';
import 'traca_screen.dart';
import 'receipt_box_screen.dart';
import 'management_screen.dart';

class LogInScreen extends StatelessWidget {
  const LogInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: const LogInForm(),
    );
  }
}

class LogInForm extends StatefulWidget {
  const LogInForm({Key? key}) : super(key: key);

  @override
  _LogInFormState createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  final _codeTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  bool login = false;
  bool submited = false;
  bool error = false;
  double _formProgress = 0;

  void tryConnecting(String code, String password) async {
    String phpUriUserDetail = Env.urlPrefix + 'Users/detail_user.php';
    try {
      http.Response res = await http.post(Uri.parse(phpUriUserDetail),
          body: {"code": code.toUpperCase(), "password": password});
      if (res.body.isNotEmpty) {
        if (res.body != 'false') {
          setState(() {
            globals.user = User.fromSnapshot(json.decode(res.body));
            globals.mainWidgetTabs = [
              const TracaScreen(),
              const TubeScreen(),
              const ReceiptBoxScreen(),
              const CallScreen(),
              if (globals.user.siteRights +
                      globals.user.roadMapRights +
                      globals.user.boxRights +
                      (globals.user.settingsRights ? 1 : 0) +
                      (globals.user.sqlExecute ? 1 : 0) >
                  0)
                const ManagementScreen(),
            ];
            globals.managementWidgetTabs = [
              if (globals.user.userRights > 0) const UserScreen(),
              if (globals.user.boxRights > 0) const BoxesPrintScreen(),
              if (globals.user.siteRights > 0) const SiteScreen(),
              if (globals.user.roadMapRights > 0) const RoadMapScreen(),
              if (globals.user.settingsRights) const SettingScreen(),
              if (globals.user.sqlExecute) const SqlScreen()
            ];
            globals.isAuthentified = true;
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/welcome', (Route<dynamic> route) => false);
          });
        }
        setState(() {
          login = true;
          error = false;
        });
      }
    } catch (_) {
      setState(() {
        error = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void _updateFormProgress() {
    var progress = 0.0;
    final controllers = [
      _codeTextController,
      _passwordTextController,
    ];

    for (final controller in controllers) {
      if (controller.value.text.isNotEmpty) {
        progress += 1 / controllers.length;
      }
    }

    setState(() {
      _formProgress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(50),
      elevation: 8,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25))),
      child: SizedBox(
        height: 350,
        width: 500,
        child: Form(
          onChanged: _updateFormProgress,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppBar(
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25))),
              leading: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/images/cerballiance_logo.png',
                  )),
              title: const Text(
                "Colisage des prélèvements",
                style: TextStyle(fontSize: 18),
              ),
              backgroundColor: themeMainColor,
              automaticallyImplyLeading: false,
              centerTitle: true,
            ),
            LinearProgressIndicator(
              value: _formProgress,
              color: themeSecondColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
              child: SizedBox(
                  height: 60,
                  child: TextFormField(
                    style: defaultTextStyle,
                    autofocus: true,
                    controller: _codeTextController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        hintText: 'Identifiant',
                        errorText: _codeTextController.text.isEmpty && submited
                            ? 'Veuillez entrer une valeur'
                            : null),
                  )),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                  height: 60,
                  child: TextFormField(
                    style: defaultTextStyle,
                    obscureText: true,
                    controller: _passwordTextController,
                    decoration: InputDecoration(
                        hintText: 'Mot de passe',
                        errorText:
                            _passwordTextController.text.isEmpty && submited
                                ? 'Veuillez enter une valeur'
                                : null),
                    onFieldSubmitted: (e) {
                      setState(() {
                        submited = true;
                      });
                      if (_codeTextController.text.isNotEmpty &&
                          _passwordTextController.text.isNotEmpty) {
                        tryConnecting(_codeTextController.text,
                            _passwordTextController.text);
                      }
                    },
                  )),
            ),
            Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                    style: myButtonStyle,
                    onPressed: () {
                      setState(() {
                        submited = true;
                      });
                      if (_codeTextController.text.isNotEmpty &&
                          _passwordTextController.text.isNotEmpty) {
                        tryConnecting(_codeTextController.text,
                            _passwordTextController.text);
                      }
                    },
                    child: const Text('Connexion'))),
            if (login == true && !globals.isAuthentified)
              const ListTile(
                title: Text(
                  'Vos identifiants ne sont pas reconnus',
                  textAlign: TextAlign.center,
                ),
                subtitle: Text(
                  'Veuillez vérifier qu\'il n\'y a pas d\'erreur.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (error)
              const ListTile(
                title: Text(
                  'Problème de connexion au serveur',
                  textAlign: TextAlign.center,
                ),
                subtitle: Text(
                  'Veuillez vérifier qu\'il n\'y a pas de problème de connexion.',
                  textAlign: TextAlign.center,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
