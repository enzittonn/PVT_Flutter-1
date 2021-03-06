import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ezsgame/firebase/authentication.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'settings.dart';
import 'favorites.dart';
import 'map_page.dart';
import 'history.dart';
import 'package:flutter/widgets.dart';


class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();

  HomePage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
}

class HomePageState extends State<HomePage> {

  static int currentNavigationIndex = 2;
  static DocumentSnapshot doc;
  static double settingsZoom;
  static CameraPosition initPosition= CameraPosition(
      target: LatLng(59.3293, 18.0686),
      zoom: 15);
  final db = Firestore.instance;

  @override
  void initState() {
    super.initState();
    getZoom().then((double value) {
      settingsZoom = value;
      initPosition = CameraPosition(
          target: LatLng(59.3293, 18.0686),
          zoom: settingsZoom);
    });

  }

  List<Widget> _tabs() => [
    FavouritesPage(
      userId: widget.userId,
      auth: widget.auth,
      logoutCallback: widget.logoutCallback,
      parent: this,
    ),
    HistoryPage(
      userId: widget.userId,
      auth: widget.auth,
      logoutCallback: widget.logoutCallback,
      parent: this,
    ),
    MapPage(
      userId: widget.userId,
      auth: widget.auth,
      logoutCallback: widget.logoutCallback,
      doc: doc,
      initPosition: initPosition,
    ),
    SettingsPage(
      userId: widget.userId,
      auth: widget.auth,
      logoutCallback: widget.logoutCallback,
      parent: this,
    ),
  ];



  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = _tabs();

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: tabs[currentNavigationIndex],
//      IndexedStack(
//        children: _tabs(),
//        index: currentNavigationIndex,
//      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentNavigationIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orangeAccent,
          unselectedItemColor: Colors.grey,
          iconSize: 45,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                title: Text('Favoriter')
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.history),
                title: Text('Historik')
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.map),
                title: Text('Karta')
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                title: Text('Inställningar')
            ),
          ],
          onTap: (index) {
            setState(() {
              currentNavigationIndex = index;
            });
          }
      ),
    );
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
