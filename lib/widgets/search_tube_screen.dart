import 'package:flutter/material.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SearchTubeScreen extends StatelessWidget {
  const SearchTubeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SearchTubeList());
  }
}

class SearchTubeList extends StatefulWidget {
  const SearchTubeList({Key? key}) : super(key: key);

  @override
  _SearchTubeListState createState() => _SearchTubeListState();
}

class _SearchTubeListState extends State<SearchTubeList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => globals.shouldKeepAlive;

  List<dynamic> items = [];
  TextEditingController tubeController = TextEditingController();
  String tube = '';
  final ScrollController _scrollController = ScrollController();
  bool submited = false;
  bool showDetails = false;

  @override
  void initState() {
    super.initState();
  }

  void getTracaTube() async {
    String phpUriGetDetailsTracaTube =
        Env.urlPrefix + 'Tracas/details_traca_tube.php';
    http.Response res = await http
        .post(Uri.parse(phpUriGetDetailsTracaTube), body: {'tube': tube});
    if (res.body.isNotEmpty) {
      setState(() {
        items = json.decode(res.body);
        tube = '';
        showDetails = items.isNotEmpty;
        if (!showDetails) {
          ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
              const Text(
                'Aucune traçabilité disponible pour ce tube',
                style: defaultTextStyle,
              ),
              color: Colors.red.shade800,
              icon: const Icon(Icons.clear, color: Colors.white)));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    TextStyle titleStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: defaultTextStyle.fontSize! + 1);
    return Scaffold(
        backgroundColor: backgroundColor,
        body: Dialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25))),
            insetPadding: const EdgeInsets.all(15),
            elevation: 8,
            child: SizedBox(
                width: 1200,
                height: 800,
                child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, bottom: 20),
                                  child: Text(
                                      'Recherche des informations d\'un tube',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade700))),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Tube :  ',
                                      style: defaultTextStyle),
                                  SizedBox(
                                      width: 250,
                                      child: TextField(
                                        autofocus: true,
                                        style: defaultTextStyle,
                                        readOnly: showDetails,
                                        controller: tubeController,
                                        decoration: InputDecoration(
                                          errorText: submited &&
                                                  tubeController.text.isEmpty
                                              ? 'Veuillez entrer une valeur'
                                              : null,
                                        ),
                                        onSubmitted: (_) => setState(() {
                                          tube = tubeController.text;
                                          submited = tube.isEmpty;
                                          submited ? null : getTracaTube();
                                        }),
                                      ))
                                ],
                              ),
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(30, 25, 30, 50),
                                  child: ElevatedButton(
                                    style: myButtonStyle,
                                    child: Text(
                                        showDetails ? 'Annuler' : 'Valider',
                                        style: defaultTextStyle),
                                    onPressed: () {
                                      showDetails
                                          ? setState(() {
                                              submited = false;
                                              showDetails = false;
                                              tube = '';
                                              tubeController.clear();
                                            })
                                          : setState(() {
                                              tube = tubeController.text;
                                              submited = tube.isEmpty;
                                              submited ? null : getTracaTube();
                                            });
                                    },
                                  )),
                              if (showDetails)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 25),
                                    child: Container(
                                        padding: const EdgeInsets.only(
                                          bottom: 5,
                                        ),
                                        decoration: const BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                          color: themeMainColor,
                                          width: 1.0,
                                        ))),
                                        child: Text('Dernière action du tube :',
                                            style: titleStyle))),
                              if (showDetails)
                                Table(
                                  defaultColumnWidth:
                                      const FractionColumnWidth(0.16),
                                  children: [
                                    TableRow(children: [
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 20),
                                          child: Text('Utilisateur',
                                              style: titleStyle)),
                                      Text('Site', style: titleStyle),
                                      Text('Action', style: titleStyle),
                                      Text('Origine', style: titleStyle),
                                      Text('Enregistrement', style: titleStyle),
                                      Text('Synchronisation',
                                          style: titleStyle),
                                    ]),
                                    TableRow(children: [
                                      Text(items[0]['UTILISATEUR'],
                                          style: defaultTextStyle),
                                      Text(items[0]['SITE'],
                                          style: defaultTextStyle),
                                      Text(items[0]['ACTION'],
                                          style: defaultTextStyle),
                                      Text(items[0]['CODE ORIGINE'],
                                          style: defaultTextStyle),
                                      Text(
                                          DateFormat("HH'h'mm:ss\ndd/MM/yyyy")
                                              .format(DateTime.parse(
                                                  items[0]['ENREGISTREMENT'])),
                                          style: defaultTextStyle),
                                      Text(
                                          DateFormat("HH'h'mm:ss\ndd/MM/yyyy")
                                              .format(DateTime.parse(
                                                  items[0]['SYNCHRONISATION'])),
                                          style: defaultTextStyle),
                                    ])
                                  ],
                                ),
                              if (showDetails)
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 30),
                                    child: Divider(
                                      indent: 20,
                                      endIndent: 20,
                                    )),
                              if (showDetails)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 25),
                                    child: Container(
                                        padding: const EdgeInsets.only(
                                          bottom: 5,
                                        ),
                                        decoration: const BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                          color: themeMainColor,
                                          width: 1.0,
                                        ))),
                                        child: SelectableText(
                                            'Dernière action de la boîte associée, ' +
                                                items[0]['BOITE'] +
                                                ' :',
                                            style: titleStyle))),
                              if (showDetails)
                                Table(
                                    defaultColumnWidth:
                                        const FractionColumnWidth(0.105),
                                    children: [
                                      TableRow(children: [
                                        Text('', style: titleStyle),
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 20),
                                            child: Text('Utilisateur',
                                                style: titleStyle)),
                                        Text('Site', style: titleStyle),
                                        Text('Tournée', style: titleStyle),
                                        Text('Origine', style: titleStyle),
                                        Text('Code voiture', style: titleStyle),
                                        Text('Commentaire', style: titleStyle),
                                        Text('Enregistrement',
                                            style: titleStyle),
                                        Text('Synchronisation',
                                            style: titleStyle),
                                      ]),
                                      TableRow(children: [
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 30),
                                            child: Text('Dernier\nramassage',
                                                style: titleStyle)),
                                        Text(items[1]['UTILISATEUR'],
                                            style: defaultTextStyle),
                                        Text(items[1]['SITE'],
                                            style: defaultTextStyle),
                                        Text(items[1]['TOURNEE'] ?? 'Aucune',
                                            style: defaultTextStyle),
                                        Text(items[1]['CODE ORIGINE'],
                                            style: defaultTextStyle),
                                        Text(
                                            items[1]['CODE VOITURE'] ?? 'Aucun',
                                            style: defaultTextStyle),
                                        Text(items[1]['COMMENTAIRE'] ?? 'Aucun',
                                            style: defaultTextStyle),
                                        Text(
                                            DateFormat("HH'h'mm:ss\ndd/MM/yyyy")
                                                .format(DateTime.parse(items[1]
                                                    ['ENREGISTREMENT'])),
                                            style: defaultTextStyle),
                                        Text(
                                            DateFormat("HH'h'mm:ss\ndd/MM/yyyy")
                                                .format(DateTime.parse(items[1]
                                                    ['SYNCHRONISATION'])),
                                            style: defaultTextStyle),
                                      ]),
                                      TableRow(children: [
                                        Text('Dernier\ndépôt',
                                            style: titleStyle),
                                        Text(items[2]['UTILISATEUR'],
                                            style: defaultTextStyle),
                                        Text(items[2]['SITE'],
                                            style: defaultTextStyle),
                                        Text(items[2]['TOURNEE'] ?? 'Aucune',
                                            style: defaultTextStyle),
                                        Text(items[2]['CODE ORIGINE'],
                                            style: defaultTextStyle),
                                        Text(
                                            items[2]['CODE VOITURE'] ?? 'Aucun',
                                            style: defaultTextStyle),
                                        Text(items[2]['COMMENTAIRE'] ?? 'Aucun',
                                            style: defaultTextStyle),
                                        Text(
                                            DateFormat("HH'h'mm:ss\ndd/MM/yyyy")
                                                .format(DateTime.parse(items[2]
                                                    ['ENREGISTREMENT'])),
                                            style: defaultTextStyle),
                                        Text(
                                            DateFormat("HH'h'mm:ss\ndd/MM/yyyy")
                                                .format(DateTime.parse(items[2]
                                                    ['SYNCHRONISATION'])),
                                            style: defaultTextStyle),
                                      ])
                                    ]),
                            ]))))));
  }
}
