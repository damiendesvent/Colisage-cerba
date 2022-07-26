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
  String searchField = searchFieldList[4];
  String advancedSearchField = searchFieldList[0];
  bool isEditing = false;
  bool showDeleteRoadMap = false;
  bool isAdvancedResearch = false;
  final ScrollController _scrollController = ScrollController();

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
      Text('La feuille de route n° ' +
          roadMap.code.toString() +
          ' a bien été ajouté'),
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
    return StreamBuilder<List>(
      stream: _streamController.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (!showDetailsRoadMap) {
            return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child:
                    CustomScrollView(controller: _scrollController, slivers: [
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
                        Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                    value: searchField,
                                    style: defaultTextStyle,
                                    items:
                                        searchFieldList.map((searchFieldList) {
                                      return DropdownMenuItem(
                                          value: searchFieldList,
                                          child:
                                              Text(searchFieldList.toString()));
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
                        if (globals.user.roadMapRights > 1)
                          const Text('Feuilles de route\nsupprimées :'),
                        if (globals.user.roadMapRights > 1)
                          Switch(
                              value: showDeleteRoadMap,
                              onChanged: (newValue) {
                                setState(() {
                                  showDeleteRoadMap = newValue;
                                });
                                getRoadMapList();
                              }),
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
                                items: numberDisplayedList
                                    .map((numberDisplayedList) {
                                  return DropdownMenuItem(
                                      value: numberDisplayedList,
                                      child:
                                          Text(numberDisplayedList.toString()));
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
                  SliverList(
                      delegate: SliverChildListDelegate([
                    if (snapshot.data.isEmpty)
                      SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: const Center(
                              child: Text(
                                  'Aucune feuille de route ne correspond à votre recherche.')))
                    else
                      for (Map roadMap in snapshot.data.take(
                          numberDisplayed)) //affiche la liste des road_maps
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.map_outlined),
                            trailing: globals.user.roadMapRights > 1
                                ? popupMenu(roadMap)
                                : null,
                            isThreeLine: false,
                            title: Text(roadMap['LIBELLE TOURNEE'],
                                style: defaultTextStyle),
                            subtitle: Row(children: [
                              SizedBox(
                                  width: 400,
                                  child: Text(
                                      searchField +
                                          ' : ' +
                                          roadMap[searchField
                                              .replaceAll('é', 'e')
                                              .toUpperCase()],
                                      style: defaultTextStyle)),
                              Text(
                                  isAdvancedResearch
                                      ? advancedSearchField +
                                          ' : ' +
                                          roadMap[advancedSearchField
                                              .replaceAll('é', 'e')
                                              .toUpperCase()]
                                      : '',
                                  style: defaultTextStyle)
                            ]),
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
                ]));
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
      },
    );
  }
}
