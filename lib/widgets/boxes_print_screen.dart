import 'dart:async';
import 'dart:convert';

import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../variables/globals.dart' as globals;

class BoxesPrintScreen extends StatelessWidget {
  const BoxesPrintScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const BoxesPrint(),
      backgroundColor: backgroundColor,
    );
  }
}

class BoxesPrint extends StatefulWidget {
  const BoxesPrint({Key? key}) : super(key: key);

  @override
  _BoxesPrintState createState() => _BoxesPrintState();
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _BoxesPrintState extends State<BoxesPrint>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => globals.shouldKeepAlive;

  final _boxQuantityController = TextEditingController();
  final StreamController<List> _streamController = StreamController<List>();
  List boxTypesLibelleList = [];
  List boxTypesAcronymeList = [];
  String boxType = '';
  String boxType2 = '';
  String quantity = '';
  Map<String, int> maxDatatable = {'': 0};
  String editedBoxType = '';
  bool deleteBoxes = false;
  bool showDeletedBoxTypes = false;
  final ScrollController _scrollController = ScrollController();
  TextEditingController minBoxController = TextEditingController();
  TextEditingController maxBoxController = TextEditingController();
  bool submited = false;

  getBoxTypeList() async {
    String phpUriBoxTypes = Env.urlPrefix + 'Box_types/list_box_type.php';
    final http.Response res = await http.post(Uri.parse(phpUriBoxTypes),
        body: {'deleted': showDeletedBoxTypes ? 'true' : 'false'});
    if (res.body.isNotEmpty) {
      final List items = json.decode(res.body);
      if (items.isNotEmpty) {
        _streamController.add(items);
        setState(() {
          boxTypesLibelleList = items.map((item) => item['LIBELLE']).toList();
          boxTypesAcronymeList = items.map((item) => item['ACRONYME']).toList();
          boxType = boxTypesLibelleList.first;
          boxType2 = boxType;
        });
        getBoxMax();
      } else {
        setState(() {
          boxTypesLibelleList = ['Aucun type de boîte trouvé'];
          boxTypesAcronymeList = ['Aucun type de boîte trouvé'];
          boxType = boxTypesLibelleList.first;
          boxType2 = boxType;
        });
      }
    }
  }

  void getBoxMax() async {
    String phpUriBoxMax = Env.urlPrefix + 'Boxes/max_box.php';
    for (String type in boxTypesLibelleList) {
      http.Response res = await http.post(Uri.parse(phpUriBoxMax), body: {
        "acronyme": boxTypesAcronymeList[boxTypesLibelleList.indexOf(type)]
      });
      if (res.body.isNotEmpty) {
        List items = json.decode(res.body);
        String item = items[0]['MAX(`CODE BOITE`)'] ?? '';
        item = item == '' ? '0' : item.substring(item.length - 5);
        setState(() {
          maxDatatable[type] = int.parse(item);
        });
      }
    }
  }

  barcodesPrint() {
    setState(() {
      quantity = _boxQuantityController.text;
    });
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
                int.parse(quantity) > 1
                    ? 'Êtes-vous sûr de vouloir imprimer \nles boîtes ' +
                        boxType +
                        ' n° ' +
                        (maxDatatable[boxType]! + 1).toString() +
                        ' à ' +
                        (maxDatatable[boxType]! + int.parse(quantity))
                            .toString() +
                        ' ?'
                    : 'Êtes-vous sûr de vouloir imprimer \nla boîte ' +
                        boxType +
                        ' n° ' +
                        (maxDatatable[boxType]! + 1).toString() +
                        ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      onPrint(
                          start: (1 + maxDatatable[boxType]!).toString(),
                          stop: (int.parse(quantity) + maxDatatable[boxType]!)
                              .toString(),
                          acronyme: boxTypesAcronymeList[
                              boxTypesLibelleList.indexOf(boxType)],
                          libelle: boxType,
                          createBoxes: true);
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

  void onPrint(
      {required String start,
      required String stop,
      required String acronyme,
      required String libelle,
      required bool createBoxes}) async {
    String phpUriBarcodes = Env.urlPrefix + 'Scripts/print_box_barcode.php';
    http.Response pdfRes = await http.post(Uri.parse(phpUriBarcodes), body: {
      'start': start,
      'stop': stop,
      'acronyme': acronyme,
      'libelle': libelle,
      'createBoxes': createBoxes ? 'true' : 'false'
    });
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfRes.bodyBytes);
    if (createBoxes) {
      Navigator.of(context).pop();
      Future.delayed(
          Duration(milliseconds: globals.milisecondWait), () => getBoxMax());
    }
    if (createBoxes) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
        Text(
          int.parse(quantity) > 1
              ? ' Les boîtes ' +
                  boxType +
                  ' n° ' +
                  (maxDatatable[boxType]! + 1).toString() +
                  ' à ' +
                  (maxDatatable[boxType]! + int.parse(quantity)).toString() +
                  ' ont bien été créées.'
              : 'La boîte ' +
                  boxType +
                  ' n° ' +
                  (maxDatatable[boxType]! + 1).toString() +
                  ' a bien été créée.',
          textAlign: TextAlign.center,
          style: defaultTextStyle,
        ),
        width: 800,
      ));
    }
  }

  Widget displayBoxes() {
    bool submited = false;
    String maxValue = '';
    String libelle = '';
    return StatefulBuilder(
        builder: (context, setState) => Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade300, offset: const Offset(0, 2))
                ],
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20)),
            child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FixedColumnWidth(160)
                },
                children: [
                  TableRow(children: [
                    TableCell(
                        child: SizedBox(
                            height: 50,
                            child: Center(
                                child: Text('Catégorie',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            defaultTextStyle.fontSize))))),
                    for (String type in boxTypesLibelleList)
                      if (type == editedBoxType && !deleteBoxes)
                        TableCell(
                            child: TextFormField(
                                textAlignVertical: TextAlignVertical.bottom,
                                initialValue: type,
                                onChanged: (newValue) => setState(() {
                                      libelle = newValue;
                                    }),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(25),
                                ],
                                decoration: InputDecoration(
                                  errorStyle: TextStyle(
                                      fontSize: defaultTextStyle.fontSize! - 4,
                                      height: 0.3),
                                  errorText: submited
                                      ? 'Veuillez entrer une valeur'
                                      : null,
                                  errorMaxLines: 2,
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: defaultTextStyle.fontSize,
                                    fontWeight: FontWeight.bold)))
                      else
                        TableCell(
                            child: SelectableText(
                          type,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: defaultTextStyle.fontSize),
                        ))
                  ]),
                  TableRow(children: [
                    TableCell(
                        child: SizedBox(
                            height: 50,
                            child: Center(
                                child: Text('Code',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            defaultTextStyle.fontSize))))),
                    for (String type in boxTypesAcronymeList)
                      TableCell(
                          child: SelectableText(
                        type,
                        textAlign: TextAlign.center,
                        style: defaultTextStyle,
                      ))
                  ]),
                  TableRow(children: [
                    TableCell(
                        child: SizedBox(
                            height: 50,
                            child: Center(
                                child: Text('N° min',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            defaultTextStyle.fontSize))))),
                    for (String type in boxTypesLibelleList)
                      TableCell(
                          child: SelectableText(
                              maxDatatable[type] != null &&
                                      maxDatatable[type]! > 0
                                  ? '1'
                                  : '0',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: defaultTextStyle.fontSize)))
                  ]),
                  TableRow(children: [
                    TableCell(
                        child: SizedBox(
                            height: 50,
                            child: Center(
                                child: Text('N° max',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            defaultTextStyle.fontSize))))),
                    for (String type in boxTypesLibelleList)
                      if (type == editedBoxType && deleteBoxes)
                        TableCell(
                            child: TextFormField(
                                textAlignVertical: TextAlignVertical.bottom,
                                initialValue: maxDatatable[type].toString(),
                                onChanged: (newValue) => setState(() {
                                      maxValue = newValue;
                                    }),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  errorStyle: TextStyle(
                                      fontSize: defaultTextStyle.fontSize! - 4,
                                      height: 0.3),
                                  errorText: submited
                                      ? 'Valeur non comprise entre 1 et ' +
                                          maxDatatable[type].toString()
                                      : null,
                                  errorMaxLines: 3,
                                ),
                                textAlign: TextAlign.center,
                                style: defaultTextStyle))
                      else
                        TableCell(
                            child: SelectableText(maxDatatable[type].toString(),
                                textAlign: TextAlign.center,
                                style: defaultTextStyle))
                  ]),
                  TableRow(children: [
                    TableCell(
                        child: SizedBox(
                            height: 70,
                            child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: ElevatedButton(
                                    style: myButtonStyle,
                                    onPressed: () {
                                      showAddPageBoxType();
                                    },
                                    child: const Text(
                                      'Ajouter une catégorie',
                                      textAlign: TextAlign.center,
                                    ))))),
                    for (String type in boxTypesLibelleList)
                      if (type == editedBoxType)
                        TableCell(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () {
                                  setState(() {
                                    submited = true;
                                  });
                                  if (deleteBoxes) {
                                    if ((maxValue == ''
                                            ? 9999
                                            : int.parse(maxValue)) <=
                                        maxDatatable[type]!) {
                                      onDeleteBoxes(maxValue);
                                    }
                                  } else {
                                    if (libelle.isNotEmpty) {
                                      onUpdate(
                                          libelle: libelle,
                                          acronyme: boxTypesAcronymeList[
                                              boxTypesLibelleList
                                                  .indexOf(type)]);
                                    }
                                  }
                                },
                                tooltip: 'Valider les changements',
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    editedBoxType = '';
                                  });
                                },
                                tooltip: 'Annuler les changements',
                              )
                            ]))
                      else
                        TableCell(
                            child: boxType != 'Aucun type de boîte trouvé'
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            setState(() {
                                              libelle = type;
                                              submited = false;
                                              editedBoxType = type;
                                              deleteBoxes = false;
                                            });
                                          },
                                          tooltip: 'Editer le libellé',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            setState(() {
                                              maxValue =
                                                  maxDatatable[type].toString();
                                              submited = false;
                                              editedBoxType = type;
                                              deleteBoxes = true;
                                            });
                                          },
                                          tooltip: 'Supprimer des boîtes',
                                        )
                                      ])
                                : const Text('Aucune action réalisable',
                                    textAlign: TextAlign.center))
                  ]),
                  TableRow(children: [
                    TableCell(
                        child: SizedBox(
                            height: 70,
                            child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(children: [
                                  const Text(
                                    'Types\nsupprimés',
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Switch(
                                      value: showDeletedBoxTypes,
                                      onChanged: (newValue) {
                                        setState(() {
                                          showDeletedBoxTypes = newValue;
                                        });
                                        getBoxTypeList();
                                      })
                                ])))),
                    for (String type in boxTypesLibelleList)
                      TableCell(
                          child: showDeletedBoxTypes
                              ? IconButton(
                                  icon:
                                      const Icon(Icons.settings_backup_restore),
                                  onPressed: () {
                                    boxType == 'Aucun type de boîte trouvé'
                                        ? null
                                        : onRestoreBoxType(libelle: type);
                                  },
                                  tooltip:
                                      boxType == 'Aucun type de boîte trouvé'
                                          ? null
                                          : ('Restaurer le type ' + type),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_forever),
                                  onPressed: () {
                                    onDeleteBoxType(libelle: type);
                                  },
                                  tooltip: 'Supprimer le type ' + type,
                                ))
                  ])
                ])));
  }

  void onDeleteBoxType({required String libelle}) {
    String code = boxTypesAcronymeList[boxTypesLibelleList.indexOf(libelle)];
    String phpUriDeleteBoxType =
        Env.urlPrefix + 'Box_types/delete_box_type.php';
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
                'Êtes-vous sûr de vouloir supprimer \nle type ' +
                    libelle +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriDeleteBoxType),
                          body: {'code': code, 'cancel': 'false'});
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => getBoxTypeList());
                      ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
                          Text('Le type de boîte ' +
                              libelle +
                              ' a bien été supprimé'),
                          action: SnackBarAction(
                              label: 'Annuler',
                              onPressed: () {
                                http.post(Uri.parse(phpUriDeleteBoxType),
                                    body: {'code': code, 'cancel': 'true'});
                                Future.delayed(
                                    Duration(
                                        milliseconds: globals.milisecondWait),
                                    () => getBoxTypeList());
                              })));
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

  void onRestoreBoxType({required String libelle}) {
    String code = boxTypesAcronymeList[boxTypesLibelleList.indexOf(libelle)];
    String phpUriDeleteBoxType =
        Env.urlPrefix + 'Box_types/delete_box_type.php';
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
                'Êtes-vous sûr de vouloir restaurer \nle type ' +
                    libelle +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriDeleteBoxType),
                          body: {'code': code, 'cancel': 'true'});
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => getBoxTypeList());
                      ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
                          Text('Le type de boîte ' +
                              libelle +
                              ' a bien été restauré')));
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

  void onUpdate({required String libelle, required String acronyme}) {
    String phpUriUpdate = Env.urlPrefix + 'Box_types/update_box_type.php';
    http.post(Uri.parse(phpUriUpdate),
        body: {'newLibelle': libelle, 'acronyme': acronyme});
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
        'Le type de boîte ' +
            boxTypesLibelleList[boxTypesAcronymeList.indexOf(acronyme)] +
            ' a été renommé en ' +
            libelle)));
    setState(() {
      editedBoxType = '';
    });
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getBoxTypeList());
  }

  void showPrintPage({required String libelle}) {
    bool submited = false;
    TextEditingController minBoxController = TextEditingController();
    TextEditingController maxBoxController = TextEditingController();
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (_) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25))),
                  title: Text('Impression d\'étiquettes ' + libelle),
                  content: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    defaultColumnWidth: const FractionColumnWidth(0.4),
                    children: [
                      TableRow(children: [
                        const TableCell(child: Text('N° début : ')),
                        TableCell(
                            child: SizedBox(
                                height: 60,
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.bottom,
                                  style: defaultTextStyle,
                                  controller: minBoxController,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  decoration: InputDecoration(
                                      errorStyle: TextStyle(
                                          fontSize:
                                              defaultTextStyle.fontSize! - 4,
                                          height: 0.3),
                                      errorText: submited &&
                                              (minBoxController.text.isEmpty ||
                                                  int.parse(minBoxController
                                                          .text) <
                                                      1 ||
                                                  int.parse(minBoxController
                                                          .text) >
                                                      maxDatatable[libelle]!)
                                          ? 'Valeur non valide'
                                          : null),
                                  textAlign: TextAlign.center,
                                )))
                      ]),
                      TableRow(children: [
                        const TableCell(child: Text('N° fin : ')),
                        TableCell(
                            child: SizedBox(
                                height: 60,
                                child: TextField(
                                  textAlignVertical: TextAlignVertical.bottom,
                                  style: defaultTextStyle,
                                  controller: maxBoxController,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  decoration: InputDecoration(
                                      errorStyle: TextStyle(
                                          fontSize:
                                              defaultTextStyle.fontSize! - 4,
                                          height: 0.3),
                                      errorText: submited
                                          ? 'Valeur non valide'
                                          : null),
                                  textAlign: TextAlign.center,
                                )))
                      ]),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          setState(() {
                            submited = true;
                          });
                          if (minBoxController.text.isNotEmpty &&
                              maxBoxController.text.isNotEmpty) {
                            if (int.parse(minBoxController.text) >= 1 &&
                                int.parse(maxBoxController.text) <=
                                    maxDatatable[libelle]! &&
                                int.parse(minBoxController.text) <=
                                    int.parse(maxBoxController.text)) {
                              onPrint(
                                  start: minBoxController.text,
                                  stop: maxBoxController.text,
                                  acronyme: boxTypesAcronymeList[
                                      boxTypesLibelleList.indexOf(libelle)],
                                  libelle: libelle,
                                  createBoxes: false);
                            }
                          }
                        },
                        child: const Text('Imprimer')),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Annuler'))
                  ],
                )));
  }

  void onDeleteBoxes(String min) {
    String phpUriDeleteBox = Env.urlPrefix + 'Boxes/delete_box.php';
    http.post(Uri.parse(phpUriDeleteBox), body: {
      'min': (int.parse(min) + 1).toString(),
      'max': maxDatatable[editedBoxType].toString(),
      'type': boxTypesAcronymeList[boxTypesLibelleList.indexOf(editedBoxType)]
    });
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
        int.parse(min) + 1 < maxDatatable[editedBoxType]!
            ? ' Les boîtes ' +
                editedBoxType +
                ' n° ' +
                (int.parse(min) + 1).toString() +
                ' à ' +
                (maxDatatable[editedBoxType]!).toString() +
                ' ont bien été supprimées.'
            : 'La boîte ' +
                editedBoxType +
                ' n° ' +
                (int.parse(min) + 1).toString() +
                ' a bien été supprimée.')));
    setState(() {
      editedBoxType = '';
    });
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getBoxMax());
  }

  Future<bool> isBoxType(String code) async {
    String phpUriCountUser = Env.urlPrefix + 'Box_types/count_box_type.php';
    http.Response res =
        await http.post(Uri.parse(phpUriCountUser), body: {"code": code});
    if (res.body.isNotEmpty && res.body != '{"COUNT(*)":"0"}') {
      return true;
    }
    return false;
  }

  void showAddPageBoxType() {
    TextEditingController codeController = TextEditingController();
    TextEditingController libelleController = TextEditingController();
    bool submited = false;
    String codeValueCheck = 'Veuillez entrer une valeur';
    bool codeExisting = true;

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
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                      width: 500,
                      height: 300,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Ajout d\'un type de boîte',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade700),
                            )),
                        const Spacer(),
                        Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          defaultColumnWidth: const FractionColumnWidth(0.4),
                          children: [
                            TableRow(children: [
                              const TableCell(
                                child:
                                    Text('Code* : ', style: defaultTextStyle),
                              ),
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: TextField(
                                          textAlignVertical:
                                              TextAlignVertical.bottom,
                                          style: defaultTextStyle,
                                          controller: codeController,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(5),
                                            UpperCaseTextFormatter()
                                          ],
                                          decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontSize:
                                                    defaultTextStyle.fontSize! -
                                                        4,
                                                height: 0.3),
                                            errorText:
                                                (codeController.text.isEmpty ||
                                                            codeExisting) &&
                                                        submited
                                                    ? codeValueCheck
                                                    : null,
                                          ))))
                            ]),
                            TableRow(children: [
                              const TableCell(
                                child: Text('Libellé* : ',
                                    style: defaultTextStyle),
                              ),
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: TextField(
                                          textAlignVertical:
                                              TextAlignVertical.bottom,
                                          style: defaultTextStyle,
                                          controller: libelleController,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                                25),
                                          ],
                                          decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontSize:
                                                    defaultTextStyle.fontSize! -
                                                        4,
                                                height: 0.3),
                                            errorText: libelleController
                                                        .text.isEmpty &&
                                                    submited
                                                ? 'Veuillez entrer une valeur'
                                                : null,
                                          ))))
                            ]),
                          ],
                        ),
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
                                            codeExisting = true;
                                          });
                                          isBoxType(codeController.text)
                                              .then((value) => setState(() {
                                                    codeExisting = value;
                                                    codeValueCheck = codeExisting
                                                        ? 'Etape existante'
                                                        : 'Veuillez entrer une valeur';
                                                    if (!codeExisting &&
                                                        codeController
                                                            .text.isNotEmpty &&
                                                        libelleController
                                                            .text.isNotEmpty) {
                                                      onAddBoxType(
                                                          code: codeController
                                                              .text,
                                                          libelle:
                                                              libelleController
                                                                  .text);
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
                                    color: Colors.grey.shade700, fontSize: 12)))
                      ]))
                ]));
          });
        });
  }

  void onAddBoxType({required String code, required String libelle}) {
    String phpUriAddBoxType = Env.urlPrefix + 'Box_types/add_box_type.php';
    http.post(Uri.parse(phpUriAddBoxType),
        body: {'code': code, 'libelle': libelle});
    Navigator.of(context).pop();
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getBoxTypeList());
  }

  @override
  void initState() {
    super.initState();
    getBoxTypeList();
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
                child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Dialog(
                                  insetPadding: const EdgeInsets.all(30),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(25))),
                                  elevation: 8,
                                  child: SizedBox(
                                      width: 400,
                                      height: 350,
                                      child: Column(
                                        children: [
                                          const Padding(
                                              padding: EdgeInsets.all(30),
                                              child: Text(
                                                'Création d\'étiquettes de boîtes',
                                                style: TextStyle(fontSize: 20),
                                              )),
                                          Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                'Cet outil crée les boîtes du type spécifié puis lance l\'impression de leurs étiquettes.',
                                                style: TextStyle(
                                                    fontSize: defaultTextStyle
                                                            .fontSize! -
                                                        2,
                                                    color:
                                                        Colors.grey.shade700),
                                              )),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 20, 10, 0),
                                              child: SizedBox(
                                                  width: 400,
                                                  child:
                                                      DropdownButtonFormField(
                                                    style: defaultTextStyle,
                                                    value: boxType,
                                                    items: boxTypesLibelleList
                                                        .map((boxType) {
                                                      return DropdownMenuItem(
                                                          value: boxType,
                                                          child: Text(boxType));
                                                    }).toList(),
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        boxType =
                                                            newValue.toString();
                                                      });
                                                    },
                                                  ))),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: SizedBox(
                                                  width: 150,
                                                  child: TextFormField(
                                                    style: defaultTextStyle,
                                                    readOnly: boxType ==
                                                        'Aucun type de boîte trouvé',
                                                    controller:
                                                        _boxQuantityController,
                                                    inputFormatters: <
                                                        TextInputFormatter>[
                                                      FilteringTextInputFormatter
                                                          .digitsOnly
                                                    ],
                                                    decoration:
                                                        const InputDecoration(
                                                            hintText:
                                                                'Quantité à imprimer'),
                                                    onFieldSubmitted: (_) {
                                                      if (_boxQuantityController
                                                          .text.isNotEmpty) {
                                                        barcodesPrint();
                                                      }
                                                    },
                                                  ))),
                                          Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: ElevatedButton(
                                                  style: myButtonStyle,
                                                  onPressed: () {
                                                    if (_boxQuantityController
                                                        .text.isNotEmpty) {
                                                      barcodesPrint();
                                                    }
                                                  },
                                                  child: const Text(
                                                      'Créer et imprimer'))),
                                        ],
                                      ))),
                              const Spacer(),
                              Dialog(
                                  insetPadding: const EdgeInsets.all(30),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(25))),
                                  elevation: 8,
                                  child: SizedBox(
                                      width: 400,
                                      height: 350,
                                      child: Column(
                                        children: [
                                          const Padding(
                                              padding: EdgeInsets.all(30),
                                              child: Text(
                                                'Impression d\'étiquettes de boîtes',
                                                style: TextStyle(fontSize: 20),
                                              )),
                                          Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                'Cet outil l\'impression des étiquettes de boîtes spécifiées.',
                                                style: TextStyle(
                                                    fontSize: defaultTextStyle
                                                            .fontSize! -
                                                        2,
                                                    color:
                                                        Colors.grey.shade700),
                                              )),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 20, 10, 0),
                                              child: SizedBox(
                                                  width: 400,
                                                  child:
                                                      DropdownButtonFormField(
                                                    style: defaultTextStyle,
                                                    value: boxType2,
                                                    items: boxTypesLibelleList
                                                        .map((boxType) {
                                                      return DropdownMenuItem(
                                                          value: boxType,
                                                          child: Text(boxType));
                                                    }).toList(),
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        boxType2 =
                                                            newValue.toString();
                                                      });
                                                    },
                                                  ))),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                        height: 60,
                                                        width: 130,
                                                        child: TextFormField(
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .bottom,
                                                          style:
                                                              defaultTextStyle,
                                                          readOnly: boxType2 ==
                                                              'Aucun type de boîte trouvé',
                                                          controller:
                                                              minBoxController,
                                                          inputFormatters: <
                                                              TextInputFormatter>[
                                                            FilteringTextInputFormatter
                                                                .digitsOnly,
                                                            LengthLimitingTextInputFormatter(
                                                                4)
                                                          ],
                                                          decoration: InputDecoration(
                                                              errorStyle: TextStyle(
                                                                  fontSize:
                                                                      defaultTextStyle
                                                                              .fontSize! -
                                                                          4,
                                                                  height: 0.3),
                                                              hintText:
                                                                  'N° début',
                                                              errorText: submited &&
                                                                      (minBoxController
                                                                              .text
                                                                              .isEmpty ||
                                                                          int.parse(minBoxController.text) <
                                                                              1 ||
                                                                          int.parse(minBoxController.text) >
                                                                              maxDatatable[boxType2]!)
                                                                  ? 'Valeur non valide'
                                                                  : null),
                                                        )),
                                                    const Padding(
                                                        padding:
                                                            EdgeInsets.all(20)),
                                                    SizedBox(
                                                        height: 60,
                                                        width: 130,
                                                        child: TextFormField(
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .bottom,
                                                          style:
                                                              defaultTextStyle,
                                                          readOnly: boxType2 ==
                                                              'Aucun type de boîte trouvé',
                                                          controller:
                                                              maxBoxController,
                                                          inputFormatters: <
                                                              TextInputFormatter>[
                                                            FilteringTextInputFormatter
                                                                .digitsOnly,
                                                            LengthLimitingTextInputFormatter(
                                                                4),
                                                          ],
                                                          decoration: InputDecoration(
                                                              errorStyle: TextStyle(
                                                                  fontSize:
                                                                      defaultTextStyle
                                                                              .fontSize! -
                                                                          4,
                                                                  height: 0.3),
                                                              hintText:
                                                                  'N° fin',
                                                              errorText: submited
                                                                  ? 'Valeur non valide'
                                                                  : null),
                                                        ))
                                                  ])),
                                          Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: ElevatedButton(
                                                  style: myButtonStyle,
                                                  onPressed: () {
                                                    setState(() {
                                                      submited = true;
                                                    });
                                                    if (minBoxController
                                                            .text.isNotEmpty &&
                                                        maxBoxController
                                                            .text.isNotEmpty) {
                                                      if (int.parse(
                                                                  minBoxController
                                                                      .text) >=
                                                              1 &&
                                                          int.parse(
                                                                  maxBoxController
                                                                      .text) <=
                                                              maxDatatable[
                                                                  boxType2]! &&
                                                          int.parse(
                                                                  minBoxController
                                                                      .text) <=
                                                              int.parse(
                                                                  maxBoxController
                                                                      .text)) {
                                                        setState(() {
                                                          submited = false;
                                                        });
                                                        onPrint(
                                                            start:
                                                                minBoxController
                                                                    .text,
                                                            stop: maxBoxController
                                                                .text,
                                                            acronyme: boxTypesAcronymeList[
                                                                boxTypesLibelleList
                                                                    .indexOf(
                                                                        boxType2)],
                                                            libelle: boxType2,
                                                            createBoxes: false);
                                                      }
                                                    }
                                                  },
                                                  child:
                                                      const Text('Imprimer'))),
                                        ],
                                      ))),
                              const Spacer()
                            ]),
                        displayBoxes(),
                      ],
                    )));
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
