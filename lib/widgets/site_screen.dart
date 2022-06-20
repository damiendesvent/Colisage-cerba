import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/variables/styles.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/site.dart';
import 'details_site.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

enum Menu { itemEdit, itemDelete }

class SiteScreen extends StatelessWidget {
  const SiteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SiteList(),
    );
  }
}

class SiteList extends StatefulWidget {
  const SiteList({Key? key}) : super(key: key);

  @override
  _SiteListState createState() => _SiteListState();
}

class _SiteListState extends State<SiteList> {
  final StreamController<List> _streamController = StreamController<List>();
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  bool showDetailsSite = false;
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
  bool isEditing = false;
  bool isCollectionSite = false;
  bool isDepositSite = false;
  String? maxSite;
  bool showDeleteSite = false;
  bool isAdvancedResearch = false;

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
                  setState(() {
                    globals.detailedSite = Site.fromSnapshot(site);
                    isEditing = true;
                    showDetailsSite = true;
                  });
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
          if (!showDetailsSite) {
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
                      decoration: const InputDecoration(hintText: 'Recherche'),
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
                for (Map site in snapshot.data
                    .take(numberDisplayed)) //affiche la liste des sites
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      trailing:
                          globals.user.siteEditing ? popupMenu(site) : null,
                      isThreeLine: true,
                      title: Text(site[searchFieldList.first.toUpperCase()]),
                      subtitle: Text(searchField +
                          ' : ' +
                          site[searchField.replaceAll('é', 'e').toUpperCase()] +
                          '\n' +
                          (isAdvancedResearch
                              ? advancedSearchField +
                                  ' : ' +
                                  site[advancedSearchField
                                      .replaceAll('é', 'e')
                                      .toUpperCase()]
                              : '')),
                      onTap: () {
                        setState(() {
                          showDetailsSite = true;
                          globals.detailedSite = Site.fromSnapshot(site);
                        });
                      },
                    ),
                  )
              ]))
            ]);
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    const Spacer(),
                    Flexible(
                      flex: 1,
                      child: IconButton(
                          onPressed: () {
                            getSiteList();
                            setState(() {
                              showDetailsSite = false;
                              isEditing = false;
                            });
                          },
                          icon: const Icon(Icons.clear_outlined),
                          tooltip: 'Retour'),
                    )
                  ],
                ),
                Row(children: [
                  const Spacer(),
                  DetailsSiteScreen(
                    site: globals.detailedSite,
                    editing: isEditing,
                  ),
                  const Spacer(),
                ]),
                Row(
                  children: const [
                    Spacer(),
                  ],
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
