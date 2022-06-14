import 'dart:async';
import 'dart:convert';
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class BoxesPrintScreen extends StatelessWidget {
  const BoxesPrintScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: BoxesPrint(),
    );
  }
}

class BoxesPrint extends StatefulWidget {
  const BoxesPrint({Key? key}) : super(key: key);

  @override
  _BoxesPrintState createState() => _BoxesPrintState();
}

class _BoxesPrintState extends State<BoxesPrint> {
  final _boxQuantityController = TextEditingController();
  final StreamController<List> _streamController = StreamController<List>();
  late final List boxTypesLibelleList;
  late final List boxTypesAcronymeList;
  late String boxType;
  String quantity = '';

  getBoxTypeList() async {
    String phpUriBoxTypes = Env.urlPrefix + 'Box_types/list_box_type.php';
    final http.Response res = await http.get(Uri.parse(phpUriBoxTypes));
    if (res.body.isNotEmpty) {
      final List items = json.decode(res.body);
      _streamController.add(items);
      setState(() {
        boxTypesLibelleList = items.map((item) => item['LIBELLE']).toList();
        boxTypesAcronymeList = items.map((item) => item['ACRONYME']).toList();
        boxType = boxTypesLibelleList.first;
      });
    }
  }

  Future<int> getBoxMax() async {
    String phpUriBoxMax = Env.urlPrefix + 'Boxes/max_box.php';
    http.Response res = await http.post(Uri.parse(phpUriBoxMax), body: {
      "acronyme": boxTypesAcronymeList[boxTypesLibelleList.indexOf(boxType)]
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      String item = items[0]['MAX(`CODE BOITE`)'] ?? '';
      item = item == '' ? '0' : item.substring(4);
      return int.parse(item);
    } else {
      return 0;
    }
  }

  barcodesPrint() async {
    String phpUriBarcodes = Env.urlPrefix + 'Scripts/print_box_barcode.php';
    setState(() {
      quantity = _boxQuantityController.text;
    });
    final maxDatatable = await getBoxMax();
    await http.post(Uri.parse(phpUriBarcodes), body: {
      'start': (1 + maxDatatable).toString(),
      'stop': (int.parse(quantity) + maxDatatable).toString(),
      'acronyme': boxTypesAcronymeList[boxTypesLibelleList.indexOf(boxType)],
      'libelle': boxType
    });
    http.Response pdfRes =
        await http.get(Uri.parse(Env.urlPrefix + 'Scripts/output.pdf'));
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfRes.bodyBytes);
  }

  @override
  void initState() {
    getBoxTypeList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List>(
        stream: _streamController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: [
                Form(
                    child: Column(
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Impression d\'étiquettes de boites',
                          style: TextStyle(fontSize: 24),
                        )),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButtonFormField(
                          value: boxType,
                          items: boxTypesLibelleList.map((boxType) {
                            return DropdownMenuItem(
                                value: boxType, child: Text(boxType));
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              boxType = newValue.toString();
                            });
                          },
                        )),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _boxQuantityController,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              hintText: 'Quantité à imprimer'),
                          onFieldSubmitted: (_) {
                            barcodesPrint();
                          },
                        )),
                    ElevatedButton(
                        style: myButtonStyle,
                        onPressed: () {
                          barcodesPrint();
                        },
                        child: const Text('Imprimer')),
                  ],
                ))
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
