import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colisage_cerba/variables/styles.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/site.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

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
  bool get wantKeepAlive => globals.shouldKeepAlive;

  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  static const numberDisplayedList = [15, 25, 50, 100];
  int numberDisplayed = numberDisplayedList.first;
  static const searchFieldList = [
    'Libellé site',
    'CP',
    'Ville',
    'Site prélèvement',
    'Site dépôt',
    'Adresse',
    'Complément adresse',
  ];
  String searchField = searchFieldList[0];
  String advancedSearchField = searchFieldList[2];
  bool isCollectionSite = false;
  bool isDepositSite = false;
  bool showDeleteSite = false;
  bool isAdvancedResearch = false;
  final ScrollController _scrollController = ScrollController();
  late String collectionSiteValue;
  late String depositSiteValue;
  static List<String> noYesList = ['Non', 'Oui'];
  String noYesValue = noYesList.first;
  List sites = [];
  bool _isAscending = true;
  int _currentSortColumn = 0;
  TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.bold, fontSize: defaultTextStyle.fontSize);

  Future<bool> isExistingSite(String libelle) async {
    String phpUriDetailsSite =
        Env.urlPrefix + 'Sites/details_site_w_libelle.php';
    http.Response res = await http
        .post(Uri.parse(phpUriDetailsSite), body: {'libelle': libelle});
    if (res.body.isNotEmpty && res.body != 'false') {
      return true;
    }
    return false;
  }

  void getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList), body: {
      "limit": '250',
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      "delete": showDeleteSite ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        sites = items;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getSiteList();
  }

  void searchSite() async {
    String phpUriSiteSearch = Env.urlPrefix + 'Sites/search_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteSearch), body: {
      "field": searchField.toUpperCase(),
      "advancedField": advancedSearchField.toUpperCase(),
      "searchText": searchField.startsWith('Site')
          ? noYesList.indexOf(noYesValue).toString()
          : _searchTextController.text,
      "advancedSearchText": isAdvancedResearch
          ? (advancedSearchField.startsWith('Site')
              ? noYesList.indexOf(noYesValue).toString()
              : _advancedSearchTextController.text)
          : '',
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      "limit": '250',
      "delete": showDeleteSite ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      setState(() {
        sites = itemsSearch;
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
            child: advancedSearchField.startsWith('Site')
                ? Center(
                    child: SizedBox(
                        width: 100,
                        child: DropdownButton(
                            style: defaultTextStyle,
                            isExpanded: true,
                            alignment: AlignmentDirectional.center,
                            value: noYesValue,
                            items: noYesList.map((value) {
                              return DropdownMenuItem(
                                  value: value, child: Text(value));
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                noYesValue = newValue!;
                              });
                              searchSite();
                            })))
                : TextFormField(
                    style: defaultTextStyle,
                    controller: _advancedSearchTextController,
                    decoration: const InputDecoration(
                        hintText: 'Deuxième champ de recherche'),
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

  sorting(String field) {
    return ((columnIndex, _) {
      setState(() {
        _currentSortColumn = columnIndex;
        _isAscending = !_isAscending;
        searchSite();
      });
    });
  }

  void onRestore(Site site) {
    String phpUriSiteDelete = Env.urlPrefix + 'Sites/delete_site.php';
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
                          () => searchSite());
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

  void showDetailSite(Site site) {
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (_) => Dialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25))),
            insetPadding: const EdgeInsets.all(50),
            elevation: 8,
            child: SingleChildScrollView(
                child: SizedBox(
                    height: 500,
                    width: 500,
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
                                      child: Text('Libellé : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: SelectableText(site.libelle,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Correspondant : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: SelectableText(
                                              site.correspondant,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Adresse : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: SelectableText(site.adress,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Complément d\'adresse : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: SelectableText(site.cpltAdress,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Code Postal : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: SelectableText(
                                              site.cp == 0
                                                  ? ''
                                                  : site.cp.toString(),
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Ville : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: SelectableText(site.city,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Site de prélèvement : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: Text(
                                              site.collectionSite
                                                  ? 'Oui'
                                                  : 'Non',
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Site de dépôt :            ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: Text(
                                              site.depositSite ? 'Oui' : 'Non',
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Commentaire : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: SelectableText(site.comment,
                                              style: defaultTextStyle)))
                                ],
                              ),
                            ]),
                        Padding(
                            padding: const EdgeInsets.all(10),
                            child: SizedBox(
                                width: 100,
                                child: ElevatedButton(
                                  style: myButtonStyle,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Row(children: const [
                                    Icon(Icons.clear),
                                    Text(' Annuler')
                                  ]),
                                ))),
                        const Spacer()
                      ],
                    )))));
  }

  void showEditPageSite(Site site) {
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
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
                elevation: 8,
                child: SingleChildScrollView(
                    child: SizedBox(
                        height: 525,
                        width: 500,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Edition du site n° ' + site.code.toString(),
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700),
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
                                              height: 40,
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
                                                        fontSize:
                                                            defaultTextStyle
                                                                    .fontSize! -
                                                                4,
                                                        height: 0.3),
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
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
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
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                style: defaultTextStyle,
                                                controller: adressController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      50)
                                                ],
                                                decoration: InputDecoration(
                                                    errorStyle: TextStyle(
                                                        fontSize:
                                                            defaultTextStyle
                                                                    .fontSize! -
                                                                4,
                                                        height: 0.3),
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
                                          child: Text(
                                              'Complément d\'adresse : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
                                                controller:
                                                    cpltAdressController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      50)
                                                ],
                                              )))
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const TableCell(
                                          child: Text('Code Postal* : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
                                                controller: cpController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      6),
                                                  FilteringTextInputFormatter
                                                      .digitsOnly
                                                ],
                                              )))
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const TableCell(
                                          child: Text('Ville* : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                style: defaultTextStyle,
                                                controller: cityController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      35)
                                                ],
                                                decoration: InputDecoration(
                                                    errorStyle: TextStyle(
                                                        fontSize:
                                                            defaultTextStyle
                                                                    .fontSize! -
                                                                4,
                                                        height: 0.3),
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
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: Center(
                                              child: SizedBox(
                                                  height: 40,
                                                  width: 60,
                                                  child: DropdownButton(
                                                    style: defaultTextStyle,
                                                    value: collectionSiteValue,
                                                    items:
                                                        yesNoList.map((yesNo) {
                                                      return DropdownMenuItem(
                                                          value: yesNo,
                                                          child: Text(yesNo
                                                              .toString()));
                                                    }).toList(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        collectionSiteValue =
                                                            newValue!;
                                                      });
                                                    },
                                                  ))))
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const TableCell(
                                          child: Text(
                                              'Site de dépôt :            ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: Center(
                                              child: SizedBox(
                                                  height: 40,
                                                  width: 60,
                                                  child: DropdownButton(
                                                    style: defaultTextStyle,
                                                    items:
                                                        yesNoList.map((yesNo) {
                                                      return DropdownMenuItem(
                                                          value: yesNo,
                                                          child: Text(yesNo
                                                              .toString()));
                                                    }).toList(),
                                                    value: depositSiteValue,
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        depositSiteValue =
                                                            newValue!;
                                                      });
                                                    },
                                                  ))))
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const TableCell(
                                          child: Text('Commentaire : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
                                                controller: commentController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      128)
                                                ],
                                              )))
                                    ],
                                  ),
                                ]),
                            Center(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
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
                                                    adress:
                                                        adressController.text,
                                                    cpltAdress:
                                                        cpltAdressController
                                                            .text,
                                                    cp: int.parse(
                                                        cpController.text),
                                                    city: cityController.text,
                                                    collectionSite:
                                                        collectionSiteValue ==
                                                            'Oui',
                                                    depositSite:
                                                        depositSiteValue ==
                                                            'Oui',
                                                    comment: commentController
                                                        .text));
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
                        ))));
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
        Duration(milliseconds: globals.milisecondWait), () => searchSite());
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  void onDelete(Site site) {
    String phpUriSiteDelete = Env.urlPrefix + 'Sites/delete_site.php';
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
                          () => searchSite());
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
                                style: defaultTextStyle,
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
                                () => searchSite());
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
      Text('Le site  ' + site.libelle + ' a bien été ajouté'),
    ));
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getSiteList());
  }

  void showAddPageSite() {
    TextEditingController libelleController = TextEditingController();
    TextEditingController correspondantController = TextEditingController();
    TextEditingController adressController = TextEditingController();
    TextEditingController cpltController = TextEditingController();
    TextEditingController cpController = TextEditingController();
    TextEditingController cityController = TextEditingController();
    TextEditingController commentController = TextEditingController();
    bool submited = false;
    String? errorLibelleText;

    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding: const EdgeInsets.all(50),
                elevation: 8,
                child: SingleChildScrollView(
                    child: SizedBox(
                        width: 500,
                        height: 525,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Ajout d\'un site',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700),
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
                                              height: 40,
                                              child: TextField(
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                style: defaultTextStyle,
                                                textInputAction:
                                                    TextInputAction.next,
                                                controller: libelleController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      35)
                                                ],
                                                decoration: InputDecoration(
                                                    errorStyle: TextStyle(
                                                        fontSize:
                                                            defaultTextStyle
                                                                    .fontSize! -
                                                                4,
                                                        height: 0.3),
                                                    errorText: submited
                                                        ? libelleController
                                                                .text.isEmpty
                                                            ? 'Veuillez entrer une valeur'
                                                            : errorLibelleText
                                                        : null),
                                              )))
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const TableCell(
                                          child: Text('Correspondant : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
                                                textInputAction:
                                                    TextInputAction.next,
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
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                style: defaultTextStyle,
                                                textInputAction:
                                                    TextInputAction.next,
                                                controller: adressController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      50)
                                                ],
                                                decoration: InputDecoration(
                                                    errorStyle: TextStyle(
                                                        fontSize:
                                                            defaultTextStyle
                                                                    .fontSize! -
                                                                4,
                                                        height: 0.3),
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
                                          child: Text(
                                              'Complément d\'adresse : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
                                                textInputAction:
                                                    TextInputAction.next,
                                                controller: cpltController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      50)
                                                ],
                                              )))
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const TableCell(
                                          child: Text('Code Postal : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
                                                textInputAction:
                                                    TextInputAction.next,
                                                controller: cpController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      6),
                                                  FilteringTextInputFormatter
                                                      .digitsOnly
                                                ],
                                              )))
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const TableCell(
                                          child: Text('Ville* : ',
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                style: defaultTextStyle,
                                                controller: cityController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      35)
                                                ],
                                                decoration: InputDecoration(
                                                    errorStyle: TextStyle(
                                                        fontSize:
                                                            defaultTextStyle
                                                                    .fontSize! -
                                                                4,
                                                        height: 0.3),
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
                                              style: defaultTextStyle)),
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
                                              style: defaultTextStyle)),
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
                                              style: defaultTextStyle)),
                                      TableCell(
                                          child: SizedBox(
                                              height: 40,
                                              child: TextField(
                                                style: defaultTextStyle,
                                                controller: commentController,
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(
                                                      128)
                                                ],
                                              )))
                                    ],
                                  ),
                                ]),
                            Center(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
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
                                              isExistingSite(
                                                      libelleController.text)
                                                  .then(((value) {
                                                if (value) {
                                                  setState(
                                                    () {
                                                      errorLibelleText =
                                                          'Site existant';
                                                    },
                                                  );
                                                } else {
                                                  setState(
                                                    () {
                                                      errorLibelleText = null;
                                                    },
                                                  );
                                                  if (libelleController
                                                          .text.isNotEmpty &&
                                                      adressController
                                                          .text.isNotEmpty &&
                                                      cityController
                                                          .text.isNotEmpty) {
                                                    onAddSite(Site(
                                                        libelle:
                                                            libelleController
                                                                .text,
                                                        correspondant:
                                                            correspondantController
                                                                .text,
                                                        adress: adressController
                                                            .text,
                                                        cpltAdress:
                                                            cpltController.text,
                                                        cp: cpController
                                                                .text.isNotEmpty
                                                            ? int.parse(
                                                                cpController
                                                                    .text)
                                                            : null,
                                                        city:
                                                            cityController.text,
                                                        collectionSite:
                                                            isCollectionSite,
                                                        depositSite:
                                                            isDepositSite,
                                                        comment:
                                                            commentController
                                                                .text));
                                                  }
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
                            Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text('* : champs obligatoires',
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12)))
                          ],
                        ))));
          });
        });
  }

  void onPrintLabel() async {
    String phpUriPrintLabel = Env.urlPrefix + 'Scripts/print_label.php';
    http.Response pdfRes = await http.post(Uri.parse(phpUriPrintLabel), body: {
      'libelles': sites.map((item) => item['LIBELLE SITE']).toList().toString(),
      'codes': sites.map((item) => item['CODE SITE']).toList().toString(),
    });
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfRes.bodyBytes);
    Navigator.of(context).pop();
  }

  void showLabelDialog() {
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
                sites.length > 1
                    ? 'Êtes-vous sûr de vouloir imprimer \nles étiquettes des ' +
                        sites.length.toString() +
                        ' sites sélectionnés ?'
                    : 'Êtes-vous sûr de vouloir imprimer l\'étiquette du site sélectionné ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      onPrintLabel();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DataTableSource siteData = SiteData(
        (site) => showEditPageSite(site),
        (site) => onDelete(site),
        (site) => onRestore(site),
        showDeleteSite,
        (site) => showDetailSite(site),
        sites);
    if (sites.isNotEmpty ||
        _searchTextController.text.isNotEmpty ||
        _advancedSearchTextController.text.isNotEmpty) {
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
                                  child: Text(searchFieldList));
                            }).toList(),
                            onChanged: (String? newsearchField) {
                              setState(() {
                                searchField = newsearchField!;
                              });
                              searchSite();
                            }))),
                SizedBox(
                    width: 300,
                    child: searchField.startsWith('Site')
                        ? Center(
                            child: SizedBox(
                                width: 100,
                                child: DropdownButton(
                                    style: defaultTextStyle,
                                    isExpanded: true,
                                    alignment: AlignmentDirectional.center,
                                    value: noYesValue,
                                    items: noYesList.map((value) {
                                      return DropdownMenuItem(
                                          value: value, child: Text(value));
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        noYesValue = newValue!;
                                      });
                                      searchSite();
                                    })))
                        : TextFormField(
                            style: defaultTextStyle,
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
                if (globals.user.siteRights > 1)
                  ElevatedButton(
                      style: myButtonStyle,
                      onPressed: () {
                        showAddPageSite();
                      },
                      child: const Text('Ajouter un site')),
                if (globals.user.siteRights > 0)
                  Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ElevatedButton(
                          style: myButtonStyle,
                          onPressed: () {
                            showLabelDialog();
                          },
                          child: const Text('Générer\nétiquettes',
                              textAlign: TextAlign.center))),
                const Spacer(),
                if (globals.shouldDisplaySyncButton)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        getSiteList();
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
          body: sites.isEmpty
              ? SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(
                      child:
                          Text('Aucun site ne correspond à votre recherche.')))
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
                                    rowsPerPage: numberDisplayed < sites.length
                                        ? numberDisplayed
                                        : sites.length,
                                    showFirstLastButtons: true,
                                    showCheckboxColumn: false,
                                    columnSpacing: 0,
                                    sortColumnIndex: _currentSortColumn,
                                    sortAscending: _isAscending,
                                    columns: [
                                      DataColumn(
                                          label: Text('Libellé site',
                                              textAlign: TextAlign.center,
                                              style: titleStyle),
                                          onSort: sorting('LIBELLE SITE')),
                                      DataColumn(
                                          label: Text('Code postal',
                                              textAlign: TextAlign.center,
                                              style: titleStyle),
                                          onSort: sorting('CP')),
                                      DataColumn(
                                          label: Text('Ville',
                                              textAlign: TextAlign.center,
                                              style: titleStyle),
                                          onSort: sorting('VILLE')),
                                      DataColumn(
                                          label: Text('Site de\nprélèvement',
                                              textAlign: TextAlign.center,
                                              style: titleStyle),
                                          onSort: sorting('SITE PRELEVEMENT')),
                                      DataColumn(
                                          label: Text('Site de\ndépôt',
                                              textAlign: TextAlign.center,
                                              style: titleStyle),
                                          onSort: sorting('SITE DEPOT')),
                                      if (globals.user.siteRights > 1)
                                        DataColumn(
                                            label: Row(children: [
                                          Text('Sites\nsupprimés :',
                                              style: titleStyle),
                                          Switch(
                                              value: showDeleteSite,
                                              onChanged: (newValue) {
                                                setState(() {
                                                  showDeleteSite = newValue;
                                                });
                                                getSiteList();
                                              })
                                        ]))
                                    ],
                                    source: siteData))))
                  ],
                ));
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class SiteData extends DataTableSource {
  List<dynamic> data;
  final Function showEditPageSite;
  final Function onDelete;
  final Function onRestore;
  final Function onRowSelected;
  bool showDeleteSite;
  SiteData(this.showEditPageSite, this.onDelete, this.onRestore,
      this.showDeleteSite, this.onRowSelected, this.data);

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
    var site = Site.fromSnapshot(data[index]);
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
            onRowSelected(site);
          }
        },
        cells: [
          DataCell(SelectableText(site.libelle, style: defaultTextStyle)),
          DataCell(SelectableText(site.cp.toString(), style: defaultTextStyle)),
          DataCell(SelectableText(site.city, style: defaultTextStyle)),
          DataCell(Text(site.collectionSite ? 'Oui' : 'Non',
              style: defaultTextStyle)),
          DataCell(
              Text(site.depositSite ? 'Oui' : 'Non', style: defaultTextStyle)),
          if (globals.user.siteRights > 1)
            DataCell(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    showEditPageSite(site);
                  },
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editer',
                ),
                if (!showDeleteSite)
                  IconButton(
                      onPressed: () {
                        onDelete(site);
                      },
                      icon: const Icon(Icons.delete_forever),
                      tooltip: 'Supprimer'),
                if (showDeleteSite)
                  IconButton(
                      onPressed: () {
                        onRestore(site);
                      },
                      icon: const Icon(Icons.settings_backup_restore),
                      tooltip: 'Restaurer')
              ],
            ))
        ]);
  }

  onRowSelect() {}
}
