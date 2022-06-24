import 'package:flutter/material.dart';
import 'package:flutter_application_1/variables/styles.dart';
import '../variables/globals.dart' as globals;
import 'site_screen.dart';
import 'user_screen.dart';
import 'tube_screen.dart';
import 'traca_screen.dart';
import 'road_map_screen.dart';
import 'boxes_print_screen.dart';
import 'sql_screen.dart';
import 'dart:async';

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
  int minTabWidth = 1130;
  List<Widget> widgetTabs = [
    if (globals.user.userEditing) const UserScreen(),
    if (globals.user.boxEditing) const BoxesPrintScreen(),
    const SiteScreen(),
    const TubeScreen(),
    const TracaScreen(),
    const RoadMapScreen(),
    if (globals.user.sqlExecute) const SqlScreen()
  ];
  int _widgetIndex = 3;
  late TabController _tabController;

  void initializeTimer() {
    timer?.cancel();
    timer = Timer(const Duration(minutes: 5), handleTimeout);
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

  @override
  void initState() {
    _tabController = TabController(
        length: widgetTabs.length, vsync: this, initialIndex: _widgetIndex);
    _tabController.addListener(() {
      setState(() {
        _widgetIndex = _tabController.index;
      });
    });
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
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text('Bonjour ' + globals.user.firstname),
                          centerTitle: true,
                          titlePadding: const EdgeInsets.fromLTRB(0, 0, 0,
                              70), //choisit la position de la zone de texte
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
                            if (globals.user.userEditing)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.manage_accounts_rounded),
                                  if (MediaQuery.of(context).size.width >
                                      minTabWidth)
                                    const Text(" Utilisateurs")
                                ],
                              ),
                            if (globals.user.boxEditing)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.print),
                                  if (MediaQuery.of(context).size.width >
                                      minTabWidth)
                                    const Text(" Etiquettes")
                                ],
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.track_changes_outlined),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Sites")
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
                                const Icon(Icons.dock_outlined),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Traçabilité")
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fact_check_outlined),
                                if (MediaQuery.of(context).size.width >
                                    minTabWidth)
                                  const Text(" Feuilles de route")
                              ],
                            ),
                            if (globals.user.sqlExecute)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.data_usage),
                                  if (MediaQuery.of(context).size.width >
                                      minTabWidth)
                                    const Text(" Interface SQL")
                                ],
                              ),
                          ],
                        ),
                      ),
                      body: IndexedStack(
                        index: _widgetIndex,
                        children: widgetTabs,
                      ),
                    )
                  : Column(
                      //si la variable isAuthentified est égale à false, on affiche un message d'erreur
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Text('Vous n\'êtes pas connecté !',
                              style: Theme.of(context).textTheme.headline2),
                          ElevatedButton(
                            style: myButtonStyle,
                            onPressed: () {
                              Navigator.of(context).pushNamed('/');
                            },
                            child: const Text('Revenir à la page de connexion'),
                          ),
                        ])),
        ));
  }
}
