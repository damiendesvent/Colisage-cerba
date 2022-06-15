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
    return const Center(
      child: RoadMapList(),
    );
  }
}

class RoadMapList extends StatefulWidget {
  const RoadMapList({Key? key}) : super(key: key);

  @override
  _RoadMapListState createState() => _RoadMapListState();
}

class _RoadMapListState extends State<RoadMapList> {
  final StreamController<List> _streamController = StreamController<List>();
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  bool showDetailsRoadMap = false;
  static const numberDisplayedList = [10, 25, 50, 100];
  int numberDisplayed = 25;
  static const searchFieldList = [
    'Code tournée',
    'Libellé tournée',
    'Tel chauffeur',
    'Commentaire',
    'Ordre affichage PDA'
  ];
  String searchField = searchFieldList[1];
  String advancedSearchField = searchFieldList[0];
  bool isEditing = false;
  bool showDeleteRoadMap = false;
  bool isAdvancedResearch = false;

  Future getRoadMapList() async {
    String phpUriRoadMapList = Env.urlPrefix + 'Road_maps/list_road_map.php';
    http.Response res = await http.post(Uri.parse(phpUriRoadMapList), body: {
      "limit": numberDisplayedList.last.toString(),
      "delete": showDeleteRoadMap ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      _streamController.add(items);
    }
  }

  @override
  void initState() {
    getRoadMapList();

    super.initState();
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
      "limit": numberDisplayedList.last.toString(),
      "delete": showDeleteRoadMap ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      _streamController.add(itemsSearch);
    }
  }

  advancedResearch() {
    if (isAdvancedResearch) {
      return [
        DropdownButtonHideUnderline(
            child: DropdownButton(
                value: advancedSearchField,
                style: const TextStyle(fontSize: 14),
                items: searchFieldList.map((searchFieldList) {
                  return DropdownMenuItem(
                      value: searchFieldList,
                      child: Text(searchFieldList.toString()));
                }).toList(),
                onChanged: (String? newAdvancedSearchField) {
                  setState(() {
                    advancedSearchField = newAdvancedSearchField!;
                  });
                })),
        Expanded(
            child: TextFormField(
          controller: _advancedSearchTextController,
          decoration:
              const InputDecoration(hintText: 'Deuxième champ de recherche'),
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

  Widget popupMenu(Map<dynamic, dynamic> roadMap) {
    return PopupMenuButton<Menu>(
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
              PopupMenuItem<Menu>(
                value: Menu.itemEdit,
                child: Row(children: const [Icon(Icons.edit), Text('Editer')]),
                onTap: () {
                  setState(() {
                    globals.detailedRoadMap = RoadMap.fromSnapshot(roadMap);
                    isEditing = true;
                    showDetailsRoadMap = true;
                  });
                },
              ),
              if (!showDeleteRoadMap)
                PopupMenuItem<Menu>(
                  value: Menu.itemDelete,
                  child: Row(children: const [
                    Icon(Icons.delete_forever),
                    Text('Supprimer')
                  ]),
                  onTap: () {
                    Future.delayed(const Duration(seconds: 0),
                        () => onDelete(RoadMap.fromSnapshot(roadMap)));
                  },
                ),
              if (showDeleteRoadMap)
                PopupMenuItem<Menu>(
                  value: Menu.itemDelete,
                  child: Row(children: const [
                    Icon(Icons.settings_backup_restore),
                    Text('Restaurer')
                  ]),
                  onTap: () {
                    Future.delayed(const Duration(seconds: 0),
                        () => onRestore(RoadMap.fromSnapshot(roadMap)));
                  },
                ),
            ]);
  }

  void onRestore(RoadMap roadMap) {
    String phpUriRoadMapDelete =
        Env.urlPrefix + 'Road_maps/delete_road_map.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir restaurer \nla feuille de route n°' +
                    roadMap.code.toString() +
                    ' : ' +
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
                      getRoadMapList();
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
                                style: const TextStyle(fontSize: 16),
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

  void onDelete(RoadMap roadMap) {
    String phpUriRoadMapDelete =
        Env.urlPrefix + 'Road_maps/delete_road_map.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir supprimer \nla feuille de route n°' +
                    roadMap.code.toString() +
                    ' : ' +
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
                      getRoadMapList();
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
                                ' La feuille de route n° ' +
                                    roadMap.code.toString() +
                                    ' : ' +
                                    roadMap.libelle +
                                    ' a bien été supprimé.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
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
                            getRoadMapList();
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
      "code": roadMap.code.toString(),
      "libelle": roadMap.libelle,
      "tel": roadMap.tel,
      "pda": roadMap.sortingNumer.toString(),
      "comment": roadMap.comment
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      Text('La feuille de route n° ' +
          roadMap.code.toString() +
          ' a bien été ajouté'),
    ));
    getRoadMapList();
  }

  Future<bool> isRoadMap(String code) async {
    String phpUriDetailsRoadMap =
        Env.urlPrefix + 'Road_maps/details_road_map.php';
    http.Response res = await http
        .post(Uri.parse(phpUriDetailsRoadMap), body: {"searchCode": code});
    if (res.body.isNotEmpty && res.body != '[]') {
      return true;
    }
    return false;
  }

  void showAddPageRoadMap() {
    const TextStyle textStyle = TextStyle(fontSize: 16);
    TextEditingController codeController = TextEditingController();
    TextEditingController libelleController = TextEditingController();
    TextEditingController telController = TextEditingController();
    TextEditingController pdaController = TextEditingController();
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
                                        child: Text('Code tournée* : ',
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
                                                    4),
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: (codeController
                                                                  .text
                                                                  .isEmpty ||
                                                              codeExisting) &&
                                                          submited
                                                      ? codeValueCheck
                                                      : null),
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Libellé* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
                                            child: TextField(
                                              controller: libelleController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: libelleController
                                                              .text.isEmpty &&
                                                          submited
                                                      ? 'Veuillez entrer une valeur'
                                                      : null),
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Tel chauffeur : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
                                            child: TextField(
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
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 60,
                                            child: TextField(
                                              controller: pdaController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    4),
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: pdaController
                                                              .text.isEmpty &&
                                                          submited
                                                      ? 'Veuillez entrer une valeur'
                                                      : null),
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
                                ),
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
                                          isRoadMap(codeController.text).then(
                                            (value) => setState(() {
                                              codeExisting = value;
                                              codeValueCheck = codeExisting
                                                  ? 'Feuille de route existante'
                                                  : 'Veuillez entrer une valeur';
                                              if (codeController
                                                      .text.isNotEmpty &&
                                                  libelleController
                                                      .text.isNotEmpty &&
                                                  pdaController
                                                      .text.isNotEmpty &&
                                                  !codeExisting) {
                                                onAddRoadMap(RoadMap(
                                                    code: int.parse(
                                                        codeController.text),
                                                    libelle:
                                                        libelleController.text,
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
                                      )))),
                          const Spacer(),
                        ],
                      ))
                ]));
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List>(
      stream: _streamController.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (!showDetailsRoadMap) {
            return CustomScrollView(slivers: [
              //barre de recherche dynamique
              SliverAppBar(
                elevation: 8,
                forceElevated: true,
                expandedHeight: isAdvancedResearch ? 100 : 55,
                floating: true,
                backgroundColor: Colors.grey[300],
                flexibleSpace: FlexibleSpaceBar(
                    background: Column(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonHideUnderline(
                        child: DropdownButton(
                            value: searchField,
                            style: const TextStyle(fontSize: 14),
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
                            })),
                    Expanded(
                        child: TextFormField(
                      controller: _searchTextController,
                      decoration: const InputDecoration(hintText: 'Recherche'),
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
                    if (globals.user.roadMapEditing)
                      ElevatedButton(
                          onPressed: () {
                            showAddPageRoadMap();
                          },
                          child: const Text('Ajouter une feuille de route')),
                    if (globals.user.roadMapEditing)
                      const Text('  Feuilles de route supprimées :'),
                    if (globals.user.roadMapEditing)
                      Switch(
                          value: showDeleteRoadMap,
                          onChanged: (newValue) {
                            setState(() {
                              showDeleteRoadMap = newValue;
                            });
                            getRoadMapList();
                          }),
                    const Spacer(),
                    const Text('Nombre de lignes affichées : '),
                    DropdownButton(
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
                        })
                  ]),
                  Row(
                    children: advancedResearch(),
                  )
                ])),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                for (Map roadMap in snapshot.data
                    .take(numberDisplayed)) //affiche la liste des road_maps
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.map_outlined),
                      trailing: globals.user.roadMapEditing
                          ? popupMenu(roadMap)
                          : null,
                      isThreeLine: true,
                      title: Text(roadMap['CODE TOURNEE']),
                      subtitle: Text(searchField +
                          ' : ' +
                          roadMap[
                              searchField.replaceAll('é', 'e').toUpperCase()] +
                          '\n' +
                          (isAdvancedResearch
                              ? advancedSearchField +
                                  ' : ' +
                                  roadMap[advancedSearchField
                                      .replaceAll('é', 'e')
                                      .toUpperCase()]
                              : '')),
                      onTap: () {
                        setState(() {
                          showDetailsRoadMap = true;
                          globals.detailedRoadMap =
                              RoadMap.fromSnapshot(roadMap);
                        });
                      },
                    ),
                  )
              ]))
            ]);
          } else {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
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
                          icon: const Icon(Icons.clear_outlined),
                          tooltip: 'Retour'),
                    )
                  ],
                ),
                Expanded(
                    child: SizedBox(
                  height: 100,
                  child: DetailsRoadMapScreen(
                    roadMap: globals.detailedRoadMap,
                    editing: isEditing,
                  ),
                ))
              ],
            );
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
