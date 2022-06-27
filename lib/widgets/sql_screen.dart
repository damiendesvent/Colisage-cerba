import 'package:flutter/material.dart';
import 'package:flutter_application_1/variables/styles.dart';
import '../variables/env.sample.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SqlScreen extends StatelessWidget {
  const SqlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SqlApp(),
      backgroundColor: backgroundColor,
    );
  }
}

class SqlApp extends StatefulWidget {
  const SqlApp({Key? key}) : super(key: key);

  @override
  _SqlAppState createState() => _SqlAppState();
}

class _SqlAppState extends State<SqlApp> {
  List? output;
  late Iterable keys;
  late Iterable values;
  bool submited = false;
  TextEditingController queryController = TextEditingController();
  String errorHintText = 'Veuillez entrer une valeur';
  String errorText = '';
  bool validQuery = true;
  final ScrollController _scrollController = ScrollController();

  void executeQuery(String query) async {
    String phpUriQuery = Env.urlPrefix + 'query.php';
    http.Response res =
        await http.post(Uri.parse(phpUriQuery), body: {"query": query});
    if (res.body.isNotEmpty) {
      if (res.body.contains('Fatal error')) {
        final startIndex = res.body.indexOf('Uncaught');
        final endindex = res.body.indexOf(':\\MAMP');
        final str = res.body.substring(startIndex, endindex);
        final lastIndex = str.lastIndexOf(' in');
        setState(() {
          validQuery = false;
          errorText = str.substring(0, lastIndex);
          errorHintText = 'Commande incorrecte.';
          output = null;
        });
      } else {
        setState(() {
          validQuery = true;
          output = json.decode(res.body);
          if (output!.isNotEmpty) {
            keys = output![0].keys;
          }
        });
      }
    }
  }

  Widget dataTable() {
    if (output != null) {
      return DataTable(
          columnSpacing: 0,
          headingTextStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          columns: keys.map((key) {
            return DataColumn(label: Text(key));
          }).toList(),
          rows: output!.take(50).map((value) {
            return DataRow(
                cells: keys.map((key) {
              return DataCell(Text(value[key] ?? ''));
            }).toList());
          }).toList());
    } else {
      if (validQuery) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 300),
          child: Text(
            'Veuillez entrer une commande.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 300),
        child: Text(
          errorText,
          style: TextStyle(color: Colors.red.shade800, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Commande : ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                              width: 1000,
                              child: TextField(
                                controller: queryController,
                                decoration: InputDecoration(
                                    hintText: 'SELECT * from sites',
                                    errorText: ((queryController.text.isEmpty ||
                                                !validQuery) &&
                                            submited
                                        ? errorHintText
                                        : null)),
                                onSubmitted: (_) {
                                  setState(() {
                                    submited = true;
                                    validQuery = true;
                                  });
                                  if (queryController.text.isNotEmpty) {
                                    executeQuery(queryController.text);
                                  } else {
                                    output = null;
                                    errorText = 'Veuillez entrer une valeur';
                                  }
                                },
                              )),
                          IconButton(
                            icon: const Icon(Icons.subdirectory_arrow_left),
                            onPressed: () {
                              setState(() {
                                submited = true;
                                validQuery = true;
                              });
                              if (queryController.text.isNotEmpty) {
                                executeQuery(queryController.text);
                              } else {
                                output = null;
                                errorText = 'Veuillez entrer une valeur';
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  dataTable()
                ])));
  }
}
