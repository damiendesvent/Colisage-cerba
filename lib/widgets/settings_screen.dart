import 'package:flutter/material.dart';
import 'package:flutter_application_1/variables/env.sample.dart';
import 'package:flutter_application_1/variables/globals.dart' as globals;
import 'package:flutter_application_1/variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Setting());
  }
}

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  List constantsList = [];
  String? editedConstant;
  String value = '';

  @override
  void initState() {
    getConstantsList();
    super.initState();
  }

  void getConstantsList() async {
    String phpUriListConstants = Env.urlPrefix + 'Constants/list_constants.php';
    http.Response res = await http.get(Uri.parse(phpUriListConstants));
    if (res.body.isNotEmpty) {
      setState(() {
        constantsList = json.decode(res.body);
      });
    }
  }

  void applyConstants() async {
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
      });
    }
  }

  void onUpdateConstant(String name) {
    String phpUriUpdateConstant =
        Env.urlPrefix + 'Constants/update_constant.php';
    http.post(Uri.parse(phpUriUpdateConstant),
        body: {'name': name, 'newValue': value});
    Future.delayed(Duration(milliseconds: globals.milisecondWait),
        () => getConstantsList());
    setState(() {
      editedConstant = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
      'Le paramètre ' + name + ' a bien été modifié',
      textAlign: TextAlign.center,
    )));
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => applyConstants());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        body: SingleChildScrollView(
            child: Dialog(
                insetPadding: const EdgeInsets.all(30),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                elevation: 8,
                child: SizedBox(
                    width: 700,
                    height: 800,
                    child: Column(children: [
                      const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'Paramètres généraux',
                            style: TextStyle(fontSize: 24),
                          )),
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Ces paramètres sont inscrits dans la base de donnée et sont donc indépendants entre les serveurs.',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          )),
                      const Spacer(),
                      Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.bottom,
                        defaultColumnWidth: const FractionColumnWidth(0.40),
                        columnWidths: const {2: FixedColumnWidth(80)},
                        children: [
                          for (Map constant in constantsList)
                            TableRow(children: [
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 20),
                                          child: Text(
                                            constant['Nom']!,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )))),
                              TableCell(
                                  child: SizedBox(
                                      height: 70,
                                      child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 17),
                                          child: editedConstant ==
                                                  constant['CODE']
                                              ? TextFormField(
                                                  initialValue:
                                                      constant['Valeur'],
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      value = newValue;
                                                    });
                                                  },
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 17),
                                                  child: Text(
                                                      constant['Valeur']!))))),
                              TableCell(
                                  child: editedConstant == constant['CODE']
                                      ? Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    editedConstant = null;
                                                  });
                                                },
                                                icon: const Icon(Icons.clear)),
                                            IconButton(
                                                onPressed: () {
                                                  onUpdateConstant(
                                                      constant['Nom']);
                                                },
                                                icon: const Icon(Icons.check))
                                          ],
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            setState(() {
                                              editedConstant = constant['CODE'];
                                              value = constant['Valeur'];
                                            });
                                          },
                                        )),
                            ])
                        ],
                      ),
                      const Spacer(),
                    ])))));
  }
}
