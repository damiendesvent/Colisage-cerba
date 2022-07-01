import 'package:flutter/material.dart';
import 'package:flutter_application_1/variables/env.sample.dart';
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

  @override
  void initState() {
    getConstantsList();
    super.initState();
  }

  void getConstantsList() async {
    String phpUriListConstantes =
        Env.urlPrefix + 'Constants/list_constants.php';
    http.Response res = await http.get(Uri.parse(phpUriListConstantes));
    if (res.body.isNotEmpty) {
      setState(() {
        constantsList = json.decode(res.body);
      });
    }
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
                        defaultColumnWidth: const FractionColumnWidth(0.4),
                        children: [
                          for (Map constant in constantsList)
                            TableRow(children: [
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: Text(constant['Nom']!))),
                              TableCell(child: Text(constant['Valeur']!))
                            ])
                        ],
                      ),
                      const Spacer(),
                    ])))));
  }
}
