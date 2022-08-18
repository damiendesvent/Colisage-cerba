import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import '../models/road_map.dart';
import 'details_road_map.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

enum Menu { itemEdit, itemDelete }

class RoadMapScreen extends StatelessWidget {
  const RoadMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: RoadMapList());
  }
}

class RoadMapList extends StatefulWidget {
  const RoadMapList({Key? key}) : super(key: key);

  @override
  _RoadMapListState createState() => _RoadMapListState();
}

class _RoadMapListState extends State<RoadMapList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => globals.shouldKeepAlive;

  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  bool showDetailsRoadMap = false;
  static const numberDisplayedList = [15, 25, 50, 100];
  int numberDisplayed = numberDisplayedList.first;
  static const searchFieldList = [
    'Libellé tournée',
    'Tel chauffeur',
    'Commentaire',
    'Ordre affichage PDA'
  ];
  String searchField = searchFieldList[0];
  String advancedSearchField = searchFieldList[3];
  bool isEditing = false;
  bool showDeleteRoadMap = false;
  bool isAdvancedResearch = false;
  final ScrollController _scrollController = ScrollController();
  List roadMaps = [];
  bool _isAscending = true;
  int _currentSortColumn = 0;
  TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.bold, fontSize: defaultTextStyle.fontSize);

  Future getRoadMapList() async {
    String phpUriRoadMapList = Env.urlPrefix + 'Road_maps/list_road_map.php';
    http.Response res = await http.post(Uri.parse(phpUriRoadMapList), body: {
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      "delete": showDeleteRoadMap ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        roadMaps = items;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getRoadMapList();
  }

  Future searchRoadMap() async {
    String phpUriRoadMapSearch =
        Env.urlPrefix + 'Road_maps/search_road_map.php';
    http.Response res = await http.post(Uri.parse(phpUriRoadMapSearch), body: {
      "field": searchField.toUpperCase(),
      "advancedField": advancedSearchField.toUpperCase(),
      "searchText": _searchTextController.text,
      "advancedSearchText":
          isAdvancedResearch ? _advancedSearchTextController.text : '',
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      "limit": numberDisplayedList.last.toString(),
      "delete": showDeleteRoadMap ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      setState(() {
        roadMaps = itemsSearch;
      });
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
        SizedBox(
            width: 300,
            child: TextFormField(
              style: defaultTextStyle,
              controller: _advancedSearchTextController,
              decoration: const InputDecoration(
                  hintText: 'Deuxième champ de recherche'),
              onFieldSubmitted: (e) {
                searchRoadMap();
              },
            )),
        const Spacer(),
      ];
    } else {
      return [const Spacer()];
    }
  }

  sorting(String field) {
    return ((columnIndex, _) {
      setState(() {
        _currentSortColumn = columnIndex;
        _isAscending = !_isAscending;
        searchRoadMap();
      });
    });
  }

  void showEditPageRoadMap(RoadMap roadMap) {
    setState(() {
      globals.detailedRoadMap = roadMap;
      isEditing = true;
      showDetailsRoadMap = true;
    });
  }

  void showDetailRoadMap(RoadMap roadMap) {
    setState(() {
      showDetailsRoadMap = true;
      globals.detailedRoadMap = roadMap;
    });
  }

  void onRestore(RoadMap roadMap) {
    String phpUriRoadMapDelete =
        Env.urlPrefix + 'Road_maps/delete_road_map.php';
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
                'Êtes-vous sûr de vouloir restaurer \nla feuille de route ' +
                    roadMap.libelle +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriRoadMapDelete), body: {
                        "searchCode": roadMap.code.toString(),
                        "cancel": 'true'
                      });
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => searchRoadMap());
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
                                ' Le feuille de route n° ' +
                                    roadMap.code.toString() +
                                    ' : ' +
                                    roadMap.libelle +
                                    ' a bien été restauré.',
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

  void onGeneratePDAUpdate() {
    String phpUriCreatePdaFile = Env.urlPrefix + 'Scripts/create_pda_files.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25))),
              title: const Text('Confirmation', textAlign: TextAlign.center),
              content: const Text(
                  'Êtes-vous sûr de vouloir générer\nune mise à jour qui sera accessible\npour tous les PDA ?',
                  textAlign: TextAlign.center),
              actions: [
                TextButton(
                    onPressed: () {
                      http.post(Uri.parse(phpUriCreatePdaFile), body: {
                        'directory_path': globals.pdaTrackInDirectory
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(mySnackBar(const Text(
                        'La mise à jour a bien été envoyée au serveur PDA.',
                        textAlign: TextAlign.center,
                      )));
                    },
                    child: const Text('Oui')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Non'))
              ],
            ));
  }

  void onDelete(RoadMap roadMap) {
    String phpUriRoadMapDelete =
        Env.urlPrefix + 'Road_maps/delete_road_map.php';
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
                'Êtes-vous sûr de vouloir supprimer \nla feuille de route ' +
                    roadMap.libelle +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriRoadMapDelete), body: {
                        "searchCode": roadMap.code.toString(),
                        "cancel": 'false'
                      });
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => searchRoadMap());
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
                                ' La feuille de route ' +
                                    roadMap.libelle +
                                    ' a bien été supprimé.',
                                textAlign: TextAlign.center,
                                style: defaultTextStyle,
                              )
                            ]),
                        action: SnackBarAction(
                          label: 'Annuler',
                          textColor: Colors.white,
                          onPressed: () {
                            http.post(Uri.parse(phpUriRoadMapDelete), body: {
                              "searchCode": roadMap.code.toString(),
                              "cancel": 'true'
                            });
                            Future.delayed(
                                Duration(milliseconds: globals.milisecondWait),
                                () => searchRoadMap());
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

  void onAddRoadMap(RoadMap roadMap) {
    String phpUriAddRoadMap = Env.urlPrefix + 'Road_maps/add_road_map.php';
    http.post(Uri.parse(phpUriAddRoadMap), body: {
      "libelle": roadMap.libelle,
      "tel": roadMap.tel,
      "pda": roadMap.sortingNumer.toString(),
      "comment": roadMap.comment
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      Text('La feuille de route ' + roadMap.libelle + ' a bien été ajouté'),
    ));
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getRoadMapList());
  }

  Future<Map<String, bool>> isRoadMap(String libelle, String order) async {
    String phpUriDetailsRoadMap =
        Env.urlPrefix + 'Road_maps/details_road_map.php';
    http.Response res = await http.post(Uri.parse(phpUriDetailsRoadMap),
        body: {"libelle": libelle, "order": order});
    Map item = json.decode(res.body);
    return {
      'libelleExist': item['libelleExist'] != '0',
      'orderExist': item['orderExist'] != '0'
    };
  }

  void showAddPageRoadMap() {
    TextEditingController libelleController = TextEditingController();
    TextEditingController telController = TextEditingController();
    TextEditingController pdaController = TextEditingController();
    TextEditingController commentController = TextEditingController();
    bool submited = false;
    String? libelleValueCheck;
    String? pdaValueCheck;

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
                      height: 450,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Ajout d\'une feuille de route',
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
                                        child: Text('Libellé* : ',
                                            style: defaultTextStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 50,
                                            child: TextField(
                                              textAlignVertical:
                                                  TextAlignVertical.bottom,
                                              style: defaultTextStyle,
                                              controller: libelleController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                              decoration: InputDecoration(
                                                  errorStyle: TextStyle(
                                                      fontSize: defaultTextStyle
                                                              .fontSize! -
                                                          4,
                                                      height: 0.3),
                                                  errorText: submited
                                                      ? libelleValueCheck
                                                      : null),
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Tel chauffeur : ',
                                            style: defaultTextStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 50,
                                            child: TextField(
                                              style: defaultTextStyle,
                                              controller: telController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    20)
                                              ],
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Ordre affichage PDA* : ',
                                            style: defaultTextStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 50,
                                            child: TextField(
                                              textAlignVertical:
                                                  TextAlignVertical.bottom,
                                              style: defaultTextStyle,
                                              controller: pdaController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    4),
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              decoration: InputDecoration(
                                                  errorStyle: TextStyle(
                                                      fontSize: defaultTextStyle
                                                              .fontSize! -
                                                          4,
                                                      height: 0.3),
                                                  errorText: submited
                                                      ? pdaValueCheck
                                                      : null),
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
                                                    254)
                                              ],
                                            )))
                                  ],
                                ),
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
                                            });
                                            isRoadMap(libelleController.text,
                                                    pdaController.text)
                                                .then(
                                              (value) => setState(() {
                                                libelleValueCheck = value[
                                                        'libelleExist']!
                                                    ? 'Feuille de route existante'
                                                    : (libelleController
                                                            .text.isEmpty
                                                        ? 'Veuillez entrer une valeur'
                                                        : null);
                                                pdaValueCheck = value[
                                                        'orderExist']!
                                                    ? 'Ordre existant'
                                                    : (pdaController
                                                            .text.isEmpty
                                                        ? 'Veuillez entrer une valeur'
                                                        : null);
                                                if (libelleController
                                                        .text.isNotEmpty &&
                                                    pdaController
                                                        .text.isNotEmpty &&
                                                    !(value['libelleExist']! ||
                                                        value['orderExist']!)) {
                                                  onAddRoadMap(RoadMap(
                                                      libelle: libelleController
                                                          .text,
                                                      tel: telController.text,
                                                      sortingNumer: int.parse(
                                                          pdaController.text),
                                                      comment: commentController
                                                          .text));
                                                }
                                              }),
                                            );
                                          },
                                          child: Row(children: const [
                                            Icon(Icons.check),
                                            Text(' Valider')
                                          ]),
                                        )
                                      ])))),
                          const Spacer(),
                          Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('* : champs obligatoires',
                                  style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12)))
                        ],
                      ))
                ]));
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DataTableSource roadMapData = RoadMapData(
        (roadMap) => showEditPageRoadMap(roadMap),
        (roadMap) => onDelete(roadMap),
        (roadMap) => onRestore(roadMap),
        showDeleteRoadMap,
        (roadMap) => showDetailRoadMap(roadMap),
        roadMaps);
    if (roadMaps.isNotEmpty ||
        _searchTextController.text.isNotEmpty ||
        _advancedSearchTextController.text.isNotEmpty) {
      if (!showDetailsRoadMap) {
        return Scaffold(
            appBar: AppBar(
              elevation: 8,
              toolbarHeight: isAdvancedResearch ? 100 : 55,
              backgroundColor: Colors.grey[300],
              flexibleSpace: FlexibleSpaceBar(
                  background: Column(children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton(
                              value: searchField,
                              style: defaultTextStyle,
                              items: searchFieldList.map((searchFieldList) {
                                return DropdownMenuItem(
                                    value: searchFieldList,
                                    child: Text(searchFieldList.toString()));
                              }).toList(),
                              onChanged: (String? newsearchField) {
                                setState(() {
                                  searchField = newsearchField!;
                                });
                                searchRoadMap();
                              }))),
                  SizedBox(
                      width: 300,
                      child: TextFormField(
                        style: defaultTextStyle,
                        controller: _searchTextController,
                        decoration:
                            const InputDecoration(hintText: 'Recherche'),
                        onFieldSubmitted: (e) {
                          searchRoadMap();
                        },
                      )),
                  IconButton(
                      onPressed: () {
                        searchRoadMap();
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
                        icon: const Icon(Icons.manage_search_outlined),
                        tooltip: 'Recherche avancée'),
                  if (isAdvancedResearch)
                    IconButton(
                        onPressed: () {
                          setState(() {
                            isAdvancedResearch = false;
                            _advancedSearchTextController.text = '';
                          });
                          searchRoadMap();
                        },
                        icon: const Icon(Icons.search_off_outlined),
                        tooltip: 'Recherche simple'),
                  const Spacer(),
                  if (globals.user.roadMapRights > 1)
                    ElevatedButton(
                        style: myButtonStyle,
                        onPressed: () {
                          showAddPageRoadMap();
                        },
                        child: const Text(
                          'Ajouter une\nfeuille de route',
                          textAlign: TextAlign.center,
                        )),
                  const Spacer(),
                  if (globals.user.roadMapRights > 1)
                    ElevatedButton(
                        style: myButtonStyle,
                        onPressed: () {
                          onGeneratePDAUpdate();
                        },
                        child: const Text('Générer une\nmise à jour PDA',
                            textAlign: TextAlign.center)),
                  const Spacer(),
                  if (globals.shouldDisplaySyncButton)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          getRoadMapList();
                        });
                      },
                      icon: const Icon(Icons.sync),
                      tooltip: 'Actualiser l\'onglet',
                    ),
                  const Spacer(),
                  const Text('Nombre de\nlignes affichées : ',
                      style: defaultTextStyle),
                  Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: DropdownButton(
                          style: defaultTextStyle,
                          value: numberDisplayed,
                          items: numberDisplayedList.map((numberDisplayedList) {
                            return DropdownMenuItem(
                                value: numberDisplayedList,
                                child: Text(numberDisplayedList.toString()));
                          }).toList(),
                          onChanged: (int? newNumberDisplayed) {
                            setState(() {
                              numberDisplayed = newNumberDisplayed!;
                            });
                          }))
                ]),
                Row(
                  children: advancedResearch(),
                )
              ])),
            ),
            body: roadMaps.isEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: const Center(
                        child: Text(
                            'Aucune feuille de route ne correspond à votre recherche.')))
                : Row(
                    children: [
                      Expanded(
                          child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                  controller: _scrollController,
                                  child: PaginatedDataTable(
                                      rowsPerPage:
                                          numberDisplayed < roadMaps.length
                                              ? numberDisplayed
                                              : roadMaps.length,
                                      showFirstLastButtons: true,
                                      showCheckboxColumn: false,
                                      columnSpacing: 0,
                                      sortColumnIndex: _currentSortColumn,
                                      sortAscending: _isAscending,
                                      columns: [
                                        DataColumn(
                                            label: Text('Libellé tournée',
                                                textAlign: TextAlign.center,
                                                style: titleStyle),
                                            onSort: sorting('LIBELLE TOURNEE')),
                                        DataColumn(
                                            label: Text('Tel chauffeur',
                                                textAlign: TextAlign.center,
                                                style: titleStyle),
                                            onSort: sorting('TEL CHAUFFEUR')),
                                        DataColumn(
                                            label: Text('Commentaire',
                                                textAlign: TextAlign.center,
                                                style: titleStyle),
                                            onSort: sorting('COMMENTAIRE')),
                                        DataColumn(
                                            label: Text('Ordre affichage\nPDA',
                                                textAlign: TextAlign.center,
                                                style: titleStyle),
                                            onSort:
                                                sorting('ORDRE AFFICHAGE PDA')),
                                        if (globals.user.roadMapRights > 1)
                                          DataColumn(
                                              label: Row(children: [
                                            Text(
                                                'Feuilles de route\nsupprimés :',
                                                style: titleStyle),
                                            Switch(
                                                value: showDeleteRoadMap,
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    showDeleteRoadMap =
                                                        newValue;
                                                  });
                                                  getRoadMapList();
                                                })
                                          ]))
                                      ],
                                      source: roadMapData))))
                    ],
                  ));
      } else {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                height: 30,
                color: backgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      flex: 1,
                      child: IconButton(
                          onPressed: () {
                            getRoadMapList();
                            setState(() {
                              showDetailsRoadMap = false;
                              isEditing = false;
                            });
                          },
                          icon: const Icon(Icons.clear, size: 26),
                          tooltip: 'Retour'),
                    )
                  ],
                )),
            Expanded(
              child: DetailsRoadMapScreen(
                roadMap: globals.detailedRoadMap,
                editing: isEditing,
              ),
            )
          ],
        );
      }
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class RoadMapData extends DataTableSource {
  List<dynamic> data;
  final Function showEditPageRoadMap;
  final Function onDelete;
  final Function onRestore;
  final Function onRowSelected;
  bool showDeleteRoadMap;
  RoadMapData(this.showEditPageRoadMap, this.onDelete, this.onRestore,
      this.showDeleteRoadMap, this.onRowSelected, this.data);

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
    var roadMap = RoadMap.fromSnapshot(data[index]);
    return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.grey.withOpacity(0.1);
          } else if (index.isEven) {
            return backgroundColor;
          }
          return null; // alterne les couleurs des lignes
        }),
        onSelectChanged: (bool? selected) {
          if (selected!) {
            onRowSelected(roadMap);
          }
        },
        cells: [
          DataCell(SelectableText(roadMap.libelle, style: defaultTextStyle)),
          DataCell(SelectableText(roadMap.tel, style: defaultTextStyle)),
          DataCell(SelectableText(roadMap.comment, style: defaultTextStyle)),
          DataCell(SelectableText(roadMap.sortingNumer.toString(),
              style: defaultTextStyle)),
          if (globals.user.roadMapRights > 1)
            DataCell(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    showEditPageRoadMap(roadMap);
                  },
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editer',
                ),
                if (!showDeleteRoadMap)
                  IconButton(
                      onPressed: () {
                        onDelete(roadMap);
                      },
                      icon: const Icon(Icons.delete_forever),
                      tooltip: 'Supprimer'),
                if (showDeleteRoadMap)
                  IconButton(
                      onPressed: () {
                        onRestore(roadMap);
                      },
                      icon: const Icon(Icons.settings_backup_restore),
                      tooltip: 'Restaurer')
              ],
            ))
        ]);
  }

  onRowSelect() {}
}
