import 'package:flutter/material.dart';
import 'package:flutter_application_1/variables/styles.dart';
import '../variables/globals.dart' as globals;
import 'site_screen.dart';
import 'user_screen.dart';
import 'road_map_screen.dart';
import 'boxes_print_screen.dart';
import 'sql_screen.dart';
import 'settings_screen.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Management());
  }
}

class Management extends StatefulWidget {
  const Management({Key? key}) : super(key: key);

  @override
  _ManagementState createState() => _ManagementState();
}

class _ManagementState extends State<Management>
    with SingleTickerProviderStateMixin {
  int minTabWidth = 1130;
  List<Widget> widgetTabs = [
    if (globals.user.userEditing) const UserScreen(),
    if (globals.user.boxEditing) const BoxesPrintScreen(),
    const SiteScreen(),
    const RoadMapScreen(),
    const SettingScreen(),
    if (globals.user.sqlExecute) const SqlScreen()
  ];
  int _widgetIndex = 1;
  late TabController _tabController;

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
    setState(() {
      _widgetIndex = widgetTabs.length ~/ 2;
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Scaffold(
              appBar: AppBar(
                toolbarHeight: 0,
                backgroundColor: themeMainColor,
                bottom: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: themeSecondColor, width: 1),
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
                          if (MediaQuery.of(context).size.width > minTabWidth)
                            const Text(" Utilisateurs")
                        ],
                      ),
                    if (globals.user.boxEditing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.print),
                          if (MediaQuery.of(context).size.width > minTabWidth)
                            const Text(" Etiquettes")
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.track_changes_outlined),
                        if (MediaQuery.of(context).size.width > minTabWidth)
                          const Text(" Sites")
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fact_check_outlined),
                        if (MediaQuery.of(context).size.width > minTabWidth)
                          const Text(" Feuilles de route")
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.settings),
                        if (MediaQuery.of(context).size.width > minTabWidth)
                          const Text(" Paramètres")
                      ],
                    ),
                    if (globals.user.sqlExecute)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.data_usage),
                          if (MediaQuery.of(context).size.width > minTabWidth)
                            const Text(" Interface SQL")
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
                      controller: _tabController, children: widgetTabs))),
    );
  }
}
