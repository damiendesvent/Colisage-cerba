import 'package:flutter/material.dart';
import 'package:flutter_application_1/variables/env.sample.dart';
import 'package:flutter_application_1/variables/styles.dart';
import '../variables/globals.dart' as globals;
import 'tube_screen.dart';
import 'traca_screen.dart';
import 'management_screen.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Welcome());
  }
}

class Welcome extends StatefulWidget {
  const Welcome({Key? key}) : super(key: key);

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with SingleTickerProviderStateMixin {
  Timer? timer;
  int minTabWidth = 800;
  List<Widget> widgetTabs = [
    const TracaScreen(),
    const TubeScreen(),
    const ManagementScreen(),
  ];
  int _widgetIndex = 1;
  late TabController _tabController;

  void initializeTimer() {
    timer?.cancel();
    timer = Timer(Duration(minutes: globals.inactivityTimeOut), handleTimeout);
  }

  void handleTimeout() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        globals.isAuthentified = false;
      });
    }
  }

  void logOut(BuildContext context) {
    globals.isAuthentified = false;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  void getConstants() async {
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

  void getIP() async {
    String phpUriGetIP = Env.urlPrefix + 'Scripts/get_ip.php';
    http.Response res = await http.get(Uri.parse(phpUriGetIP));
    if (res.body.isNotEmpty) {
      setState(() {
        globals.ip = json.decode(res.body);
      });
    }
  }

  @override
  void initState() {
    _tabController = TabController(
        length: widgetTabs.length, vsync: this, initialIndex: _widgetIndex);
    _tabController.addListener(() {
      setState(() {
        _widgetIndex = _tabController.index;
      });
    });
    getConstants();
    getIP();
    super.initState();
    initializeTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => initializeTimer(),
        onPanDown: (_) => initializeTimer(),
        onPanUpdate: (_) => initializeTimer(),
        child: Scaffold(
          body: Center(
              child: (globals.isAuthentified)
                  ? Scaffold(
                      appBar: AppBar(
                        title: const Text('Colisage des prélèvements'),
                        automaticallyImplyLeading: false,
                        leading: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              'assets/images/cerballiance_logo.png',
                            )),
                        backgroundColor: themeMainColor,
                        toolbarHeight: 50,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text('Bonjour ' + globals.user.firstname),
                          centerTitle: true,
                          titlePadding: const EdgeInsets.fromLTRB(0, 0, 0,
                              60), //choisit la position de la zone de texte
                        ),
                        actions: <Widget>[
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              child: IconButton(
                                  tooltip: 'Se déconnecter',
                                  onPressed: () {
                                    logOut(context);
                                  },
                                  icon: const Icon(
                                    Icons.exit_to_app,
                                    size: 30,
                                    color: Colors.red,
                                  ))),
                        ],
                        bottom: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: themeSecondColor, width: 1),
                              borderRadius: BorderRadius.circular(8)),
                          labelColor: themeMainColor,
                          unselectedLabelColor: Colors.white,
                          labelStyle: const TextStyle(fontSize: 16),
                          tabs: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.dock_outlined),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Traçabilité")
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.science),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Gestion tubes")
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Gestion colisage")
                              ],
                            ),
                          ],
                        ),
                      ),
                      body: /*IndexedStack(
                        index: _widgetIndex,
                        children: widgetTabs,
                      ),*/
                          TabBarView(
                              controller: _tabController, children: widgetTabs))
                  : Column(
                      //si la variable isAuthentified est égale à false, on affiche un message d'erreur
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Text('Vous n\'êtes pas connecté !',
                              style: Theme.of(context).textTheme.headline2),
                          Padding(
                              padding: const EdgeInsets.all(30),
                              child: ElevatedButton(
                                style: myButtonStyle,
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/');
                                },
                                child: const Text(
                                    'Revenir à la page de connexion'),
                              )),
                        ])),
        ));
  }
}
