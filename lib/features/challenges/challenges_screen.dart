import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentCenter = const LatLng(51.5072, -0.1276);
  List<Marker> _eventMarkers = [];
  bool _loading = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _searchLocation() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);

    try {
      final locations = await geo.locationFromAddress(text);

      if (locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not found")),
        );
        return;
      }

      final place = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      setState(() => _currentCenter = place);
      _mapController.move(place, 12);

      await _loadNearbyEvents(place);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadNearbyEvents(LatLng searchedPlace) async {
    final snap = await FirebaseFirestore.instance
        .collection('community_events')
        .get();

    final markers = <Marker>[];

    for (final doc in snap.docs) {
      final data = doc.data();

      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      final distance = _distanceKm(
        searchedPlace.latitude,
        searchedPlace.longitude,
        lat,
        lng,
      );

      if (distance <= 50) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => _showEventPopup(doc.id, data),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 42,
              ),
            ),
          ),
        );
      }
    }

    setState(() => _eventMarkers = markers);

    if (markers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No events found nearby")),
      );
    }
  }

  double _distanceKm(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const r = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * pi / 180;


  void _showEventPopup(String eventId, Map<String, dynamic> data) {
    final title = (data['title'] ?? 'Event').toString();
    final description = (data['description'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final date = (data['date'] ?? '').toString();
    final time = (data['time'] ?? '').toString();
    final url = (data['url'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text("$location\n$date • $time", textAlign: TextAlign.center),
              const SizedBox(height: 20),


              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: url.isEmpty
                      ? null
                      : () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text("Open Event Website"),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Back to Events"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFEAF3DF);
    const green = Color(0xFF2E6B3F);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          "Community Events",
          style: TextStyle(
              color: green,
              fontWeight: FontWeight.w800,
              fontFamily: "Poppins",
            ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 7,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.testapp",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentCenter,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.green,
                      size: 34,
                    ),
                  ),
                  ..._eventMarkers,
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchLocation(),
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loading ? null : _searchLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Go",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}