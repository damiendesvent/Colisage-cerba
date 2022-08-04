import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:searchfield/searchfield.dart';
import '../variables/globals.dart' as globals;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: CallList());
  }
}

class CallList extends StatefulWidget {
  const CallList({Key? key}) : super(key: key);

  @override
  _CallListState createState() => _CallListState();
}

extension TimeOfDayConverter on TimeOfDay {
  String to24hours() {
    final hour = this.hour.toString().padLeft(2, "0");
    final minute = this.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }
}

class _CallListState extends State<CallList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => globals.shouldKeepAlive;

  String site = '';
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  static const numberDisplayedList = [15, 25, 50, 100, 250, 500];
  int numberDisplayed = numberDisplayedList.first;
  static const searchFieldList = [
    'Heure arrivée',
    'Libellé tournée',
    'Téléphone',
    'Passage sur appel',
  ];
  String searchField = searchFieldList.first;
  String advancedSearchField = searchFieldList[1];
  bool _isAscending = true;
  int _currentSortColumn = 0;
  int i = 0;
  int isAdvancedResearch = 0;
  String beginTime = '';
  String endTime = '';
  List<dynamic> items = [];
  List<dynamic> backupFiles = [];
  String backupFile = '';
  bool backupMode = false;
  List sites = [];
  bool showCalls = false;
  TextEditingController commentController = TextEditingController();

  void getCallList() async {
    String phpUriCallList =
        Env.urlPrefix + 'Calls/list_calls_road_map_detail.php';
    http.Response res = await http.post(Uri.parse(phpUriCallList), body: {
      "site": site,
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
    });
    if (res.body.isNotEmpty) {
      setState(() {
        items = json.decode(res.body);
      });
    }
  }

  @override
  void initState() {
    getSiteList();
    super.initState();
  }

  void getSiteList() async {
    String phpUriSiteList = Env.urlPrefix + 'Sites/list_site.php';
    http.Response res = await http.post(Uri.parse(phpUriSiteList),
        body: {"limit": '100000', "delete": 'false'});
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        sites = items.map((item) => item['LIBELLE SITE']).toList();
      });
    }
  }

  Future searchCall() async {
    String phpUriTracaSearch =
        Env.urlPrefix + 'Calls/search_calls_road_map_detail.php';
    http.Response res = await http.post(Uri.parse(phpUriTracaSearch), body: {
      "site": site.toString(),
      "field": searchField == 'Téléphone'
          ? 'TEL CHAUFFEUR'
          : searchField.toUpperCase(),
      "advancedField": advancedSearchField == 'Téléphone'
          ? 'TEL CHAUFFEUR'
          : advancedSearchField.toUpperCase(),
      "searchText": _searchTextController.text,
      "advancedSearchText":
          isAdvancedResearch > 0 ? _advancedSearchTextController.text : '',
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      setState(() {
        items = itemsSearch;
      });
    }
  }

  sorting(String field) {
    return ((columnIndex, _) {
      setState(() {
        _currentSortColumn = columnIndex;
        _isAscending = !_isAscending;
        searchCall();
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
                      }))),
          SizedBox(
              width: 360,
              child: TextFormField(
                style: defaultTextStyle,
                controller: _advancedSearchTextController,
                decoration: const InputDecoration(
                    hintText: 'Deuxième champ de recherche'),
                onFieldSubmitted: (e) {
                  searchCall();
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
      case 0:
        return [const Spacer()];
    }
  }

  void onAddTraca({required String action, required String tournee}) {
    String phpUriAddTraca = Env.urlPrefix + 'Tracas/add_traca.php';
    http.post(Uri.parse(phpUriAddTraca), body: {
      'user': globals.user.code,
      'site': site,
      'box': '',
      'tournee': tournee,
      'tube': '',
      'action': action,
      'car': '',
      'comment': commentController.text,
      'registering': DateTime.now()
          .toString()
          .substring(0, DateTime.now().toString().length - 4),
      'pgm': globals.ip.length > 15 ? globals.ip.substring(0, 15) : globals.ip,
    });
  }

  void onAddCall(dynamic call) {
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
                            'Tracer un apppel',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade700),
                          )),
                      const Spacer(),
                      Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          defaultColumnWidth: const FractionColumnWidth(0.4),
                          children: [
                            TableRow(children: [
                              const TableCell(
                                child: Text('Commentaire : ',
                                    style: defaultTextStyle),
                              ),
                              TableCell(
                                  child: SizedBox(
                                      height: 40,
                                      child: TextField(
                                        style: defaultTextStyle,
                                        textAlignVertical:
                                            TextAlignVertical.bottom,
                                        textInputAction: TextInputAction.next,
                                        controller: commentController,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(80),
                                        ],
                                      )))
                            ]),
                          ]),
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
                                      onAddTraca(
                                          action: 'TEL',
                                          tournee: call['LIBELLE TOURNEE']);
                                    },
                                    child: const Text('Valider'))
                              ])),
                      const Spacer(),
                    ])))));
  }

  final ScrollController _scrollController = ScrollController();
  final formKey = GlobalKey<FormState>();
  bool submited = false;
  TextEditingController siteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DataTableSource tracaData = CallData((call) => onAddCall(call), items);
    TextStyle titleStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: defaultTextStyle.fontSize);
    return !showCalls
        ? Scaffold(
            backgroundColor: backgroundColor,
            body: Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding: const EdgeInsets.all(15),
                elevation: 8,
                child: SizedBox(
                    width: 500,
                    height: 250,
                    child: Form(
                        key: formKey,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, bottom: 20),
                                  child: Text('Passage des tournées',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade700))),
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Site :  ',
                                      style: defaultTextStyle),
                                  SizedBox(
                                      width: 250,
                                      child: SearchField(
                                        itemHeight: 30,
                                        searchStyle: defaultTextStyle,
                                        onSubmit: (_) {
                                          formKey.currentState!.validate();
                                        },
                                        controller: siteController,
                                        textInputAction: TextInputAction.next,
                                        validator: (x) {
                                          if (!sites.contains(x) ||
                                              x!.isEmpty) {
                                            return 'Veuillez entrer un site valide';
                                          }
                                          return null;
                                        },
                                        emptyWidget: Text('Aucun site trouvé',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.red.shade900,
                                                fontSize:
                                                    defaultTextStyle.fontSize! -
                                                        3)),
                                        searchInputDecoration: InputDecoration(
                                          errorStyle: TextStyle(
                                              fontSize:
                                                  defaultTextStyle.fontSize! -
                                                      4,
                                              height: 0.3),
                                          errorText:
                                              (siteController.text.isEmpty &&
                                                      submited
                                                  ? 'Veuillez entrer une valeur'
                                                  : null),
                                        ),
                                        suggestions: sites
                                            .map(
                                              (e) =>
                                                  SearchFieldListItem<String>(
                                                e,
                                                item: e,
                                              ),
                                            )
                                            .toList(),
                                      ))
                                ],
                              ),
                              Padding(
                                  padding: const EdgeInsets.all(30),
                                  child: ElevatedButton(
                                    style: myButtonStyle,
                                    child: const Text('Valider',
                                        style: defaultTextStyle),
                                    onPressed: () {
                                      setState(() {
                                        submited = true;
                                      });
                                      if (siteController.text.isNotEmpty &&
                                          formKey.currentState!.validate()) {
                                        setState(() {
                                          submited = false;
                                          site = siteController.text;
                                          showCalls = true;
                                          siteController.clear();
                                        });
                                        getCallList();
                                      }
                                    },
                                  )),
                              const Spacer(),
                            ])))))
        : Scaffold(
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
                        child: TextFormField(
                          style: defaultTextStyle,
                          controller: _searchTextController,
                          decoration:
                              const InputDecoration(hintText: 'Recherche'),
                          onFieldSubmitted: (e) {
                            searchCall();
                          },
                        )),
                    IconButton(
                        onPressed: () {
                          searchCall();
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
                            });
                            searchCall();
                          },
                          icon: const Icon(Icons.search_off_outlined),
                          tooltip: 'Recherche simple'),
                    const Spacer(),
                    ElevatedButton(
                        style: myButtonStyle,
                        onPressed: () => setState(() {
                              showCalls = false;
                              site = '';
                              items = [];
                            }),
                        child: const Text('Changer de site',
                            style: defaultTextStyle)),
                    if (globals.shouldDisplaySyncButton)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                getCallList();
                              });
                            },
                            icon: const Icon(Icons.sync),
                            tooltip: 'Actualiser l\'onglet',
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
                                    rowsPerPage: numberDisplayed < items.length
                                        ? numberDisplayed
                                        : items.length,
                                    showFirstLastButtons: true,
                                    showCheckboxColumn: false,
                                    columnSpacing: 0,
                                    sortColumnIndex: _currentSortColumn,
                                    sortAscending: _isAscending,
                                    columns: [
                                      DataColumn(
                                          label: Text('Heure arrivée',
                                              style: titleStyle),
                                          onSort: sorting('HEURE ARRIVEE')),
                                      DataColumn(
                                        label: Text('Libellé site',
                                            style: titleStyle),
                                      ),
                                      DataColumn(
                                          label: Text('Libellé tournée',
                                              style: titleStyle),
                                          onSort: sorting('LIBELLE TOURNEE')),
                                      DataColumn(
                                          label: Text('Téléphone',
                                              style: titleStyle),
                                          onSort: sorting('TELEPHONE')),
                                      DataColumn(
                                          label: Text('Passage sur appel',
                                              style: titleStyle),
                                          onSort: sorting('PASSAGE SUR APPEL')),
                                      const DataColumn(label: Text(''))
                                    ],
                                    source: tracaData))))
                  ])
                : (_searchTextController.text.isEmpty &&
                        _advancedSearchTextController.text.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(
                        child: Text(
                            'Aucun élément ne correspond à votre recherche'))));
  }
}

class CallData extends DataTableSource {
  List<dynamic> data;
  final Function addCall;
  CallData(this.addCall, this.data);

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
        cells: [
          DataCell(SelectableText(data[index]['HEURE ARRIVEE'],
              style: defaultTextStyle)),
          DataCell(SizedBox(
              width: 150,
              child: AutoSizeText(
                data[index]['LIBELLE SITE'] ??
                    (data[index]['CODE SITE'] ?? 'Aucune'),
                style: defaultTextStyle,
                maxLines: 2,
                minFontSize: defaultTextStyle.fontSize! - 2,
                overflowReplacement: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Tooltip(
                        message: data[index]['LIBELLE SITE'] ??
                            (data[index]['CODE SITE'] ?? 'Aucune'),
                        child: Text(
                            data[index]['LIBELLE SITE'] ??
                                (data[index]['CODE SITE'] ?? 'Aucune'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: defaultTextStyle)),
                  ],
                ),
              ))),
          DataCell(SizedBox(
              width: 150,
              child: AutoSizeText(
                data[index]['LIBELLE TOURNEE'] ??
                    (data[index]['CODE TOURNEE'] ?? 'Aucun'),
                style: defaultTextStyle,
                maxLines: 3,
                minFontSize: defaultTextStyle.fontSize! - 2,
                overflowReplacement: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Tooltip(
                        message: data[index]['LIBELLE TOURNEE'] ??
                            (data[index]['CODE TOURNEE'] ?? 'Aucun'),
                        child: Text(
                            data[index]['LIBELLE TOURNEE'] ??
                                (data[index]['CODE TOURNEE'] ?? 'Aucun'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: defaultTextStyle)),
                  ],
                ),
              ))),
          DataCell(SelectableText(data[index]['TELEPHONE'],
              style: defaultTextStyle)),
          DataCell(SelectableText(
              data[index]['PASSAGE SUR APPEL'] == '1' ? 'Oui' : 'Non',
              style: defaultTextStyle)),
          DataCell(data[index]['PASSAGE SUR APPEL'] == '1'
              ? IconButton(
                  icon: const Icon(Icons.add_ic_call),
                  tooltip: 'Tracer l\'appel',
                  onPressed: () {
                    addCall(data[index]);
                  },
                )
              : const Text(''))
        ]);
  }
}
