import 'package:flutter/material.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/traca.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class TracaScreen extends StatelessWidget {
  const TracaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: TracaList());
  }
}

class TracaList extends StatefulWidget {
  const TracaList({Key? key}) : super(key: key);

  @override
  _TracaListState createState() => _TracaListState();
}

class _TracaListState extends State<TracaList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final StreamController<List> _streamController = StreamController<List>();
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  String phpUriTracaList = Env.urlPrefix + 'Tracas/list_traca.php';
  String phpUriTracaSearch = Env.urlPrefix + 'Tracas/search_traca.php';
  static const numberDisplayedList = [10, 25, 50, 100];
  int numberDisplayed = 25;
  static const searchFieldList = [
    'Code tracabilité',
    'Utilisateur',
    'Code tournée',
    'Code site',
    'Boite',
    'Tube',
    'Action',
    'Code voiture',
    'Date Heure enregistrement',
    'Date Heure synchronisation',
  ];
  String searchField = searchFieldList.first;
  String advancedSearchField = searchFieldList[1];
  bool _isAscending = false;
  int _currentSortColumn = 0;
  int i = 0;
  bool isAdvancedResearch = false;

  Future getTracaList() async {
    http.Response res = await http.post(Uri.parse(phpUriTracaList), body: {
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      _streamController.add(items);
    }
  }

  @override
  void initState() {
    getTracaList();

    super.initState();
  }

  Future searchTraca() async {
    http.Response res = await http.post(Uri.parse(phpUriTracaSearch), body: {
      "field": searchField.toUpperCase(),
      "advancedField": advancedSearchField.toUpperCase(),
      "searchText": _searchTextController.text,
      "advancedSearchText":
          isAdvancedResearch ? _advancedSearchTextController.text : '',
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      _streamController.add(itemsSearch);
    }
  }

  sorting(String field) {
    return ((columnIndex, _) {
      setState(() {
        _currentSortColumn = columnIndex;
        _isAscending = !_isAscending;
        searchTraca();
      });
    });
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
                  searchTraca();
                })),
        Expanded(
            child: TextFormField(
          controller: _advancedSearchTextController,
          decoration:
              const InputDecoration(hintText: 'Deuxième champ de recherche'),
          onFieldSubmitted: (e) {
            searchTraca();
          },
        )),
        const Spacer(),
      ];
    } else {
      return [const Spacer()];
    }
  }

  void showDetailTraca(Traca traca) {
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
                            'Détails de traçabilité n° ' +
                                traca.code.toString(),
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
                                    child: Text('Code : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16))),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(traca.code.toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)))),
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Utilisateur : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child:
                                            Text(traca.user, style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child:
                                        Text('Tournée : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(traca.tournee.toString(),
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Site : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(traca.site.toString(),
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Boite : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child:
                                            Text(traca.box, style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Tube : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child:
                                            Text(traca.tube, style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Action : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(traca.action,
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
                                        height: 40,
                                        child: Text(traca.correspondant,
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Enregistrement : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(
                                            globals
                                                .detailedTraca.registeringTime,
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Synchronisation : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(traca.synchronizingTime,
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Origine PGM : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child:
                                            Text(traca.pgm, style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child:
                                        Text('Lettrage : ', style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(traca.lettrage.toString(),
                                            style: textStyle)))
                              ],
                            ),
                            TableRow(
                              children: [
                                const TableCell(
                                    child: Text('Code voiture : ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: Text(traca.car.toString(),
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
                                        height: 40,
                                        child: Text(traca.comment,
                                            style: textStyle)))
                              ],
                            ),
                          ]),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                            width: 110,
                            child: ElevatedButton(
                              style: myButtonStyle,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Row(children: const [
                                Icon(Icons.clear),
                                Text(' Annuler')
                              ]),
                            )),
                      ),
                      const Spacer()
                    ],
                  ))
            ])));
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List>(
        stream: _streamController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                    elevation: 8,
                    toolbarHeight: isAdvancedResearch ? 100 : 55,
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
                                })),
                        Expanded(
                            child: TextFormField(
                          controller: _searchTextController,
                          decoration:
                              const InputDecoration(hintText: 'Recherche'),
                          onFieldSubmitted: (e) {
                            searchTraca();
                          },
                        )),
                        IconButton(
                            onPressed: () {
                              searchTraca();
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
                                searchTraca();
                              },
                              icon: const Icon(Icons.search_off_outlined),
                              tooltip: 'Recherche simple'),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              getTracaList();
                            });
                          },
                          icon: const Icon(Icons.sync),
                          tooltip: 'Actualiser l\'onglet',
                        ),
                        const Spacer(),
                        const Text('Nombre de lignes affichées : '),
                        DropdownButton(
                            value: numberDisplayed,
                            items:
                                numberDisplayedList.map((numberDisplayedList) {
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
                    ]))),
                body: snapshot.data.isEmpty
                    ? const Center(
                        child: Text(
                            'Aucune traçabilité ne correspond à votre recherche.'))
                    : Row(children: <Widget>[
                        Expanded(
                            child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty
                                          .resolveWith<Color?>(
                                              (Set<MaterialState> states) {
                                        return Colors.grey.withOpacity(0.2);
                                      }),
                                      showCheckboxColumn: false,
                                      sortColumnIndex: _currentSortColumn,
                                      sortAscending: _isAscending,
                                      headingTextStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      columns: [
                                        DataColumn(
                                            label:
                                                const Text('Code tracabilité'),
                                            onSort:
                                                sorting('CODE TRACABILITE')),
                                        DataColumn(
                                            label: const Text('Utilisateur'),
                                            onSort: sorting('UTILISATEUR')),
                                        DataColumn(
                                            label: const Text('Code tournée'),
                                            onSort: sorting('CODE TOURNEE')),
                                        DataColumn(
                                            label: const Text('Code site'),
                                            onSort: sorting('CODE SITE')),
                                        DataColumn(
                                            label: const Text('Boite'),
                                            onSort: sorting('BOITE')),
                                        DataColumn(
                                            label: const Text('Tube'),
                                            onSort: sorting('TUBE')),
                                        DataColumn(
                                            label: const Text('Action'),
                                            onSort: sorting('ACTION')),
                                        DataColumn(
                                            label: const Text('Code voiture'),
                                            onSort: sorting('CODE VOITURE')),
                                        DataColumn(
                                            label: const Text('Enregistrement'),
                                            onSort: sorting(
                                                'DATE HEURE ENREGISTREMENT')),
                                        DataColumn(
                                            label:
                                                const Text('Synchronisation'),
                                            onSort: sorting(
                                                'DATE HEURE SYNCHRONISATION')),
                                      ],
                                      rows: [
                                        for (Map traca in snapshot.data
                                            .take(numberDisplayed))
                                          DataRow(
                                              color: MaterialStateProperty
                                                  .resolveWith<Color?>(
                                                      (Set<MaterialState>
                                                          states) {
                                                if (states.contains(
                                                    MaterialState.selected)) {
                                                  return Colors.grey
                                                      .withOpacity(0.08);
                                                }
                                                if ((i += 1).isEven) {
                                                  return backgroundColor;
                                                }
                                                return null; // alterne les couleurs des lignes
                                              }),
                                              onSelectChanged:
                                                  (bool? selected) {
                                                if (selected!) {
                                                  showDetailTraca(
                                                      Traca.fromSnapshot(
                                                          traca));
                                                }
                                              },
                                              cells: [
                                                DataCell(SelectableText(
                                                  traca['CODE TRACABILITE'],
                                                )),
                                                DataCell(
                                                    SelectableText(traca['UTILISATEUR'])),
                                                DataCell(SelectableText(
                                                    traca['CODE TOURNEE'] ??
                                                        '')),
                                                DataCell(
                                                    SelectableText(traca['CODE SITE'])),
                                                DataCell(
                                                    SelectableText(traca['BOITE'] ?? '')),
                                                DataCell(
                                                    SelectableText(traca['TUBE'] ?? '')),
                                                DataCell(SelectableText(traca['ACTION'])),
                                                DataCell(SelectableText(
                                                    traca['CODE VOITURE'] ??
                                                        '')),
                                                DataCell(SelectableText(traca[
                                                    'DATE HEURE ENREGISTREMENT'])),
                                                DataCell(SelectableText(traca[
                                                    'DATE HEURE SYNCHRONISATION'])),
                                              ])
                                      ],
                                    ))))
                      ]));
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
