import 'package:flutter/material.dart';
import 'package:colisage_cerba/variables/env.sample.dart';
import 'package:colisage_cerba/variables/globals.dart' as globals;
import 'package:colisage_cerba/variables/styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:searchfield/searchfield.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Setting());
  }
}

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  List constantsList = [];
  List ipList = [];
  List sites = [];
  String? editedConstant;
  String? editedIP;
  String value = '';

  @override
  void initState() {
    getConstantsList();
    getIpTable();
    getSiteList();
    super.initState();
  }

  void getConstantsList() async {
    String phpUriListConstants = Env.urlPrefix + 'Constants/list_constants.php';
    http.Response res = await http.get(Uri.parse(phpUriListConstants));
    if (res.body.isNotEmpty) {
      setState(() {
        constantsList = json.decode(res.body);
      });
    }
  }

  void getIpTable() async {
    String phpUriListIp = Env.urlPrefix + 'IPs/list_IPs.php';
    http.Response res = await http.get(Uri.parse(phpUriListIp));
    if (res.body.isNotEmpty) {
      setState(() {
        ipList = json.decode(res.body);
      });
    }
  }

  void applyConstants() async {
    String phpUriListConstants = Env.urlPrefix + 'Constants/list_constants.php';
    http.Response res = await http.get(Uri.parse(phpUriListConstants));
    if (res.body.isNotEmpty) {
      List items = json.decode(res.body);
      setState(() {
        globals.shouldDisplaySyncButton = items[0]['Valeur'] == 'Oui';
        globals.pdaTrackInDirectory = items[1]['Valeur'];
        globals.milisecondWait = int.parse(items[2]['Valeur']);
        globals.shouldKeepAlive = items[3]['Valeur'] == 'Oui';
        globals.inactivityTimeOut = int.parse(items[4]['Valeur']);
      });
    }
  }

  void onUpdateConstant(String name) {
    String phpUriUpdateConstant =
        Env.urlPrefix + 'Constants/update_constant.php';
    http.post(Uri.parse(phpUriUpdateConstant),
        body: {'name': name, 'newValue': value});
    Future.delayed(Duration(milliseconds: globals.milisecondWait),
        () => getConstantsList());
    setState(() {
      editedConstant = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(Text(
      'Le paramètre ' + name + ' a bien été modifié',
      textAlign: TextAlign.center,
    )));
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => applyConstants());
  }

  void onUpdateIp(String code, String prefix, String site) {
    String phpUriUpdateIp = Env.urlPrefix + 'IPs/update_IP.php';
    http.post(Uri.parse(phpUriUpdateIp),
        body: {'code': code, 'prefix': prefix, 'site': site});
    Future.delayed(Duration(milliseconds: globals.milisecondWait), () {
      getIpTable();
      Navigator.of(context).pop();
    });
  }

  void onDeleteIp(String code, String prefix) {
    String phpUriDeleteIp = Env.urlPrefix + 'IPs/delete_IP.php';
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Confirmation'),
              content: Text(
                  'Êtes-vous sûr de vouloir supprimer\nl\'assiociation du préfixe ' +
                      prefix +
                      ' ?'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Non')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      http.post(Uri.parse(phpUriDeleteIp),
                          body: {'code': code});
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
                          Text('L\'association liée au préfixe ' +
                              prefix +
                              ' a bien été supprimée.')));
                      Future.delayed(
                          Duration(milliseconds: globals.milisecondWait),
                          () => getIpTable());
                    },
                    child: const Text('Oui'))
              ],
            ));
  }

  void onAddIp(String prefix, String site) {
    String phpUriAddIp = Env.urlPrefix + 'IPs/add_IP.php';
    http.post(Uri.parse(phpUriAddIp), body: {'prefix': prefix, 'site': site});
    Navigator.of(context).pop();
    Future.delayed(
        Duration(milliseconds: globals.milisecondWait), () => getIpTable());
  }

  void showIpTable() {
    String? prefixIp;
    String? site;
    TextEditingController siteController = TextEditingController();
    showDialog(
        barrierColor: myBarrierColor,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 100),
                elevation: 8,
                child: SizedBox(
                    width: 600,
                    height: 600,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 50),
                          child: Text(
                            'Table de correspondance entre IP et sites',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade700),
                          )),
                      Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          defaultColumnWidth: const FractionColumnWidth(0.4),
                          columnWidths: const {
                            2: FixedColumnWidth(80)
                          },
                          children: [
                            TableRow(children: [
                              const TableCell(
                                  child: Padding(
                                      padding: EdgeInsets.only(bottom: 20),
                                      child: Text('Préfixe IP',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)))),
                              const TableCell(
                                  child: Padding(
                                      padding: EdgeInsets.only(bottom: 20),
                                      child: Text('Site',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)))),
                              TableCell(
                                  child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              ipList.add({
                                                'CODE': '0',
                                                'PREFIXE IP': '',
                                                'LIBELLE SITE': ''
                                              });
                                              prefixIp = '';
                                              editedIP = '0';
                                            });
                                          },
                                          icon: const Icon(Icons.plus_one))))
                            ]),
                            for (Map ip in ipList)
                              TableRow(children: [
                                TableCell(
                                    child: editedIP == ip['CODE']
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                right: 20),
                                            child: TextFormField(
                                              style: defaultTextStyle,
                                              autofocus: true,
                                              initialValue: ip['PREFIXE IP'],
                                              onChanged: (newValue) {
                                                setState(() {
                                                  prefixIp = newValue;
                                                });
                                              },
                                            ))
                                        : SelectableText(ip['PREFIXE IP'])),
                                TableCell(
                                    child: editedIP == ip['CODE']
                                        ? SearchField(
                                            //searchStyle: textStyle,
                                            textInputAction:
                                                TextInputAction.none,
                                            initialValue: site == null
                                                ? null
                                                : SearchFieldListItem<String>(
                                                    site!),
                                            validator: (x) {
                                              if (!sites.contains(x) ||
                                                  x!.isEmpty) {
                                                return 'Veuillez entrer un site valide';
                                              }
                                              return null;
                                            },
                                            controller: siteController,
                                            emptyWidget: Text(
                                                'Aucun site trouvé',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.red.shade900,
                                                    fontSize: 15)),
                                            suggestions: sites
                                                .map(
                                                  (e) => SearchFieldListItem<
                                                      String>(
                                                    e,
                                                    item: e,
                                                  ),
                                                )
                                                .toList(),
                                          )
                                        : SelectableText(ip['LIBELLE SITE'])),
                                TableCell(
                                    child: editedIP == ip['CODE']
                                        ? Row(children: [
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    prefixIp = null;
                                                    site = null;
                                                    editedIP = null;
                                                    if (ip['CODE'] == '0') {
                                                      ipList.removeLast();
                                                    }
                                                  });
                                                },
                                                icon: const Icon(Icons.clear)),
                                            IconButton(
                                              icon: const Icon(Icons.check),
                                              onPressed: () {
                                                if (ip['CODE'] == '0') {
                                                  onAddIp(prefixIp!,
                                                      siteController.text);
                                                } else {
                                                  onUpdateIp(
                                                      ip['CODE'],
                                                      prefixIp!,
                                                      siteController.text);
                                                }
                                                setState(() {
                                                  prefixIp = null;
                                                  site = null;
                                                  editedIP = null;
                                                });
                                              },
                                            ),
                                          ])
                                        : Row(children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                setState(() {
                                                  prefixIp = ip['PREFIXE IP'];
                                                  site = ip['LIBELLE SITE'];
                                                  editedIP = ip['CODE'];
                                                });
                                              },
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  onDeleteIp(ip['CODE'],
                                                      ip['PREFIXE IP']);
                                                },
                                                icon: const Icon(Icons.delete))
                                          ]))
                              ])
                          ]),
                    ]))));
          });
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        body: SingleChildScrollView(
            child: Dialog(
                insetPadding: const EdgeInsets.all(30),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))),
                elevation: 8,
                child: SizedBox(
                    width: 700,
                    height: 800,
                    child: Column(children: [
                      const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'Paramètres généraux',
                            style: TextStyle(fontSize: 24),
                          )),
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Ces paramètres sont inscrits dans la base de donnée et sont donc\ndépendants du serveur sur lequel il se trouve.',
                            style: TextStyle(
                                fontSize: defaultTextStyle.fontSize,
                                color: Colors.grey.shade700),
                          )),
                      const Spacer(),
                      Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.bottom,
                        defaultColumnWidth: const FractionColumnWidth(0.40),
                        columnWidths: const {2: FixedColumnWidth(80)},
                        children: [
                          for (Map constant in constantsList)
                            TableRow(children: [
                              TableCell(
                                  child: SizedBox(
                                      height: 60,
                                      child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 20),
                                          child: Text(
                                            constant['Nom']!,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    defaultTextStyle.fontSize),
                                          )))),
                              TableCell(
                                  child: SizedBox(
                                      height: 70,
                                      child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 17),
                                          child: editedConstant ==
                                                  constant['CODE']
                                              ? TextFormField(
                                                  style: defaultTextStyle,
                                                  initialValue:
                                                      constant['Valeur'],
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      value = newValue;
                                                    });
                                                  },
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 17),
                                                  child: Text(
                                                      constant['Valeur']!,
                                                      style:
                                                          defaultTextStyle))))),
                              TableCell(
                                  child: editedConstant == constant['CODE']
                                      ? Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    editedConstant = null;
                                                  });
                                                },
                                                icon: const Icon(Icons.clear)),
                                            IconButton(
                                                onPressed: () {
                                                  onUpdateConstant(
                                                      constant['Nom']);
                                                },
                                                icon: const Icon(Icons.check))
                                          ],
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            setState(() {
                                              editedConstant = constant['CODE'];
                                              value = constant['Valeur'];
                                            });
                                          },
                                        )),
                            ])
                        ],
                      ),
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: ElevatedButton(
                              style: myButtonStyle,
                              onPressed: () {
                                showIpTable();
                              },
                              child: const Text('Correspondance IP - sites'))),
                      const Spacer(),
                    ])))));
  }
}
