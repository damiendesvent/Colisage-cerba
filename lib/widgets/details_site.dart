import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/site.dart';
import '../variables/env.sample.dart';
import '../variables/styles.dart';
import 'dart:convert';
import '../variables/globals.dart' as globals;

class DetailsSiteScreen extends StatelessWidget {
  final Site site;
  final bool editing;

  const DetailsSiteScreen({required this.site, this.editing = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DetailsSite(
        site: site,
        editing: editing,
      ),
    );
  }
}

class DetailsSite extends StatefulWidget {
  final Site site;
  final bool editing;
  const DetailsSite({required this.site, this.editing = false, Key? key})
      : super(key: key);

  @override
  _DetailsSiteState createState() => _DetailsSiteState();
}

class _DetailsSiteState extends State<DetailsSite> {
  TextStyle textStyle = const TextStyle(fontSize: 18);
  late TextEditingController libelleController =
      TextEditingController(text: site.libelle);
  late TextEditingController correspondantController =
      TextEditingController(text: site.correspondant);
  late TextEditingController adressController =
      TextEditingController(text: site.adress);
  late TextEditingController cpltAdressController =
      TextEditingController(text: site.cpltAdress);
  late TextEditingController cpController =
      TextEditingController(text: site.cp.toString());
  late TextEditingController cityController =
      TextEditingController(text: site.city);
  late TextEditingController commentController =
      TextEditingController(text: site.comment);

  List<String> yesNoList = ['Non', 'Oui'];
  late bool editing = widget.editing;
  late Site site = widget.site;
  late String collectionSiteValue = site.collectionSite ? 'Oui' : 'Non';
  late String depositSiteValue = site.depositSite ? 'Oui' : 'Non';

  void onUpdateSite() async {
    String phpUriSiteDetail = Env.urlPrefix + 'Sites/details_site.php';
    String phpUriSiteUpdate = Env.urlPrefix + 'Sites/update_site.php';
    await http.post(Uri.parse(phpUriSiteUpdate), body: {
      "searchCode": site.code.toString(),
      "correspondant": correspondantController.text,
      "libelle": libelleController.text,
      "adress": adressController.text,
      "cpltAdress": cpltAdressController.text,
      "cp": cpController.text,
      "city": cityController.text,
      "collectionSite": collectionSiteValue,
      "depositSite": depositSiteValue,
      "comment": commentController.text
    });
    http.Response res = await http.post(Uri.parse(phpUriSiteDetail),
        body: {"searchCode": site.code.toString()});
    if (res.body.isNotEmpty) {
      List item = json.decode(res.body);
      setState(() {
        site = Site.fromList(item);
        globals.detailedSite = site;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(const Text('Les modifications ont été enregistrées')));
  }

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return SizedBox(
          height: 600,
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Code : ${site.code}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Spacer(),
              Text('Libellé : ${site.libelle}', style: textStyle),
              const Spacer(),
              Text('Correspondant : ${site.correspondant}', style: textStyle),
              const Spacer(),
              Text('Adresse : ${site.adress}', style: textStyle),
              const Spacer(),
              Text('Complément d\'adressse : ${site.cpltAdress}',
                  style: textStyle),
              const Spacer(),
              Text('Code postal : ${site.cp}', style: textStyle),
              const Spacer(),
              Text('Ville : ${site.city}', style: textStyle),
              const Spacer(),
              Text(
                  'Site de prélèvement : ${site.collectionSite ? 'Oui' : 'Non'}',
                  style: textStyle),
              const Spacer(),
              Text('Site de dépôt : ${site.depositSite ? 'Oui' : 'Non'}',
                  style: textStyle),
              const Spacer(),
              Text('Commentaires correspondant : ${site.comment}',
                  style: textStyle),
              const Spacer(),
              const Spacer()
            ],
          ));
    } else {
      return SizedBox(
        height: 600,
        width: 400,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Code : ${site.code}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: [
                  Text('Libellé : ', style: textStyle),
                  SizedBox(
                      width: 200,
                      child: TextField(
                        controller: libelleController,
                        inputFormatters: [LengthLimitingTextInputFormatter(35)],
                      ))
                ],
              ),
              Row(
                children: [
                  Text('Correspondant : ', style: textStyle),
                  SizedBox(
                      width: 200,
                      child: TextField(
                          controller: correspondantController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20)
                          ]))
                ],
              ),
              Row(
                children: [
                  Text('Adresse : ', style: textStyle),
                  SizedBox(
                      width: 200,
                      child: TextField(
                          controller: adressController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(35)
                          ]))
                ],
              ),
              Row(
                children: [
                  Text('Complément d\'adresse : ', style: textStyle),
                  SizedBox(
                      width: 200,
                      child: TextField(
                          controller: cpltAdressController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(35)
                          ]))
                ],
              ),
              Row(
                children: [
                  Text('Code postal : ', style: textStyle),
                  SizedBox(
                      width: 200,
                      child: TextField(
                          controller: cpController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6),
                            FilteringTextInputFormatter.digitsOnly
                          ]))
                ],
              ),
              Row(
                children: [
                  Text('Ville : ', style: textStyle),
                  SizedBox(
                      width: 200,
                      child: TextField(
                          controller: cityController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(35)
                          ]))
                ],
              ),
              Row(
                children: [
                  Text('Site de prélèvement : ', style: textStyle),
                  SizedBox(
                      width: 100,
                      child: DropdownButton(
                        items: yesNoList.map((yesNo) {
                          return DropdownMenuItem(
                              value: yesNo, child: Text(yesNo.toString()));
                        }).toList(),
                        value: collectionSiteValue,
                        onChanged: (String? newValue) {
                          setState(() {
                            collectionSiteValue = newValue!;
                          });
                        },
                      ))
                ],
              ),
              Row(
                children: [
                  Text('Site de dépôt : ', style: textStyle),
                  SizedBox(
                      width: 100,
                      child: DropdownButton(
                        items: yesNoList.map((yesNo) {
                          return DropdownMenuItem(
                              value: yesNo, child: Text(yesNo.toString()));
                        }).toList(),
                        value: depositSiteValue,
                        onChanged: (String? newValue) {
                          setState(() {
                            depositSiteValue = newValue!;
                          });
                        },
                      ))
                ],
              ),
              Row(
                children: [
                  Text('Commentaire : ', style: textStyle),
                  SizedBox(
                      width: 200,
                      child: TextField(
                          controller: commentController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(254)
                          ]))
                ],
              ),
              Center(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 148),
                      child: ElevatedButton(
                        onPressed: () {
                          onUpdateSite();
                          setState(() {
                            editing = false;
                          });
                        },
                        child: Row(children: const [
                          Icon(Icons.check),
                          Text(' Valider')
                        ]),
                      ))),
            ]),
      );
    }
  }
}
