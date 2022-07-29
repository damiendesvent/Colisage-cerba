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
      if (items.isEmpty) {
        Future.delayed(const Duration(seconds: 2), () => getTracaList());
      }
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
                        searchTraca();
                      }))),
          SizedBox(
              width: 360,
              child: advancedSearchField.contains('Date')
                  ? Row(
                      children: [
                        const Text(' De : '),
                        SizedBox(
                            width: 90,
                            child: TextFormField(
                                style: defaultTextStyle,
                                textAlign: TextAlign.center,
                                initialValue: beginDate,
                                onChanged: (newValue) {
                                  setState(() {
                                    beginDate = newValue;
                                  });
                                })),
                        const Text(' : '),
                        SizedBox(
                            width: 50,
                            child: TextFormField(
                              style: defaultTextStyle,
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
                            width: 90,
                            child: TextFormField(
                              style: defaultTextStyle,
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
                            width: 50,
                            child: TextFormField(
                              style: defaultTextStyle,
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
                      style: defaultTextStyle,
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
                          searchTraca();
                        }))),
            Padding(
                padding: const EdgeInsets.only(left: 10),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                        value: secondAdvancedSearchField,
                        style: defaultTextStyle,
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
              width: 360,
              child: Column(children: [
                advancedSearchField.contains('Date')
                    ? Row(
                        children: [
                          const Text(' De : '),
                          SizedBox(
                              width: 90,
                              child: TextFormField(
                                  style: defaultTextStyle,
                                  textAlign: TextAlign.center,
                                  initialValue: beginDate,
                                  onChanged: (newValue) {
                                    setState(() {
                                      beginDate = newValue;
                                    });
                                  })),
                          const Text(' : '),
                          SizedBox(
                              width: 50,
                              child: TextFormField(
                                style: defaultTextStyle,
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
                              width: 90,
                              child: TextFormField(
                                style: defaultTextStyle,
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
                              width: 50,
                              child: TextFormField(
                                style: defaultTextStyle,
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
                        style: defaultTextStyle,
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
                              width: 90,
                              child: TextFormField(
                                  style: defaultTextStyle,
                                  textAlign: TextAlign.center,
                                  initialValue: beginDate,
                                  onChanged: (newValue) {
                                    setState(() {
                                      beginDate = newValue;
                                    });
                                  })),
                          const Text(' : '),
                          SizedBox(
                              width: 50,
                              child: TextFormField(
                                style: defaultTextStyle,
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
                              width: 90,
                              child: TextFormField(
                                style: defaultTextStyle,
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
                              width: 50,
                              child: TextFormField(
                                style: defaultTextStyle,
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
                        style: defaultTextStyle,
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
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            elevation: 8,
            child: SingleChildScrollView(
                child: SizedBox(
                    height: 610,
                    width: 500,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 40),
                            child: Text(
                              'Détails de traçabilité n° ' +
                                  traca.code.toString(),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade700),
                            )),
                        Table(
                            defaultColumnWidth: const FractionColumnWidth(0.4),
                            children: [
                              TableRow(
                                children: [
                                  TableCell(
                                      child: Text('Code : ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  defaultTextStyle.fontSize))),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.code.toString(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: defaultTextStyle
                                                      .fontSize)))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Utilisateur : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.user,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Tournée : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.tournee,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Site : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.site,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Boîte/Sachet : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.box,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Tube : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.tube,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Action : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.action,
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
                                          height: 30,
                                          child: Text(traca.correspondant,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Enregistrement : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.registeringTime,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Synchronisation : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.synchronizingTime,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Origine : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.pgm,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Lettrage : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.lettrage.toString(),
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Code voiture : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: Text(traca.car.toString(),
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
                                          height: 30,
                                          child: Text(traca.comment,
                                              style: defaultTextStyle)))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Image : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: traca.picture.isNotEmpty
                                              ? TextButton(
                                                  onPressed: () =>
                                                      showImage(traca.picture),
                                                  child: Text(traca.picture,
                                                      style: defaultTextStyle))
                                              : const Center(
                                                  child: Text('Aucune',
                                                      style:
                                                          defaultTextStyle))))
                                ],
                              ),
                              TableRow(
                                children: [
                                  const TableCell(
                                      child: Text('Signature : ',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 30,
                                          child: traca.signing.isNotEmpty
                                              ? TextButton(
                                                  onPressed: () =>
                                                      showImage(traca.signing),
                                                  child: Text(traca.signing,
                                                      style: defaultTextStyle))
                                              : const Center(
                                                  child: Text('Aucune',
                                                      style:
                                                          defaultTextStyle))))
                                ],
                              ),
                            ]),
                        Padding(
                          padding: const EdgeInsets.all(15),
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
                              )),
                        ),
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
      tracas = [];
    });
    Future.delayed(const Duration(seconds: 2), () => getTracaList());
  }

  void showBackupDialog() {
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, setState) => Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
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
                                fontSize: 16, color: Colors.grey.shade700),
                          )),
                      const Spacer(),
                      DropdownButton(
                          style: defaultTextStyle,
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

  void showImage(String image) async {
    String phpUriGetImageUrl = Env.urlPrefix + 'Scripts/get_image_url.php';
    http.Response res =
        await http.post(Uri.parse(phpUriGetImageUrl), body: {'image': image});
    if (res.body.isNotEmpty) {
      showDialog(
          barrierColor: myBarrierColor,
          context: context,
          builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(20),
              elevation: 8,
              child: Image.network(json.decode(res.body))));
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    beginTime = TimeOfDay.now().to24hours();
    endTime = TimeOfDay.now().to24hours();
    DataTableSource tracaData =
        TracaData((traca) => showDetailTraca(traca), tracas);
    TextStyle titleStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: defaultTextStyle.fontSize);
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
                            }))),
                SizedBox(
                    width: 360,
                    child: searchField.contains('Date')
                        ? Row(
                            children: [
                              const Text(' De : '),
                              SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                      style: defaultTextStyle,
                                      textAlign: TextAlign.center,
                                      initialValue: beginDate,
                                      onChanged: (newValue) {
                                        setState(() {
                                          beginDate = newValue;
                                        });
                                      })),
                              const Text(' : '),
                              SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    style: defaultTextStyle,
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
                                  width: 90,
                                  child: TextFormField(
                                    style: defaultTextStyle,
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
                                  width: 50,
                                  child: TextFormField(
                                    style: defaultTextStyle,
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
                            style: defaultTextStyle,
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
                const Text(
                  'Nombre de\nlignes affichées : ',
                  style: defaultTextStyle,
                ),
                DropdownButton(
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
            : (_searchTextController.text.isEmpty &&
                    _advancedSearchTextController.text.isEmpty &&
                    _secondAdvancedSearchTextController.text.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : const Center(
                    child: Text(
                        'Aucun élément ne correspond à votre recherche'))));
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
          }
        },
        cells: [
          DataCell(SelectableText(data[index]['CODE TRACABILITE'],
              style: defaultTextStyle)),
          DataCell(SelectableText(data[index]['UTILISATEUR'],
              style: defaultTextStyle)),
          DataCell(SizedBox(
              width: 150,
              child: AutoSizeText(
                data[index]['LIBELLE TOURNEE'] ??
                    (data[index]['CODE TOURNEE'] ?? 'Aucune'),
                style: defaultTextStyle,
                maxLines: 2,
                minFontSize: defaultTextStyle.fontSize! - 2,
                overflowReplacement: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Tooltip(
                        message: data[index]['LIBELLE TOURNEE'] ??
                            (data[index]['CODE TOURNEE'] ?? 'Aucune'),
                        child: Text(
                            data[index]['LIBELLE TOURNEE'] ??
                                (data[index]['CODE TOURNEE'] ?? 'Aucune'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: defaultTextStyle)),
                  ],
                ),
              ))),
          DataCell(SizedBox(
              width: 150,
              child: AutoSizeText(
                data[index]['LIBELLE SITE'] ??
                    (data[index]['CODE SITE'] ?? 'Aucun'),
                style: defaultTextStyle,
                maxLines: 3,
                minFontSize: defaultTextStyle.fontSize! - 2,
                overflowReplacement: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Tooltip(
                        message: data[index]['LIBELLE SITE'] ??
                            (data[index]['CODE SITE'] ?? 'Aucun'),
                        child: Text(
                            data[index]['LIBELLE SITE'] ??
                                (data[index]['CODE SITE'] ?? 'Aucun'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: defaultTextStyle)),
                  ],
                ),
              ))),
          DataCell(SelectableText(data[index]['BOITE'] ?? '',
              style: defaultTextStyle)),
          DataCell(SelectableText(data[index]['TUBE'] ?? '',
              style: defaultTextStyle)),
          DataCell(
              SelectableText(data[index]['ACTION'], style: defaultTextStyle)),
          DataCell(SelectableText(data[index]['CODE VOITURE'] ?? '',
              style: defaultTextStyle)),
          DataCell(SelectableText(
              DateFormat("HH'h'mm:ss\ndd/MM/yyyy").format(
                  DateTime.parse(data[index]['DATE HEURE ENREGISTREMENT'])),
              style: defaultTextStyle)),
          DataCell(SelectableText(
              DateFormat("HH'h'mm:ss\ndd/MM/yyyy").format(
                  DateTime.parse(data[index]['DATE HEURE SYNCHRONISATION'])),
              style: defaultTextStyle)),
        ]);
  }

  onRowSelect() {}
}
