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
    return Scaffold(
      body: const TubeList(),
      backgroundColor: backgroundColor,
    );
  }
}

class TubeList extends StatefulWidget {
  const TubeList({Key? key}) : super(key: key);

  @override
  _TubeListState createState() => _TubeListState();
}

class _TubeListState extends State<TubeList> {
  TextEditingController siteController = TextEditingController();
  TextEditingController userController = TextEditingController();
  TextEditingController boxController = TextEditingController();
  TextEditingController tubeController = TextEditingController();
  TextEditingController roadMapController = TextEditingController();
  TextEditingController carController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  bool submited = false;
  List sites = [];
  List users = [];
  List roadMaps = [];
  static const List<String> actionsList = [
    '1 : Ajouter un tube dans un sachet/boîte',
    '2 : Enlever un tube d\'un sachet/boîte',
    '3 : Ramasser un sachet/boîte',
    '4 : Déposer un sachet/boîte',
    '5 : Vider un sachet/boîte',
    '6 : Réceptionner un sachet/boîte'
  ];
  String action = actionsList.first;
  final formKey = GlobalKey<FormState>();
  final roadMapKey = GlobalKey<FormState>();
  bool showBoxDialog = false;
  bool showBoxesDialog = false;
  bool showTubeDialog = false;
  bool showRoadMapDialog = false;
  bool showCarDialog = false;
  bool showCommentDialog = false;
  bool showValidation = false;
  List tubes = [];
  int index = 1;
  String natureContent = 'Boîte/Sachet';
  List alreadyOnBoxTubes = [];
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _secondScrollController = ScrollController();
  String? boxErrorText;
  var ip = '';
  String tempText = '';
  int confirm = 0;
  bool canChooseSite =
      globals.user.siteRights > 1 || globals.currentSite.isEmpty;
  bool canChooseUser = globals.user.userRights > 1;
  late FocusNode roadMapFocusNode;

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

  void getRoadMapList() async {
    String phpUriRoadMapList = Env.urlPrefix + 'Road_maps/list_road_map.php';
    http.Response res = await http.post(Uri.parse(phpUriRoadMapList),
        body: {"limit": '100000', "delete": 'false'});
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        roadMaps = items.map((item) => item['LIBELLE TOURNEE']).toList();
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

  void getListTube(String code,
      {bool setTubes = false,
      bool removeTubes = false,
      bool resetStates = false}) async {
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
        if (removeTubes) {
          for (String tube in alreadyOnBoxTubes) {
            onRemoveTube(tube);
          }
          setState(() {
            boxController.clear();
          });
          resetStates ? onResetStates() : null;
        }
      });
    }
  }

  void onAddTraca({required String action, String tube = ''}) {
    String phpUriAddTraca = Env.urlPrefix + 'Tracas/add_traca.php';
    http.post(Uri.parse(phpUriAddTraca), body: {
      'user': userController.text
          .substring(0, userController.text.indexOf(':') - 1),
      'site': siteController.text,
      'box': boxController.text,
      'tournee': roadMapController.text,
      'tube': tube,
      'action': action,
      'car': carController.text,
      'comment': commentController.text,
      'registering': DateTime.now()
          .toString()
          .substring(0, DateTime.now().toString().length - 4),
      'pgm': globals.ip.length > 15 ? globals.ip.substring(0, 15) : globals.ip,
    });
  }

  void onRemoveLastTracaTube({required String tube}) {
    String phpUriRemoveLastTracaTube =
        Env.urlPrefix + 'Tracas/remove_tube_traca.php';
    http.post(Uri.parse(phpUriRemoveLastTracaTube), body: {'tube': tube});
    if (action[0] == '1') {
      onRemoveTube(tube);
    } else {
      onAddTube(tube);
    }
  }

  void onResetStates() {
    setState(() {
      natureContent = 'Boîte/sachet';
      showBoxDialog = false;
      showBoxesDialog = false;
      showTubeDialog = false;
      showRoadMapDialog = false;
      showCarDialog = false;
      showCommentDialog = false;
      showValidation = false;
      tubes = [];
      boxController.clear();
      tubeController.clear();
      roadMapController.clear();
      carController.clear();
      commentController.clear();
    });
  }

  void onAddTube(String tube) {
    String phpUriTubeAddOrUpdate =
        Env.urlPrefix + 'Tubes/add_or_update_tube.php';
    onAddTraca(action: 'AJT', tube: tube);
    http.post(Uri.parse(phpUriTubeAddOrUpdate), body: {
      'tube': tube,
      'box': boxController.text,
      'site': siteController.text
    });
  }

  void onAddBag() {
    String phpUriBoxAdd = Env.urlPrefix + 'Boxes/add_box.php';
    http.post(Uri.parse(phpUriBoxAdd),
        body: {'box': boxController.text, 'type': 'SAC'});
  }

  void onRemoveTube(String tube) {
    String phpUriTubeRemoveBox = Env.urlPrefix + 'Tubes/remove_box_tube.php';
    onAddTraca(action: 'VIT', tube: tube);
    http.post(Uri.parse(phpUriTubeRemoveBox), body: {'tube': tube});
  }

  void onPickUpBox() {
    String phpUriUpdateSiteTubes =
        Env.urlPrefix + 'Tubes/update_site_tubes.php';
    onAddTraca(action: 'RAM');
    http.post(Uri.parse(phpUriUpdateSiteTubes),
        body: {'box': boxController.text, 'site': 'SITE PAR DEFAUT'});
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
        natureContent == 'Boîte'
            ? 'La boîte ' + boxController.text + ' a bien été ramassée'
            : 'Le sachet ' + boxController.text + ' a bien été ramassé')));
    onResetStates();
  }

  void onDepositBox() {
    String phpUriUpdateSiteTubes =
        Env.urlPrefix + 'Tubes/update_site_tubes.php';
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
        natureContent == 'Boîte'
            ? 'La boîte ' + boxController.text + ' a bien été déposée'
            : 'Le sachet ' + boxController.text + ' a bien été déposé')));
    if (tubes.isNotEmpty) {
      for (String tube in tubes) {
        onRemoveTube(tube);
      }
      setState(() {
        tubes = [];
      });
    }
    onAddTraca(action: 'DEP');
    http.post(Uri.parse(phpUriUpdateSiteTubes),
        body: {'box': boxController.text, 'site': siteController.text});
    onResetStates();
  }

  Future<Map<String, String>> checkLastBoxTraca() async {
    String phpUriCheckLastTraca =
        Env.urlPrefix + 'Tracas/check_last_action_and_site_traca.php';
    http.Response res = await http.post(Uri.parse(phpUriCheckLastTraca),
        body: {'box': boxController.text});
    if (res.body.isNotEmpty) {
      var items = json.decode(res.body);
      if (items is! bool) {
        return {'action': items['ACTION'], 'site': items['LIBELLE SITE']};
      }
    }
    return {'action': '', 'site': ''};
  }

  Future<bool> isDepositSite() async {
    String phpUriDetailSite =
        Env.urlPrefix + 'Sites/details_site_w_libelle.php';
    http.Response res = await http.post(Uri.parse(phpUriDetailSite),
        body: {'libelle': siteController.text});
    if (res.body.isNotEmpty) {
      var items = json.decode(res.body);
      if (items['SITE DEPOT'] == '1') {
        return true;
      }
    }
    return false;
  }

  Future<String> getSiteTubes() async {
    String phpUriGetSiteTubes = Env.urlPrefix + 'Tubes/get_site_tubes.php';
    http.Response res = await http
        .post(Uri.parse(phpUriGetSiteTubes), body: {'box': boxController.text});
    if (res.body.isNotEmpty) {
      return json.decode(res.body)['LIBELLE SITE'];
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    if (canChooseSite) getSiteList();
    if (canChooseUser) getUserList();
    roadMapFocusNode = FocusNode();
  }

  String? tubeErrorText() {
    if (tubeController.text.isEmpty) {
      setState(() {});
      return 'Veuillez entrer une valeur';
    } else if (tubes.contains(tubeController.text)) {
      setState(() {
        confirm += 1;
      });
      if (confirm > 2) {
        setState(() {
          confirm = 0;
        });
        return null;
      }
      return 'Le tube a déjà été scanné, bippez à nouveau pour confirmer';
    } else if (alreadyOnBoxTubes.contains(tubeController.text) &&
        action[0] == '1') {
      setState(() {
        confirm += 1;
      });
      if (confirm > 2) {
        setState(() {
          confirm = 0;
        });
        return null;
      }
      return 'Le tube est déjà présent, validez à nouveau pour confirmer';
    } else if (alreadyOnBoxTubes.length + tubes.length >= 50) {
      setState(() {});
      return 'La boîte est pleine';
    } else {
      setState(() {
        confirm = 0;
      });
      return null;
    }
  }

  void checkBoxErrorText() {
    checkLastBoxTraca().then((lastTracaBox) {
      if (boxController.text.isNotEmpty) {
        action[0] != '6' ? getNatureContent(boxController.text) : null;
        switch (action[0]) {
          case '1':
            switch (lastTracaBox['action']) {
              case 'AJT':
                if (lastTracaBox['site'] == siteController.text) {
                  getListTube(boxController.text);
                  setState(() {
                    showTubeDialog = true;
                    boxErrorText = null;
                    submited = false;
                  });
                } else {
                  setState(() {
                    boxErrorText =
                        'La boîte contient des tubes d\'un autre site';
                  });
                }
                break;
              case 'VIT':
                getSiteTubes().then((value) {
                  if (value == siteController.text || value.isEmpty) {
                    getListTube(boxController.text);
                    setState(() {
                      showTubeDialog = true;
                      boxErrorText = null;
                      submited = false;
                    });
                  } else {
                    setState(() {
                      boxErrorText =
                          'La boîte contient des tubes d\'un autre site';
                    });
                  }
                });
                break;
              default:
                getListTube(boxController.text);
                setState(() {
                  boxErrorText = null;
                  submited = false;
                  showTubeDialog = true;
                });
                break;
            }
            break;
          case '2':
            getListTube(boxController.text);
            setState(() {
              boxErrorText = null;
              submited = false;
              showTubeDialog = true;
            });
            break;
          case '3':
            switch (lastTracaBox['action']) {
              case 'DEP':
                if (lastTracaBox['site'] == siteController.text) {
                  setState(() {
                    boxErrorText = null;
                    submited = false;
                    showRoadMapDialog = true;
                  });
                } else {
                  setState(() {
                    boxErrorText = 'La boîte n\'est pas sur ce site';
                  });
                }
                break;
              case 'RAM':
                setState(() {
                  boxErrorText = 'Boîte déjà ramassée';
                });
                break;
              default:
                setState(() {
                  boxErrorText = null;
                  submited = false;
                  showRoadMapDialog = true;
                });
                break;
            }
            break;
          case '4':
            switch (lastTracaBox['action']) {
              case '':
                setState(() {
                  boxErrorText = 'La boîte n\'a pas été ramassée';
                });
                break;
              case 'DEP':
                setState(() {
                  boxErrorText = 'La boîte a déjà été déposée';
                });
                break;
              case 'RAM':
                isDepositSite().then((value) {
                  if (value) {
                    getListTube(boxController.text, setTubes: true);
                  }
                });
                setState(() {
                  showRoadMapDialog = true;
                });
                break;
            }
            break;
          case '5':
            boxErrorText = null;
            getListTube(boxController.text,
                removeTubes: true, resetStates: true);
            break;
          case '6':
            if (tubes.contains(boxController.text)) {
              setState(() {
                confirm += 1;
              });
              if (confirm > 1) {
                getListTube(boxController.text, removeTubes: true);
                onAddTraca(action: 'REC');
                setState(() {
                  confirm = 0;
                  tubes.add(boxController.text);
                  boxErrorText = null;
                  showBoxesDialog = true;
                });
              } else {
                setState(() {
                  boxErrorText =
                      'La boîte a déjà été scannée, bippez à nouveau pour confirmer';
                });
              }
            } else {
              getListTube(boxController.text, removeTubes: true);
              onAddTraca(action: 'REC');
              setState(() {
                confirm = 0;
                tubes.add(boxController.text);
                boxErrorText = null;
                showBoxesDialog = true;
              });
            }
        }
      }
    });
  }

  List<Widget> screen() {
    return [
      Dialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25))),
          insetPadding: const EdgeInsets.all(15),
          elevation: 8,
          child: SizedBox(
            width: 500,
            height: 515,
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
                              child: Text('Site : ', style: defaultTextStyle)),
                          TableCell(
                              child: SizedBox(
                                  height: 50,
                                  child: showBoxDialog
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: Text(
                                            siteController.text,
                                            style: defaultTextStyle,
                                          ))
                                      : canChooseSite
                                          ? SearchField(
                                              itemHeight: 30,
                                              searchStyle: defaultTextStyle,
                                              onSubmit: (_) {
                                                formKey.currentState!
                                                    .validate();
                                              },
                                              textInputAction:
                                                  TextInputAction.next,
                                              initialValue: SearchFieldListItem<
                                                      String>(
                                                  globals.currentSite.isEmpty
                                                      ? sites[0]
                                                      : globals.currentSite),
                                              controller: siteController,
                                              validator: (x) {
                                                if (!sites.contains(x) ||
                                                    x!.isEmpty) {
                                                  return 'Veuillez entrer un site valide';
                                                }
                                                return null;
                                              },
                                              emptyWidget: Text(
                                                  'Aucun site trouvé',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color:
                                                          Colors.red.shade900,
                                                      fontSize: defaultTextStyle
                                                              .fontSize! -
                                                          3)),
                                              searchInputDecoration:
                                                  InputDecoration(
                                                errorStyle: TextStyle(
                                                    fontSize: defaultTextStyle
                                                            .fontSize! -
                                                        4,
                                                    height: 0.3),
                                                errorText: (siteController
                                                            .text.isEmpty &&
                                                        submited
                                                    ? 'Veuillez entrer une valeur'
                                                    : null),
                                              ),
                                              suggestions: sites
                                                  .map(
                                                    (e) => SearchFieldListItem<
                                                        String>(
                                                      e,
                                                      item: e,
                                                    ),
                                                  )
                                                  .toList(),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 15),
                                              child: Text(
                                                siteController.text =
                                                    globals.currentSite,
                                                style: defaultTextStyle,
                                              ))))
                        ],
                      ),
                      TableRow(
                        children: [
                          const TableCell(
                              child: Text(
                            'Utilisateur : ',
                            style: defaultTextStyle,
                          )),
                          TableCell(
                              child: SizedBox(
                                  height: 50,
                                  child: showBoxDialog
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: Text(
                                            userController.text,
                                            style: defaultTextStyle,
                                          ))
                                      : canChooseUser
                                          ? SearchField(
                                              itemHeight: 30,
                                              searchStyle: defaultTextStyle,
                                              onSubmit: (_) => formKey
                                                  .currentState!
                                                  .validate(),
                                              initialValue: SearchFieldListItem<
                                                      String>(
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
                                                      color:
                                                          Colors.red.shade900,
                                                      fontSize: defaultTextStyle
                                                              .fontSize! -
                                                          3)),
                                              searchInputDecoration:
                                                  InputDecoration(
                                                errorStyle: TextStyle(
                                                    fontSize: defaultTextStyle
                                                            .fontSize! -
                                                        4,
                                                    height: 0.3),
                                                errorText: (userController
                                                            .text.isEmpty &&
                                                        submited
                                                    ? 'Veuillez entrer une valeur'
                                                    : null),
                                              ),
                                              suggestions: users
                                                  .map(
                                                    (e) => SearchFieldListItem<
                                                        String>(
                                                      e,
                                                      item: e,
                                                    ),
                                                  )
                                                  .toList(),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 15),
                                              child: Text(
                                                userController.text =
                                                    globals.user.code +
                                                        ' : ' +
                                                        globals.user.firstname +
                                                        ' ' +
                                                        globals.user.lastname,
                                                style: defaultTextStyle,
                                              ))))
                        ],
                      ),
                      TableRow(
                        children: [
                          const TableCell(
                              child: Text(
                            'Action : ',
                            style: defaultTextStyle,
                          )),
                          TableCell(
                              child: SizedBox(
                                  height: 50,
                                  child: showBoxDialog
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 16),
                                          child: Text(
                                            action,
                                            style: defaultTextStyle,
                                          ))
                                      : DropdownButtonHideUnderline(
                                          child: DropdownButton(
                                              value: action,
                                              style: defaultTextStyle,
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
                padding: const EdgeInsets.all(15),
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: myButtonStyle.backgroundColor,
                      foregroundColor: myButtonStyle.foregroundColor,
                      padding: myButtonStyle.padding,
                      shape: myButtonStyle.shape),
                  child: const Text('Valider', style: defaultTextStyle),
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
                              if ('34'.contains(action[0])) {
                                getRoadMapList();
                              }
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
                                  style: defaultTextStyle)),
                          TableCell(
                              child: SizedBox(
                                  height: 50,
                                  child: showTubeDialog || showRoadMapDialog
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 21),
                                          child: Text(
                                            boxController.text,
                                            style: defaultTextStyle,
                                          ))
                                      : Row(children: [
                                          SizedBox(
                                              width: 220,
                                              child: SizedBox(
                                                  height: 50,
                                                  child: TextField(
                                                    textAlignVertical:
                                                        TextAlignVertical
                                                            .bottom,
                                                    textInputAction:
                                                        TextInputAction.none,
                                                    style: defaultTextStyle,
                                                    autofocus: true,
                                                    controller: boxController,
                                                    decoration: InputDecoration(
                                                        errorStyle: TextStyle(
                                                            fontSize:
                                                                defaultTextStyle
                                                                        .fontSize! -
                                                                    4,
                                                            height: 0.8),
                                                        errorMaxLines: 2,
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
                                                      onAddBag();
                                                      if ('34'.contains(
                                                          action[0])) {
                                                        setState(() {
                                                          roadMapFocusNode =
                                                              FocusNode();
                                                        });
                                                        roadMapFocusNode
                                                            .requestFocus();
                                                      }
                                                    },
                                                  ))),
                                          IconButton(
                                              tooltip: 'Valider',
                                              onPressed: () {
                                                setState(() {
                                                  submited = true;
                                                });
                                                checkBoxErrorText();
                                                onAddBag();
                                                if ('34'.contains(action[0])) {
                                                  setState(() {
                                                    roadMapFocusNode =
                                                        FocusNode();
                                                  });
                                                  roadMapFocusNode
                                                      .requestFocus();
                                                }
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
                              child: Text('Tube : ', style: defaultTextStyle)),
                          TableCell(
                              child: Row(children: [
                            SizedBox(
                                width: 220,
                                height: 50,
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.bottom,
                                  style: defaultTextStyle,
                                  textInputAction: TextInputAction.none,
                                  autofocus: true,
                                  controller: tubeController,
                                  decoration: InputDecoration(
                                      errorStyle: TextStyle(
                                          fontSize:
                                              defaultTextStyle.fontSize! - 4,
                                          height: 0.8),
                                      errorMaxLines: 2,
                                      errorText:
                                          submited ? tubeErrorText() : null),
                                  onSubmitted: (_) {
                                    setState(() {
                                      submited = true;
                                      if (tempText ==
                                          tubeController.text.substring(
                                              0,
                                              tubeController.text.length ~/
                                                  2)) {
                                        tubeController.text = tempText;
                                      }
                                      tempText = tubeController.text;
                                    });
                                    if (tubeErrorText() == null) {
                                      action[0] == '1'
                                          ? onAddTube(tubeController.text)
                                          : onRemoveTube(tubeController.text);
                                      setState(() {
                                        submited = false;
                                        tubes.add(tubeController.text);
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
                                  if (tubeErrorText() == null) {
                                    action[0] == '1'
                                        ? onAddTube(tubeController.text)
                                        : onRemoveTube(tubeController.text);
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
                              child:
                                  Padding(padding: EdgeInsets.only(top: 80))),
                          TableCell(
                              child: Text(
                                  'Nombre de tubes dans ' +
                                      (natureContent == 'Boîte'
                                          ? 'la '
                                          : 'le ') +
                                      natureContent.toLowerCase(),
                                  style: defaultTextStyle))
                        ],
                      ),
                      TableRow(
                        children: [
                          const TableCell(
                              child: Padding(
                                  padding: EdgeInsets.only(bottom: 15),
                                  child: Text('Avant modification',
                                      style: defaultTextStyle))),
                          TableCell(
                              child: Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: Text(
                                    alreadyOnBoxTubes.length.toString() +
                                        ' / 50',
                                    style: defaultTextStyle,
                                    textAlign: TextAlign.center,
                                  )))
                        ],
                      ),
                      TableRow(
                        children: [
                          const TableCell(
                              child: Text('Après modification',
                                  style: defaultTextStyle)),
                          TableCell(
                              child: Text(
                                  (action[0] == '1'
                                              ? alreadyOnBoxTubes.length +
                                                  tubes.length
                                              : alreadyOnBoxTubes.length -
                                                  tubes.length)
                                          .toString() +
                                      ' / 50',
                                  style: defaultTextStyle,
                                  textAlign: TextAlign.center))
                        ],
                      ),
                    ]),
              if (showRoadMapDialog)
                Form(
                    key: roadMapKey,
                    child: Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: const {
                          0: FixedColumnWidth(160),
                          1: FractionColumnWidth(0.6)
                        },
                        children: [
                          TableRow(
                            children: [
                              const TableCell(
                                  child: Text('Tournée : ',
                                      style: defaultTextStyle)),
                              TableCell(
                                  child: SizedBox(
                                      height: 50,
                                      child: showCarDialog
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 15),
                                              child: Text(
                                                roadMapController.text.isEmpty
                                                    ? 'Aucune'
                                                    : roadMapController.text,
                                                style: defaultTextStyle,
                                              ))
                                          : Row(children: [
                                              SizedBox(
                                                  width: 220,
                                                  child: SearchField(
                                                    focusNode: roadMapFocusNode,
                                                    itemHeight: 30,
                                                    searchStyle:
                                                        defaultTextStyle,
                                                    controller:
                                                        roadMapController,
                                                    validator: (x) {
                                                      if (!roadMaps
                                                              .contains(x) &&
                                                          x!.isNotEmpty) {
                                                        return 'Veuillez entrer une feuille de route valide';
                                                      }
                                                      return null;
                                                    },
                                                    emptyWidget: Text(
                                                        'Aucune feuille de route trouvée',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .red.shade900,
                                                            fontSize:
                                                                defaultTextStyle
                                                                        .fontSize! -
                                                                    3)),
                                                    searchInputDecoration:
                                                        InputDecoration(
                                                      hintText:
                                                          'Aucune si vide',
                                                      errorStyle: TextStyle(
                                                          fontSize:
                                                              defaultTextStyle
                                                                      .fontSize! -
                                                                  4,
                                                          height: 0.3),
                                                      errorText: (siteController
                                                                  .text
                                                                  .isEmpty &&
                                                              submited
                                                          ? 'Veuillez entrer une valeur'
                                                          : null),
                                                    ),
                                                    suggestions: roadMaps
                                                        .map(
                                                          (e) =>
                                                              SearchFieldListItem<
                                                                  String>(
                                                            e,
                                                            item: e,
                                                          ),
                                                        )
                                                        .toList(),
                                                    onSubmit: (_) {
                                                      if (roadMapKey
                                                          .currentState!
                                                          .validate()) {
                                                        setState(() {
                                                          showCarDialog = true;
                                                        });
                                                      }
                                                    },
                                                  )),
                                              IconButton(
                                                  tooltip: 'Valider',
                                                  onPressed: () {
                                                    if (roadMapKey.currentState!
                                                        .validate()) {
                                                      setState(() {
                                                        showCarDialog = true;
                                                      });
                                                    }
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
                                    child: Text('Code voiture : ',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 50,
                                        child: showCommentDialog
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 15),
                                                child: Text(
                                                  carController.text.isEmpty
                                                      ? 'Aucun'
                                                      : carController.text,
                                                  style: defaultTextStyle,
                                                ))
                                            : Row(children: [
                                                SizedBox(
                                                    width: 220,
                                                    height: 50,
                                                    child: TextField(
                                                        style: defaultTextStyle,
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
                                                        })),
                                                IconButton(
                                                    tooltip: 'Valider',
                                                    onPressed: () {
                                                      setState(() {
                                                        showCommentDialog =
                                                            true;
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
                                    child: Text('Commentaire : ',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 50,
                                        child: showValidation
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 15),
                                                child: Text(
                                                  commentController.text.isEmpty
                                                      ? 'Aucun'
                                                      : commentController.text,
                                                  style: defaultTextStyle,
                                                ))
                                            : Row(children: [
                                                SizedBox(
                                                    width: 220,
                                                    height: 50,
                                                    child: TextField(
                                                        style: defaultTextStyle,
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
                                                        })),
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
                        ])),
              if (showValidation)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
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
                  padding: const EdgeInsets.all(15),
                  child: ElevatedButton(
                    style: myButtonStyle,
                    child: const Text('Fermer'),
                    onPressed: () {
                      onResetStates();
                    },
                  ),
                ),
            ]),
          )),
      if (showTubeDialog || showBoxesDialog)
        Dialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25))),
            insetPadding: const EdgeInsets.all(15),
            elevation: 8,
            child: SizedBox(
                height: 515,
                child: Column(children: [
                  SizedBox(
                      width: 500,
                      height: 515,
                      child: Scrollbar(
                          controller: _secondScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                              controller: _secondScrollController,
                              child: Column(children: [
                                Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      showBoxesDialog
                                          ? 'Réception des sachets/boîtes :'
                                          : natureContent +
                                              ' n° ' +
                                              boxController.text,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade800),
                                    )),
                                if (alreadyOnBoxTubes.isNotEmpty &&
                                    !showBoxesDialog)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 20, 410, 5),
                                    child: Text(
                                      'Contenu :',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: defaultTextStyle.fontSize),
                                    ),
                                  ),
                                if (alreadyOnBoxTubes.isNotEmpty &&
                                    !showBoxesDialog)
                                  Table(
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      columnWidths: const {
                                        0: FixedColumnWidth(80),
                                        1: FractionColumnWidth(0.7),
                                        2: FixedColumnWidth(80)
                                      },
                                      children: [
                                        for (String i in alreadyOnBoxTubes)
                                          TableRow(
                                              decoration: alreadyOnBoxTubes
                                                      .indexOf(i)
                                                      .isEven
                                                  ? BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200)
                                                  : null,
                                              children: [
                                                TableCell(
                                                    child: Text(
                                                  ' ' +
                                                      (alreadyOnBoxTubes
                                                                  .indexOf(i) +
                                                              1)
                                                          .toString(),
                                                  style: defaultTextStyle,
                                                )),
                                                TableCell(
                                                    child: Text('tube ' + i,
                                                        style:
                                                            defaultTextStyle)),
                                                const TableCell(
                                                    child: SizedBox(
                                                  height: 40,
                                                ))
                                              ]),
                                      ]),
                                if (tubes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 20, 410, 5),
                                    child: Text(
                                      'Actions :',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: defaultTextStyle.fontSize),
                                    ),
                                  ),
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
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 5),
                                                      child: Text(
                                                        ' ' +
                                                            (tubes.indexOf(i) +
                                                                    1)
                                                                .toString(),
                                                        style: defaultTextStyle,
                                                      ))),
                                              TableCell(
                                                  child: Text(
                                                      action[0] == '6'
                                                          ? 'Réception du sachet/boîte ' +
                                                              i
                                                          : (action[0] == '1'
                                                                  ? 'Ajout'
                                                                  : 'Enlèvement') +
                                                              ' du tube ' +
                                                              i,
                                                      style: defaultTextStyle)),
                                              TableCell(
                                                  child: SizedBox(
                                                      height: 40,
                                                      child: IconButton(
                                                        icon: const Icon(
                                                            Icons.clear),
                                                        onPressed: () {
                                                          setState(() {
                                                            tubes.remove(i);
                                                          });
                                                          onRemoveLastTracaTube(
                                                              tube: i);
                                                        },
                                                      )))
                                            ]),
                                    ]),
                              ])))),
                ])))
    ];
  }

  @override
  Widget build(BuildContext context) {
    if ((!canChooseSite || sites.isNotEmpty) &&
        (!canChooseUser || users.isNotEmpty)) {
      if (MediaQuery.of(context).size.width > 1060 || !showTubeDialog) {
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
