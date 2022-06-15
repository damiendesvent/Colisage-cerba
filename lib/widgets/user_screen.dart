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
    return const Scaffold(body: UserApp());
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

  bool isAdvancedResearch = false;
  static const searchFieldList = [
    'Code utilisateur',
    'Nom',
    'Prénom',
    'Fonction',
    'Edition site',
    'Edition feuille de route',
    'Edition boite',
    'Edition utilisateur',
    'Exécution SQL'
  ];
  String searchField = searchFieldList.first;
  String advancedSearchField = searchFieldList[1];
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  static const numberDisplayedList = [10, 25, 50, 100];
  int numberDisplayed = 25;

  bool showDeleteUser = false;

  Future getUserList() async {
    String phpUriUserList = Env.urlPrefix + 'Users/list_user.php';
    http.Response res = await http.post(Uri.parse(phpUriUserList), body: {
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      "delete": showDeleteUser ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        users = items;
      });
      _streamController.add(items);
    }
  }

  Future searchUser() async {
    String phpUriUserSearch = Env.urlPrefix + 'Users/search_user.php';
    http.Response res = await http.post(Uri.parse(phpUriUserSearch), body: {
      "field": searchField.toUpperCase(),
      "advancedField": advancedSearchField.toUpperCase(),
      "searchText": _searchTextController.text,
      "advancedSearchText":
          isAdvancedResearch ? _advancedSearchTextController.text : '',
      "limit": numberDisplayedList.last.toString(),
      "order": searchFieldList[_currentSortColumn].toUpperCase(),
      "isAscending": _isAscending.toString(),
      "delete": showDeleteUser ? 'true' : 'false'
    });
    if (res.body.isNotEmpty) {
      List itemsSearch = json.decode(res.body);
      _streamController.add(itemsSearch);
    }
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
                })),
        Expanded(
            child: TextFormField(
          controller: _advancedSearchTextController,
          decoration:
              const InputDecoration(hintText: 'Deuxième champ de recherche'),
          onFieldSubmitted: (e) {
            searchUser();
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
        searchUser();
      });
    });
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

  void onRestore(Map<dynamic, dynamic> user) {
    String phpUriUserlDelete = Env.urlPrefix + 'Users/delete_user.php';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text(
                'Confirmation',
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Êtes-vous sûr de vouloir restaurer \nl\'utilisateur ' +
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
                        "cancel": 'true'
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
                                    ' a bien été restauré.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
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
                                          obscureText: true,
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

  void showResetPasswordPage(Map<dynamic, dynamic> user) {
    const TextStyle textStyle = TextStyle(fontSize: 16);
    TextEditingController passwordController = TextEditingController();
    TextEditingController repeatPasswordController = TextEditingController();
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
                      height: 250,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Réinitialisation du mot de passe de ' +
                                  user['PRENOM'] +
                                  ' ' +
                                  user['NOM'],
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
                                    child: Text('Mot de passe* :   ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        width: 60,
                                        child: TextField(
                                          obscureText: true,
                                          controller: passwordController,
                                          decoration: InputDecoration(
                                              hintText: 'Nouveau mot de passe',
                                              errorText: submited &&
                                                      passwordController
                                                              .text.length <
                                                          4
                                                  ? 'Veuillez entrer au moins 4 caractères'
                                                  : null),
                                        )))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Répêter le mot de passe* :   ',
                                        style: textStyle)),
                                TableCell(
                                    child: SizedBox(
                                        width: 60,
                                        child: TextField(
                                          obscureText: true,
                                          controller: repeatPasswordController,
                                          decoration: InputDecoration(
                                              hintText:
                                                  'Répêter le nouveau mot de passe',
                                              errorText: submited &&
                                                      passwordController.text !=
                                                          repeatPasswordController
                                                              .text
                                                  ? 'Mots de passe non identiques'
                                                  : null),
                                        )))
                              ])
                            ]),
                        Center(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30),
                                child: SizedBox(
                                    width: 105,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          submited = true;
                                        });
                                        if (passwordController.text.length >
                                                3 &&
                                            passwordController.text ==
                                                repeatPasswordController.text) {
                                          onResetPassword(
                                              user['CODE UTILISATEUR'],
                                              passwordController.text);
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

  void onResetPassword(String code, String password) {
    String phpUriResetPasswordUser =
        Env.urlPrefix + 'Users/reset_password_user.php';
    http.post(Uri.parse(phpUriResetPasswordUser),
        body: {"code": code, "password": password});
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Le mot de passe a bien été réinitialisé')));
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
      return [
        DataCell(TextField(controller: codeController)),
        DataCell(TextField(controller: lastnameController)),
        DataCell(TextField(controller: firstnameController)),
        DataCell(TextField(controller: functionController)),
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
                            password: '',
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
              icon: const Icon(Icons.edit),
              tooltip: 'Editer',
            ),
            IconButton(
              onPressed: () {
                showResetPasswordPage(user);
              },
              icon: const Icon(Icons.lock_person),
              tooltip: 'Réinitialiser le mot de passe',
            ),
            if (!showDeleteUser)
              IconButton(
                  onPressed: () {
                    onDelete(user);
                  },
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Supprimer'),
            if (showDeleteUser)
              IconButton(
                  onPressed: () {
                    onRestore(user);
                  },
                  icon: const Icon(Icons.settings_backup_restore),
                  tooltip: 'Restaurer')
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
                            searchUser();
                          },
                        )),
                        IconButton(
                            onPressed: () {
                              searchUser();
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
                                });
                              },
                              icon: const Icon(Icons.search_off_outlined),
                              tooltip: 'Recherche simple'),
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
                body: Row(
                  children: [
                    Expanded(
                        child: SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                          DataTable(
                            headingRowHeight: 80,
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
                                  label: const Text('Nom',
                                      textAlign: TextAlign.center),
                                  onSort: sorting('NOM')),
                              DataColumn(
                                  label: const Text('Prénom',
                                      textAlign: TextAlign.center),
                                  onSort: sorting('PRENOM')),
                              DataColumn(
                                  label: const Text('Fonction',
                                      textAlign: TextAlign.center),
                                  onSort: sorting('FONCTION')),
                              DataColumn(
                                  label: const Text('Edition\nde sites',
                                      textAlign: TextAlign.center),
                                  onSort: sorting('EDITION SITE')),
                              DataColumn(
                                  label: const Text(
                                      'Edition\nde feuilles de route',
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
                                  label: Column(children: [
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                    child: ElevatedButton(
                                        onPressed: () {
                                          showAddPageUser();
                                        },
                                        child: const Text(
                                            'Ajouter un utilisateur'))),
                                const Spacer(),
                                Row(children: [
                                  const Text('Utilisateur supprimées :'),
                                  Switch(
                                      value: showDeleteUser,
                                      onChanged: (newValue) {
                                        setState(() {
                                          showDeleteUser = newValue;
                                        });
                                        getUserList();
                                      })
                                ])
                              ]))
                            ],
                            rows: [
                              for (Map user in snapshot.data)
                                DataRow(
                                  color:
                                      MaterialStateProperty.resolveWith<Color?>(
                                          (Set<MaterialState> states) {
                                    if (states
                                        .contains(MaterialState.selected)) {
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
                        ])))
                  ],
                ));
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
