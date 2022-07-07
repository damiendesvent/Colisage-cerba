import 'package:flutter/material.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/traca.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class ReceiptTubeScreen extends StatelessWidget {
  const ReceiptTubeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ReceiptTube());
  }
}

class ReceiptTube extends StatefulWidget {
  const ReceiptTube({Key? key}) : super(key: key);

  @override
  _ReceiptTubeState createState() => _ReceiptTubeState();
}

class _ReceiptTubeState extends State<ReceiptTube> {
  TextEditingController tubeController = TextEditingController();
  bool submited = false;
  bool showResult = false;
  String result = '';

  @override
  void initState() {
    super.initState();
  }

  Future searchLastTracaTube() async {
    String phpUriTracaSearchTube =
        Env.urlPrefix + 'Tracas/search_last_tube_traca.php';
    http.Response res =
        await http.post(Uri.parse(phpUriTracaSearchTube), body: {
      'tube': tubeController.text,
    });
    if (res.body.isNotEmpty) {
      var lastTracaTube = json.decode(res.body);
      setState(() {
        result = lastTracaTube == false
            ? 'Aucune donnée disponible pour le tube'
            : 'Heure de réception : ' +
                lastTracaTube['DATE HEURE ENREGISTREMENT'];
        showResult = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        body: SingleChildScrollView(
            child: Dialog(
                insetPadding: const EdgeInsets.all(50),
                elevation: 8,
                child: SizedBox(
                    width: 600,
                    height: 500,
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                              'Recherche de la dernière réception d\'un tube',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade700))),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 60),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Tube :   '),
                              SizedBox(
                                  width: 320,
                                  child: TextField(
                                    autofocus: true,
                                    controller: tubeController,
                                    onSubmitted: (_) {
                                      setState(() {
                                        submited = true;
                                      });
                                      if (tubeController.text.isNotEmpty) {
                                        setState(() {
                                          submited = false;
                                          searchLastTracaTube();
                                          tubeController.clear();
                                        });
                                      }
                                    },
                                  )),
                              IconButton(
                                  tooltip: 'Valider',
                                  onPressed: () {
                                    setState(() {
                                      submited = true;
                                    });
                                    if (tubeController.text.isNotEmpty) {
                                      setState(() {
                                        submited = false;
                                        searchLastTracaTube();
                                        tubeController.clear();
                                      });
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.subdirectory_arrow_left))
                            ],
                          )),
                      if (showResult) SelectableText(result)
                    ])))));
  }
}
