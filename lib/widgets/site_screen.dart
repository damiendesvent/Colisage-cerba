import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/variables/styles.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/site.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

enum Menu { itemEdit, itemDelete }

class SiteScreen extends StatelessWidget {
  const SiteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SiteList());
  }
}

class SiteList extends StatefulWidget {
  const SiteList({Key? key}) : super(key: key);

  @override
  _SiteListState createState() => _SiteListState();
}

class _SiteListState extends State<SiteList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final StreamController<List> _streamController = StreamController<List>();
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  static const numberDisplayedList = [10, 25, 50, 100];
  int numberDisplayed = 25;
  static const searchFieldList = [
    'Code site',
    'Correspondant',
    'Libellé site',
    'Adresse',
    'Complément adresse',
    'CP',
    'Ville'
  ];
  String searchField = searchFieldList[2];
  String advancedSearchField = searchFieldList[6];
  bool isCollectionSite = false;
  bool isDepositSite = false;
  String? maxSite;
  bool showDeleteSite = false;
  bool isAdvancedResearch = false;
  final ScrollController _scrollController = ScrollController();
  late String collectionSiteValue;
  late String depositSiteValue;

  Future getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList), body: {
      "limit": numberDisplayedList.last.toString(),
      "delete": showDeleteSite ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      _streamController.add(items);
    }
  }

  @override
  void initState() {
    getSiteList();
    getMaxSite();
    super.initState();
  }

  Future searchSite() async {
    String phpUriSiteSearch = Env.urlPrefix + 'Sites/search_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteSearch), body: {
      "field": searchField.toUpperCase(),
      "advancedField": advancedSearchField.toUpperCase(),
      "searchText": _searchTextController.text,
      "advancedSearchText":
          isAdvancedResearch ? _advancedSearchTextController.text : '',
      "limit": numberDisplayedList.last.toString(),
      "delete": showDeleteSite ? 'true' : 'false'
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
            searchSite();
          },
        )),
        const Spacer(),
      ];
    } else {
      return [const Spacer()];
    }
  }

  void getMaxSite() async {
    String phpUriMaxSite = Env.urlPrefix + 'Sites/max_site.php';
    http.Response res = await http.get(Uri.parse(phpUriMaxSite));
    if (res.body.isNotEmpty) {
      setState(() {
        maxSite = json.decode(res.body)[0]['MAX(`CODE SITE`)'];
      });
    }
  }

  Widget popupMenu(Map<dynamic, dynamic> site) {
    return PopupMenuButton<Menu>(
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
              PopupMenuItem<Menu>(
                value: Menu.itemEdit,
                child: Row(children: const [Icon(Icons.edit), Text('Editer')]),
                onTap: () {
                  Future.delayed(const Duration(seconds: 0),
                      () => showEditPageSite(Site.fromSnapshot(site)));
                },
              ),
              if (!showDeleteSite)
                PopupMenuItem<Menu>(
                  value: Menu.itemDelete,
                  child: Row(children: const [
                    Icon(Icons.delete_forever),
                    Text('Supprimer')
                  ]),
                  onTap: () {
                    Future.delayed(const Duration(seconds: 0),
                        () => onDelete(Site.fromSnapshot(site)));
                  },
                ),
              if (showDeleteSite)
                PopupMenuItem<Menu>(
                  value: Menu.itemDelete,
                  child: Row(children: const [
                    Icon(Icons.settings_backup_restore),
                    Text('Restaurer')
                  ]),
                  onTap: () {
                    Future.delayed(const Duration(seconds: 0),
                        () => onRestore(Site.fromSnapshot(site)));
                  },
                ),
            ]);
  }

  void onRestore(Site site) {
    String phpUriSiteDelete = Env.urlPrefix + 'Sites/delete_site.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir restaurer \nle site n°' +
                    site.code.toString() +
                    ' : ' +
                    site.libelle +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriSiteDelete), body: {
                        "searchCode": site.code.toString(),
                        "cancel": 'true'
                      });
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => getSiteList());
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
                                ' Le site n° ' +
                                    site.code.toString() +
                                    ' : ' +
                                    site.libelle +
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

  void showDetailSite(Site site) {
    const TextStyle textStyle = TextStyle(fontSize: 18);
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (_) => Dialog(
            insetPadding:
                const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
            elevation: 8,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                  height: 700,
                  width: 700,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Détails du site n° ' + site.code.toString(),
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade700),
                          )),
                      const Spacer(),
                      Table(
                          defaultColumnWidth: const FractionColumnWidth(0.4),
                          children: [
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Code site : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16))),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child: Text(site.code.toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)))),
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child:
                                        Text('Libellé : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child: Text(site.libelle,
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Correspondant : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child: Text(site.correspondant,
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child:
                                        Text('Adresse : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child: Text(site.adress,
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Complément d\'adresse : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child: Text(site.cpltAdress,
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Code Postal : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child: Text(site.cp.toString(),
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Ville : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child:
                                            Text(site.city, style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Site de prélèvement : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(
                                            site.collectionSite ? 'Oui' : 'Non',
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Site de dépôt :            ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(
                                            site.depositSite ? 'Oui' : 'Non',
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Commentaire : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 55,
                                        child: Text(site.comment,
                                            style: textStyle)))
                              ],
                            ),
                          ]),
                      const Spacer()
                    ],
                  ))
            ])));
  }

  void showEditPageSite(Site site) {
    const TextStyle textStyle = TextStyle(fontSize: 18);
    late TextEditingController libelleController =
        TextEditingController(text: site.libelle);
    late TextEditingController correspondantController =
        TextEditingController(text: site.correspondant);
    late TextEditingController adressController =
        TextEditingController(text: site.adress);
    late TextEditingController cpltAdressController =
        TextEditingController(text: site.cpltAdress);
    late TextEditingController cpController =
        TextEditingController(text: site.cp.toString());
    late TextEditingController cityController =
        TextEditingController(text: site.city);
    late TextEditingController commentController =
        TextEditingController(text: site.comment);
    List<String> yesNoList = ['Non', 'Oui'];
    setState(() {
      collectionSiteValue = site.collectionSite ? 'Oui' : 'Non';
      depositSiteValue = site.depositSite ? 'Oui' : 'Non';
    });

    bool submited = false;
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
                      height: 700,
                      width: 700,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Edition du site n° ' + site.code.toString(),
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
                                        child: Text('Code site : ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16))),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: Text(site.code.toString(),
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold))))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Libellé* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
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
                                        child: Text('Correspondant : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller:
                                                  correspondantController,
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
                                        child: Text('Adresse* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: adressController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: adressController
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
                                        child: Text('Complément d\'adresse : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: cpltAdressController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Code Postal* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: cpController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    6),
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: cpController
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
                                        child: Text('Ville* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: cityController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: cityController
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
                                        child: Text('Site de prélèvement : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 40,
                                            width: 100,
                                            child: DropdownButton(
                                              value: collectionSiteValue,
                                              items: yesNoList.map((yesNo) {
                                                return DropdownMenuItem(
                                                    value: yesNo,
                                                    child:
                                                        Text(yesNo.toString()));
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  collectionSiteValue =
                                                      newValue!;
                                                });
                                              },
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text(
                                            'Site de dépôt :            ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 40,
                                            width: 100,
                                            child: DropdownButton(
                                              items: yesNoList.map((yesNo) {
                                                return DropdownMenuItem(
                                                    value: yesNo,
                                                    child:
                                                        Text(yesNo.toString()));
                                              }).toList(),
                                              value: depositSiteValue,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  depositSiteValue = newValue!;
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
                                            height: 55,
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
                                            if (libelleController
                                                    .text.isNotEmpty &&
                                                adressController
                                                    .text.isNotEmpty &&
                                                cityController
                                                    .text.isNotEmpty) {
                                              onUpdateSite(Site(
                                                  code: site.code,
                                                  libelle:
                                                      libelleController.text,
                                                  correspondant:
                                                      correspondantController
                                                          .text,
                                                  adress: adressController.text,
                                                  cpltAdress:
                                                      cpltAdressController.text,
                                                  cp: int.parse(
                                                      cpController.text),
                                                  city: cityController.text,
                                                  collectionSite:
                                                      collectionSiteValue ==
                                                          'Oui',
                                                  depositSite:
                                                      depositSiteValue == 'Oui',
                                                  comment:
                                                      commentController.text));
                                            }
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

  void onUpdateSite(Site site) {
    String phpUriSiteUpdate = Env.urlPrefix + 'Sites/update_site.php';
    http.post(Uri.parse(phpUriSiteUpdate), body: {
      "searchCode": site.code.toString(),
      "correspondant": site.correspondant,
      "libelle": site.libelle,
      "adress": site.adress,
      "cpltAdress": site.cpltAdress,
      "cp": site.cp.toString(),
      "city": site.city,
      "collectionSite": site.collectionSite ? 'Oui' : 'Non',
      "depositSite": site.depositSite ? 'Oui' : 'Non',
      "comment": site.comment
    });
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getSiteList());
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  void onDelete(Site site) {
    String phpUriSiteDelete = Env.urlPrefix + 'Sites/delete_site.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir supprimer \nle site n°' +
                    site.code.toString() +
                    ' : ' +
                    site.libelle +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriSiteDelete), body: {
                        "searchCode": site.code.toString(),
                        "cancel": 'false'
                      });
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => getSiteList());
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
                                ' Le site n° ' +
                                    site.code.toString() +
                                    ' : ' +
                                    site.libelle +
                                    ' a bien été supprimé.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              )
                            ]),
                        action: SnackBarAction(
                          label: 'Annuler',
                          textColor: Colors.white,
                          onPressed: () {
                            http.post(Uri.parse(phpUriSiteDelete), body: {
                              "searchCode": site.code.toString(),
                              "cancel": 'true'
                            });
                            Future.delayed(
                                Duration(milliseconds: globals.milisecondWait),
                                () => getSiteList());
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

  void onAddSite(Site site) {
    String phpUriAddSite = Env.urlPrefix + 'Sites/add_site.php';
    http.post(Uri.parse(phpUriAddSite), body: {
      "code": site.code.toString(),
      "libelle": site.libelle,
      "correspondant": site.correspondant,
      "adress": site.adress,
      "cplt": site.cpltAdress,
      "cp": site.cp.toString(),
      "city": site.city,
      "collectionSite": site.collectionSite ? '1' : '0',
      "depositSite": site.depositSite ? '1' : '0',
      "comment": site.comment
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      Text('Le site n° ' + site.code.toString() + ' a bien été ajouté'),
    ));
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getMaxSite());
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getSiteList());
  }

  void showAddPageSite() {
    const TextStyle textStyle = TextStyle(fontSize: 16);
    TextEditingController codeController = TextEditingController();
    TextEditingController libelleController = TextEditingController();
    TextEditingController correspondantController = TextEditingController();
    TextEditingController adressController = TextEditingController();
    TextEditingController cpltController = TextEditingController();
    TextEditingController cpController = TextEditingController();
    TextEditingController cityController = TextEditingController();
    TextEditingController commentController = TextEditingController();
    bool submited = false;
    String codeValueCheck = 'Veuillez entrer une valeur';

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
                      width: 600,
                      height: 700,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Ajout d\'un site',
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
                                        child: Text('Code site* : ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16))),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: codeController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    4),
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              decoration: InputDecoration(
                                                  hintText: 'A partir de ' +
                                                      (int.parse(maxSite!) + 1)
                                                          .toString(),
                                                  errorText: (codeController
                                                                  .text
                                                                  .isEmpty ||
                                                              int.parse(
                                                                      maxSite!) >=
                                                                  int.parse(
                                                                      codeController
                                                                          .text)) &&
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
                                            height: 55,
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
                                        child: Text('Correspondant : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller:
                                                  correspondantController,
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
                                        child: Text('Adresse* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: adressController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: adressController
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
                                        child: Text('Complément d\'adresse : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: cpltController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text('Code Postal* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: cpController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    6),
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: cpController
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
                                        child: Text('Ville* : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 55,
                                            child: TextField(
                                              controller: cityController,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(
                                                    35)
                                              ],
                                              decoration: InputDecoration(
                                                  errorText: cityController
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
                                        child: Text('Site de prélèvement : ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 40,
                                            child: Checkbox(
                                              value: isCollectionSite,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isCollectionSite = value!;
                                                });
                                              },
                                            )))
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const TableCell(
                                        child: Text(
                                            'Site de dépôt :            ',
                                            style: textStyle)),
                                    TableCell(
                                        child: SizedBox(
                                            height: 40,
                                            child: Checkbox(
                                              value: isDepositSite,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isDepositSite = value!;
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
                                            height: 55,
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
                                            if (codeController.text.isNotEmpty &&
                                                libelleController
                                                    .text.isNotEmpty &&
                                                adressController
                                                    .text.isNotEmpty &&
                                                cityController
                                                    .text.isNotEmpty &&
                                                cpController.text.isNotEmpty &&
                                                (int.parse(maxSite!) <
                                                    int.parse(
                                                        codeController.text))) {
                                              onAddSite(Site(
                                                  code: int.parse(
                                                      codeController.text),
                                                  libelle:
                                                      libelleController.text,
                                                  correspondant:
                                                      correspondantController
                                                          .text,
                                                  adress: adressController.text,
                                                  cpltAdress:
                                                      cpltController.text,
                                                  cp: int.parse(
                                                      cpController.text),
                                                  city: cityController.text,
                                                  collectionSite:
                                                      isCollectionSite,
                                                  depositSite: isDepositSite,
                                                  comment:
                                                      commentController.text));
                                            } else {
                                              int code =
                                                  codeController.text == ''
                                                      ? 0
                                                      : int.parse(
                                                          codeController.text);
                                              setState(() {
                                                codeValueCheck = int.parse(
                                                                maxSite!) <
                                                            code ||
                                                        code == 0
                                                    ? 'Veuillez entrer une valeur'
                                                    : 'Code site existant';
                                              });
                                            }
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
          return Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: CustomScrollView(controller: _scrollController, slivers: [
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
                                    child: Text(searchFieldList));
                              }).toList(),
                              onChanged: (String? newsearchField) {
                                setState(() {
                                  searchField = newsearchField!;
                                });
                                searchSite();
                              })),
                      Expanded(
                          child: TextFormField(
                        controller: _searchTextController,
                        decoration:
                            const InputDecoration(hintText: 'Recherche'),
                        onFieldSubmitted: (e) {
                          searchSite();
                        },
                      )),
                      IconButton(
                          onPressed: () {
                            searchSite();
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
                              searchSite();
                            },
                            icon: const Icon(Icons.search_off_outlined),
                            tooltip: 'Recherche simple'),
                      const Spacer(),
                      if (globals.user.siteEditing)
                        ElevatedButton(
                            style: myButtonStyle,
                            onPressed: () {
                              showAddPageSite();
                            },
                            child: const Text('Ajouter un site')),
                      if (globals.user.siteEditing)
                        const Text('  Sites supprimés :'),
                      if (globals.user.siteEditing)
                        Switch(
                            value: showDeleteSite,
                            onChanged: (newValue) {
                              setState(() {
                                showDeleteSite = newValue;
                              });
                              getSiteList();
                            }),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            getSiteList();
                            getMaxSite();
                          });
                        },
                        icon: const Icon(Icons.sync),
                        tooltip: 'Actualiser l\'onglet',
                      ),
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
                  if (snapshot.data.isEmpty)
                    SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: const Center(
                            child: Text(
                                'Aucun utilisateur ne correspond à votre recherche.')))
                  else
                    for (Map site in snapshot.data
                        .take(numberDisplayed)) //affiche la liste des sites
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          trailing:
                              globals.user.siteEditing ? popupMenu(site) : null,
                          isThreeLine: true,
                          title:
                              Text(site[searchFieldList.first.toUpperCase()]),
                          subtitle: Text(searchField +
                              ' : ' +
                              site[searchField
                                  .replaceAll('é', 'e')
                                  .toUpperCase()] +
                              '\n' +
                              (isAdvancedResearch
                                  ? advancedSearchField +
                                      ' : ' +
                                      site[advancedSearchField
                                          .replaceAll('é', 'e')
                                          .toUpperCase()]
                                  : '')),
                          onTap: () {
                            showDetailSite(Site.fromSnapshot(site));
                          },
                        ),
                      )
                ]))
              ]));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
