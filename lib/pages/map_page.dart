import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezsgame/api/Services.dart';
import 'package:ezsgame/firebase/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ezsgame/firebase/authentication.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'IconInfo.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:flutter/widgets.dart';
import 'package:search_map_place/search_map_place.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();

  MapPage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;
}

class _MapPageState extends State<MapPage> {
  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  bool handicapToggled = false;
  var _globalCarToggled = true;
  var _globalTruckToggled = false;
  var _globalMotorcycleToggled = false;
  bool _filterSwitched = false;
  var _distanceValue = 0.0;
  var _costValue = 0.0;
  var currMarker;
  var parkings;
  var currParking;
  final db = Firestore.instance;

  static final CameraPosition initPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
    zoom: 12,
  );

  Completer<GoogleMapController> _mapController = Completer();
  Location location = Location();
  LocationData _myLocation;
  GoogleMapController _controller;
  StreamSubscription<LocationData> _locationSubscription;
  final Map<String, Marker> _markers = {};
  final Map<String, Circle> circles = {};
  BitmapDescriptor arrowIcon;
  LatLng initLocation = LatLng(59.3293, 18.0686);
  String _error;

  double _pinPillPosition = -300; // Used in InfoWindow Animation

  @override
  void initState() {
    super.initState();
    getBytesFromAsset('assets/direction-arrow.png', 64).then((onValue) {
      arrowIcon = BitmapDescriptor.fromBytes(onValue);
    });
    setInitLocation();
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  Future<void> _listenLocation() async {
    _locationSubscription =
        location.onLocationChanged.handleError((dynamic err) {
      setState(() {
        _error = err.code;
      });
      _locationSubscription.cancel();
    }).listen((LocationData currentLocation) {
      setState(() {
        _myLocation = currentLocation;
        updatePinOnMap();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _listenLocation();
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Container(
            child: Stack(
              children: <Widget>[
                showGoogleMaps(),
            showWindow(),
            //showFavoritesButton(),
                showTopBar(),
                showMyLocationButton()
              ],
            )));
  }

  Widget showTopBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 50),
          ), //empty container to move down the searchfield
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Flexible(child: Container(height: 10,)),
              Expanded(
                child: showSearchTextField(),
                flex: 5,
              ),
              Flexible(child: showFilterButton(), flex: 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget showSearchTextField() {
    return SearchMapPlaceWidget(
        apiKey: "AIzaSyBLNOKl2W5s0vuY0aZ-ll_PNoeldgko12w",
        // The language of the autocompletion
        language: 'se',
        // The position used to give better recomendations.
        location: LatLng(59.3293, 18.0686),
        radius: 30000,
        //darkMode: true,
        placeholder: "Sök gata, adress, etc.",
        onSelected: (Place place) async {
          final geolocation = await place.geolocation;

          // Will animate the GoogleMap camera, taking us to the selected position with an appropriate zoom
          final GoogleMapController controller = await _mapController.future;

          setState(() {
            controller
                .animateCamera(CameraUpdate.newLatLng(geolocation.coordinates));
            controller.animateCamera(
                CameraUpdate.newLatLngBounds(geolocation.bounds, 0));
          });
        });
  }

  Widget showFilterButton() {
    return IconButton(
      icon: Icon(
        MdiIcons.filterMenu,
        color: _filterSwitched ? Colors.orangeAccent : Colors.grey,
      ),
      onPressed: () {
        createDialog(context);
        showGoogleMaps();
        // do something
      },
      //     ),
    );
  }

  addToFavorites() async {
    String id = widget.userId;

    await db.collection('userData').document(id).collection('favorites').add({
      'location': currParking.properties.address,
      'district': currParking.properties.cityDistrict
    });

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: Text('Success'),
            content:
            Text(currParking.properties.address + ' added to favorites!')));
  }

  Widget showFavoritesButton() {
    return Container(
      child: FlatButton(
          child: Icon(
              Icons.favorite_border, size: 60, color: Colors.orangeAccent),
          onPressed: () {
            if (currMarker != null) addToFavorites();
          }),
    );
  }

  _onMarkerTapped(String marker, var parking) {
    if (_markers.containsKey(parking.properties.address)) {
      final marker = _markers[parking.properties.address];
      currMarker = marker;
      currParking = parking;
      //print(currMarker.markerId.toString() + '');
      print(parking.properties.cityDistrict);
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    parkings = await Services.fetchParkering(_globalCarToggled,
        _globalTruckToggled, _globalMotorcycleToggled, handicapToggled);
    _controller = controller;
    _mapController.complete(controller);

    setState(() {
      _markers.clear();
      for (final parking in parkings.features) {
        final marker = Marker(
          onTap: () {
            _onMarkerTapped(parking.properties.address, parking);
            _pinPillPosition = 0;
          },
          markerId: MarkerId(parking.properties.address),
          position: LatLng(parking.geometry.coordinates[0][1],
              parking.geometry.coordinates[0][0]),
          /*infoWindow: InfoWindow(
              title: parking.properties.cityDistrict,
              snippet: parking.properties.address,
              onTap: () {
                _onMarkerTapped(parking.properties.address, parking);
                },
            )*/
        );
        _markers[parking.properties.address] = marker;
      }
      updatePinOnMap();
    });
  }

  Widget showGoogleMaps() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: const LatLng(59.3293, 18.0686),
        zoom: 12,
      ),
      markers: _markers.values.toSet(),
      onTap: (LatLng location) {
        setState(() {
          _pinPillPosition = -300;
        });
      },
    );
  }

  // Animated info window
  Widget showWindow() {
    return AnimatedPositioned(
      bottom: _pinPillPosition,
      right: 0,
      left: 0,
      duration: Duration(milliseconds: 100),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.all(20),
          height: 150,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(50)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  blurRadius: 20,
                  offset: Offset.zero,
                  color: Colors.grey.withOpacity(0.5),
                )
              ]),
          child: Row(
            children: <Widget>[
              _buildLocationInfo(),
              _showFavBtnAndDirectionBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
        margin: EdgeInsets.only(left: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '  Street Adress: \n',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '  Stadsdel:',
              style: TextStyle(fontSize: 15),
            ),
            Text(
              '  Servicedagar: ',
              style: TextStyle(fontSize: 15),
            ),
            Text(
              '  Max timmar: ',
              style: TextStyle(fontSize: 15),
            ),
          ],
        )
    );
  }

  Widget showChooseParkingBtn() {
    return Container(
      margin: EdgeInsets.only(left: 5, right: 10, top: 10),
      child: FlatButton(
        onPressed: null,
        child: Text('Välj Bort', style: TextStyle(color: Colors.orangeAccent)),
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: Colors.blue, width: 1, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }

  Widget _showFavBtnAndDirectionBtn() {
    return Container(
        margin: EdgeInsets.only(left: 120, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: showFavoritesButton(),
              alignment: Alignment.topRight,
            ),
            Container(
              child: showChooseParkingBtn(),
              alignment: Alignment.bottomRight,
            ),
          ],
        ));
  }

  Widget showMyLocationButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FloatingActionButton(
          child: Icon(Icons.my_location, color: Colors.black),
          backgroundColor: Color.fromRGBO(160, 160, 160, 1.0),
          onPressed: () {
            showCurrentLocation();
          }),
    );
  }

  void showCurrentLocation() async {
    _myLocation = await location.getLocation();
    _controller.animateCamera(CameraUpdate.newCameraPosition(new CameraPosition(
        bearing: 0,
        target: LatLng(_myLocation.latitude, _myLocation.longitude),
        tilt: 0,
        zoom: 16)));
  }

  void setInitLocation() async {
    initLocation = await getCurrentLocation();
  }

  Future<LatLng> getCurrentLocation() async {
    _myLocation = await location.getLocation();
    return LatLng(_myLocation.latitude, _myLocation.longitude);
  }

  void updatePinOnMap() async {
    _markers['PhoneLocationMarker'] = Marker(
        markerId: MarkerId('PhoneLocationMarker'),
        position: LatLng(_myLocation.latitude, _myLocation.longitude),
        //rotation: _myLocation.heading,                                  //acting funny
        icon: arrowIcon);
  }

  createDialog(BuildContext context) {
    // The following code is for the filter popup page.
    showDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) =>
              IconInfo(
                  _globalCarToggled, _globalTruckToggled,
                  _globalMotorcycleToggled),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                content: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text("Filter"),
                          showSwitchButton(),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          CarIconButton(),
                          TruckIconButton(),
                          MotorcycleIconButton()
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text("Avstånd från destination:"),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Kort"),
                                Expanded(child: showDistanceSlider()),
                                Text("Långt"),
                              ]),
                          Text("Prisklass:"),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Låg"),
                                Expanded(child: showCostSlider()),
                                Text("Hög"),
                              ]),
                        ],
                      ),
                      showHandicapIconButton(),
                    ],
                  ),
                ),
                actions: <Widget>[
                  showCancelButton(context),
                  showOkButton(context),
                ],
              );
            },
          ),
        );
      },
    ).then((val) {
      // retrieve and update the state of the icons
      IconInfo ic = val;
      if (ic != null) {
        _globalMotorcycleToggled = ic.motorcycleToggled;
        _globalTruckToggled = ic.truckToggled;
        _globalCarToggled = ic.carToggled;
      }
    });
  }

  Widget showSwitchButton() {
    return StatefulBuilder(builder: (context, setState) {
      return Align(
        alignment: Alignment.centerRight,
        child: Switch(
          value: _filterSwitched,
          onChanged: (value) {
            setState(() {
              _filterSwitched = value;
            });
          },
          activeTrackColor: Colors.orangeAccent,
          activeColor: Colors.orange,
        ),
      );
    });
  }

  Widget showDistanceSlider() {
    return StatefulBuilder(builder: (context, setState) {
      return SliderTheme(
        data: SliderThemeData(
          thumbColor: Colors.orangeAccent,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
          inactiveTickMarkColor: Colors.black,
          activeTickMarkColor: Colors.black,
          activeTrackColor: Colors.orangeAccent,
          inactiveTrackColor: Colors.grey,
        ),
        child: Slider(
          min: 0,
          max: 100,
          value: _distanceValue,
          divisions: 2,
          onChanged: (value) {
            setState(() {
              _distanceValue = value;
            });
          },
        ),
      );
    });
  }

  Widget showCostSlider() {
    return StatefulBuilder(builder: (context, setState) {
      return Center(
        child: SliderTheme(
          data: SliderThemeData(
            thumbColor: Colors.orangeAccent,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            inactiveTickMarkColor: Colors.black,
            activeTickMarkColor: Colors.black,
            activeTrackColor: Colors.orangeAccent,
            inactiveTrackColor: Colors.grey,
          ),
          child: Slider(
            min: 0,
            max: 100,
            value: _costValue,
            divisions: 2,
            onChanged: (value) {
              setState(() {
                _costValue = value;
              });
            },
          ),
        ),
      );
    });
  }

  Widget showHandicapIconButton() {
    return StatefulBuilder(builder: (context, setState) {
      return Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          iconSize: 50,
          icon: Icon(
            Icons.accessible,
            color: handicapToggled ? Colors.orangeAccent : Colors.grey,
          ),
          onPressed: () => setState(() => handicapToggled = !handicapToggled),
        ),
      );
    });
  }

  Widget showOkButton(BuildContext context) {
    var iconInfo = Provider.of<IconInfo>(context);
    return StatefulBuilder(builder: (context, setState) {
      return FlatButton(
        onPressed: () => {
          _onMapCreated(_controller),
          Navigator.pop(context, iconInfo),
        },
        child: Text("Klar"),
      );
    });
  }

  Widget showCancelButton(BuildContext context) {
    var iconInfo = Provider.of<IconInfo>(context);
    return StatefulBuilder(builder: (context, setState) {
      return FlatButton(
        onPressed: () => {
          Navigator.pop(context, iconInfo),
          _onMapCreated(_controller),
        },
        child: Text("Avbryt"),
      );
    });
  }
}

class CarIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var iconInfo = Provider.of<IconInfo>(context);
    return IconButton(
        iconSize: 50,
        icon: Icon(
          Icons.directions_car,
          color: iconInfo.carToggled ? Colors.orangeAccent : Colors.grey,
        ),
        onPressed: () {
          iconInfo.car = !iconInfo.carToggled;

          bool truckValue = iconInfo.truckToggled;
          if (truckValue) iconInfo.truck = !truckValue;

          bool motorcycleValue = iconInfo.motorcycleToggled;
          if (motorcycleValue) iconInfo.motorcycle = !motorcycleValue;
        });
  }
}

class TruckIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var iconInfo = Provider.of<IconInfo>(context);
    return IconButton(
        iconSize: 50,
        icon: Icon(
          MdiIcons.truck,
          color: iconInfo.truckToggled ? Colors.orangeAccent : Colors.grey,
        ),
        onPressed: () {
          iconInfo.truck = !iconInfo.truckToggled;

          bool carValue = iconInfo.carToggled;
          if (carValue) iconInfo.car = !carValue;

          bool motorcycleValue = iconInfo.truckToggled;
          if (motorcycleValue) iconInfo.motorcycle = !motorcycleValue;
        });
  }
}

class MotorcycleIconButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var iconInfo = Provider.of<IconInfo>(context);
    return IconButton(
        iconSize: 50,
        icon: Icon(
          Icons.motorcycle,
          color: iconInfo.motorcycleToggled ? Colors.orangeAccent : Colors.grey,
        ),
        onPressed: () {
          iconInfo.motorcycle = !iconInfo.motorcycleToggled;

          bool carValue = iconInfo.carToggled;
          if (carValue) iconInfo.car = !carValue;

          bool truckValue = iconInfo.truckToggled;
          if (truckValue) iconInfo.truck = !truckValue;
        });
  }
}
