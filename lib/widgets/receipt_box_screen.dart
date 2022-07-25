import 'package:flutter/material.dart';
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ReceiptBoxScreen extends StatelessWidget {
  const ReceiptBoxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ReceiptBox());
  }
}

class ReceiptBox extends StatefulWidget {
  const ReceiptBox({Key? key}) : super(key: key);

  @override
  _ReceiptBoxState createState() => _ReceiptBoxState();
}

class _ReceiptBoxState extends State<ReceiptBox> {
  TextEditingController boxController = TextEditingController();
  bool submited = false;
  bool showResult = false;
  String result = '';

  @override
  void initState() {
    super.initState();
  }

  Future searchLastTracaBox() async {
    String phpUriTracaSearchBox =
        Env.urlPrefix + 'Tracas/search_last_box_traca.php';
    http.Response res = await http.post(Uri.parse(phpUriTracaSearchBox), body: {
      'box': boxController.text,
    });
    if (res.body.isNotEmpty) {
      var lastTracaBox = json.decode(res.body);
      setState(() {
        result = lastTracaBox == false
            ? 'Aucune donnée disponible pour la boîte'
            : 'Heure de réception : ' +
                DateFormat("HH'h'mm le dd/MM/yyyy").format(
                    DateTime.parse(lastTracaBox['DATE HEURE ENREGISTREMENT']));
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
                insetPadding: const EdgeInsets.all(30),
                elevation: 8,
                child: SizedBox(
                    width: 500,
                    height: 500,
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                              'Recherche de la dernière réception d\'une boîte',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade700))),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 60),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Boîte :   ', style: defaultTextStyle),
                              SizedBox(
                                  width: 320,
                                  child: TextField(
                                    style: defaultTextStyle,
                                    autofocus: true,
                                    controller: boxController,
                                    onSubmitted: (_) {
                                      setState(() {
                                        submited = true;
                                      });
                                      if (boxController.text.isNotEmpty) {
                                        setState(() {
                                          submited = false;
                                          searchLastTracaBox();
                                          boxController.clear();
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
                                    if (boxController.text.isNotEmpty) {
                                      setState(() {
                                        submited = false;
                                        searchLastTracaBox();
                                        boxController.clear();
                                      });
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.subdirectory_arrow_left))
                            ],
                          )),
                      if (showResult)
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SelectableText(result),
                              IconButton(
                                onPressed: () => Clipboard.setData(
                                    ClipboardData(text: result)),
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copier',
                              )
                            ])
                    ])))));
  }
}
