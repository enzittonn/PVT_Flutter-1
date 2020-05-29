import 'package:flutter/material.dart';
import 'package:ezsgame/firebase/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState(value, this.parent);

  HistoryPage(
      {Key key, this.userId, this.auth, this.logoutCallback, this.value, this.parent})
      : super(key: key);

  final String userId;
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String value;
  final HomePageState parent;
}

class _HistoryPageState extends State<HistoryPage> {
  String value;
  final db = Firestore.instance;
  HomePageState parent;

  _HistoryPageState(this.value, this.parent);

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Senast valda destinationer'
        ),
      ),
      body: Container(
        child: StreamBuilder(
            stream: getUserHistoryParkings(context),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const Text("Loading..");
              return new ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (BuildContext context, int index) =>
                      buildHistoryCard(
                          context, snapshot.data.documents[index]));
            }),
      ),
    );
  }

  Stream<QuerySnapshot> getUserHistoryParkings(BuildContext context) async* {
    String uId = widget.userId;
    yield* Firestore.instance
        .collection('userData')
        .document(uId)
        .collection('history')
        .snapshots();
  }
  //TODO: sort cards by timestamp
  Widget buildHistoryCard(BuildContext context, DocumentSnapshot parking) {
    return new Container(
        child: new GestureDetector(
      onTap: () => showOnCardTapDialogue(parking),
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(parking['location'],
                          style: new TextStyle(fontSize: 14)),
                      Icon(Icons.directions_car)
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(parking['district'],
                          style: new TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text('Användes senast: ' + parking['timestamp'],
                          style: new TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ))),
    ));
  }

  Future<void> showOnCardTapDialogue(DocumentSnapshot doc) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(doc['location']),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ta bort'),
              onPressed: () {
                showRemoveConfirmationDialogue(doc);
              },
            ),
            FlatButton(
              child: Text('Visa på karta'),
              onPressed: () {
                Navigator.of(context).pop();
                showParkingOnMapPage();
              },
            ),
            FlatButton(
              child: Text('Avbryt'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future showRemoveConfirmationDialogue(DocumentSnapshot doc) {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(''),
            content: Text("Är du säker på att du vill ta bort " + doc['location'] + " från din historik?"),
            actions: [
              FlatButton(
                child: Text('Ja'),
                onPressed: () {
                  deleteHistoryParking(doc);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Nej'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  showParkingOnMapPage() {
    this.parent.setState(() {
      HomePageState.currentNavigationIndex = 1;
    });
  }

  void deleteHistoryParking(DocumentSnapshot doc) async {
    String uId = widget.userId;
    try {
      db
          .collection('userData')
          .document(uId)
          .collection('history')
          .document(doc.documentID)
          .delete();
    } catch (e) {
      print('Error: $e');
    }
  }
}