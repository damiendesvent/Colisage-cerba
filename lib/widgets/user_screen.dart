import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'dart:async';
import 'dart:convert';
import '../variables/globals.dart' as globals;

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

class _UserState extends State<UserApp> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => globals.shouldKeepAlive;
  final StreamController<List> _streamController = StreamController<List>();
  int i = 0;
  bool _isAscending = true;
  int _currentSortColumn = 0;
  late List users;
  String? siteRights;
  String? roadMapRights;
  String? boxRights;
  String? userRights;
  String? executeSqlStatus;
  String? settingsAccessStatus;
  final List<String> yesNoList = ['Oui', 'Non'];
  final List<String> accessRightsList = ['Acun', 'Affichage', 'Gestion'];
  final List<String> userRightsList = [
    'Acun',
    'Affichage',
    'Gestion',
    'Super Gestion'
  ];
  bool isAdvancedResearch = false;
  static const searchFieldList = [
    'Code utilisateur',
    'Nom',
    'Prénom',
    'Fonction',
    'Droits site',
    'Droits feuille de route',
    'Droits boîte',
    'Droits utilisateur',
    'Accès paramètres',
    'Exécution SQL'
  ];
  String searchField = searchFieldList.first;
  String advancedSearchField = searchFieldList[1];
  final _searchTextController = TextEditingController();
  final _advancedSearchTextController = TextEditingController();
  static const numberDisplayedList = [10, 25, 50, 100];
  int numberDisplayed = 25;
  final ScrollController _scrollController = ScrollController();
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
        Padding(
            padding: const EdgeInsets.only(left: 10),
            child: DropdownButtonHideUnderline(
                child: DropdownButton(
                    style: defaultTextStyle,
                    value: advancedSearchField,
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
        Expanded(
            child: TextFormField(
          style: defaultTextStyle,
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

  void onUpdateUser(User myUser) async {
    String phpUriUserUpdate = Env.urlPrefix + 'Users/update_user.php';
    await http.post(Uri.parse(phpUriUserUpdate), body: {
      "code": myUser.code,
      "firstname": myUser.firstname,
      "lastname": myUser.lastname,
      "function": myUser.function,
      "siteRights": myUser.siteRights.toString(),
      "roadMapRights": myUser.roadMapRights.toString(),
      "boxRights": myUser.boxRights.toString(),
      "userRights": myUser.userRights.toString(),
      "sqlExecute": myUser.sqlExecute ? 'true' : 'false',
      "settingsAccess": myUser.settingsRights ? 'true' : 'false',
    });
    setState(() {
      siteRights = null;
      roadMapRights = null;
      boxRights = null;
      userRights = null;
    });
    Navigator.of(context).pop();
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => searchUser());
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  void onDelete(Map<dynamic, dynamic> user) {
    String phpUriUserlDelete = Env.urlPrefix + 'Users/delete_user.php';
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
                'Êtes-vous sûr de vouloir supprimer \nl\'utilisateur ' +
                    user['CODE UTILISATEUR'] +
                    ' : ' +
                    user['PRENOM'] +
                    ' ' +
                    user['NOM'] +
                    ' ?',
                textAlign: TextAlign.center,
                style: defaultTextStyle,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriUserlDelete), body: {
                        "searchCode": user['CODE UTILISATEUR'],
                        "cancel": 'false'
                      });
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => searchUser());
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
                            Future.delayed(
                                Duration(milliseconds: globals.milisecondWait),
                                () => searchUser());
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
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25))),
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
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => searchUser());
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
      "siteRights": user.siteRights.toString(),
      "roadMapRights": user.roadMapRights.toString(),
      "boxRights": user.boxRights.toString(),
      "userRights": user.userRights.toString(),
      "sqlExecute": user.sqlExecute ? 'true' : 'false',
      "settingsAccess": user.settingsRights ? 'true' : 'false',
      "password": user.password
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      Text('L\'utilisateur ' + user.code + ' a bien été ajouté'),
    ));
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getUserList());
  }

  Future<bool> isUser(String code) async {
    String phpUriCountUser = Env.urlPrefix + 'Users/count_user.php';
    http.Response res =
        await http.post(Uri.parse(phpUriCountUser), body: {"code": code});
    if (res.body.isNotEmpty && res.body != '{"COUNT(*)":"0"}') {
      return true;
    }
    return false;
  }

  void showAddPageUser() {
    TextEditingController codeController = TextEditingController();
    TextEditingController firstnameController = TextEditingController();
    TextEditingController lastnameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController functionController = TextEditingController();
    bool submited = false;
    String codeValueCheck = 'Veuillez entrer une valeur';
    bool codeExisting = true;
    String siteRights = accessRightsList[0];
    String roadMapRights = accessRightsList[0];
    String boxRights = accessRightsList[0];
    String userRights = userRightsList[0];
    String executeSqlStatus = yesNoList[1];
    String settingsAccessStatus = yesNoList[1];

    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding: const EdgeInsets.all(20),
                elevation: 8,
                child: SingleChildScrollView(
                    child: SizedBox(
                        width: 550,
                        height: globals.user.userRights > 2 ? 600 : 500,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
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
                                  child:
                                      Text('Code* : ', style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            textInputAction:
                                                TextInputAction.next,
                                            controller: codeController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  10),
                                              UpperCaseTextFormatter(),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
                                              errorText: (codeController
                                                              .text.isEmpty ||
                                                          codeExisting) &&
                                                      submited
                                                  ? codeValueCheck
                                                  : null,
                                            ))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                  child: Text('Prénom* : ',
                                      style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            textInputAction:
                                                TextInputAction.next,
                                            controller: firstnameController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  20),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
                                              errorText: firstnameController
                                                          .text.isEmpty &&
                                                      submited
                                                  ? 'Veuillez entrer une valeur'
                                                  : null,
                                            ))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                  child:
                                      Text('Nom* : ', style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            textInputAction:
                                                TextInputAction.next,
                                            controller: lastnameController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  20),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
                                              errorText: lastnameController
                                                          .text.isEmpty &&
                                                      submited
                                                  ? 'Veuillez entrer une valeur'
                                                  : null,
                                            ))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Fonction* : ',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            textInputAction:
                                                TextInputAction.next,
                                            controller: functionController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  35),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
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
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            obscureText: true,
                                            controller: passwordController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  24),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
                                              errorText: passwordController
                                                              .text.length <
                                                          4 &&
                                                      submited
                                                  ? 'Veuillez entrer au moins 4 caractères'
                                                  : null,
                                            ))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits sites :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: Center(
                                        child: SizedBox(
                                            height: 40,
                                            child: DropdownButtonHideUnderline(
                                                child: DropdownButton(
                                                    value: siteRights,
                                                    style: defaultTextStyle,
                                                    items: accessRightsList
                                                        .map((value) {
                                                      return DropdownMenuItem(
                                                          value: value,
                                                          child: Text(value));
                                                    }).toList(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        siteRights = newValue!;
                                                      });
                                                    })))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits feuilles de route :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: Center(
                                        child: SizedBox(
                                            height: 40,
                                            child: DropdownButtonHideUnderline(
                                                child: DropdownButton(
                                                    value: roadMapRights,
                                                    style: defaultTextStyle,
                                                    items: accessRightsList
                                                        .map((value) {
                                                      return DropdownMenuItem(
                                                          value: value,
                                                          child: Text(value));
                                                    }).toList(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        roadMapRights =
                                                            newValue!;
                                                      });
                                                    })))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits boîtes :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: Center(
                                        child: SizedBox(
                                            height: 40,
                                            child: DropdownButtonHideUnderline(
                                                child: DropdownButton(
                                                    value: boxRights,
                                                    style: defaultTextStyle,
                                                    items: accessRightsList
                                                        .map((value) {
                                                      return DropdownMenuItem(
                                                          value: value,
                                                          child: Text(value));
                                                    }).toList(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        boxRights = newValue!;
                                                      });
                                                    })))))
                              ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Droits utilisateurs :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: Center(
                                          child: SizedBox(
                                              height: 40,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                      child: DropdownButton(
                                                          value: userRights,
                                                          style:
                                                              defaultTextStyle,
                                                          items: userRightsList
                                                              .map((value) {
                                                            return DropdownMenuItem(
                                                                value: value,
                                                                child: Text(
                                                                    value));
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              userRights =
                                                                  newValue!;
                                                            });
                                                          })))))
                                ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Accès au panneau SQL :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: Center(
                                          child: SizedBox(
                                              height: 40,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                      child: DropdownButton(
                                                          value:
                                                              executeSqlStatus,
                                                          style:
                                                              defaultTextStyle,
                                                          items: yesNoList
                                                              .map((value) {
                                                            return DropdownMenuItem(
                                                                value: value,
                                                                child: Text(
                                                                    value));
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              executeSqlStatus =
                                                                  newValue!;
                                                            });
                                                          })))))
                                ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Accès aux paramètres :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: Center(
                                          child: SizedBox(
                                              height: 40,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                      child: DropdownButton(
                                                          value:
                                                              settingsAccessStatus,
                                                          style:
                                                              defaultTextStyle,
                                                          items: yesNoList
                                                              .map((value) {
                                                            return DropdownMenuItem(
                                                                value: value,
                                                                child: Text(
                                                                    value));
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              settingsAccessStatus =
                                                                  newValue!;
                                                            });
                                                          })))))
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
                                            isUser(codeController.text)
                                                .then((value) => setState(() {
                                                      codeExisting = value;
                                                      codeValueCheck = codeExisting
                                                          ? 'Utilisateur existant'
                                                          : 'Veuillez entrer une valeur';
                                                      if (!codeExisting &&
                                                          codeController.text
                                                              .isNotEmpty &&
                                                          firstnameController
                                                              .text
                                                              .isNotEmpty &&
                                                          lastnameController
                                                              .text
                                                              .isNotEmpty &&
                                                          passwordController
                                                                  .text.length >
                                                              3 &&
                                                          functionController
                                                              .text
                                                              .isNotEmpty) {
                                                        onAddUser(User(
                                                            code: codeController
                                                                .text,
                                                            firstname:
                                                                firstnameController
                                                                    .text,
                                                            lastname:
                                                                lastnameController
                                                                    .text,
                                                            function:
                                                                functionController
                                                                    .text,
                                                            password:
                                                                passwordController
                                                                    .text,
                                                            siteRights:
                                                                accessRightsList.indexOf(
                                                                    siteRights),
                                                            roadMapRights:
                                                                accessRightsList
                                                                    .indexOf(
                                                                        roadMapRights),
                                                            boxRights:
                                                                accessRightsList
                                                                    .indexOf(
                                                                        boxRights),
                                                            userRights:
                                                                accessRightsList
                                                                    .indexOf(
                                                                        userRights),
                                                            sqlExecute:
                                                                executeSqlStatus ==
                                                                    'Oui',
                                                            settingsRights:
                                                                settingsAccessStatus ==
                                                                    'Oui'));
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
                                      color: Colors.grey.shade700,
                                      fontSize: 12)))
                        ]))));
          });
        });
  }

  void showEditPageUser(User user) {
    TextEditingController firstnameController =
        TextEditingController(text: user.firstname);
    TextEditingController lastnameController =
        TextEditingController(text: user.lastname);
    TextEditingController functionController =
        TextEditingController(text: user.function);
    bool submited = false;
    String siteRights = accessRightsList[user.siteRights];
    String roadMapRights = accessRightsList[user.roadMapRights];
    String boxRights = accessRightsList[user.boxRights];
    String userRights = userRightsList[user.userRights];
    String executeSqlStatus = yesNoList[user.sqlExecute ? 0 : 1];
    String settingsAccessStatus = yesNoList[user.settingsRights ? 0 : 1];

    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding: const EdgeInsets.all(20),
                elevation: 8,
                child: SingleChildScrollView(
                    child: SizedBox(
                        width: 550,
                        height: globals.user.userRights > 2 ? 600 : 500,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Edition de l\'utilisateur ' + user.code,
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
                                  child: Text('Prénom* : ',
                                      style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            textInputAction:
                                                TextInputAction.next,
                                            controller: firstnameController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  20),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
                                              errorText: firstnameController
                                                          .text.isEmpty &&
                                                      submited
                                                  ? 'Veuillez entrer une valeur'
                                                  : null,
                                            ))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                  child:
                                      Text('Nom* : ', style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            textInputAction:
                                                TextInputAction.next,
                                            controller: lastnameController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  20),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
                                              errorText: lastnameController
                                                          .text.isEmpty &&
                                                      submited
                                                  ? 'Veuillez entrer une valeur'
                                                  : null,
                                            ))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Fonction* : ',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: TextField(
                                            style: defaultTextStyle,
                                            textAlignVertical:
                                                TextAlignVertical.bottom,
                                            textInputAction:
                                                TextInputAction.next,
                                            controller: functionController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                  35),
                                            ],
                                            decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
                                              errorText: functionController
                                                          .text.isEmpty &&
                                                      submited
                                                  ? 'Veuillez entrer une valeur'
                                                  : null,
                                            ))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits sites :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: Center(
                                        child: SizedBox(
                                            height: 45,
                                            child: DropdownButtonHideUnderline(
                                                child: DropdownButton(
                                                    value: siteRights,
                                                    style: defaultTextStyle,
                                                    items: accessRightsList
                                                        .map((value) {
                                                      return DropdownMenuItem(
                                                          value: value,
                                                          child: Text(value));
                                                    }).toList(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        siteRights = newValue!;
                                                      });
                                                    })))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits feuilles de route :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: Center(
                                        child: SizedBox(
                                            height: 45,
                                            child: DropdownButtonHideUnderline(
                                                child: DropdownButton(
                                                    value: roadMapRights,
                                                    style: defaultTextStyle,
                                                    items: accessRightsList
                                                        .map((value) {
                                                      return DropdownMenuItem(
                                                          value: value,
                                                          child: Text(value));
                                                    }).toList(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        roadMapRights =
                                                            newValue!;
                                                      });
                                                    })))))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits boîtes :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: Center(
                                        child: SizedBox(
                                            height: 45,
                                            child: DropdownButtonHideUnderline(
                                                child: DropdownButton(
                                                    value: boxRights,
                                                    style: defaultTextStyle,
                                                    items: accessRightsList
                                                        .map((value) {
                                                      return DropdownMenuItem(
                                                          value: value,
                                                          child: Text(value));
                                                    }).toList(),
                                                    onChanged:
                                                        (String? newValue) {
                                                      setState(() {
                                                        boxRights = newValue!;
                                                      });
                                                    })))))
                              ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Droits utilisateurs :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: Center(
                                          child: SizedBox(
                                              height: 45,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                      child: DropdownButton(
                                                          value: userRights,
                                                          style:
                                                              defaultTextStyle,
                                                          items: userRightsList
                                                              .map((value) {
                                                            return DropdownMenuItem(
                                                                value: value,
                                                                child: Text(
                                                                    value));
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              userRights =
                                                                  newValue!;
                                                            });
                                                          })))))
                                ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Accès au panneau SQL :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: Center(
                                          child: SizedBox(
                                              height: 45,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                      child: DropdownButton(
                                                          value:
                                                              executeSqlStatus,
                                                          style:
                                                              defaultTextStyle,
                                                          items: yesNoList
                                                              .map((value) {
                                                            return DropdownMenuItem(
                                                                value: value,
                                                                child: Text(
                                                                    value));
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              executeSqlStatus =
                                                                  newValue!;
                                                            });
                                                          })))))
                                ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Accès aux paramètres :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: Center(
                                          child: SizedBox(
                                              height: 45,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                      child: DropdownButton(
                                                          value:
                                                              settingsAccessStatus,
                                                          style:
                                                              defaultTextStyle,
                                                          items: yesNoList
                                                              .map((value) {
                                                            return DropdownMenuItem(
                                                                value: value,
                                                                child: Text(
                                                                    value));
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setState(() {
                                                              settingsAccessStatus =
                                                                  newValue!;
                                                            });
                                                          })))))
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
                                            });
                                            setState(() {
                                              if (firstnameController
                                                      .text.isNotEmpty &&
                                                  lastnameController
                                                      .text.isNotEmpty &&
                                                  functionController
                                                      .text.isNotEmpty) {
                                                onUpdateUser(User(
                                                    code: user.code,
                                                    firstname:
                                                        firstnameController
                                                            .text,
                                                    lastname:
                                                        lastnameController.text,
                                                    function:
                                                        functionController.text,
                                                    password: '',
                                                    siteRights: accessRightsList
                                                        .indexOf(siteRights),
                                                    roadMapRights:
                                                        accessRightsList
                                                            .indexOf(
                                                                roadMapRights),
                                                    boxRights: accessRightsList
                                                        .indexOf(boxRights),
                                                    userRights: userRightsList
                                                        .indexOf(userRights),
                                                    sqlExecute:
                                                        executeSqlStatus ==
                                                            'Oui',
                                                    settingsRights:
                                                        settingsAccessStatus ==
                                                            'Oui'));
                                              }
                                            });
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
                                      color: Colors.grey.shade700,
                                      fontSize: 12)))
                        ]))));
          });
        });
  }

  void showDetailsPageUser(User user) {
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                insetPadding: const EdgeInsets.all(20),
                elevation: 8,
                child: SingleChildScrollView(
                    child: SizedBox(
                        width: 550,
                        height: globals.user.userRights > 2 ? 600 : 500,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Détails de ' +
                                    user.firstname +
                                    ' ' +
                                    user.lastname,
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey.shade700),
                              )),
                          const Spacer(),
                          Table(
                            defaultColumnWidth: const FractionColumnWidth(0.4),
                            children: [
                              TableRow(children: [
                                const TableCell(
                                  child:
                                      Text('Code : ', style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(user.code,
                                            style: defaultTextStyle)))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                  child: Text('Prénom : ',
                                      style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(user.firstname,
                                            style: defaultTextStyle)))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                  child:
                                      Text('Nom : ', style: defaultTextStyle),
                                ),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(user.lastname,
                                            style: defaultTextStyle)))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Fonction : ',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(user.function,
                                            style: defaultTextStyle)))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits sites :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(
                                            accessRightsList[user.siteRights],
                                            style: defaultTextStyle)))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits feuilles de route :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(
                                            accessRightsList[
                                                user.roadMapRights],
                                            style: defaultTextStyle)))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits boîtes :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(
                                            accessRightsList[user.boxRights],
                                            style: defaultTextStyle)))
                              ]),
                              TableRow(children: [
                                const TableCell(
                                    child: Text('Droits utilisateurs :',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        height: 45,
                                        child: SelectableText(
                                            userRightsList[user.userRights],
                                            style: defaultTextStyle)))
                              ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Accès au panneau SQL :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 45,
                                          child: SelectableText(
                                              yesNoList[
                                                  user.sqlExecute ? 0 : 1],
                                              style: defaultTextStyle)))
                                ]),
                              if (globals.user.userRights > 2)
                                TableRow(children: [
                                  const TableCell(
                                      child: Text('Accès aux paramètres :',
                                          style: defaultTextStyle)),
                                  TableCell(
                                      child: SizedBox(
                                          height: 45,
                                          child: SelectableText(
                                              yesNoList[
                                                  user.sqlExecute ? 0 : 1],
                                              style: defaultTextStyle)))
                                ]),
                            ],
                          ),
                          Center(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
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
                                    ),
                                  ))),
                          const Spacer(),
                        ]))));
          });
        });
  }

  void showResetPasswordPage(Map<dynamic, dynamic> user) {
    const TextStyle defaultTextStyle = TextStyle(fontSize: 16);
    TextEditingController passwordController = TextEditingController();
    TextEditingController repeatPasswordController = TextEditingController();
    bool submited = false;

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
                                    child: Text('Nouveau mot de passe* :   ',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        width: 50,
                                        child: TextField(
                                          style: defaultTextStyle,
                                          textAlignVertical:
                                              TextAlignVertical.bottom,
                                          obscureText: true,
                                          controller: passwordController,
                                          decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
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
                                    child: Text(
                                        'Répêter le nouveau mot de passe* :   ',
                                        style: defaultTextStyle)),
                                TableCell(
                                    child: SizedBox(
                                        width: 50,
                                        child: TextField(
                                          style: defaultTextStyle,
                                          textAlignVertical:
                                              TextAlignVertical.bottom,
                                          obscureText: true,
                                          controller: repeatPasswordController,
                                          decoration: InputDecoration(
                                              errorStyle: TextStyle(
                                                  fontSize: defaultTextStyle
                                                          .fontSize! -
                                                      4,
                                                  height: 0.3),
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
                                    width: 231,
                                    child: Row(children: [
                                      ElevatedButton(
                                          style: myButtonStyle,
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Row(children: const [
                                            Icon(Icons.clear),
                                            Text('Annuler')
                                          ])),
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10)),
                                      ElevatedButton(
                                        style: myButtonStyle,
                                        onPressed: () {
                                          setState(() {
                                            submited = true;
                                          });
                                          if (passwordController.text.length >
                                                  3 &&
                                              passwordController.text ==
                                                  repeatPasswordController
                                                      .text) {
                                            onResetPassword(
                                                user['CODE UTILISATEUR'],
                                                passwordController.text);
                                          }
                                        },
                                        child: Row(children: const [
                                          Icon(Icons.check),
                                          Text(' Valider')
                                        ]),
                                      )
                                    ])))),
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
    return [
      DataCell(
          SelectableText(user['CODE UTILISATEUR'], style: defaultTextStyle)),
      DataCell(SelectableText(user['NOM'], style: defaultTextStyle)),
      DataCell(SelectableText(user['PRENOM'], style: defaultTextStyle)),
      DataCell(SelectableText(user['FONCTION'], style: defaultTextStyle)),
      if (globals.user.userRights > 1)
        DataCell(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                showEditPageUser(User.fromSnapshot(user));
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
                    user['DROITS UTILISATEUR'] != '3' ||
                            globals.user.userRights > 2
                        ? onDelete(user)
                        : null;
                  },
                  icon: const Icon(Icons.delete_forever),
                  tooltip: user['DROITS UTILISATEUR'] != '3' ||
                          globals.user.userRights > 2
                      ? 'Supprimer'
                      : 'Vous n\'avez pas les droits pour supprimer cet utilisateur'),
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

  @override
  void initState() {
    super.initState();
    getUserList();
  }

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
                        Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                    value: searchField,
                                    style: defaultTextStyle,
                                    items:
                                        searchFieldList.map((searchFieldList) {
                                      return DropdownMenuItem(
                                          value: searchFieldList,
                                          child:
                                              Text(searchFieldList.toString()));
                                    }).toList(),
                                    onChanged: (String? newsearchField) {
                                      setState(() {
                                        searchField = newsearchField!;
                                      });
                                    }))),
                        Expanded(
                            child: TextFormField(
                          style: defaultTextStyle,
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
                        if (globals.user.userRights > 1)
                          ElevatedButton(
                              style: myButtonStyle,
                              onPressed: () {
                                showAddPageUser();
                              },
                              child: const Text('Ajouter un utilisateur')),
                        if (globals.shouldDisplaySyncButton)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                getUserList();
                              });
                            },
                            icon: const Icon(Icons.sync),
                            tooltip: 'Actualiser l\'onglet',
                          ),
                        const Spacer(),
                        const Text('Nombre de lignes affichées : ',
                            style: defaultTextStyle),
                        DropdownButton(
                            style: defaultTextStyle,
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
                            'Aucun utilisateur ne correspond à votre recherche.'))
                    : Row(
                        children: [
                          Expanded(
                              child: Scrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  child: SingleChildScrollView(
                                      controller: _scrollController,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            DataTable(
                                              showCheckboxColumn: false,
                                              headingRowColor:
                                                  MaterialStateProperty
                                                      .resolveWith<Color?>((Set<
                                                              MaterialState>
                                                          states) {
                                                return Colors.grey
                                                    .withOpacity(0.2);
                                              }),
                                              headingRowHeight: 50,
                                              sortColumnIndex:
                                                  _currentSortColumn,
                                              sortAscending: _isAscending,
                                              headingTextStyle: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                              columns: [
                                                DataColumn(
                                                    label: const Text(
                                                        'Code\nutilisateur',
                                                        textAlign:
                                                            TextAlign.center),
                                                    onSort: sorting(
                                                        'CODE UTILISATEUR')),
                                                DataColumn(
                                                    label: const Text('Nom',
                                                        textAlign:
                                                            TextAlign.center),
                                                    onSort: sorting('NOM')),
                                                DataColumn(
                                                    label: const Text('Prénom',
                                                        textAlign:
                                                            TextAlign.center),
                                                    onSort: sorting('PRENOM')),
                                                DataColumn(
                                                    label: const Text(
                                                        'Fonction',
                                                        textAlign:
                                                            TextAlign.center),
                                                    onSort:
                                                        sorting('FONCTION')),
                                                if (globals.user.userRights > 1)
                                                  DataColumn(
                                                      label: Row(children: [
                                                    const Text(
                                                        'Utilisateurs\nsupprimées :'),
                                                    Switch(
                                                        value: showDeleteUser,
                                                        onChanged: (newValue) {
                                                          setState(() {
                                                            showDeleteUser =
                                                                newValue;
                                                          });
                                                          getUserList();
                                                        })
                                                  ]))
                                              ],
                                              rows: [
                                                for (Map user in snapshot.data)
                                                  DataRow(
                                                    onSelectChanged: (_) =>
                                                        showDetailsPageUser(
                                                            User.fromSnapshot(
                                                                user)),
                                                    color: MaterialStateProperty
                                                        .resolveWith<Color?>(
                                                            (Set<MaterialState>
                                                                states) {
                                                      if (states.contains(
                                                          MaterialState
                                                              .selected)) {
                                                        return Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.08);
                                                      }
                                                      if ((i = i + 1).isEven) {
                                                        return backgroundColor;
                                                      }
                                                      return null; // Use the default value.
                                                    }),
                                                    cells: dataCells(user),
                                                  )
                                              ],
                                            )
                                          ]))))
                        ],
                      ));
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}
