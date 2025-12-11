import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RestaurantMapScreen extends StatelessWidget {
  final double lat;
  final double lng;
  final String title;

  const RestaurantMapScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: MarkerId("restaurant"),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: title),
          )
        },
      ),
    );
  }
}
