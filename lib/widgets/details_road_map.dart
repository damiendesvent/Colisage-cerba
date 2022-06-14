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
  TextStyle textStyle = const TextStyle(fontSize: 16);
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

  Future getDetailsRoadMapList() async {
    String phpUriDetailsRoadMapList =
        Env.urlPrefix + 'Road_map_details/list_road_map_detail.php';
    http.Response res = await http.post(Uri.parse(phpUriDetailsRoadMapList),
        body: {'codeTournee': globals.detailedRoadMap.code.toString()});
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        roadmaps = items;
      });
      _streamController.add(items);
    }
  }

  void showDetailedSite(String code) async {
    const TextStyle textStyle = TextStyle(fontSize: 16);
    String phpUriDetailedSite = Env.urlPrefix + 'Sites/details_site.php';
    http.Response res = await http
        .post(Uri.parse(phpUriDetailedSite), body: {'searchCode': code});
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      Site site = Site.fromList(items);
      showDialog(
          context: context,
          builder: (_) => Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
              elevation: 8,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                    width: 600,
                    height: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Spacer(),
                        Text('Code site : ' + code,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        const Spacer(),
                        Text('Libellé : ' + site.libelle, style: textStyle),
                        const Spacer(),
                        Text('Correspondant : ' + site.correspondant,
                            style: textStyle),
                        const Spacer(),
                        Text('Adresse : ' + site.adress, style: textStyle),
                        const Spacer(),
                        Text('Complément d\'adresse : ' + site.cpltAdress,
                            style: textStyle),
                        const Spacer(),
                        Text(
                            'Code postal : ' +
                                (site.cp == 0 ? '' : site.cp.toString()),
                            style: textStyle),
                        const Spacer(),
                        Text('Ville : ' + site.city, style: textStyle),
                        const Spacer(),
                        Text(
                            'Site de prélèvement : ' +
                                (site.collectionSite ? 'Oui' : 'Non'),
                            style: textStyle),
                        const Spacer(),
                        Text(
                            'Site de dépôt : ' +
                                (site.depositSite ? 'Oui' : 'Non'),
                            style: textStyle),
                        const Spacer(),
                        Text('Commentaires correspondant : ' + (site.comment),
                            style: textStyle),
                        const Spacer(),
                      ],
                    ))
              ])));
    }
  }

  sorting(String field, {bool isNumber = false}) {
    if (isNumber) {
      return ((columnIndex, _) {
        setState(() {
          _currentSortColumn = columnIndex;
          if (_isAscending) {
            roadmaps.sort((roadmapA, roadmapB) => int.parse(roadmapB[field])
                .compareTo(int.parse(roadmapA[field])));
          } else {
            roadmaps.sort((roadmapA, roadmapB) => int.parse(roadmapA[field])
                .compareTo(int.parse(roadmapB[field])));
          }
          _isAscending = !_isAscending;
        });
      });
    } else {
      return ((columnIndex, _) {
        setState(() {
          _currentSortColumn = columnIndex;
          if (_isAscending) {
            roadmaps.sort((roadmapA, roadmapB) =>
                roadmapB[field].compareTo(roadmapA[field]));
          } else {
            roadmaps.sort((roadmapA, roadmapB) =>
                roadmapA[field].compareTo(roadmapB[field]));
          }
          _isAscending = !_isAscending;
        });
      });
    }
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
    getDetailsRoadMapList();
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  void onDelete(Map<dynamic, dynamic> roadMapDetail) {
    String phpUriRoadMapDetailDelete =
        Env.urlPrefix + 'Road_map_details/delete_road_map_detail.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
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
                      getDetailsRoadMapList();
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
                                style: const TextStyle(fontSize: 16),
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
                            getDetailsRoadMapList();
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
    getDetailsRoadMapList();
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
    const TextStyle textStyle = TextStyle(fontSize: 16);
    TextEditingController codeController = TextEditingController();
    TextEditingController siteController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    TextEditingController commentController = TextEditingController();
    bool submited = false;
    String codeValueCheck = 'Veuillez entrer une valeur';
    bool codeExisting = true;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
                elevation: 8,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                      width: 600,
                      height: 500,
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
                                    const TableCell(
                                        child: Text('Code étape* : ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16))),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
                                            child: TextField(
                                                controller: codeController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      3),
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                decoration: InputDecoration(
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
                                        child:
                                            Text('Site* : ', style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
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
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
                                            child: TextField(
                                                textAlign: TextAlign.center,
                                                controller: timeController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      5),
                                                  //FilteringTextInputFormatter.digitsOnly,
                                                  FilteringTextInputFormatter
                                                      .allow(RegExp('[0-9h]'))
                                                ],
                                                decoration: InputDecoration(
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
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
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
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
                                            child: TextField(
                                              controller: commentController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    254)
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
                                      width: 105,
                                      child: ElevatedButton(
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
                                                        siteController
                                                            .text.isNotEmpty &&
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
                                      )))),
                          const Spacer(),
                        ],
                      ))
                ]));
          });
        });
  }

  Widget headerRoadMap(bool isEditing) {
    if (!isEditing) {
      return Column(children: [
        Text('Code tournée : ${roadMap.code}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Libellé : ${roadMap.libelle}', style: textStyle),
        Text('Téléphone chauffeur : ${roadMap.tel}', style: textStyle),
        Text('Commentaire : ${roadMap.comment}', style: textStyle),
        Text('Ordre d\'affichage PDA : ${roadMap.sortingNumer}',
            style: textStyle),
      ]);
    } else {
      late TextEditingController libelleController =
          TextEditingController(text: roadMap.libelle);
      late TextEditingController telController =
          TextEditingController(text: roadMap.tel);
      late TextEditingController commentController =
          TextEditingController(text: roadMap.comment);
      late TextEditingController pdaController =
          TextEditingController(text: roadMap.sortingNumer.toString());
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Code tournée : ${roadMap.code}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Libellé : ', style: textStyle),
          SizedBox(
            width: 200,
            child: TextField(
              controller: libelleController,
              inputFormatters: [LengthLimitingTextInputFormatter(35)],
            ),
          )
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Téléphone chauffeur : ', style: textStyle),
          SizedBox(
            width: 200,
            child: TextField(
              controller: telController,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
            ),
          )
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Commentaire : ', style: textStyle),
          SizedBox(
            width: 200,
            child: TextField(
              controller: commentController,
              inputFormatters: [LengthLimitingTextInputFormatter(254)],
            ),
          )
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Ordre d\'affichage PDA : ', style: textStyle),
          SizedBox(
            width: 200,
            child: TextField(
              controller: pdaController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(4),
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          )
        ]),
        Center(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                    width: 105,
                    child: ElevatedButton(
                      onPressed: () {
                        onUpdateRoadMap(RoadMap(
                            code: roadMap.code,
                            libelle: libelleController.text,
                            tel: telController.text,
                            comment: commentController.text,
                            sortingNumer: int.parse(pdaController.text)));
                        setState(() {
                          editing = false;
                        });
                      },
                      child: Row(children: const [
                        Icon(Icons.check),
                        Text(' Valider')
                      ]),
                    )))),
      ]);
    }
  }

  void getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.get(Uri.parse(phpUriSiteList));
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        sites = items.map(
          (e) => Site.fromSnapshot(e),
        );
      });
    }
  }

  List<DataCell> dataCells(Map<dynamic, dynamic> roadMapDetail) {
    if (roadMapDetail['CODE TOURNEE + AVANCEMENT'] == editingDetailRoadMap) {
      onCallStatus ??=
          roadMapDetail['PASSAGE SUR APPEL'] == '1' ? 'Oui' : 'Non';
      List<String> onCallList = ['Oui', 'Non'];
      TextEditingController timeController =
          TextEditingController(text: roadMapDetail['HEURE ARRIVEE']);
      TextEditingController libelleController = TextEditingController();
      TextEditingController commentController =
          TextEditingController(text: roadMapDetail['COMMENTAIRE']);
      return [
        DataCell(Text(roadMapDetail['CODE AVANCEMENT'])),
        DataCell(SearchField(
          controller: libelleController,
          emptyWidget: Text('Aucun site trouvé',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade900, fontSize: 15)),
          suggestions: sites
              .map(
                (e) => SearchFieldListItem<Site>(
                  e.libelle,
                  item: e,
                ),
              )
              .toList(),
          initialValue:
              SearchFieldListItem<Site>(roadMapDetail['LIBELLE SITE']),
        )),
        DataCell(TextField(controller: timeController)),
        DataCell(TextField(controller: commentController)),
        DataCell(DropdownButton(
            value: onCallStatus,
            style: const TextStyle(fontSize: 14),
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
                          style: TextStyle(fontSize: 16),
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
        DataCell(Text(roadMapDetail['CODE AVANCEMENT'])),
        DataCell(Text(roadMapDetail['LIBELLE SITE']), onTap: () {
          showDetailedSite(roadMapDetail['CODE SITE']);
        }),
        DataCell(Text(roadMapDetail['HEURE ARRIVEE'])),
        DataCell(Text(roadMapDetail['COMMENTAIRE'])),
        DataCell(
            Text(roadMapDetail['PASSAGE SUR APPEL'] == '1' ? 'Oui' : 'Non')),
        if (globals.user.roadMapEditing)
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
                  icon: const Icon(Icons.edit)),
              IconButton(
                  onPressed: () {
                    onDelete(roadMapDetail);
                  },
                  icon: const Icon(Icons.delete_forever))
            ],
          ))
      ];
    }
  }

  @override
  void initState() {
    getDetailsRoadMapList();
    getSiteList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List>(
        stream: _streamController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  headerRoadMap(editing),
                  DataTable(
                    sortColumnIndex: _currentSortColumn,
                    sortAscending: _isAscending,
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    columns: [
                      DataColumn(
                          label: const Text('Code avancement',
                              textAlign: TextAlign.center),
                          onSort: sorting('CODE AVANCEMENT', isNumber: true)),
                      DataColumn(
                          label:
                              const Text('Site', textAlign: TextAlign.center),
                          onSort: sorting('LIBELLE SITE')),
                      DataColumn(
                          label: const Text('Heure arrivée',
                              textAlign: TextAlign.center),
                          onSort: sorting('HEURE ARRIVEE')),
                      DataColumn(
                          label: const Text('Commentaire',
                              textAlign: TextAlign.center),
                          onSort: sorting('COMMENTAIRE')),
                      DataColumn(
                          label: const Text('Passage sur appel',
                              textAlign: TextAlign.center),
                          onSort: sorting('PASSAGE SUR APPEL')),
                      if (globals.user.roadMapEditing)
                        DataColumn(
                            label: ElevatedButton(
                                onPressed: () {
                                  showAddPageDetailRoadMap();
                                },
                                child: const Text('Ajouter une étape')))
                    ],
                    rows: [
                      for (Map roadMapDetail in snapshot.data)
                        DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08);
                            }
                            if ((i = i + 1).isEven) {
                              return Colors.grey.withOpacity(0.2);
                            }
                            return null; // Use the default value.
                          }),
                          cells: dataCells(roadMapDetail),
                        )
                    ],
                  )
                ]));
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
