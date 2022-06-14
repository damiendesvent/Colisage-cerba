library flutter_application_test_log_in.globals;

import '../models/user.dart';
import '../models/site.dart';
import '../models/road_map.dart';
import '../models/traca.dart';

bool isAuthentified = false;

User user = User(
    code: '',
    lastname: '',
    firstname: '',
    function: '',
    password: '',
    siteEditing: false,
    roadMapEditing: false,
    boxEditing: false,
    sqlExecute: false,
    userEditing: false);

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

Traca detailedTraca = Traca(
    code: 0,
    user: '',
    tournee: 0,
    site: 0,
    box: '',
    tube: '',
    action: '',
    correspondant: '',
    registeringTime: '',
    synchronizingTime: '',
    pgm: '',
    lettrage: 0,
    car: 0,
    comment: '');
