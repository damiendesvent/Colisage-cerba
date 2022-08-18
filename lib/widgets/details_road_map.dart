import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../variables/globals.dart' as globals;
import '../models/road_map.dart';
import '../models/site.dart';
import 'package:http/http.dart' as http;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'dart:async';
import 'dart:convert';
import 'package:searchfield/searchfield.dart';

class DetailsRoadMapScreen extends StatelessWidget {
  final RoadMap roadMap;
  final bool editing;
  const DetailsRoadMapScreen(
      {required this.roadMap, required this.editing, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Expanded(
          child: DetailsRoadMap(
        roadMap: roadMap,
        editing: editing,
      ))
    ]);
  }
}

class DetailsRoadMap extends StatefulWidget {
  final RoadMap roadMap;
  final bool editing;
  const DetailsRoadMap({required this.roadMap, required this.editing, Key? key})
      : super(key: key);

  @override
  _DetailsRoadMapState createState() => _DetailsRoadMapState();
}

class _DetailsRoadMapState extends State<DetailsRoadMap> {
  final StreamController<List> _streamController = StreamController<List>();
  int i = 0;
  bool _isAscending = true;
  int _currentSortColumn = 2;
  late List roadmaps;
  late RoadMap roadMap = widget.roadMap;
  late bool editing = widget.editing;
  String? editingDetailRoadMap;
  String? onCallStatus;
  bool onCallValue = false;
  late Iterable<Site> sites;
  bool showDeleteDetailRoadMap = false;
  final ScrollController _scrollController = ScrollController();

  Future getDetailsRoadMapList() async {
    String phpUriDetailsRoadMapList =
        Env.urlPrefix + 'Road_map_details/list_road_map_detail.php';
    http.Response res =
        await http.post(Uri.parse(phpUriDetailsRoadMapList), body: {
      'codeTournee': globals.detailedRoadMap.code.toString(),
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      'delete': showDeleteDetailRoadMap ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        roadmaps = items;
      });
      _streamController.add(items);
    }
  }

  sorting(String field) {
    return ((columnIndex, _) {
      setState(() {
        _currentSortColumn = columnIndex;
        _isAscending = !_isAscending;
        searchDetailRoadMap();
      });
    });
  }

  void onUpdateRoadMap(RoadMap myRoadMap) async {
    String phpUriRoadMapDetail =
        Env.urlPrefix + 'Road_maps/details_road_map.php';
    String phpUriRoadMapUpdate =
        Env.urlPrefix + 'Road_maps/update_road_map.php';
    await http.post(Uri.parse(phpUriRoadMapUpdate), body: {
      "searchCode": roadMap.code.toString(),
      "libelle": myRoadMap.libelle,
      "tel": myRoadMap.tel,
      "pda": myRoadMap.sortingNumer.toString(),
      "comment": myRoadMap.comment,
    });
    http.Response res = await http.post(Uri.parse(phpUriRoadMapDetail),
        body: {"searchCode": roadMap.code.toString()});
    if (res.body.isNotEmpty) {
      List item = json.decode(res.body);
      setState(() {
        roadMap = RoadMap.fromList(item);
        globals.detailedRoadMap = roadMap;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  void onUpdateDetailRoadMap(
      String libelleSite, String time, String onCall, String comment) async {
    String phpUriDetailRoadMapUpdate =
        Env.urlPrefix + 'Road_map_details/update_road_map_detail.php';
    await http.post(Uri.parse(phpUriDetailRoadMapUpdate), body: {
      "searchCode": editingDetailRoadMap,
      "libelleSite": libelleSite,
      "time": time,
      "onCall": onCall,
      "comment": comment,
    });
    setState(() {
      editingDetailRoadMap = null;
      onCallStatus = null;
    });
    Future.delayed(Duration(milliseconds: globals.milisecondWait),
        () => searchDetailRoadMap());
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  void onDelete(Map<dynamic, dynamic> roadMapDetail) {
    String phpUriRoadMapDetailDelete =
        Env.urlPrefix + 'Road_map_details/delete_road_map_detail.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25))),
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir supprimer \nl\'étape n°' +
                    roadMapDetail['CODE AVANCEMENT'] +
                    ' : ' +
                    roadMapDetail['LIBELLE SITE'] +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriRoadMapDetailDelete), body: {
                        "searchCode":
                            roadMapDetail['CODE TOURNEE + AVANCEMENT'],
                        "cancel": 'false'
                      });
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => searchDetailRoadMap());
                      final snackBar = SnackBar(
                        backgroundColor: Colors.green[800],
                        duration: const Duration(seconds: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        content: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              Text(
                                ' L\'étape n° ' +
                                    roadMapDetail['CODE AVANCEMENT'] +
                                    ' : ' +
                                    roadMapDetail['LIBELLE SITE'] +
                                    ' a bien été supprimé.',
                                textAlign: TextAlign.center,
                                style: defaultTextStyle,
                              )
                            ]),
                        action: SnackBarAction(
                          label: 'Annuler',
                          textColor: Colors.white,
                          onPressed: () {
                            http.post(Uri.parse(phpUriRoadMapDetailDelete),
                                body: {
                                  "searchCode": roadMapDetail[
                                      'CODE TOURNEE + AVANCEMENT'],
                                  "cancel": 'true'
                                });
                            Future.delayed(
                                Duration(milliseconds: globals.milisecondWait),
                                () => searchDetailRoadMap());
                          },
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    child: const Text('Oui')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Non')),
              ],
              elevation: 16,
            ));
  }

  void onRestore(Map<dynamic, dynamic> roadMapDetail) {
    String phpUriRoadMapDetailDelete =
        Env.urlPrefix + 'Road_map_details/delete_road_map_detail.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25))),
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir restaurer \nl\'étape n°' +
                    roadMapDetail['CODE AVANCEMENT'] +
                    ' : ' +
                    roadMapDetail['LIBELLE SITE'] +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriRoadMapDetailDelete), body: {
                        "searchCode":
                            roadMapDetail['CODE TOURNEE + AVANCEMENT'],
                        "cancel": 'true'
                      });
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => searchDetailRoadMap());
                      final snackBar = SnackBar(
                        backgroundColor: Colors.green[800],
                        duration: const Duration(seconds: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        content: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              Text(
                                ' L\'étape n° ' +
                                    roadMapDetail['CODE AVANCEMENT'] +
                                    ' : ' +
                                    roadMapDetail['LIBELLE SITE'] +
                                    ' a bien été restaurée.',
                                textAlign: TextAlign.center,
                                style: defaultTextStyle,
                              )
                            ]),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    child: const Text('Oui')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Non')),
              ],
              elevation: 16,
            ));
  }

  void onAddDetailRoadMap(
      {required String code,
      required String site,
      required String time,
      required String comment,
      required bool onCallValue}) {
    String phpUriAddDetailRoadMap =
        Env.urlPrefix + 'Road_map_details/add_road_map_detail.php';
    http.post(Uri.parse(phpUriAddDetailRoadMap), body: {
      "progressCode": code,
      "roadMapCode": roadMap.code.toString(),
      "siteLibelle": site,
      "time": time,
      "onCall": onCallValue ? '1' : '0',
      "comment": comment
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      Text('L\'étape n° ' + code + ' a bien été ajouté'),
    ));
    Future.delayed(Duration(milliseconds: globals.milisecondWait),
        () => getDetailsRoadMapList());
  }

  Future<bool> isDetailRoadMap(String code) async {
    String phpUriDetailsDetailRoadMap =
        Env.urlPrefix + 'Road_map_details/details_road_map_detail.php';
    http.Response res = await http.post(Uri.parse(phpUriDetailsDetailRoadMap),
        body: {"searchCode": code});
    if (res.body.isNotEmpty && res.body != '[]') {
      return true;
    }
    return false;
  }

  void showAddPageDetailRoadMap() {
    TextEditingController codeController = TextEditingController();
    TextEditingController siteController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    TextEditingController commentController = TextEditingController();
    bool submited = false;
    String codeValueCheck = 'Veuillez entrer une valeur';
    bool codeExisting = true;

    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
                elevation: 8,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                      width: 500,
                      height: 420,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Ajout d\'une étape',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey.shade700),
                              )),
                          const Spacer(),
                          Table(
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              defaultColumnWidth:
                                  const FractionColumnWidth(0.4),
                              children: [
                                TableRow(
                                  children: [
                                    TableCell(
                                        child: Text('Code avancement* : ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: defaultTextStyle
                                                    .fontSize))),
                                    TableCell(
                                        child: SizedBox(
                                            height: 50,
                                            child: TextField(
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                style: defaultTextStyle,
                                                controller: codeController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      3),
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                decoration: InputDecoration(
                                                  errorStyle: TextStyle(
                                                      fontSize: defaultTextStyle
                                                              .fontSize! -
                                                          4,
                                                      height: 0.3),
                                                  errorText: ((codeController
                                                                  .text
                                                                  .isEmpty ||
                                                              codeExisting) &&
                                                          submited
                                                      ? codeValueCheck
                                                      : null),
                                                ))))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Site* : ',
                                            style: defaultTextStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 70,
                                            child: SearchField(
                                              controller: siteController,
                                              emptyWidget: Text(
                                                  'Aucun site trouvé',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color:
                                                          Colors.red.shade900,
                                                      fontSize: 15)),
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
                                                        Site>(
                                                      e.libelle,
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
                                        child: Text('Heure arrivée* : ',
                                            style: defaultTextStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 50,
                                            child: TextField(
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                style: defaultTextStyle,
                                                textAlign: TextAlign.center,
                                                controller: timeController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      5),
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp('[0-9h]'))
                                                ],
                                                decoration: InputDecoration(
                                                  errorStyle: TextStyle(
                                                      fontSize: defaultTextStyle
                                                              .fontSize! -
                                                          4,
                                                      height: 0.3),
                                                  hintText: 'au format 00h00',
                                                  errorText: (timeController
                                                                  .text.length <
                                                              5 &&
                                                          submited
                                                      ? 'Valeur non valide'
                                                      : null),
                                                ))))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Passage sur appel : ',
                                            style: defaultTextStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 50,
                                            width: 100,
                                            child: Checkbox(
                                              value: onCallValue,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  onCallValue = value!;
                                                });
                                              },
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Commentaire : ',
                                            style: defaultTextStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 50,
                                            child: TextField(
                                              style: defaultTextStyle,
                                              controller: commentController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    128)
                                              ],
                                            )))
                                  ],
                                )
                              ]),
                          Center(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: SizedBox(
                                      width: 231,
                                      child: Row(children: [
                                        ElevatedButton(
                                          style: myButtonStyle,
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Row(children: const [
                                            Icon(Icons.clear),
                                            Text(' Annuler')
                                          ]),
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10)),
                                        ElevatedButton(
                                          style: myButtonStyle,
                                          onPressed: () {
                                            setState(() {
                                              submited = true;
                                              codeExisting = true;
                                            });
                                            isDetailRoadMap(
                                                    roadMap.code.toString() +
                                                        codeController.text
                                                            .padLeft(3, '0'))
                                                .then((value) => setState(() {
                                                      codeExisting = value;
                                                      codeValueCheck = codeExisting
                                                          ? 'Etape existante'
                                                          : 'Veuillez entrer une valeur';
                                                      if (codeController.text.isNotEmpty &&
                                                          siteController.text
                                                              .isNotEmpty &&
                                                          timeController
                                                                  .text.length >
                                                              4 &&
                                                          !codeExisting) {
                                                        onAddDetailRoadMap(
                                                            code: codeController
                                                                .text,
                                                            site: siteController
                                                                .text,
                                                            time: timeController
                                                                .text,
                                                            comment:
                                                                commentController
                                                                    .text,
                                                            onCallValue:
                                                                onCallValue);
                                                      }
                                                    }));
                                          },
                                          child: Row(children: const [
                                            Icon(Icons.check),
                                            Text(' Valider')
                                          ]),
                                        )
                                      ])))),
                          const Spacer(),
                        ],
                      ))
                ]));
          });
        });
  }

  Widget headerRoadMap(bool isEditing) {
    double cellHeight = 20;
    if (!isEditing) {
      return Dialog(
          insetPadding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25))),
          elevation: 8,
          child: SizedBox(
              width: 500,
              height: 110,
              child: Center(
                  child: Table(
                      defaultColumnWidth: const FractionColumnWidth(0.4),
                      children: [
                    TableRow(children: [
                      TableCell(
                          child: SizedBox(
                              height: cellHeight,
                              child: Text('Code tournée :',
                                  style: TextStyle(
                                      fontSize: defaultTextStyle.fontSize! + 2,
                                      fontWeight: FontWeight.bold)))),
                      TableCell(
                          child: SelectableText(roadMap.code.toString(),
                              style: TextStyle(
                                  fontSize: defaultTextStyle.fontSize! + 2,
                                  fontWeight: FontWeight.bold)))
                    ]),
                    TableRow(children: [
                      TableCell(
                          child: SizedBox(
                              height: cellHeight,
                              child: const Text('Libellé :',
                                  style: defaultTextStyle))),
                      TableCell(
                          child: SelectableText(roadMap.libelle,
                              style: defaultTextStyle))
                    ]),
                    TableRow(children: [
                      TableCell(
                          child: SizedBox(
                              height: cellHeight,
                              child: const Text('Téléphone chauffeur :',
                                  style: defaultTextStyle))),
                      TableCell(
                          child: SelectableText(roadMap.tel,
                              style: defaultTextStyle))
                    ]),
                    TableRow(children: [
                      TableCell(
                          child: SizedBox(
                              height: cellHeight,
                              child: const Text('Ordre d\'affichage PDA :',
                                  style: defaultTextStyle))),
                      TableCell(
                          child: SelectableText(roadMap.sortingNumer.toString(),
                              style: defaultTextStyle))
                    ]),
                    TableRow(children: [
                      TableCell(
                          child: SizedBox(
                              height: cellHeight,
                              child: const Text('Commentaire :',
                                  style: defaultTextStyle))),
                      TableCell(
                          child: SelectableText(roadMap.comment,
                              style: defaultTextStyle))
                    ]),
                  ]))));
    } else {
      late TextEditingController libelleController =
          TextEditingController(text: roadMap.libelle);
      late TextEditingController telController =
          TextEditingController(text: roadMap.tel);
      late TextEditingController commentController =
          TextEditingController(text: roadMap.comment);
      late TextEditingController pdaController =
          TextEditingController(text: roadMap.sortingNumer.toString());
      return Dialog(
          insetPadding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25))),
          elevation: 8,
          child: SizedBox(
              width: 500,
              height: 250,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Code tournée : ${roadMap.code}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        defaultColumnWidth: const FractionColumnWidth(0.4),
                        children: [
                          TableRow(children: [
                            const TableCell(
                                child: Text('Libellé* : ',
                                    style: defaultTextStyle)),
                            TableCell(
                                child: SizedBox(
                              width: 200,
                              height: cellHeight + 15,
                              child: TextField(
                                style: defaultTextStyle,
                                controller: libelleController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(35)
                                ],
                              ),
                            ))
                          ]),
                          TableRow(children: [
                            const TableCell(
                                child: Text('Téléphone chauffeur* : ',
                                    style: defaultTextStyle)),
                            TableCell(
                                child: SizedBox(
                              width: 200,
                              height: cellHeight + 15,
                              child: TextField(
                                style: defaultTextStyle,
                                controller: telController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(20)
                                ],
                              ),
                            ))
                          ]),
                          TableRow(children: [
                            const TableCell(
                                child: Text('Ordre d\'affichage PDA* : ',
                                    style: defaultTextStyle)),
                            TableCell(
                                child: SizedBox(
                              width: 200,
                              height: cellHeight + 15,
                              child: TextField(
                                style: defaultTextStyle,
                                controller: pdaController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ))
                          ]),
                          TableRow(children: [
                            const TableCell(
                                child: Text('Commentaire : ',
                                    style: defaultTextStyle)),
                            TableCell(
                                child: SizedBox(
                              width: 200,
                              height: cellHeight + 15,
                              child: TextField(
                                style: defaultTextStyle,
                                controller: commentController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(128)
                                ],
                              ),
                            ))
                          ]),
                        ]),
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: SizedBox(
                                width: 231,
                                child: Row(children: [
                                  ElevatedButton(
                                      style: myButtonStyle,
                                      onPressed: () {
                                        setState(() {
                                          editing = false;
                                        });
                                      },
                                      child: Row(children: const [
                                        Icon(Icons.clear),
                                        Text(' Annuler')
                                      ])),
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10)),
                                  ElevatedButton(
                                    style: myButtonStyle,
                                    onPressed: () {
                                      onUpdateRoadMap(RoadMap(
                                          code: roadMap.code,
                                          libelle: libelleController.text,
                                          tel: telController.text,
                                          comment: commentController.text,
                                          sortingNumer:
                                              int.parse(pdaController.text)));
                                      setState(() {
                                        editing = false;
                                      });
                                    },
                                    child: Row(children: const [
                                      Icon(Icons.check),
                                      Text(' Valider')
                                    ]),
                                  )
                                ])))),
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('* : champs obligatoires',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 12)))
                  ])));
    }
  }

  advancedResearch() {
    if (isAdvancedResearch) {
      return [
        Padding(
            padding: const EdgeInsets.only(left: 10),
            child: DropdownButtonHideUnderline(
                child: DropdownButton(
                    value: advancedSearchField,
                    style: defaultTextStyle,
                    items: searchFieldList.map((searchFieldList) {
                      return DropdownMenuItem(
                          value: searchFieldList,
                          child: Text(searchFieldList.toString()));
                    }).toList(),
                    onChanged: (String? newAdvancedSearchField) {
                      setState(() {
                        advancedSearchField = newAdvancedSearchField!;
                      });
                    }))),
        Expanded(
            child: TextFormField(
          style: defaultTextStyle,
          controller: _advancedSearchTextController,
          decoration:
              const InputDecoration(hintText: 'Deuxième champ de recherche'),
          onFieldSubmitted: (e) {
            searchDetailRoadMap();
          },
        )),
        const Spacer(),
      ];
    } else {
      return [const Spacer()];
    }
  }

  void getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList), body: {
      "limit": '10000',
      "order": '',
      "isAscending": '',
      "delete": 'false'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        sites = items.map(
          (e) => Site.fromSnapshot(e),
        );
      });
    }
  }

  Future searchDetailRoadMap() async {
    String phpUriDetailRoadMapSearch =
        Env.urlPrefix + 'Road_map_details/search_road_map_detail.php';
    http.Response res =
        await http.post(Uri.parse(phpUriDetailRoadMapSearch), body: {
      "codeTournee": globals.detailedRoadMap.code.toString(),
      "field": searchField.toUpperCase(),
      "advancedField": advancedSearchField.toUpperCase(),
      "searchText": _searchTextController.text,
      "advancedSearchText":
          isAdvancedResearch ? _advancedSearchTextController.text : '',
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      "delete": showDeleteDetailRoadMap ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      _streamController.add(itemsSearch);
    }
  }

  List<DataCell> dataCells(Map<dynamic, dynamic> roadMapDetail) {
    if (roadMapDetail['CODE TOURNEE + AVANCEMENT'] == editingDetailRoadMap) {
      onCallStatus ??=
          roadMapDetail['PASSAGE SUR APPEL'] == '1' ? 'Oui' : 'Non';
      List<String> onCallList = ['Oui', 'Non'];
      TextEditingController timeController =
          TextEditingController(text: roadMapDetail['HEURE ARRIVEE']);
      TextEditingController libelleController =
          TextEditingController(text: roadMapDetail['LIBELLE SITE']);
      TextEditingController commentController =
          TextEditingController(text: roadMapDetail['COMMENTAIRE']);
      return [
        DataCell(Text(roadMapDetail['CODE AVANCEMENT'])),
        DataCell(SearchField(
          controller: libelleController,
          emptyWidget: Text('Aucun site trouvé',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: defaultTextStyle.fontSize)),
          suggestions: sites
              .map(
                (e) => SearchFieldListItem<Site>(
                  e.libelle,
                  item: e,
                ),
              )
              .toList(),
        )),
        DataCell(TextField(
          style: defaultTextStyle,
          controller: timeController,
          inputFormatters: [
            LengthLimitingTextInputFormatter(5),
            FilteringTextInputFormatter.allow(RegExp('[0-9h]'))
          ],
        )),
        DataCell(TextField(
            style: defaultTextStyle,
            controller: commentController,
            inputFormatters: [LengthLimitingTextInputFormatter(128)])),
        DataCell(DropdownButton(
            value: onCallStatus,
            style: defaultTextStyle,
            items: onCallList.map((onCall) {
              return DropdownMenuItem(value: onCall, child: Text(onCall));
            }).toList(),
            onChanged: (String? newOnCallStatus) {
              setState(() {
                onCallStatus = newOnCallStatus!;
              });
            })),
        DataCell(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  if (sites.any((e) => e.libelle == libelleController.text)) {
                    onUpdateDetailRoadMap(
                        libelleController.text,
                        timeController.text,
                        onCallStatus!,
                        commentController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
                        const Text(
                          'Site introuvable, veuillez selectionner un site dans la liste',
                          textAlign: TextAlign.center,
                          style: defaultTextStyle,
                        ),
                        color: (Colors.red[800])!,
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white,
                        )));
                  }
                },
                icon: const Icon(Icons.check)),
            IconButton(
                onPressed: () {
                  setState(() {
                    editingDetailRoadMap = null;
                    onCallStatus = null;
                  });
                },
                icon: const Icon(Icons.clear_outlined))
          ],
        ))
      ];
    } else {
      return [
        DataCell(SelectableText(roadMapDetail['CODE AVANCEMENT'],
            style: defaultTextStyle)),
        DataCell(SelectableText(roadMapDetail['LIBELLE SITE'],
            style: defaultTextStyle)),
        DataCell(SelectableText(roadMapDetail['HEURE ARRIVEE'],
            style: defaultTextStyle)),
        DataCell(SelectableText(roadMapDetail['COMMENTAIRE'] ?? '',
            style: defaultTextStyle)),
        DataCell(SelectableText(
            roadMapDetail['PASSAGE SUR APPEL'] == '1' ? 'Oui' : 'Non',
            style: defaultTextStyle)),
        if (globals.user.roadMapRights > 1)
          DataCell(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    editingDetailRoadMap =
                        roadMapDetail['CODE TOURNEE + AVANCEMENT'];
                  });
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Editer',
              ),
              if (!showDeleteDetailRoadMap)
                IconButton(
                  onPressed: () {
                    onDelete(roadMapDetail);
                  },
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Supprimer',
                ),
              if (showDeleteDetailRoadMap)
                IconButton(
                  onPressed: () {
                    onRestore(roadMapDetail);
                  },
                  icon: const Icon(Icons.settings_backup_restore),
                  tooltip: 'Restaurer',
                )
            ],
          ))
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    getDetailsRoadMapList();
    getSiteList();
  }

  bool isAdvancedResearch = false;
  static const searchFieldList = [
    'Code avancement',
    'Libellé site',
    'Heure arrivée',
    'Commentaire',
    'Passage sur appel',
  ];
  String searchField = searchFieldList.first;
  String advancedSearchField = searchFieldList[1];
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  static const numberDisplayedList = [10, 25, 50, 100];
  int numberDisplayed = 25;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List>(
        stream: _streamController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                appBar: PreferredSize(
                    child: Column(children: [
                      Container(
                          width: double.infinity,
                          color: backgroundColor,
                          child: headerRoadMap(editing)),
                      AppBar(
                          elevation: 8,
                          toolbarHeight: isAdvancedResearch ? 100 : 55,
                          backgroundColor: Colors.grey[300],
                          flexibleSpace: Column(children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: DropdownButtonHideUnderline(
                                      child: DropdownButton(
                                          value: searchField,
                                          style: defaultTextStyle,
                                          items: searchFieldList
                                              .map((searchFieldList) {
                                            return DropdownMenuItem(
                                                value: searchFieldList,
                                                child: Text(searchFieldList
                                                    .toString()));
                                          }).toList(),
                                          onChanged: (String? newsearchField) {
                                            setState(() {
                                              searchField = newsearchField!;
                                            });
                                          }))),
                              Expanded(
                                  child: TextFormField(
                                style: defaultTextStyle,
                                controller: _searchTextController,
                                decoration: const InputDecoration(
                                    hintText: 'Recherche'),
                                onFieldSubmitted: (e) {
                                  searchDetailRoadMap();
                                },
                              )),
                              IconButton(
                                  onPressed: () {
                                    searchDetailRoadMap();
                                  },
                                  icon: const Icon(Icons.search_outlined),
                                  tooltip: 'Rechercher'),
                              if (!isAdvancedResearch)
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isAdvancedResearch = true;
                                      });
                                    },
                                    icon: const Icon(
                                        Icons.manage_search_outlined),
                                    tooltip: 'Recherche avancée'),
                              if (isAdvancedResearch)
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isAdvancedResearch = false;
                                      });
                                    },
                                    icon: const Icon(Icons.search_off_outlined),
                                    tooltip: 'Recherche simple'),
                              const Spacer(),
                              if (globals.user.roadMapRights > 1)
                                ElevatedButton(
                                    style: myButtonStyle,
                                    onPressed: () {
                                      showAddPageDetailRoadMap();
                                    },
                                    child: const Text('Ajouter une étape')),
                              if (globals.shouldDisplaySyncButton)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      getDetailsRoadMapList();
                                      getSiteList();
                                    });
                                  },
                                  icon: const Icon(Icons.sync),
                                  tooltip: 'Actualiser l\'onglet',
                                ),
                              const Spacer(),
                              const Text('Nombre de lignes affichées : ',
                                  style: defaultTextStyle),
                              DropdownButton(
                                  style: defaultTextStyle,
                                  value: numberDisplayed,
                                  items: numberDisplayedList
                                      .map((numberDisplayedList) {
                                    return DropdownMenuItem(
                                        value: numberDisplayedList,
                                        child: Text(
                                            numberDisplayedList.toString()));
                                  }).toList(),
                                  onChanged: (int? newNumberDisplayed) {
                                    setState(() {
                                      numberDisplayed = newNumberDisplayed!;
                                    });
                                  })
                            ]),
                            Row(
                              children: advancedResearch(),
                            )
                          ])),
                    ]),
                    preferredSize: Size(double.infinity, editing ? 325 : 185)),
                body: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              snapshot.data.isEmpty
                                  ? SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height -
                                              348,
                                      child: Center(
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                            const Padding(
                                                padding:
                                                    EdgeInsets.only(bottom: 15),
                                                child: Text(
                                                    'Aucune étape ne correspond à votre recherche.',
                                                    style: defaultTextStyle)),
                                            ElevatedButton(
                                                style: myButtonStyle,
                                                onPressed: () {
                                                  setState(() {
                                                    _searchTextController
                                                        .clear();
                                                    _advancedSearchTextController
                                                        .clear();
                                                    showDeleteDetailRoadMap =
                                                        false;
                                                  });
                                                  getDetailsRoadMapList();
                                                },
                                                child: const Text(
                                                    'Afficher toutes les étapes',
                                                    style: defaultTextStyle))
                                          ])))
                                  : DataTable(
                                      columnSpacing: 0,
                                      headingRowHeight: 50,
                                      sortColumnIndex: _currentSortColumn,
                                      sortAscending: _isAscending,
                                      headingTextStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: defaultTextStyle.fontSize),
                                      columns: [
                                        DataColumn(
                                            label: const Text(
                                                'Code\navancement',
                                                textAlign: TextAlign.center),
                                            onSort: sorting('CODE AVANCEMENT')),
                                        DataColumn(
                                            label: const Text('Site',
                                                textAlign: TextAlign.center),
                                            onSort: sorting('LIBELLE SITE')),
                                        DataColumn(
                                            label: const Text('Heure\narrivée',
                                                textAlign: TextAlign.center),
                                            onSort: sorting('HEURE ARRIVEE')),
                                        DataColumn(
                                            label: const Text('Commentaire',
                                                textAlign: TextAlign.center),
                                            onSort: sorting('COMMENTAIRE')),
                                        DataColumn(
                                            label: const Text(
                                                'Passage\nsur appel',
                                                textAlign: TextAlign.center),
                                            onSort:
                                                sorting('PASSAGE SUR APPEL')),
                                        if (globals.user.roadMapRights > 1)
                                          DataColumn(
                                              label: Row(children: [
                                            const Text('Etapes\nsupprimées :'),
                                            Switch(
                                                value: showDeleteDetailRoadMap,
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    showDeleteDetailRoadMap =
                                                        newValue;
                                                  });
                                                  getDetailsRoadMapList();
                                                })
                                          ]))
                                      ],
                                      rows: [
                                        for (Map roadMapDetail in snapshot.data)
                                          DataRow(
                                            color: MaterialStateProperty
                                                .resolveWith<Color?>(
                                                    (Set<MaterialState>
                                                        states) {
                                              if (states.contains(
                                                  MaterialState.selected)) {
                                                return Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.08);
                                              }
                                              if ((i = i + 1).isEven) {
                                                return Colors.grey
                                                    .withOpacity(0.2);
                                              }
                                              return null; // Use the default value.
                                            }),
                                            cells: dataCells(roadMapDetail),
                                          )
                                      ],
                                    )
                            ]))));
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
