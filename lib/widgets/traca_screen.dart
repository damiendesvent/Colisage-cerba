import 'package:flutter/material.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../models/traca.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';

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

extension TimeOfDayConverter on TimeOfDay {
  String to24hours() {
    final hour = this.hour.toString().padLeft(2, "0");
    final minute = this.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }
}

class _TracaListState extends State<TracaList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => globals.shouldKeepAlive;

  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  final _secondAdvancedSearchTextController = TextEditingController();
  static const numberDisplayedList = [15, 25, 50, 100, 250];
  int numberDisplayed = numberDisplayedList.first;
  static const searchFieldList = [
    'Code tracabilité',
    'Utilisateur',
    'Libellé tournée',
    'Libellé site',
    'Boite',
    'Tube',
    'Action',
    'Code voiture',
    'Date Heure enregistrement',
    'Date Heure synchronisation',
  ];
  String searchField = searchFieldList.first;
  String advancedSearchField = searchFieldList[1];
  String secondAdvancedSearchField = searchFieldList[2];
  bool _isAscending = false;
  int _currentSortColumn = 0;
  int i = 0;
  int isAdvancedResearch = 0;
  String beginDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String beginTime = '';
  String endTime = '';
  List<dynamic> tracas = [];
  List<dynamic> backupFiles = [];
  String backupFile = '';
  bool backupMode = false;

  void getTracaList() async {
    String phpUriTracaList = Env.urlPrefix + 'Tracas/list_traca.php';
    http.Response res = await http.post(Uri.parse(phpUriTracaList), body: {
      "backup": backupMode ? 'true' : 'false',
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      //_streamController.add(items);
      setState(() {
        tracas = items;
      });
    }
  }

  void getBackupTracaFiles() async {
    String phpUriBackupTracaFiles =
        Env.urlPrefix + 'Backup_traca/list_backup_traca_files.php';
    http.Response res = await http.get(Uri.parse(phpUriBackupTracaFiles));
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        backupFiles = items;
        backupFile = backupFiles.first;
      });
    }
  }

  @override
  void initState() {
    getTracaList();
    getBackupTracaFiles();
    super.initState();
  }

  Future searchTraca() async {
    String phpUriTracaSearch = Env.urlPrefix + 'Tracas/search_traca.php';
    http.Response res = await http.post(Uri.parse(phpUriTracaSearch), body: {
      "backup": backupMode ? 'true' : 'false',
      "field": searchField.toUpperCase(),
      "advancedField": advancedSearchField.toUpperCase(),
      "secondAdvancedField": secondAdvancedSearchField.toUpperCase(),
      "searchText": searchField.contains('Date')
          ? beginDate + ' ' + beginTime + '__' + endDate + ' ' + endTime
          : _searchTextController.text,
      "advancedSearchText": isAdvancedResearch > 0
          ? (advancedSearchField.contains('Date')
              ? beginDate + ' ' + beginTime + '__' + endDate + ' ' + endTime
              : _advancedSearchTextController.text)
          : '',
      "secondAdvancedSearchText": isAdvancedResearch > 1
          ? (secondAdvancedSearchField.contains('Date')
              ? beginDate + ' ' + beginTime + '__' + endDate + ' ' + endTime
              : _secondAdvancedSearchTextController.text)
          : '',
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      setState(() {
        tracas = itemsSearch;
      });
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
    switch (isAdvancedResearch) {
      case 1:
        return [
          Padding(
              padding: const EdgeInsets.only(left: 10),
              child: DropdownButtonHideUnderline(
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
                      }))),
          SizedBox(
              width: 550,
              child: advancedSearchField.contains('Date')
                  ? Row(
                      children: [
                        const Text(' De : '),
                        SizedBox(
                            width: 120,
                            child: TextFormField(
                                textAlign: TextAlign.center,
                                initialValue: beginDate,
                                onChanged: (newValue) {
                                  setState(() {
                                    beginDate = newValue;
                                  });
                                })),
                        const Text(' : '),
                        SizedBox(
                            width: 60,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              initialValue: beginTime,
                              onChanged: (newValue) {
                                setState(() {
                                  beginTime = newValue;
                                });
                              },
                            )),
                        const Text(' à : '),
                        SizedBox(
                            width: 120,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              initialValue: endDate,
                              onChanged: (newValue) {
                                setState(() {
                                  endDate = newValue;
                                });
                              },
                            )),
                        const Text(' : '),
                        SizedBox(
                            width: 60,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              initialValue: endTime,
                              onChanged: (newValue) {
                                setState(() {
                                  endTime = newValue;
                                });
                              },
                            )),
                      ],
                    )
                  : TextFormField(
                      controller: _advancedSearchTextController,
                      decoration: const InputDecoration(
                          hintText: 'Deuxième champ de recherche'),
                      onFieldSubmitted: (e) {
                        searchTraca();
                      },
                    )),
          IconButton(
              onPressed: () {
                setState(() {
                  isAdvancedResearch = 2;
                });
              },
              icon: const Icon(Icons.manage_search_outlined),
              tooltip: 'Troisième champ de recherche'),
          const Spacer(),
        ];
      case 2:
        return [
          Column(children: [
            Padding(
                padding: const EdgeInsets.only(left: 10),
                child: DropdownButtonHideUnderline(
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
                        }))),
            Padding(
                padding: const EdgeInsets.only(left: 10),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                        value: secondAdvancedSearchField,
                        style: const TextStyle(fontSize: 14),
                        items: searchFieldList.map((searchFieldList) {
                          return DropdownMenuItem(
                              value: searchFieldList,
                              child: Text(searchFieldList.toString()));
                        }).toList(),
                        onChanged: (String? newAdvancedSearchField) {
                          setState(() {
                            secondAdvancedSearchField = newAdvancedSearchField!;
                          });
                          searchTraca();
                        })))
          ]),
          SizedBox(
              width: 550,
              child: Column(children: [
                advancedSearchField.contains('Date')
                    ? Row(
                        children: [
                          const Text(' De : '),
                          SizedBox(
                              width: 120,
                              child: TextFormField(
                                  textAlign: TextAlign.center,
                                  initialValue: beginDate,
                                  onChanged: (newValue) {
                                    setState(() {
                                      beginDate = newValue;
                                    });
                                  })),
                          const Text(' : '),
                          SizedBox(
                              width: 60,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                initialValue: beginTime,
                                onChanged: (newValue) {
                                  setState(() {
                                    beginTime = newValue;
                                  });
                                },
                              )),
                          const Text(' à : '),
                          SizedBox(
                              width: 120,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                initialValue: endDate,
                                onChanged: (newValue) {
                                  setState(() {
                                    endDate = newValue;
                                  });
                                },
                              )),
                          const Text(' : '),
                          SizedBox(
                              width: 60,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                initialValue: endTime,
                                onChanged: (newValue) {
                                  setState(() {
                                    endTime = newValue;
                                  });
                                },
                              )),
                        ],
                      )
                    : TextFormField(
                        controller: _advancedSearchTextController,
                        decoration: const InputDecoration(
                            hintText: 'Deuxième champ de recherche'),
                        onFieldSubmitted: (e) {
                          searchTraca();
                        },
                      ),
                secondAdvancedSearchField.contains('Date')
                    ? Row(
                        children: [
                          const Text(' De : '),
                          SizedBox(
                              width: 120,
                              child: TextFormField(
                                  textAlign: TextAlign.center,
                                  initialValue: beginDate,
                                  onChanged: (newValue) {
                                    setState(() {
                                      beginDate = newValue;
                                    });
                                  })),
                          const Text(' : '),
                          SizedBox(
                              width: 60,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                initialValue: beginTime,
                                onChanged: (newValue) {
                                  setState(() {
                                    beginTime = newValue;
                                  });
                                },
                              )),
                          const Text(' à : '),
                          SizedBox(
                              width: 120,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                initialValue: endDate,
                                onChanged: (newValue) {
                                  setState(() {
                                    endDate = newValue;
                                  });
                                },
                              )),
                          const Text(' : '),
                          SizedBox(
                              width: 60,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                initialValue: endTime,
                                onChanged: (newValue) {
                                  setState(() {
                                    endTime = newValue;
                                  });
                                },
                              )),
                        ],
                      )
                    : TextFormField(
                        controller: _secondAdvancedSearchTextController,
                        decoration: const InputDecoration(
                            hintText: 'Troisième champ de recherche'),
                        onFieldSubmitted: (e) {
                          searchTraca();
                        },
                      )
              ])),
          Padding(
              padding: const EdgeInsets.only(top: 40),
              child: IconButton(
                  onPressed: () {
                    setState(() {
                      isAdvancedResearch = 1;
                      _advancedSearchTextController.text = '';
                    });
                    searchTraca();
                  },
                  icon: const Icon(Icons.search_off_outlined),
                  tooltip: 'Supprimer champ de recherche')),
          const Spacer(),
        ];
      case 0:
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
            child: SingleChildScrollView(
                child: SizedBox(
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
                                          child: Text(traca.user,
                                              style: textStyle)))
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
                                          child: Text(traca.tournee,
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
                                          child: Text(traca.site,
                                              style: textStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child:
                                          Text('Boite : ', style: textStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: Text(traca.box,
                                              style: textStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Tube : ', style: textStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: Text(traca.tube,
                                              style: textStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child:
                                          Text('Action : ', style: textStyle)),
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
                                          child: Text(traca.registeringTime,
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
                                      child:
                                          Text('Origine : ', style: textStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 40,
                                          child: Text(traca.pgm,
                                              style: textStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Lettrage : ',
                                          style: textStyle)),
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
                    )))));
  }

  void loadBackupTraca({bool cancel = false}) {
    String phpUriLoadBackupTraca =
        Env.urlPrefix + 'Backup_traca/write_backup_traca.php';
    http.post(Uri.parse(phpUriLoadBackupTraca),
        body: {'file': cancel ? '_' : backupFile});
    setState(() {
      backupMode = !cancel;
    });
    Future.delayed(const Duration(milliseconds: 200), () => getTracaList());
  }

  void showBackupDialog() {
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, setState) => Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
                elevation: 8,
                child: SizedBox(
                    height: 200,
                    width: 400,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Accès aux archives',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade700),
                          )),
                      const Spacer(),
                      DropdownButton(
                          style: const TextStyle(fontSize: 16),
                          value: backupFile,
                          items: backupFiles.map((file) {
                            return DropdownMenuItem(
                                value: file,
                                child: Text(file.split('_')[1] +
                                    ' ' +
                                    file.split('-')[0]));
                          }).toList(),
                          onChanged: (dynamic newValue) {
                            setState(() {
                              backupFile = newValue!;
                            });
                          }),
                      const Spacer(),
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                    style: myButtonStyle,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Annuler')),
                                const Padding(
                                  padding: EdgeInsets.only(left: 20),
                                ),
                                ElevatedButton(
                                    style: myButtonStyle,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      loadBackupTraca();
                                    },
                                    child: const Text('Valider'))
                              ])),
                    ])))));
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    beginTime = TimeOfDay.now().to24hours();
    endTime = TimeOfDay.now().to24hours();
    DataTableSource tracaData =
        TracaData((traca) => showDetailTraca(traca), tracas);
    TextStyle titleStyle =
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    return Scaffold(
        appBar: AppBar(
            elevation: 8,
            toolbarHeight: 55.0 + 50 * isAdvancedResearch,
            backgroundColor: Colors.grey[300],
            flexibleSpace: FlexibleSpaceBar(
                background: Column(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
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
                            }))),
                SizedBox(
                    width: 550,
                    child: searchField.contains('Date')
                        ? Row(
                            children: [
                              const Text(' De : '),
                              SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                      textAlign: TextAlign.center,
                                      initialValue: beginDate,
                                      onChanged: (newValue) {
                                        setState(() {
                                          beginDate = newValue;
                                        });
                                      })),
                              const Text(' : '),
                              SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    initialValue: beginTime,
                                    onChanged: (newValue) {
                                      setState(() {
                                        beginTime = newValue;
                                      });
                                    },
                                  )),
                              const Text(' à : '),
                              SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    initialValue: endDate,
                                    onChanged: (newValue) {
                                      setState(() {
                                        endDate = newValue;
                                      });
                                    },
                                  )),
                              const Text(' : '),
                              SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    initialValue: endTime,
                                    onChanged: (newValue) {
                                      setState(() {
                                        endTime = newValue;
                                      });
                                    },
                                  )),
                            ],
                          )
                        : TextFormField(
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
                if (isAdvancedResearch == 0)
                  IconButton(
                      onPressed: () {
                        setState(() {
                          isAdvancedResearch = 1;
                        });
                      },
                      icon: const Icon(Icons.manage_search_outlined),
                      tooltip: 'Recherche avancée'),
                if (isAdvancedResearch > 0)
                  IconButton(
                      onPressed: () {
                        setState(() {
                          isAdvancedResearch = 0;
                          _advancedSearchTextController.text = '';
                          _secondAdvancedSearchTextController.text = '';
                        });
                        searchTraca();
                      },
                      icon: const Icon(Icons.search_off_outlined),
                      tooltip: 'Recherche simple'),
                const Spacer(),
                if (globals.shouldDisplaySyncButton)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        getTracaList();
                      });
                    },
                    icon: const Icon(Icons.sync),
                    tooltip: 'Actualiser l\'onglet',
                  ),
                if (backupMode)
                  ElevatedButton(
                      style: myButtonStyle,
                      onPressed: () => loadBackupTraca(cancel: true),
                      child: const Text(
                        'Retour à la\nbase de données',
                        textAlign: TextAlign.center,
                      )),
                if (!backupMode)
                  ElevatedButton(
                      style: myButtonStyle,
                      onPressed: () {
                        showBackupDialog();
                      },
                      child: const Text(
                        'Accéder aux\n archives',
                        textAlign: TextAlign.center,
                      )),
                const Spacer(),
                const Text('Nombre de\nlignes affichées : '),
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
            ]))),
        body: tracaData.rowCount != 0
            ? Row(children: <Widget>[
                Expanded(
                    child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                            controller: _scrollController,
                            child: PaginatedDataTable(
                                rowsPerPage: numberDisplayed,
                                showFirstLastButtons: true,
                                showCheckboxColumn: false,
                                columnSpacing: 0,
                                sortColumnIndex: _currentSortColumn,
                                sortAscending: _isAscending,
                                columns: [
                                  DataColumn(
                                      label: Text(
                                        'Code\ntracabilité',
                                        textAlign: TextAlign.center,
                                        style: titleStyle,
                                      ),
                                      onSort: sorting('CODE TRACABILITE')),
                                  DataColumn(
                                      label: Text('Utilisateur',
                                          style: titleStyle),
                                      onSort: sorting('UTILISATEUR')),
                                  DataColumn(
                                      label: Text('Tournée', style: titleStyle),
                                      onSort: sorting('LIBELLE TOURNEE')),
                                  DataColumn(
                                      label: Text('Site', style: titleStyle),
                                      onSort: sorting('LIBELLE SITE')),
                                  DataColumn(
                                      label: Text('Boite', style: titleStyle),
                                      onSort: sorting('BOITE')),
                                  DataColumn(
                                      label: Text('Tube', style: titleStyle),
                                      onSort: sorting('TUBE')),
                                  DataColumn(
                                      label: Text('Action', style: titleStyle),
                                      onSort: sorting('ACTION')),
                                  DataColumn(
                                      label: Text('Code\nvoiture',
                                          textAlign: TextAlign.center,
                                          style: titleStyle),
                                      onSort: sorting('CODE VOITURE')),
                                  DataColumn(
                                      label: Text('Enregistrement',
                                          style: titleStyle),
                                      onSort:
                                          sorting('DATE HEURE ENREGISTREMENT')),
                                  DataColumn(
                                      label: Text('Synchronisation',
                                          style: titleStyle),
                                      onSort: sorting(
                                          'DATE HEURE SYNCHRONISATION')),
                                ],
                                source: tracaData))))
              ])
            : const Center(
                child: Text('Aucun élément ne correspond à votre recherche')));
  }
}

class TracaData extends DataTableSource {
  List<dynamic> data;
  final Function onRowSelected;
  TracaData(this.onRowSelected, this.data);

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
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
            onRowSelected(Traca.fromSnapshot(data[index]));
            //notifyListeners();
          }
        },
        cells: [
          DataCell(SelectableText(data[index]['CODE TRACABILITE'])),
          DataCell(SelectableText(data[index]['UTILISATEUR'])),
          DataCell(SizedBox(
              width: 150,
              child: AutoSizeText(
                data[index]['LIBELLE TOURNEE'] ?? '',
                maxLines: 2,
                minFontSize: 14,
                overflowReplacement: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Tooltip(
                        message: data[index]['LIBELLE TOURNEE'] ?? '',
                        child: Text(
                          data[index]['LIBELLE TOURNEE'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                ),
              ))),
          DataCell(SizedBox(
              width: 150,
              child: AutoSizeText(
                data[index]['LIBELLE SITE'],
                maxLines: 3,
                minFontSize: 14,
                overflowReplacement: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Tooltip(
                        message: data[index]['LIBELLE SITE'],
                        child: Text(
                          data[index]['LIBELLE SITE'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                ),
              ))),
          DataCell(SelectableText(data[index]['BOITE'] ?? '')),
          DataCell(SelectableText(data[index]['TUBE'] ?? '')),
          DataCell(SelectableText(data[index]['ACTION'])),
          DataCell(SelectableText(data[index]['CODE VOITURE'] ?? '')),
          DataCell(SelectableText(DateFormat("HH'h'mm:ss\ndd/MM/yyyy").format(
              DateTime.parse(data[index]['DATE HEURE ENREGISTREMENT'])))),
          DataCell(SelectableText(DateFormat("HH'h'mm:ss\ndd/MM/yyyy").format(
              DateTime.parse(data[index]['DATE HEURE SYNCHRONISATION'])))),
        ]);
  }

  onRowSelect() {}
}
