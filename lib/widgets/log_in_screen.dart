import 'dart:convert';
import 'package:flutter/material.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/user.dart';

class LogInScreen extends StatelessWidget {
  const LogInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: const Center(
        child: SizedBox(
          width: double.infinity,
          child: Card(
            child: LogInForm(),
          ),
        ),
      ),
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
  double _formProgress = 0;

  void tryConnecting(String code, String password) async {
    String phpUriUserDetail = Env.urlPrefix + 'Users/detail_user.php';
    setState(() {
      login = true;
    });
    http.Response res = await http.post(Uri.parse(phpUriUserDetail),
        body: {"code": code.toUpperCase(), "password": password});
    if (res.body.isNotEmpty) {
      if (res.body != 'false') {
        setState(() {
          globals.user = User.fromSnapshot(json.decode(res.body));
          globals.isAuthentified = true;
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/welcome', (Route<dynamic> route) => false);
        });
      }
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
    return Scaffold(
        appBar: AppBar(
          title: const Text("Connexion"),
          backgroundColor: themeColor,
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: ListView(
          children: [
            Form(
              onChanged: _updateFormProgress,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                LinearProgressIndicator(
                  value: _formProgress,
                  color: Colors.amber,
                ),
                Text('Veuillez rentrer vos identifiants',
                    style: Theme.of(context).textTheme.headline4),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _codeTextController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        hintText: 'Identifiant',
                        errorText: _codeTextController.text.isEmpty && submited
                            ? 'Veuillez entrer une valeur'
                            : null),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
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
                  ),
                ),
                ElevatedButton(
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
                    child: const Text('Connexion')),
              ]),
            ),
            if (login == true)
              if (!globals.isAuthentified)
                const ListTile(
                  title: Text('Vos identifiants ne sont pas reconnus'),
                  subtitle:
                      Text('Veuillez vérifier qu\'il n\'y a pas d\'erreur.'),
                )
          ],
        ));
  }
}
