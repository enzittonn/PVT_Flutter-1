import 'package:flutter/material.dart';
import 'settings.dart';
import 'map_page.dart';
import 'SizeConfig.dart';

class FavouritesPage extends StatefulWidget {
  @override
  _FavouritesPageState createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  Future navigateToCurrentPage(context) async {}

  Future navigateToSettingsPage(context) async {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => new SettingsPage()));
  }

  Future navigateToMapPage(context) async {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => new MapPage()));
  }

  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Favoriter", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.greenAccent,
        actions: <Widget>[],
      ),
      body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              SizedBox(height: SizeConfig.blockSizeVertical * 75),
              Expanded(
                child: Row(
                  children: <Widget>[
                    SizedBox(width: SizeConfig.blockSizeHorizontal * 5),
                    showFavoritesNavigationButton(),
                    SizedBox(width: SizeConfig.blockSizeHorizontal * 7),
                    showMapNavigationButton(),
                    SizedBox(width: SizeConfig.blockSizeHorizontal * 7),
                    showSettingsNavigationButton(),
                ],
              ),
            ),
         ],
      )),
    );
  }

  Widget showFavoritesNavigationButton() {
    return FlatButton(
        onPressed: () => {navigateToCurrentPage(context)},
        child: Column(
          children: <Widget>[
            Icon(Icons.favorite, size: 45, color: Colors.orangeAccent),
            Text("Favoriter",
                style: TextStyle(fontSize: 13))
          ],
        )
    );
  }

  Widget showMapNavigationButton() {
    return FlatButton(
        onPressed: () => {navigateToMapPage(context)},
        child: Column(
          children: <Widget>[
            Icon(Icons.map, size: 45, color: Colors.grey),
            Text("Karta",
                style: TextStyle(fontSize: 13))
          ],
        ));
  }

  Widget showSettingsNavigationButton() {
    return FlatButton(
        onPressed: () => {navigateToSettingsPage(context)},
        child: Column(
          children: <Widget>[
            Icon(Icons.settings, size: 45, color: Colors.grey),
            Text("Inställningar",
                style: TextStyle(fontSize: 13))
          ],
        )
    );
  }
}
