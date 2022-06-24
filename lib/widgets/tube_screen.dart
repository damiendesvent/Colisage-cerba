import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  TextEditingController tourneeController = TextEditingController();
  TextEditingController carController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  bool submited = false;
  List sites = [];
  List users = [];
  static const List<String> actionsList = [
    '1. Ajouter un tube dans une boîte',
    '2. Enlever un tube d\'une boîte',
    '3. Ramasser une boîte',
    '4. Déposer une boîte',
    '5. Vider une boîte'
  ];
  String action = actionsList.first;
  final formKey = GlobalKey<FormState>();
  bool showBoxDialog = false;
  bool showTubeDialog = false;
  bool showTourneeDialog = false;
  bool showCarDialog = false;
  bool showCommentDialog = false;
  bool showValidation = false;
  List tubes = [];
  int index = 1;
  String natureContent = 'Boîte/Sachet';
  List alreadyOnBoxTubes = [];
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _secondScrollController = ScrollController();
  String lastBoxAction = '';
  String? boxErrorText;

  void getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList),
        body: {"limit": '100000', "delete": 'false'});
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        sites = items.map((item) => item['LIBELLE SITE']).toList();
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
        users = items
            .map((item) =>
                item['CODE UTILISATEUR'] +
                ' : ' +
                item['PRENOM'] +
                ' ' +
                item['NOM'])
            .toList();
      });
    }
  }

  void getNatureContent(String code) {
    setState(() {
      natureContent = code.startsWith('B') ? 'Boîte' : 'Sachet';
    });
  }

  void getListTube(String code, {bool setTubes = false}) async {
    String phpUriTubeList = Env.urlPrefix + 'Tubes/list_tube.php';
    http.Response res =
        await http.post(Uri.parse(phpUriTubeList), body: {'code': code});
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        alreadyOnBoxTubes = items.map((item) => item['CODE TUBE']).toList();
        if (setTubes) {
          tubes = alreadyOnBoxTubes;
        }
      });
    }
  }

  void onAddTraca({required String action}) {
    String phpUriAddTraca = Env.urlPrefix + 'Tracas/add_tracas.php';
    http.post(Uri.parse(phpUriAddTraca), body: {
      'user': userController.text
          .substring(0, userController.text.indexOf(':') - 1),
      'site': siteController.text,
      'box': boxController.text,
      'tube': tubes.toString(),
      'action': action,
      'registering': DateTime.now()
          .toString()
          .substring(0, DateTime.now().toString().length - 4),
      'pgm': 'A',
    });
  }

  void onResetStates() {
    setState(() {
      natureContent = 'Boîte/sachet';
      showBoxDialog = false;
      showTubeDialog = false;
      showTourneeDialog = false;
      showCarDialog = false;
      showCommentDialog = false;
      showValidation = false;
      tubes = [];
      boxController.clear();
      tubeController.clear();
      tourneeController.clear();
      carController.clear();
      commentController.clear();
    });
  }

  void onAddTube() {
    String phpUriTubeAddOrUpdate =
        Env.urlPrefix + 'Tubes/add_or_update_tubes.php';
    onAddTraca(action: 'AJT');
    http.post(Uri.parse(phpUriTubeAddOrUpdate),
        body: {'tube': tubes.toString(), 'box': boxController.text});
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
        Text(' ' +
            tubes.length.toString() +
            ' tubes ont bien été ajoutés à la boîte n° ' +
            boxController.text),
        duration: 8));
    onResetStates();
  }

  void onAddBag() {
    String phpUriBoxAdd = Env.urlPrefix + 'Boxes/add_box.php';
    http.post(Uri.parse(phpUriBoxAdd),
        body: {'box': boxController.text, 'type': 'SAC'});
  }

  void onRemoveTube() {
    String phpUriTubeRemoveBox = Env.urlPrefix + 'Tubes/remove_box_tubes.php';
    onAddTraca(action: 'VIT');
    http.post(Uri.parse(phpUriTubeRemoveBox),
        body: {'tube': tubes.toString(), 'box': boxController.text});
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
        Text(' ' +
            tubes.length.toString() +
            ' tubes ont bien été enlevé de la boîte n° ' +
            boxController.text),
        duration: 8));
    onResetStates();
  }

  void onPickUpBox() {
    onAddTraca(action: 'RAM');
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
        natureContent == 'Boîte'
            ? 'La boîte ' + boxController.text + ' a bien été ramassée'
            : 'Le sachet ' + boxController.text + ' a bien été ramassé')));
    onResetStates();
  }

  void onDepositBox() {
    onAddTraca(action: 'DEP');
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
        natureContent == 'Boîte'
            ? 'La boîte ' + boxController.text + ' a bien été déposée'
            : 'Le sachet ' + boxController.text + ' a bien été déposé')));
    onResetStates();
  }

  Future<String> checkLastBoxAction() async {
    String phpUriCheckLastActionTraca =
        Env.urlPrefix + 'Tracas/check_last_action_traca.php';
    http.Response res = await http.post(Uri.parse(phpUriCheckLastActionTraca),
        body: {'box': boxController.text});
    if (res.body.isNotEmpty) {
      var items = json.decode(res.body);
      if (items is! bool) {
        return items['ACTION'];
      }
    }
    return '';
  }

  @override
  void initState() {
    getSiteList();
    getUserList();
    super.initState();
  }

  String? tubeErrorText() {
    if (tubeController.text.isEmpty) {
      setState(() {});
      return 'Veuillez entrer une valeur';
    } else if (tubes.contains(tubeController.text)) {
      setState(() {});
      return 'Le tube a déjà été scanné';
    } else if (alreadyOnBoxTubes.contains(tubeController.text) &&
        action[0] == '1') {
      setState(() {});
      return 'Le tube est déjà présent';
    } else if (!alreadyOnBoxTubes.contains(tubeController.text) &&
        action[0] == '2') {
      setState(() {});
      return 'Le tube n\'est pas présent';
    } else {
      setState(() {});
      return null;
    }
  }

  void checkBoxErrorText() {
    checkLastBoxAction().then((value) {
      if (boxController.text.isNotEmpty) {
        getNatureContent(boxController.text);
        if (value == 'RAM' && action[0] != '4') {
          setState(() {
            boxErrorText = natureContent == 'Boîte'
                ? 'La boîte est ramassée'
                : 'Le sachet est ramassé';
          });
        } else if (value == 'DEP' && action[0] != '3') {
          setState(() {
            boxErrorText = natureContent == 'Boîte'
                ? 'La boîte est déposée'
                : 'Le sachet est déposé';
          });
        } else {
          setState(() {
            submited = false;
            boxErrorText = null;
          });
          if ('12'.contains(action[0])) {
            getListTube(boxController.text);
            setState(() {
              showTubeDialog = true;
            });
          } else if ('34'.contains(action[0])) {
            setState(() {
              showTourneeDialog = true;
            });
          } else {
            getListTube(boxController.text, setTubes: true);
            setState(() {
              showTubeDialog = true;
            });
          }
        }
      } else {
        setState(() {
          boxErrorText = 'Veuillez entrer une valeur';
        });
      }
    });
  }

  List<Widget> screen() {
    return [
      Dialog(
          insetPadding: const EdgeInsets.all(50),
          elevation: 8,
          child: SizedBox(
            width: 600,
            height: 700,
            child: Column(children: [
              Form(
                  key: formKey,
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(160),
                      1: FractionColumnWidth(0.6)
                    },
                    children: [
                      TableRow(
                        children: [
                          const TableCell(
                              child: Text('Site : ', style: textStyle)),
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
                                      : SearchField(
                                          searchStyle: textStyle,
                                          onSubmit: (_) {
                                            formKey.currentState!.validate();
                                          },
                                          textInputAction: TextInputAction.none,
                                          initialValue:
                                              SearchFieldListItem<String>(
                                                  sites[4]),
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
                                          searchInputDecoration:
                                              InputDecoration(
                                            errorText: (siteController
                                                        .text.isEmpty &&
                                                    submited
                                                ? 'Veuillez entrer une valeur'
                                                : null),
                                          ),
                                          suggestions: sites
                                              .map(
                                                (e) =>
                                                    SearchFieldListItem<String>(
                                                  e,
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
                                          initialValue:
                                              SearchFieldListItem<String>(
                                                  globals.user.code +
                                                      ' : ' +
                                                      globals.user.firstname +
                                                      ' ' +
                                                      globals.user.lastname),
                                          controller: userController,
                                          validator: (x) {
                                            if (!users.contains(x) ||
                                                x!.isEmpty) {
                                              return 'Veuillez entrer un utilisateur valide';
                                            }
                                            return null;
                                          },
                                          emptyWidget: Text(
                                              'Aucun utilisateur trouvé',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Colors.red.shade900,
                                                  fontSize: 15)),
                                          searchInputDecoration:
                                              InputDecoration(
                                            errorText: (userController
                                                        .text.isEmpty &&
                                                    submited
                                                ? 'Veuillez entrer une valeur'
                                                : null),
                                          ),
                                          suggestions: users
                                              .map(
                                                (e) =>
                                                    SearchFieldListItem<String>(
                                                  e,
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
                                                    child:
                                                        Text(value.toString()));
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  action = newValue!;
                                                });
                                              }))))
                        ],
                      ),
                    ],
                  )),
              Padding(
                padding: const EdgeInsets.all(30),
                child: ElevatedButton(
                  style: myButtonStyle,
                  child: const Text('Valider'),
                  onPressed: showBoxDialog
                      ? null
                      : () {
                          setState(() {
                            submited = true;
                          });
                          if (siteController.text.isNotEmpty &&
                              userController.text.isNotEmpty &&
                              formKey.currentState!.validate()) {
                            setState(() {
                              submited = false;
                              showBoxDialog = true;
                              showTubeDialog = false;
                              tubes.clear;
                              tubeController.clear();
                            });
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
                                  child: showTubeDialog || showTourneeDialog
                                      ? Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 14, 0, 0),
                                          child: Text(
                                            boxController.text,
                                            style: textStyle,
                                          ))
                                      : Row(children: [
                                          SizedBox(
                                              width: 320,
                                              child: SizedBox(
                                                  height: 70,
                                                  child: TextField(
                                                    textInputAction:
                                                        TextInputAction.none,
                                                    style: textStyle,
                                                    autofocus: true,
                                                    controller: boxController,
                                                    decoration: InputDecoration(
                                                        errorText: submited
                                                            ? boxErrorText
                                                            : null),
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .deny('"')
                                                    ],
                                                    onSubmitted: (_) {
                                                      setState(() {
                                                        submited = true;
                                                      });
                                                      checkBoxErrorText();
                                                    },
                                                  ))),
                                          IconButton(
                                              tooltip: 'Valider',
                                              onPressed: () {
                                                setState(() {
                                                  submited = true;
                                                });
                                                checkBoxErrorText();
                                              },
                                              icon: const Icon(Icons
                                                  .subdirectory_arrow_left))
                                        ])))
                        ],
                      ),
                    ]),
              if (showTubeDialog && action[0] != '5')
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
                              child: Row(children: [
                            SizedBox(
                                width: 320,
                                child: SizedBox(
                                    height: 70,
                                    child: TextField(
                                      textInputAction: TextInputAction.none,
                                      autofocus: true,
                                      controller: tubeController,
                                      decoration: InputDecoration(
                                          errorText: submited
                                              ? tubeErrorText()
                                              : null),
                                      onSubmitted: (_) {
                                        setState(() {
                                          submited = true;
                                        });
                                        if (tubeErrorText() == null) {
                                          setState(() {
                                            submited = false;
                                            tubes.add(tubeController.text);
                                            tubeController.clear();
                                          });
                                        }
                                      },
                                    ))),
                            IconButton(
                                tooltip: 'Valider',
                                onPressed: () {
                                  setState(() {
                                    submited = true;
                                  });
                                  if (tubeErrorText() == null) {
                                    setState(() {
                                      submited = false;
                                      tubes.add(tubeController.text);
                                      tubeController.clear();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.subdirectory_arrow_left))
                          ]))
                        ],
                      )
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
                              child: Padding(padding: EdgeInsets.all(40))),
                          TableCell(
                              child: Text(
                                  'Nombre de tubes dans ' +
                                      (natureContent == 'Boîte'
                                          ? 'la '
                                          : 'le ') +
                                      natureContent.toLowerCase(),
                                  style: textStyle))
                        ],
                      ),
                      TableRow(
                        children: [
                          const TableCell(
                              child:
                                  Text('Avant modification', style: textStyle)),
                          TableCell(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    alreadyOnBoxTubes.length.toString() +
                                        ' / 50',
                                    style: textStyle,
                                    textAlign: TextAlign.center,
                                  )))
                        ],
                      ),
                      TableRow(
                        children: [
                          const TableCell(
                              child:
                                  Text('Après modification', style: textStyle)),
                          TableCell(
                              child: Text(
                                  (action[0] == '1'
                                              ? alreadyOnBoxTubes.length +
                                                  tubes.length
                                              : alreadyOnBoxTubes.length -
                                                  tubes.length)
                                          .toString() +
                                      ' / 50',
                                  style: textStyle,
                                  textAlign: TextAlign.center))
                        ],
                      ),
                    ]),
              if (showTourneeDialog)
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
                              child: Text('Code tournée : ', style: textStyle)),
                          TableCell(
                              child: SizedBox(
                                  height: 70,
                                  child: showCarDialog
                                      ? Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 14, 0, 0),
                                          child: Text(
                                            tourneeController.text.isEmpty
                                                ? 'Aucun'
                                                : tourneeController.text,
                                            style: textStyle,
                                          ))
                                      : Row(children: [
                                          SizedBox(
                                              width: 320,
                                              child: SizedBox(
                                                  height: 70,
                                                  child: TextField(
                                                      autofocus: true,
                                                      controller:
                                                          tourneeController,
                                                      decoration:
                                                          const InputDecoration(
                                                              hintText:
                                                                  'Aucun si vide'),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly
                                                      ],
                                                      onSubmitted: (_) {
                                                        setState(() {
                                                          showCarDialog = true;
                                                        });
                                                      }))),
                                          IconButton(
                                              tooltip: 'Valider',
                                              onPressed: () {
                                                setState(() {
                                                  showCarDialog = true;
                                                });
                                              },
                                              icon: const Icon(Icons
                                                  .subdirectory_arrow_left))
                                        ])))
                        ],
                      ),
                      if (showCarDialog)
                        TableRow(
                          children: [
                            const TableCell(
                                child:
                                    Text('Code voiture : ', style: textStyle)),
                            TableCell(
                                child: SizedBox(
                                    height: 70,
                                    child: showCommentDialog
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 14, 0, 0),
                                            child: Text(
                                              carController.text.isEmpty
                                                  ? 'Aucun'
                                                  : carController.text,
                                              style: textStyle,
                                            ))
                                        : Row(children: [
                                            SizedBox(
                                                width: 320,
                                                child: SizedBox(
                                                    height: 70,
                                                    child: TextField(
                                                        autofocus: true,
                                                        controller:
                                                            carController,
                                                        decoration:
                                                            const InputDecoration(
                                                                hintText:
                                                                    'Aucun si vide'),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly
                                                        ],
                                                        onSubmitted: (_) {
                                                          setState(() {
                                                            showCommentDialog =
                                                                true;
                                                          });
                                                        }))),
                                            IconButton(
                                                tooltip: 'Valider',
                                                onPressed: () {
                                                  setState(() {
                                                    showCommentDialog = true;
                                                  });
                                                },
                                                icon: const Icon(Icons
                                                    .subdirectory_arrow_left))
                                          ])))
                          ],
                        ),
                      if (showCommentDialog)
                        TableRow(
                          children: [
                            const TableCell(
                                child:
                                    Text('Commentaire : ', style: textStyle)),
                            TableCell(
                                child: SizedBox(
                                    height: 70,
                                    child: showValidation
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 14, 0, 0),
                                            child: Text(
                                              commentController.text.isEmpty
                                                  ? 'Aucun'
                                                  : commentController.text,
                                              style: textStyle,
                                            ))
                                        : Row(children: [
                                            SizedBox(
                                                width: 320,
                                                child: SizedBox(
                                                    height: 70,
                                                    child: TextField(
                                                        autofocus: true,
                                                        controller:
                                                            commentController,
                                                        decoration:
                                                            const InputDecoration(
                                                                hintText:
                                                                    'Aucun si vide'),
                                                        onSubmitted: (_) {
                                                          setState(() {
                                                            showValidation =
                                                                true;
                                                          });
                                                        }))),
                                            IconButton(
                                                tooltip: 'Valider',
                                                onPressed: () {
                                                  setState(() {
                                                    showValidation = true;
                                                  });
                                                },
                                                icon: const Icon(Icons
                                                    .subdirectory_arrow_left))
                                          ])))
                          ],
                        ),
                    ]),
              if (showValidation)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                  child: ElevatedButton(
                    style: myButtonStyle,
                    child: Text((action[0] == '3' ? 'Ramasser' : 'Déposer') +
                        ' la boîte'),
                    onPressed: () {
                      switch (action[0]) {
                        case '3':
                          onPickUpBox();
                          break;
                        case '4':
                          onDepositBox();
                          break;
                      }
                    },
                  ),
                ),
              if (showBoxDialog)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 25, 0, 10),
                  child: ElevatedButton(
                    style: myButtonStyle,
                    child: const Text('Annuler'),
                    onPressed: () {
                      onResetStates();
                    },
                  ),
                ),
            ]),
          )),
      if (showTubeDialog)
        Dialog(
            insetPadding: const EdgeInsets.all(50),
            elevation: 8,
            child: SizedBox(
                height: 700,
                child: Column(children: [
                  SizedBox(
                      width: 600,
                      height: 640,
                      child: Scrollbar(
                          controller: _secondScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                              controller: _secondScrollController,
                              child: Column(children: [
                                Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      natureContent +
                                          ' n° ' +
                                          boxController.text,
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade800),
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
                                                ? BoxDecoration(
                                                    color: Colors.grey.shade200)
                                                : null,
                                            children: [
                                              TableCell(
                                                  child: Text(
                                                ' ' +
                                                    (tubes.indexOf(i) + 1)
                                                        .toString(),
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
                              ])))),
                  if (tubes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: ElevatedButton(
                        style: myButtonStyle,
                        child: const Text('Valider les changements'),
                        onPressed: () {
                          switch (action[0]) {
                            case '1':
                              if (natureContent == 'Sachet') {
                                onAddBag();
                              }
                              onAddTube();
                              break;
                            case '2':
                              onRemoveTube();
                              break;
                            case '5':
                              onRemoveTube();
                          }
                        },
                      ),
                    ),
                ])))
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (sites.isNotEmpty && users.isNotEmpty) {
      if (MediaQuery.of(context).size.width > 1400 || !showTubeDialog) {
        return Scrollbar(
            controller: _mainScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
                controller: _mainScrollController,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: screen())));
      } else {
        return Scrollbar(
            controller: _mainScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
                controller: _mainScrollController,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: screen())));
      }
    }
    return const Center(child: CircularProgressIndicator());
  }
}
