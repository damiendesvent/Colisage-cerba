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
  bool showDetailsSite = false;
  String searchText = '';
  static const numberDisplayedList = [10, 25, 50, 100, 1000];
  int numberDisplayed = 25;
  static const searchFieldList = [
    'CODE SITE',
    'CORRESPONDANT',
    'LIBELLE SITE',
    'ADRESSE',
    'COMPLEMENT ADRESSE',
    'CP',
    'VILLE'
  ];
  String searchField = 'CODE SITE';
  bool isEditing = false;
  bool isCollectionSite = false;
  bool isDepositSite = false;
  String? maxSite;

  Future getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.get(Uri.parse(phpUriSiteList));
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
    setState(() {
      searchText = _searchTextController.text;
    });
    http.Response res = await http.post(Uri.parse(phpUriSiteSearch),
        body: {"field": searchField, "searchText": searchText});
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      _streamController.add(itemsSearch);
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
            ]);
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
                      getSiteList();
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
                            getSiteList();
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
    getMaxSite();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      Text('Le site n° ' + site.code.toString() + ' a bien été ajouté'),
    ));
    getSiteList();
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
                                      width: 105,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            submited = true;
                                          });
                                          if (codeController.text.isNotEmpty &&
                                              libelleController
                                                  .text.isNotEmpty &&
                                              adressController
                                                  .text.isNotEmpty &&
                                              cityController.text.isNotEmpty &&
                                              (int.parse(maxSite!) <
                                                  int.parse(
                                                      codeController.text))) {
                                            onAddSite(Site(
                                                code: int.parse(
                                                    codeController.text),
                                                libelle: libelleController.text,
                                                correspondant:
                                                    correspondantController
                                                        .text,
                                                adress: adressController.text,
                                                cpltAdress: cpltController.text,
                                                cp: int.parse(
                                                    cpController.text),
                                                city: cityController.text,
                                                collectionSite:
                                                    isCollectionSite,
                                                depositSite: isDepositSite,
                                                comment:
                                                    commentController.text));
                                          } else {
                                            int code = codeController.text == ''
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
          if (!showDetailsSite) {
            return CustomScrollView(slivers: [
              //barre de recherche dynamique
              SliverAppBar(
                elevation: 8,
                forceElevated: true,
                expandedHeight: 50,
                floating: true,
                backgroundColor: Colors.grey[300],
                flexibleSpace: FlexibleSpaceBar(
                    background: Row(mainAxisSize: MainAxisSize.min, children: [
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
                  const Spacer(),
                  if (globals.user.siteEditing)
                    ElevatedButton(
                        onPressed: () {
                          showAddPageSite();
                        },
                        child: const Text('Ajouter un site')),
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
                      title: Text(site['CODE SITE']),
                      subtitle: Text(site['LIBELLE SITE'] +
                          '\n' +
                          (searchField == 'CODE SITE'
                              ? ''
                              : searchField + ' : ' + site[searchField])),
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
