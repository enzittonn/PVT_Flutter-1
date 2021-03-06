import 'package:flutter/material.dart';
import 'package:ezsgame/firebase/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FavouritesPage extends StatefulWidget {
  @override
  _FavouritesPageState createState() => _FavouritesPageState(value, this.parent, this.map);

  FavouritesPage(
      {Key key, this.userId, this.auth, this.logoutCallback, this.value, this.parent, this.map})
      : super(key: key);

  final String userId;
  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String value;
  final HomePageState parent;
  final MapPage map;
}

class _FavouritesPageState extends State<FavouritesPage> {
  String value;
  final db = Firestore.instance;
  HomePageState parent;
  MapPage map;
  double _zoom;


  _FavouritesPageState(this.value, this.parent, this.map);

  @override
  void initState() {
    super.initState();
    HomePageState.doc = null;
    getZoom().then((double value) {
      _zoom = value;
      HomePageState.initPosition = CameraPosition(
        target: LatLng(59.3293, 18.0686),
        zoom: _zoom,
      );
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        automaticallyImplyLeading: false,
        title: Text('Favoritparkeringar', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: StreamBuilder(
            stream: getUserFavoriteParkings(context),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const Text("Loading..");
              return new ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (BuildContext context, int index) =>
                      buildFavoriteCard(
                          context, snapshot.data.documents[index]));
            }),
      ),
    );
  }

  Stream<QuerySnapshot> getUserFavoriteParkings(BuildContext context) async* {
    String uId = widget.userId;
    yield* Firestore.instance
        .collection('userData')
        .document(uId)
        .collection('favorites')
        .snapshots();
  }

  Icon getVehicleTypeIcon(DocumentSnapshot parking) {
    if (parking['vehicleType'] == 'car') {
      return new Icon(Icons.directions_car);
    }
    else if (parking['vehicleType'] == 'motorcykel') {
      return new Icon(Icons.motorcycle);
    }
    else if (parking['vehicleType'] == 'lastbil') {
      return new Icon(MdiIcons.truck);
    }
    else if (parking['vehicleType'] == 'handicap') {
      return new Icon(Icons.accessible);
    }
    return new Icon(Icons.directions_car);
  }

  Widget buildFavoriteCard(BuildContext context, DocumentSnapshot parking) {


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
                      SizedBox(width: 10,),
                      getVehicleTypeIcon(parking),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(parking['district'],
                          style: new TextStyle(fontSize: 10)),
                    ],
                  )
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
                Text(doc['location'], style: TextStyle(fontSize: 16)),
                Text('Stadsdel: ' + doc['district'], style: TextStyle(fontSize: 14)),
                Text('Övrig info: ' + doc['info'], style: TextStyle(fontSize: 14)),
                Text('Max timmar: ' + doc['maxTimmar'], style: TextStyle(fontSize: 14)),
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
                showParkingOnMapPage(doc);
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
            content: Text("Är du säker på att du vill ta bort " + doc['location'] + " från dina favoriter?"),
            actions: [
              FlatButton(
                child: Text('Ja'),
                onPressed: () {
                  deleteFavoriteParking(doc);
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

  showParkingOnMapPage(DocumentSnapshot doc) {

    this.parent.setState(() {
      HomePageState.currentNavigationIndex = 2;
      HomePageState.doc = doc;
      HomePageState.initPosition = CameraPosition(
          target: LatLng(doc['coordinatesX'], doc['coordinatesY']),
          zoom: _zoom);
    });

  }

  void deleteFavoriteParking(DocumentSnapshot doc) async {
    String uId = widget.userId;
    try {
      db
          .collection('userData')
          .document(uId)
          .collection('favorites')
          .document(doc.documentID)
          .delete();
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<double> getZoom() async{
    DocumentSnapshot snap = await db.collection('userData')
        .document(widget.userId)
        .collection('settings').document('SettingsData').get();
    if(snap.exists && snap.data["zoom"] != null) {
      return snap.data["zoom"];
    }else{
      String uId = widget.userId;
      db.collection('userData')
          .document(uId)
          .collection('settings')
          .document('SettingsData')
          .setData({
        'zoom' : 15.0,
      });
      return 15.0;
    }
  }
}
