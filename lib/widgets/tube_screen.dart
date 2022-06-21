import 'package:flutter/material.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/site.dart';
import '../models/user.dart';
import 'package:searchfield/searchfield.dart';

class TubeScreen extends StatelessWidget {
  const TubeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: TubeList());
  }
}

class TubeList extends StatefulWidget {
  const TubeList({Key? key}) : super(key: key);

  @override
  _TubeListState createState() => _TubeListState();
}

class _TubeListState extends State<TubeList> {
  static const TextStyle textStyle = TextStyle(fontSize: 18);
  TextEditingController siteController = TextEditingController();
  TextEditingController userController = TextEditingController();
  TextEditingController boxController = TextEditingController();
  TextEditingController tubeController = TextEditingController();
  bool submited = false;
  Iterable<Site> sites = [];
  Iterable<User> users = [];
  static const List<String> actionsList = [
    '1. Ajouter un tube dans une boite',
    '2. Enlever un tube d\'une boite',
    '3. Ramasser une boite',
    '4. Déposer une boite',
    '5. Vider une boite'
  ];
  String action = actionsList.first;
  final formKey = GlobalKey<FormState>();
  bool showBoxDialog = false;
  bool showTubeDialog = false;
  List<String> tubes = [];
  int index = 1;
  var existedBox;
  String natureContent = 'Boite/Sachet';

  void getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList),
        body: {"limit": '100000', "delete": 'false'});
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        sites = items.map(
          (e) => Site.fromSnapshot(e),
        );
      });
    }
  }

  void getUserList() async {
    String phpUriSiteList = Env.urlPrefix + 'Users/list_user.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList), body: {
      "limit": '100000',
      "delete": 'false',
      "isAscending": 'true',
      "order": 'code utilisateur'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        users = items.map(
          (e) => User.fromSnapshot(e),
        );
      });
    }
  }

  void getBoxDetail(String code) async {
    String phpUriSiteList = Env.urlPrefix + 'Boxes/details_box.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList), body: {
      "code": code,
    });
    if (res.body.isNotEmpty) {
      setState(() {
        existedBox = json.decode(res.body)['CODE BOITE'];
        natureContent = existedBox is String ? 'Boite' : 'Sachet';
      });
    }
  }

  void onAddTube() {}

  void onRemoveTube() {}

  void onClearBox() {}

  void onPickUpBox() {}

  void onDepositBox() {}

  @override
  void initState() {
    getSiteList();
    getUserList();
    super.initState();
  }

  List<Widget> screen() {
    return [
      Dialog(
          insetPadding: const EdgeInsets.all(50),
          elevation: 8,
          child: SizedBox(
            width: 600,
            height: 800,
            child: Column(children: [
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FixedColumnWidth(160),
                  1: FractionColumnWidth(0.6)
                },
                children: [
                  TableRow(
                    children: [
                      const TableCell(child: Text('Site : ', style: textStyle)),
                      TableCell(
                          child: SizedBox(
                              height: 70,
                              child: showBoxDialog
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 14, 0, 0),
                                      child: Text(
                                        siteController.text,
                                        style: textStyle,
                                      ))
                                  : Form(
                                      key: formKey,
                                      child: SearchField(
                                        searchStyle: textStyle,
                                        onSubmit: (_) {
                                          formKey.currentState!.validate();
                                        },
                                        textInputAction: TextInputAction.none,
                                        //suggestionAction: SuggestionAction.unfocus,
                                        initialValue: SearchFieldListItem<Site>(
                                            sites.elementAt(4).libelle),
                                        controller: siteController,
                                        validator: (x) {
                                          if (!sites.contains(x) ||
                                              x!.isEmpty) {
                                            return 'Veuillez entrer un site valide';
                                          }
                                          return null;
                                        },
                                        emptyWidget: Text('Aucun site trouvé',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.red.shade900,
                                                fontSize: 15)),
                                        searchInputDecoration: InputDecoration(
                                          errorText:
                                              (siteController.text.isEmpty &&
                                                      submited
                                                  ? 'Veuillez entrer une valeur'
                                                  : null),
                                        ),
                                        suggestions: sites
                                            .map(
                                              (e) => SearchFieldListItem<Site>(
                                                e.libelle,
                                                item: e,
                                              ),
                                            )
                                            .toList(),
                                      ))))
                    ],
                  ),
                  TableRow(
                    children: [
                      const TableCell(
                          child: Text(
                        'Utilisateur : ',
                        style: textStyle,
                      )),
                      TableCell(
                          child: SizedBox(
                              height: 70,
                              child: showBoxDialog
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 14, 0, 0),
                                      child: Text(
                                        userController.text,
                                        style: textStyle,
                                      ))
                                  : SearchField(
                                      searchStyle: textStyle,
                                      initialValue: SearchFieldListItem<User>(
                                          globals.user.code),
                                      controller: userController,
                                      emptyWidget: Text(
                                          'Aucun utilisateur trouvé',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.red.shade900,
                                              fontSize: 15)),
                                      searchInputDecoration: InputDecoration(
                                        errorText:
                                            (userController.text.isEmpty &&
                                                    submited
                                                ? 'Veuillez entrer une valeur'
                                                : null),
                                      ),
                                      suggestions: users
                                          .map(
                                            (e) => SearchFieldListItem<User>(
                                              e.code,
                                              item: e,
                                            ),
                                          )
                                          .toList(),
                                    )))
                    ],
                  ),
                  TableRow(
                    children: [
                      const TableCell(
                          child: Text(
                        'Action : ',
                        style: textStyle,
                      )),
                      TableCell(
                          child: SizedBox(
                              height: 70,
                              child: showBoxDialog
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 25, 0, 0),
                                      child: Text(
                                        action,
                                        style: textStyle,
                                      ))
                                  : DropdownButtonHideUnderline(
                                      child: DropdownButton(
                                          value: action,
                                          style: textStyle,
                                          items: actionsList.map((value) {
                                            return DropdownMenuItem(
                                                value: value,
                                                child: Text(value.toString()));
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              action = newValue!;
                                            });
                                          }))))
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: ElevatedButton(
                  style: myButtonStyle,
                  child: showBoxDialog
                      ? const Text('Annuler')
                      : const Text('Valider'),
                  onPressed: () {
                    setState(() {
                      submited = true;
                    });
                    if (showBoxDialog) {
                      setState(() {
                        boxController.clear();
                        natureContent = 'Boite/sachet';
                        existedBox = null;
                        showBoxDialog = false;
                        showTubeDialog = false;
                        tubes.clear;
                        tubeController.clear();
                      });
                    } else {
                      if (siteController.text.isNotEmpty &&
                          userController.text.isNotEmpty) {
                        setState(() {
                          submited = false;
                          showBoxDialog = true;
                          showTubeDialog = false;
                          tubes.clear;
                          tubeController.clear();
                        });
                      }
                    }
                  },
                ),
              ),
              if (showBoxDialog)
                Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(160),
                      1: FractionColumnWidth(0.6)
                    },
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                              child: Text(natureContent + ' : ',
                                  style: textStyle)),
                          TableCell(
                              child: SizedBox(
                                  height: 70,
                                  child: showTubeDialog
                                      ? Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 14, 0, 0),
                                          child: Text(
                                            boxController.text,
                                            style: textStyle,
                                          ))
                                      : TextField(
                                          textInputAction: TextInputAction.none,
                                          style: textStyle,
                                          autofocus: true,
                                          controller: boxController,
                                          decoration: InputDecoration(
                                              errorText: submited &&
                                                      boxController.text.isEmpty
                                                  ? 'Veuillez entrer une valeur'
                                                  : null),
                                          onSubmitted: (_) {
                                            setState(() {
                                              submited = true;
                                            });
                                            if (boxController.text.isNotEmpty) {
                                              setState(() {
                                                submited = false;
                                              });
                                              getBoxDetail(boxController.text);
                                              if (action[0] == '1' ||
                                                  action[0] == '2') {
                                                setState(() {
                                                  showTubeDialog = true;
                                                });
                                              } else {
                                                switch (action[0]) {
                                                  case '3':
                                                    onPickUpBox();
                                                    break;
                                                  case '4':
                                                    onDepositBox();
                                                    break;
                                                  case '5':
                                                    onClearBox();
                                                    break;
                                                }
                                              }
                                            }
                                          },
                                        )))
                        ],
                      ),
                    ]),
              if (showTubeDialog)
                Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(160),
                      1: FractionColumnWidth(0.6)
                    },
                    children: [
                      TableRow(
                        children: [
                          const TableCell(
                              child: Text('Tube : ', style: textStyle)),
                          TableCell(
                              child: SizedBox(
                                  height: 70,
                                  child: TextField(
                                    textInputAction: TextInputAction.none,
                                    autofocus: true,
                                    controller: tubeController,
                                    decoration: InputDecoration(
                                        errorText: submited &&
                                                (tubeController.text.isEmpty ||
                                                    tubes.contains(
                                                        tubeController.text))
                                            ? (tubes.contains(
                                                    tubeController.text)
                                                ? 'Ce tube a déjà été scanné'
                                                : 'Veuillez entrer une valeur')
                                            : null),
                                    onSubmitted: (_) {
                                      setState(() {
                                        submited = true;
                                      });
                                      if (tubeController.text.isNotEmpty &&
                                          !tubes
                                              .contains(tubeController.text)) {
                                        setState(() {
                                          submited = false;
                                          tubes.add(tubeController.text);
                                          tubeController.clear();
                                        });
                                      }
                                    },
                                  )))
                        ],
                      ),
                    ]),
            ]),
          )),
      if (showTubeDialog)
        Dialog(
            insetPadding: const EdgeInsets.all(50),
            elevation: 8,
            child: SizedBox(
                width: 600,
                height: 800,
                child: SingleChildScrollView(
                    child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        natureContent + ' n° ' + boxController.text,
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade800),
                      )),
                  Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(80),
                        1: FractionColumnWidth(0.7),
                        2: FixedColumnWidth(80)
                      },
                      children: [
                        for (String i in tubes)
                          TableRow(
                              decoration: tubes.indexOf(i).isEven
                                  ? BoxDecoration(color: Colors.grey.shade200)
                                  : null,
                              children: [
                                TableCell(
                                    child: Text(
                                  ' ' + (tubes.indexOf(i) + 1).toString(),
                                  style: textStyle,
                                )),
                                TableCell(
                                    child: Text(
                                        (action[0] == '1'
                                                ? 'Ajout'
                                                : 'Enlèvement') +
                                            ' du tube ' +
                                            i,
                                        style: textStyle)),
                                TableCell(
                                    child: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      tubes.remove(i);
                                    });
                                  },
                                ))
                              ]),
                      ]),
                  if (tubes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: ElevatedButton(
                        style: myButtonStyle,
                        child: const Text('Valider les changements'),
                        onPressed: () {
                          if (action[0] == '1') {
                            onAddTube();
                          } else {
                            onRemoveTube();
                          }
                          setState(() {
                            showBoxDialog = false;
                            showTubeDialog = false;
                            tubes.clear;
                            boxController.clear();
                            tubeController.clear();
                          });
                        },
                      ),
                    ),
                ]))))
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (sites.isNotEmpty && users.isNotEmpty) {
      if (MediaQuery.of(context).size.width > 1400 || !showTubeDialog) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center, children: screen());
      } else {
        return SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: screen()));
      }
    }
    return const Center(child: CircularProgressIndicator());
  }
}
