import 'package:flutter/material.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/traca.dart';
import 'details_traca.dart';
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

class _TracaListState extends State<TracaList> {
  final StreamController<List> _streamController = StreamController<List>();
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  String phpUriTracaList = Env.urlPrefix + 'Tracas/list_traca.php';
  String phpUriTracaSearch = Env.urlPrefix + 'Tracas/search_traca.php';
  bool showDetailsTraca = false;
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List>(
        stream: _streamController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (!showDetailsTraca) {
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
                                        child:
                                            Text(searchFieldList.toString()));
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
                          const Text('Nombre de lignes affichées : '),
                          DropdownButton(
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
                              })
                        ]),
                        Row(
                          children: advancedResearch(),
                        )
                      ]))),
                  body: Row(children: <Widget>[
                    Expanded(
                        child: SingleChildScrollView(
                            child: DataTable(
                      showCheckboxColumn: false,
                      sortColumnIndex: _currentSortColumn,
                      sortAscending: _isAscending,
                      headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      headingRowColor:
                          MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8);
                        }
                        return Colors.amber.shade400
                            .withOpacity(0.9); // Use the default value.
                      }),
                      columns: [
                        DataColumn(
                            label: const Text('Code tracabilité'),
                            onSort: sorting('CODE TRACABILITE')),
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
                            label: const Text('Tube'), onSort: sorting('TUBE')),
                        DataColumn(
                            label: const Text('Action'),
                            onSort: sorting('ACTION')),
                        DataColumn(
                            label: const Text('Code voiture'),
                            onSort: sorting('CODE VOITURE')),
                        DataColumn(
                            label: const Text('Enregistrement'),
                            onSort: sorting('DATE HEURE ENREGISTREMENT')),
                        DataColumn(
                            label: const Text('Synchronisation'),
                            onSort: sorting('DATE HEURE SYNCHRONISATION')),
                      ],
                      rows: [
                        for (Map traca in snapshot.data.take(numberDisplayed))
                          DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.grey.withOpacity(0.08);
                                }
                                if ((i += 1).isEven) {
                                  return Colors.grey.withOpacity(0.2);
                                }
                                return null; // alterne les couleurs des lignes
                              }),
                              onSelectChanged: (bool? selected) {
                                if (selected!) {
                                  setState(() {
                                    showDetailsTraca = true;
                                    globals.detailedTraca =
                                        Traca.fromSnapshot(traca);
                                  });
                                }
                              },
                              cells: [
                                DataCell(Text(traca['CODE TRACABILITE'])),
                                DataCell(Text(traca['UTILISATEUR'])),
                                DataCell(Text(traca['CODE TOURNEE'] ?? '')),
                                DataCell(Text(traca['CODE SITE'])),
                                DataCell(Text(traca['BOITE'] ?? '')),
                                DataCell(Text(traca['TUBE'] ?? '')),
                                DataCell(Text(traca['ACTION'])),
                                DataCell(Text(traca['CODE VOITURE'] ?? '')),
                                DataCell(
                                    Text(traca['DATE HEURE ENREGISTREMENT'])),
                                DataCell(
                                    Text(traca['DATE HEURE SYNCHRONISATION'])),
                              ])
                      ],
                    )))
                  ]));
            } else {
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      Flexible(
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                showDetailsTraca = false;
                              });
                            },
                            icon: const Icon(Icons.clear_outlined),
                            tooltip: 'Retour'),
                      )
                    ],
                  ),
                  Row(children: [
                    const Spacer(),
                    DetailsTracaScreen(traca: globals.detailedTraca),
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
        });
  }
}
