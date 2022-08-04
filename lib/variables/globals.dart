library flutter_application_test_log_in.globals;

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/site.dart';
import '../models/road_map.dart';

bool isAuthentified = false;

int milisecondWait = 20;
bool shouldKeepAlive = false;
bool shouldDisplaySyncButton = false;
String pdaTrackInDirectory = '/';
int inactivityTimeOut = 15;
String ip = '';
String currentSite = '';
int maxCapacityBox = 50;

User user = User(
    code: '',
    lastname: '',
    firstname: '',
    function: '',
    password: '',
    siteRights: 0,
    roadMapRights: 0,
    boxRights: 0,
    sqlExecute: false,
    userRights: 0,
    settingsRights: false);

Site detailedSite = Site(
    code: 0,
    correspondant: '',
    libelle: '',
    adress: '',
    cpltAdress: '',
    cp: 0,
    city: '',
    collectionSite: false,
    depositSite: false,
    comment: '');

RoadMap detailedRoadMap =
    RoadMap(code: 0, libelle: '', tel: '', comment: '', sortingNumer: 0);

List<Widget> mainWidgetTabs = [];
List<Widget> managementWidgetTabs = [];
