import 'package:flutter/material.dart';
import '../models/traca.dart';

class DetailsTracaScreen extends StatelessWidget {
  final Traca traca;
  const DetailsTracaScreen({required this.traca, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DetailsTraca(
        traca: traca,
      ),
    );
  }
}

class DetailsTraca extends StatefulWidget {
  final Traca traca;

  const DetailsTraca({required this.traca, Key? key}) : super(key: key);

  @override
  _DetailsTracaState createState() => _DetailsTracaState();
}

class _DetailsTracaState extends State<DetailsTraca> {
  TextStyle textStyle = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 650,
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Code : ${widget.traca.code}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Utilisateur : ${widget.traca.user}', style: textStyle),
            Text('Tournée : ${widget.traca.tournee}', style: textStyle),
            Text('Site : ${widget.traca.site}', style: textStyle),
            Text('Boite : ${widget.traca.box}', style: textStyle),
            Text('Tube : ${widget.traca.tube}', style: textStyle),
            Text('Action : ${widget.traca.action}', style: textStyle),
            Text('Correspondant : ${widget.traca.correspondant}',
                style: textStyle),
            Text('Enregistrement : ${widget.traca.registeringTime}',
                style: textStyle),
            Text('Synchronisation : ${widget.traca.synchronizingTime}',
                style: textStyle),
            Text('Origine PGM : ${widget.traca.pgm}', style: textStyle),
            Text('Lettrage : ${widget.traca.lettrage}', style: textStyle),
            Text('Code voiture : ${widget.traca.car}', style: textStyle),
            Text('Commentaire : ${widget.traca.comment}', style: textStyle),
          ],
        ));
  }
}
