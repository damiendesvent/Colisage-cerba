import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'dart:async';
import 'dart:convert';

class UserScreen extends StatelessWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: const <Widget>[Expanded(child: UserApp())]);
  }
}

class UserApp extends StatefulWidget {
  const UserApp({Key? key}) : super(key: key);

  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<UserApp> {
  TextStyle textStyle = const TextStyle(fontSize: 16);
  final StreamController<List> _streamController = StreamController<List>();
  int i = 0;
  bool _isAscending = true;
  int _currentSortColumn = 0;
  late List users;
  String? editingUser;
  String? editingSiteStatus;
  String? editingRoadMapStatus;
  String? editingBoxStatus;
  String? editingUserStatus;
  String? executeSqlStatus;

  bool editingSiteValue = false;
  bool editingRoadMapValue = false;
  bool editingBoxValue = false;
  bool editingUserValue = false;
  bool executeSqlValue = false;

  Future getUserList() async {
    String phpUriUserList = Env.urlPrefix + 'Users/list_user.php';
    http.Response res = await http.get(Uri.parse(phpUriUserList));
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        users = items;
      });
      _streamController.add(items);
    }
  }

  sorting(String field, {bool isNumber = false}) {
    if (isNumber) {
      return ((columnIndex, _) {
        setState(() {
          _currentSortColumn = columnIndex;
          if (_isAscending) {
            users.sort((userA, userB) =>
                int.parse(userB[field]).compareTo(int.parse(userA[field])));
          } else {
            users.sort((userA, userB) =>
                int.parse(userA[field]).compareTo(int.parse(userB[field])));
          }
          _isAscending = !_isAscending;
        });
      });
    } else {
      return ((columnIndex, _) {
        setState(() {
          _currentSortColumn = columnIndex;
          if (_isAscending) {
            users.sort((userA, userB) => userB[field].compareTo(userA[field]));
          } else {
            users.sort((userA, userB) => userA[field].compareTo(userB[field]));
          }
          _isAscending = !_isAscending;
        });
      });
    }
  }

  void onUpdateUser(User myUser, String searchCode) async {
    String phpUriUserUpdate = Env.urlPrefix + 'Users/update_user.php';
    await http.post(Uri.parse(phpUriUserUpdate), body: {
      "code": myUser.code,
      "firstname": myUser.firstname,
      "lastname": myUser.lastname,
      "function": myUser.function,
      "siteEditing": myUser.siteEditing ? 'true' : 'false',
      "roadMapEditing": myUser.roadMapEditing ? 'true' : 'false',
      "boxEditing": myUser.boxEditing ? 'true' : 'false',
      "userEditing": myUser.userEditing ? 'true' : 'false',
      "sqlExecute": myUser.sqlExecute ? 'true' : 'false',
      "password": myUser.password,
      "searchCode": searchCode
    });
    setState(() {
      editingUser = null;
    });
    getUserList();
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  void onDelete(Map<dynamic, dynamic> user) {
    String phpUriUserlDelete = Env.urlPrefix + 'Users/delete_user.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir supprimer \nl\'utilisateur ' +
                    user['CODE UTILISATEUR'] +
                    ' : ' +
                    user['PRENOM'] +
                    ' ' +
                    user['NOM'] +
                    ' ?',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriUserlDelete), body: {
                        "searchCode": user['CODE UTILISATEUR'],
                        "cancel": 'false'
                      });
                      getUserList();
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
                                ' L\'utilisateur ' +
                                    user['CODE UTILISATEUR'] +
                                    ' : ' +
                                    user['PRENOM'] +
                                    ' ' +
                                    user['NOM'] +
                                    ' a bien été supprimé.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              )
                            ]),
                        action: SnackBarAction(
                          label: 'Annuler',
                          textColor: Colors.white,
                          onPressed: () {
                            http.post(Uri.parse(phpUriUserlDelete), body: {
                              "searchCode": user['CODE UTILISATEUR'],
                              "cancel": 'true'
                            });
                            getUserList();
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

  void onAddUser(User user) {
    String phpUriAddDetailRoadMap = Env.urlPrefix + 'Users/add_user.php';
    http.post(Uri.parse(phpUriAddDetailRoadMap), body: {
      "code": user.code,
      "firstname": user.firstname,
      "lastname": user.lastname,
      "function": user.function,
      "siteEditing": user.siteEditing ? 'true' : 'false',
      "roadMapEditing": user.roadMapEditing ? 'true' : 'false',
      "boxEditing": user.boxEditing ? 'true' : 'false',
      "userEditing": user.userEditing ? 'true' : 'false',
      "sqlExecute": user.sqlExecute ? 'true' : 'false',
      "password": user.password
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      Text('L\'utilisateur ' + user.code + ' a bien été ajouté'),
    ));
    getUserList();
  }

  /*Future<bool> isDetailRoadMap(String code) async {
    String phpUriDetailsDetailRoadMap =
        Env.urlPrefix + 'Road_map_details/details_road_map_detail.php';
    http.Response res = await http.post(Uri.parse(phpUriDetailsDetailRoadMap),
        body: {"searchCode": code});
    if (res.body.isNotEmpty && res.body != '[]') {
      return true;
    }
    return false;
  }*/

  void showAddPageUser() {
    const TextStyle textStyle = TextStyle(fontSize: 16);
    const tableRowSpacer = TableRow(children: [
      TableCell(child: SizedBox(height: 12)),
      TableCell(child: SizedBox(height: 12))
    ]);
    TextEditingController firstnameController = TextEditingController();
    TextEditingController lastnameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController functionController = TextEditingController();
    bool submited = false;

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
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Ajout d\'un utilisateur',
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
                                child: Text('Prénom* : ', style: textStyle),
                              ),
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: TextField(
                                          controller: firstnameController,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                                20),
                                          ],
                                          decoration: InputDecoration(
                                            errorText: firstnameController
                                                        .text.isEmpty &&
                                                    submited
                                                ? 'Veuillez entrer une valeur'
                                                : null,
                                          ))))
                            ]),
                            TableRow(children: [
                              const TableCell(
                                child: Text('Nom* : ', style: textStyle),
                              ),
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: TextField(
                                          controller: lastnameController,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                                20),
                                          ],
                                          decoration: InputDecoration(
                                            errorText: lastnameController
                                                        .text.isEmpty &&
                                                    submited
                                                ? 'Veuillez entrer une valeur'
                                                : null,
                                          ))))
                            ]),
                            TableRow(children: [
                              const TableCell(
                                  child:
                                      Text('Fonction* : ', style: textStyle)),
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: TextField(
                                          controller: functionController,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                                35),
                                          ],
                                          decoration: InputDecoration(
                                            errorText: functionController
                                                        .text.isEmpty &&
                                                    submited
                                                ? 'Veuillez entrer une valeur'
                                                : null,
                                          ))))
                            ]),
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Mot de passe* : ',
                                      style: textStyle)),
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: TextField(
                                          controller: passwordController,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                                24),
                                          ],
                                          decoration: InputDecoration(
                                            errorText: passwordController
                                                            .text.length <
                                                        4 &&
                                                    submited
                                                ? 'Veuillez entrer au moins 4 caractères'
                                                : null,
                                          ))))
                            ]),
                            tableRowSpacer,
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Edition de sites :',
                                      style: textStyle)),
                              TableCell(
                                  child: Checkbox(
                                value: editingSiteValue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    editingSiteValue = value!;
                                  });
                                },
                              ))
                            ]),
                            tableRowSpacer,
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Edition de feuilles de route :',
                                      style: textStyle)),
                              TableCell(
                                  child: Checkbox(
                                value: editingRoadMapValue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    editingRoadMapValue = value!;
                                  });
                                },
                              ))
                            ]),
                            tableRowSpacer,
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Edition de boites :',
                                      style: textStyle)),
                              TableCell(
                                  child: Checkbox(
                                value: editingBoxValue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    editingBoxValue = value!;
                                  });
                                },
                              ))
                            ]),
                            tableRowSpacer,
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Edition d\'utilisateurs :',
                                      style: textStyle)),
                              TableCell(
                                  child: Checkbox(
                                value: editingUserValue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    editingUserValue = value!;
                                  });
                                },
                              ))
                            ]),
                            tableRowSpacer,
                            TableRow(children: [
                              const TableCell(
                                  child: Text('Accès au panneau SQL :',
                                      style: textStyle)),
                              TableCell(
                                  child: Checkbox(
                                value: executeSqlValue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    executeSqlValue = value!;
                                  });
                                },
                              ))
                            ]),
                          ],
                        ),
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
                                        if (firstnameController
                                                .text.isNotEmpty &&
                                            lastnameController
                                                .text.isNotEmpty &&
                                            passwordController.text.length >
                                                3 &&
                                            functionController
                                                .text.isNotEmpty) {
                                          onAddUser(User(
                                              code: (lastnameController.text
                                                          .substring(0, 3) +
                                                      firstnameController.text
                                                          .substring(0, 1))
                                                  .toUpperCase(),
                                              firstname:
                                                  firstnameController.text,
                                              lastname: lastnameController.text,
                                              function: functionController.text,
                                              password: passwordController.text,
                                              siteEditing: editingSiteValue,
                                              roadMapEditing:
                                                  editingRoadMapValue,
                                              boxEditing: editingBoxValue,
                                              userEditing: editingUserValue,
                                              sqlExecute: executeSqlValue));
                                        }
                                      },
                                      child: Row(children: const [
                                        Icon(Icons.check),
                                        Text(' Valider')
                                      ]),
                                    )))),
                        const Spacer(),
                      ]))
                ]));
          });
        });
  }

  List<DataCell> dataCells(Map<dynamic, dynamic> user) {
    if (user['CODE UTILISATEUR'] == editingUser) {
      editingSiteStatus ??= user['EDITION SITE'] == '1' ? 'Oui' : 'Non';
      editingRoadMapStatus ??=
          user['EDITION FEUILLE DE ROUTE'] == '1' ? 'Oui' : 'Non';
      editingBoxStatus ??= user['EDITION BOITE'] == '1' ? 'Oui' : 'Non';
      editingUserStatus ??= user['EDITION UTILISATEUR'] == '1' ? 'Oui' : 'Non';
      executeSqlStatus ??= user['EXECUTION SQL'] == '1' ? 'Oui' : 'Non';
      const List<String> yesNoList = ['Oui', 'Non'];
      TextEditingController codeController =
          TextEditingController(text: user['CODE UTILISATEUR']);
      TextEditingController lastnameController =
          TextEditingController(text: user['NOM']);
      TextEditingController firstnameController =
          TextEditingController(text: user['PRENOM']);
      TextEditingController functionController =
          TextEditingController(text: user['FONCTION']);
      TextEditingController passwordController = TextEditingController();
      return [
        DataCell(TextField(controller: codeController)),
        DataCell(TextField(controller: lastnameController)),
        DataCell(TextField(controller: firstnameController)),
        DataCell(TextField(controller: functionController)),
        DataCell(SizedBox(
            width: 150,
            child: TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                  hintText: 'Réinitialiser le mot de passe'),
            ))),
        DataCell(DropdownButton(
            value: editingSiteStatus,
            style: const TextStyle(fontSize: 14),
            items: yesNoList.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                editingSiteStatus = newValue!;
              });
            })),
        DataCell(DropdownButton(
            value: editingRoadMapStatus,
            style: const TextStyle(fontSize: 14),
            items: yesNoList.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                editingRoadMapStatus = newValue!;
              });
            })),
        DataCell(DropdownButton(
            value: editingBoxStatus,
            style: const TextStyle(fontSize: 14),
            items: yesNoList.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                editingBoxStatus = newValue!;
              });
            })),
        DataCell(DropdownButton(
            value: editingUserStatus,
            style: const TextStyle(fontSize: 14),
            items: yesNoList.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                editingUserStatus = newValue!;
              });
            })),
        DataCell(DropdownButton(
            value: executeSqlStatus,
            style: const TextStyle(fontSize: 14),
            items: yesNoList.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                executeSqlStatus = newValue!;
              });
            })),
        DataCell(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  if (lastnameController.text.isNotEmpty &&
                      firstnameController.text.isNotEmpty &&
                      functionController.text.isNotEmpty) {
                    onUpdateUser(
                        User(
                            code: codeController.text,
                            firstname: firstnameController.text,
                            lastname: lastnameController.text,
                            function: functionController.text,
                            password: passwordController.text,
                            siteEditing: editingSiteStatus == 'Oui',
                            roadMapEditing: editingRoadMapStatus == 'Oui',
                            boxEditing: editingBoxStatus == 'Oui',
                            userEditing: editingUserStatus == 'Oui',
                            sqlExecute: executeSqlStatus == 'Oui'),
                        user['CODE UTILISATEUR']);
                  }
                },
                icon: const Icon(Icons.check)),
            IconButton(
                onPressed: () {
                  setState(() {
                    editingUser = null;
                    editingSiteStatus = null;
                    editingRoadMapStatus = null;
                    editingBoxStatus = null;
                    editingUserStatus = null;
                    executeSqlStatus = null;
                  });
                },
                icon: const Icon(Icons.clear_outlined))
          ],
        ))
      ];
    } else {
      return [
        DataCell(Text(user['CODE UTILISATEUR'])),
        DataCell(Text(user['NOM'])),
        DataCell(Text(user['PRENOM'])),
        DataCell(Text(user['FONCTION'])),
        const DataCell(Text('')),
        DataCell(Text(user['EDITION SITE'] == '1' ? 'Oui' : 'Non')),
        DataCell(Text(user['EDITION FEUILLE DE ROUTE'] == '1' ? 'Oui' : 'Non')),
        DataCell(Text(user['EDITION BOITE'] == '1' ? 'Oui' : 'Non')),
        DataCell(Text(user['EDITION UTILISATEUR'] == '1' ? 'Oui' : 'Non')),
        DataCell(Text(user['EXECUTION SQL'] == '1' ? 'Oui' : 'Non')),
        DataCell(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  setState(() {
                    editingUser = user['CODE UTILISATEUR'];
                  });
                },
                icon: const Icon(Icons.edit)),
            IconButton(
                onPressed: () {
                  onDelete(user);
                },
                icon: const Icon(Icons.delete_forever))
          ],
        ))
      ];
    }
  }

  @override
  void initState() {
    getUserList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List>(
        stream: _streamController.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  DataTable(
                    sortColumnIndex: _currentSortColumn,
                    sortAscending: _isAscending,
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    columns: [
                      DataColumn(
                          label: const Text('Code\nutilisateur',
                              textAlign: TextAlign.center),
                          onSort: sorting('CODE UTILISATEUR')),
                      DataColumn(
                          label: const Text('Nom', textAlign: TextAlign.center),
                          onSort: sorting('NOM')),
                      DataColumn(
                          label:
                              const Text('Prénom', textAlign: TextAlign.center),
                          onSort: sorting('PRENOM')),
                      DataColumn(
                          label: const Text('Fonction',
                              textAlign: TextAlign.center),
                          onSort: sorting('FONCTION')),
                      const DataColumn(
                          label: Text('Mot de\npasse',
                              textAlign: TextAlign.center)),
                      DataColumn(
                          label: const Text('Edition\nde sites',
                              textAlign: TextAlign.center),
                          onSort: sorting('EDITION SITE')),
                      DataColumn(
                          label: const Text('Edition\nde feuilles de route',
                              textAlign: TextAlign.center),
                          onSort: sorting('EDITION FEUILLE DE ROUTE')),
                      DataColumn(
                          label: const Text('Edition\nde boites',
                              textAlign: TextAlign.center),
                          onSort: sorting('EDITION BOITE')),
                      DataColumn(
                          label: const Text('Edition\ndes utilisateurs',
                              textAlign: TextAlign.center),
                          onSort: sorting('EDITION UTILISATEUR')),
                      DataColumn(
                          label: const Text('Accès au\npanneau SQL',
                              textAlign: TextAlign.center),
                          onSort: sorting('EXECUTION SQL')),
                      DataColumn(
                          label: ElevatedButton(
                              onPressed: () {
                                showAddPageUser();
                              },
                              child: const Text('Ajouter un utilisateur')))
                    ],
                    rows: [
                      for (Map user in snapshot.data)
                        DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08);
                            }
                            if ((i = i + 1).isEven) {
                              return Colors.grey.withOpacity(0.2);
                            }
                            return null; // Use the default value.
                          }),
                          cells: dataCells(user),
                        )
                    ],
                  )
                ]));
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
