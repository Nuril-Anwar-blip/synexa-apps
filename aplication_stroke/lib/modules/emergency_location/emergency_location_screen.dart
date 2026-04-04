// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';

// class EmergencyLocationScreen extends StatefulWidget {
//   const EmergencyLocationScreen({super.key});

//   @override
//   State<EmergencyLocationScreen> createState() =>
//       _EmergencyLocationScreenState();
// }

// class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
//   // -------------------------------
//   // 🔥 GANTI API KEY DI SINI
//   // -------------------------------
//   static const String apiKey = "AIzaSyBggaOmseqyHiiS7KYgOwquqXkdXJgc5dY";

//   final Completer<GoogleMapController> _mapController = Completer();
//   LatLng? _currentLatLng;

//   bool _loadingLocation = true;
//   bool _loadingPlaces = false;
//   String? _error;

//   final Set<Marker> _markers = {};
//   final List<_HospitalPlace> _places = [];

//   static const LatLng fallbackCenter = LatLng(-6.1754, 106.8272);

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     debugPrint("SOS: Initializing EmergencyLocationScreen...");
//     await _getLocation();
//     if (_currentLatLng != null) {
//       debugPrint("SOS: Location found, fetching hospitals...");
//       await _fetchHospitalsGuaranteed();
//     } else {
//       debugPrint("SOS: Failed to obtain current location.");
//     }
//   }

//   // ================================
//   // 📍 AMBIL LOKASI
//   // ================================
//   Future<void> _getLocation() async {
//     try {
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         if (!mounted) return;
//         setState(() {
//           _loadingLocation = false;
//           _error = "Layanan lokasi perangkat nonaktif.";
//         });
//         return;
//       }

//       LocationPermission perm = await Geolocator.checkPermission();
//       if (perm == LocationPermission.denied ||
//           perm == LocationPermission.deniedForever) {
//         perm = await Geolocator.requestPermission();
//       }

//       final pos = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//           distanceFilter: 10,
//         ),
//       );
//       _currentLatLng = LatLng(pos.latitude, pos.longitude);

//       // Log to database
//       _logEmergency(pos.latitude, pos.longitude);

//       _markers.add(
//         Marker(
//           markerId: const MarkerId("you"),
//           position: _currentLatLng!,
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueAzure,
//           ),
//           infoWindow: const InfoWindow(title: "Lokasi Anda"),
//         ),
//       );

//       if (!mounted) return;
//       setState(() => _loadingLocation = false);
//       _animateTo(_currentLatLng!, zoom: 15);
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _loadingLocation = false;
//         _error = "Gagal mendapatkan lokasi: $e";
//       });
//     }
//   }

//   Future<void> _logEmergency(double lat, double lng) async {
//     final supabase = Supabase.instance.client;
//     final user = supabase.auth.currentUser;
//     if (user == null) return;

//     try {
//       await supabase.from('emergency_logs').insert({
//         'user_id': user.id,
//         'location_lat': lat,
//         'location_long': lng,
//         'status': 'active',
//       });
//       debugPrint("SOS: Emergency log created for user ${user.id}");
//     } catch (e) {
//       debugPrint("SOS: Failed to log emergency: $e");
//     }
//   }

//   /// Metode utama untuk mengambil daftar rumah sakit terdekat dengan strategi fallback.
//   Future<void> _fetchHospitalsGuaranteed() async {
//     setState(() {
//       _loadingPlaces = true;
//       _error = null;
//     });

//     debugPrint("SOS: Memulai Pencarian Utama (Text Search)...");

//     // STRATEGI: Menggunakan kueri yang lebih luas untuk mencakup berbagai fasilitas medis di Indonesia.
//     final queries = ["Rumah Sakit", "RS", "Puskesmas", "Klinik"];
//     List<_HospitalPlace> combinedResults = [];

//     for (final q in queries) {
//       final results = await _searchByText(query: q);
//       combinedResults.addAll(results);
//       if (combinedResults.length >= 10) break; // Jika sudah cukup, hentikan pencarian
//     }

//     if (combinedResults.isNotEmpty) {
//       // Hapus duplikat berdasarkan nama
//       final seen = <String>{};
//       _places.clear();
//       _places.addAll(combinedResults.where((p) => seen.add(p.name)));

//       debugPrint("SOS: Text Search berhasil (${_places.length} tempat ditemukan)");
//       setState(() => _loadingPlaces = false);
//       return;
//     }

//     debugPrint("SOS: Text Search gagal, mencoba Nearby Search (Fallback)...");
//     final tier1Results = await _searchNearby(
//       types: ["hospital", "medical_clinic", "doctor", "health_care_provider", "health"],
//     );

//     if (tier1Results.isNotEmpty) {
//       _places.clear();
//       _places.addAll(tier1Results);
//       debugPrint("SOS: Nearby Search berhasil (${tier1Results.length} tempat ditemukan)");
//       setState(() => _loadingPlaces = false);
//       return;
//     }

//     setState(() {
//       _loadingPlaces = false;
//       _error = "TIDAK ADA HASIL DITEMUKAN\n"
//           "----------------------------------\n"
//           "Lokasi: ${_currentLatLng?.latitude}, ${_currentLatLng?.longitude}\n"
//           "Radius: 20km\n"
//           "----------------------------------\n"
//           "Tips:\n"
//           "1. Pastikan GPS/Layanan Lokasi aktif.\n"
//           "2. Pastikan koneksi internet stabil.\n"
//           "3. Coba 'Hot Restart' aplikasi jika masalah berlanjut.";
//     });
//   }

//   // =============================================================
//   // 🔥 FUNCTION PLACES API NEW v1
//   // =============================================================
//   Future<List<_HospitalPlace>> _searchNearby({
//     required List<String> types,
//   }) async {
//     if (_currentLatLng == null) return [];

//     final url = Uri.parse(
//       "https://places.googleapis.com/v1/places:searchNearby",
//     );

//     final payload = {
//       "includedTypes": types,
//       "languageCode": "id",
//       "maxResultCount": 20,
//       "rankPreference": "DISTANCE", // Cari yang benar-benar TERDEKAT
//       "locationRestriction": {
//         "circle": {
//           "center": {
//             "latitude": _currentLatLng!.latitude,
//             "longitude": _currentLatLng!.longitude,
//           },
//           "radius": 20000.0, // Jangkauan dibatasi hingga 20km sesuai permintaan
//         },
//       },
//     };

//     final headers = {
//       "Content-Type": "application/json",
//       "X-Goog-Api-Key": apiKey,
//       "X-Goog-FieldMask":
//           "places.displayName,places.formattedAddress,places.location,places.rating,places.nationalPhoneNumber",
//     };

//     try {
//       final res = await http.post(
//         url,
//         headers: headers,
//         body: jsonEncode(payload),
//       );
//       if (res.statusCode != 200) {
//         debugPrint("SOS: Nearby Search Error ${res.statusCode}: ${res.body}");
//         if (mounted) {
//           setState(() {
//             _error = "API Error (Nearby): ${res.statusCode}\nDetail: ${res.body}";
//           });
//         }
//         return [];
//       }

//       final decoded = jsonDecode(res.body);

//       if (decoded["places"] == null) return [];

//       final List<_HospitalPlace> result = [];

//       for (final p in decoded["places"]) {
//         final loc = p["location"];
//         result.add(
//           _HospitalPlace.fromApi(
//             p,
//             LatLng(
//               (loc["latitude"] as num).toDouble(),
//               (loc["longitude"] as num).toDouble(),
//             ),
//             _currentLatLng!,
//           ),
//         );
//       }

//       result.sort((a, b) => a.distance.compareTo(b.distance));

//       // update markers
//       for (final hospital in result) {
//         _markers.add(
//           Marker(
//             markerId: MarkerId(hospital.name),
//             position: hospital.location,
//             infoWindow: InfoWindow(
//               title: hospital.name,
//               snippet:
//                   "${(hospital.distance / 1000).toStringAsFixed(2)} km • ${hospital.address}",
//             ),
//           ),
//         );
//       }

//       if (mounted) setState(() {});
//       return result;
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _error = "Gagal memuat tempat: $e";
//         });
//       }
//       return [];
//     }
//   }

//   // =============================================================
//   // 🔍 TEXT SEARCH New (v1)
//   // Untuk mencari institusi berdasarkan nama "Rumah Sakit"
//   // =============================================================
//   Future<List<_HospitalPlace>> _searchByText({
//     required String query,
//   }) async {
//     if (_currentLatLng == null) return [];

//     final url = Uri.parse("https://places.googleapis.com/v1/places:searchText");

//     final payload = {
//       "textQuery": query,
//       "languageCode": "id",
//       "locationBias": {
//         "circle": {
//           "center": {
//             "latitude": _currentLatLng!.latitude,
//             "longitude": _currentLatLng!.longitude,
//           },
//           "radius": 20000.0, // Diperbarui menjadi 20km sesuai permintaan
//         },
//       },
//     };

//     final headers = {
//       "Content-Type": "application/json",
//       "X-Goog-Api-Key": apiKey,
//       "X-Goog-FieldMask":
//           "places.displayName,places.formattedAddress,places.location,places.rating,places.nationalPhoneNumber",
//     };

//     try {
//       final res = await http.post(
//         url,
//         headers: headers,
//         body: jsonEncode(payload),
//       );
//       if (res.statusCode != 200) {
//         debugPrint("SOS: Text Search Error ${res.statusCode}: ${res.body}");
//         return [];
//       }

//       final decoded = jsonDecode(res.body);
//       if (decoded["places"] == null) return [];

//       final List<_HospitalPlace> result = [];
//       for (final p in decoded["places"]) {
//         final loc = p["location"];
//         result.add(
//           _HospitalPlace.fromApi(
//             p,
//             LatLng(
//               (loc["latitude"] as num).toDouble(),
//               (loc["longitude"] as num).toDouble(),
//             ),
//             _currentLatLng!,
//           ),
//         );
//       }

//       // Sync markers
//       for (final hospital in result) {
//         _markers.add(
//           Marker(
//             markerId: MarkerId(hospital.name),
//             position: hospital.location,
//             infoWindow: InfoWindow(
//               title: hospital.name,
//               snippet:
//                   "${(hospital.distance / 1000).toStringAsFixed(2)} km • ${hospital.address}",
//             ),
//           ),
//         );
//       }

//       if (mounted) setState(() {});
//       return result;
//     } catch (e) {
//       debugPrint("SOS: TextSearch error: $e");
//       return [];
//     }
//   }

//   // =============================================================
//   Future<void> _animateTo(LatLng target, {double zoom = 15}) async {
//     if (!_mapController.isCompleted) return;
//     final c = await _mapController.future;
//     c.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
//   }

//   Future<void> _openGoogleMaps(LatLng loc) async {
//     final uri = Uri.parse(
//       "https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}&travelmode=driving",
//     );
//     try {
//       final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
//       if (!ok && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Gagal membuka Maps: $e')));
//       }
//     }
//   }

//   Future<void> _routeToNearest() async {
//     try {
//       if (_places.isEmpty) {
//         await _fetchHospitalsGuaranteed();
//       }
//       if (_places.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Tidak ditemukan RS terdekat')),
//           );
//         }
//         return;
//       }
//       await _openGoogleMaps(_places.first.location);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Gagal membuka rute: $e')));
//       }
//     }
//   }

//   // =============================================================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Rumah Sakit Terdekat")),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: const CameraPosition(
//               target: fallbackCenter,
//               zoom: 13,
//             ),
//             markers: _markers,
//             myLocationEnabled: true,
//             onMapCreated: (c) {
//               debugPrint("SOS: Map created successfully.");
//               if (!_mapController.isCompleted) {
//                 _mapController.complete(c);
//               }
//             },
//           ),

//           if (_loadingLocation || _loadingPlaces)
//             Container(
//               color: Colors.white70,
//               child: const Center(child: CircularProgressIndicator()),
//             ),

//           if (_error != null)
//             Positioned(
//               top: 30,
//               left: 20,
//               right: 20,
//               child: Material(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 child: ListTile(
//                   leading: const Icon(Icons.warning, color: Colors.red),
//                   title: Text(
//                     _error!,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                 ),
//               ),
//             ),

//           if (_places.isNotEmpty)
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: _HospitalList(
//                 places: _places,
//                 onNavigate: (p) => _openGoogleMaps(p.location),
//                 onSelect: (p) => _animateTo(p.location),
//                 onCall: (p) async {
//                   final phone = p.phoneNumber;
//                   if (phone == null || phone.trim().isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                           'Nomor telepon rumah sakit tidak tersedia',
//                         ),
//                       ),
//                     );
//                     return;
//                   }
//                   final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
//                   await launchUrl(uri);
//                 },
//               ),
//             ),
//           Positioned(
//             right: 16,
//             bottom: _places.isNotEmpty ? 270 : 16,
//             child: FloatingActionButton.extended(
//               onPressed: _routeToNearest,
//               icon: const Icon(Icons.navigation_rounded),
//               label: const Text('Rute RS Terdekat'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =============================================================
// // MODEL
// // =============================================================
// class _HospitalPlace {
//   final String name;
//   final String address;
//   final LatLng location;
//   final double distance;
//   final String? phoneNumber;

//   _HospitalPlace({
//     required this.name,
//     required this.address,
//     required this.location,
//     required this.distance,
//     this.phoneNumber,
//   });

//   factory _HospitalPlace.fromApi(
//     Map<String, dynamic> json,
//     LatLng coord,
//     LatLng origin,
//   ) {
//     double dist = Geolocator.distanceBetween(
//       origin.latitude,
//       origin.longitude,
//       coord.latitude,
//       coord.longitude,
//     );

//     final dn = json["displayName"];
//     final name = dn is Map && dn["text"] is String
//         ? (dn["text"] as String)
//         : (dn?.toString() ?? "Tanpa Nama");
//     final address =
//         json["formattedAddress"]?.toString() ?? "Alamat tidak tersedia";
//     final phone = json["nationalPhoneNumber"]?.toString();

//     return _HospitalPlace(
//       name: name,
//       address: address,
//       location: coord,
//       distance: dist,
//       phoneNumber: phone,
//     );
//   }
// }

// // =============================================================
// // LIST WIDGET
// // =============================================================
// class _HospitalList extends StatelessWidget {
//   final List<_HospitalPlace> places;
//   final void Function(_HospitalPlace) onNavigate;
//   final void Function(_HospitalPlace) onSelect;
//   final void Function(_HospitalPlace) onCall;

//   const _HospitalList({
//     required this.places,
//     required this.onNavigate,
//     required this.onSelect,
//     required this.onCall,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 260,
//       color: Colors.white,
//       child: ListView.builder(
//         itemCount: places.length,
//         itemBuilder: (context, i) {
//           final p = places[i];
//           return ListTile(
//             title: Text(p.name),
//             subtitle: Text(
//               "${(p.distance / 1000).toStringAsFixed(2)} km • ${p.address}",
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.call_rounded, color: Colors.green),
//                   onPressed: () => onCall(p),
//                 ),
//                 IconButton(
//                   icon: const Icon(
//                     Icons.navigation_rounded,
//                     color: Colors.blue,
//                   ),
//                   onPressed: () => onNavigate(p),
//                 ),
//               ],
//             ),
//             onTap: () => onSelect(p),
//           );
//         },
//       ),
//     );
//   }
// }

// ====================================================================
// File: emergency_location_screen.dart — Fixed hospital display + better UI
// FIX: Ganti Places API v1 (New) agar RS terdekat tampil dengan benar
// ====================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyLocationScreen extends StatefulWidget {
  const EmergencyLocationScreen({super.key});

  @override
  State<EmergencyLocationScreen> createState() =>
      _EmergencyLocationScreenState();
}

class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
  static const String _apiKey = "AIzaSyBggaOmseqyHiiS7KYgOwquqXkdXJgc5dY";
  static const LatLng _fallback = LatLng(-6.1754, 106.8272);

  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  final List<_HospitalPlace> _places = [];

  bool _loadingLocation = true;
  bool _loadingPlaces = false;
  String? _statusMessage;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getLocation();
    if (_currentLatLng != null) await _fetchHospitals();
  }

  Future<void> _getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _statusMessage = 'Aktifkan layanan lokasi perangkat.';
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentLatLng = LatLng(pos.latitude, pos.longitude);

      // Log emergency ke Supabase
      _logEmergency(pos.latitude, pos.longitude);

      _markers.add(
        Marker(
          markerId: const MarkerId('you'),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: '📍 Lokasi Saya'),
        ),
      );

      if (!mounted) return;
      setState(() => _loadingLocation = false);
      _animateTo(_currentLatLng!, zoom: 15);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _statusMessage = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  Future<void> _logEmergency(double lat, double lng) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('emergency_logs').insert({
        'user_id': user.id,
        'location_lat': lat,
        'location_long': lng,
        'status': 'active',
      });
    } catch (_) {}
  }

  // FIX: Gunakan Places API (Legacy) yang lebih kompatibel dengan Android/iOS
  Future<void> _fetchHospitals() async {
    if (_currentLatLng == null) return;
    setState(() {
      _loadingPlaces = true;
      _statusMessage = null;
    });

    try {
      // Coba Text Search dulu (lebih akurat untuk Indonesia)
      final textResults = await _textSearch('Rumah Sakit');
      if (textResults.isNotEmpty) {
        _applyResults(textResults);
        setState(() => _loadingPlaces = false);
        return;
      }

      // Fallback: Nearby Search
      final nearbyResults = await _nearbySearch();
      if (nearbyResults.isNotEmpty) {
        _applyResults(nearbyResults);
        setState(() => _loadingPlaces = false);
        return;
      }

      setState(() {
        _loadingPlaces = false;
        _statusMessage = 'Tidak ada rumah sakit ditemukan dalam radius 20km.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlaces = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  // Text Search — menggunakan Places API (non-v1) yang lebih stabil
  Future<List<_HospitalPlace>> _textSearch(String query) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
      '?query=${Uri.encodeComponent(query)}'
      '&location=${_currentLatLng!.latitude},${_currentLatLng!.longitude}'
      '&radius=20000'
      '&language=id'
      '&key=$_apiKey',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        debugPrint(
          'Text Search status: ${data['status']} — ${data['error_message']}',
        );
      }
      if (data['status'] != 'OK') return [];
      final results = data['results'] as List;
      return _parseTextResults(results);
    } catch (e) {
      debugPrint('Text Search error: $e');
      return [];
    }
  }

  // Nearby Search — fallback Places API
  Future<List<_HospitalPlace>> _nearbySearch() async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${_currentLatLng!.latitude},${_currentLatLng!.longitude}'
      '&radius=20000'
      '&type=hospital'
      '&language=id'
      '&key=$_apiKey',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return [];
      final results = data['results'] as List;
      return _parseNearbyResults(results);
    } catch (e) {
      debugPrint('Nearby Search error: $e');
      return [];
    }
  }

  List<_HospitalPlace> _parseTextResults(List results) {
    final list = <_HospitalPlace>[];
    for (final p in results) {
      final geo = p['geometry']?['location'];
      if (geo == null) continue;
      final lat = (geo['lat'] as num).toDouble();
      final lng = (geo['lng'] as num).toDouble();
      final coord = LatLng(lat, lng);
      final dist = Geolocator.distanceBetween(
        _currentLatLng!.latitude,
        _currentLatLng!.longitude,
        lat,
        lng,
      );
      list.add(
        _HospitalPlace(
          name: p['name']?.toString() ?? 'Rumah Sakit',
          address:
              p['formatted_address']?.toString() ??
              p['vicinity']?.toString() ??
              '',
          location: coord,
          distance: dist,
          placeId: p['place_id']?.toString(),
        ),
      );
    }
    list.sort((a, b) => a.distance.compareTo(b.distance));
    return list;
  }

  List<_HospitalPlace> _parseNearbyResults(List results) {
    final list = <_HospitalPlace>[];
    for (final p in results) {
      final geo = p['geometry']?['location'];
      if (geo == null) continue;
      final lat = (geo['lat'] as num).toDouble();
      final lng = (geo['lng'] as num).toDouble();
      final coord = LatLng(lat, lng);
      final dist = Geolocator.distanceBetween(
        _currentLatLng!.latitude,
        _currentLatLng!.longitude,
        lat,
        lng,
      );
      list.add(
        _HospitalPlace(
          name: p['name']?.toString() ?? 'Rumah Sakit',
          address: p['vicinity']?.toString() ?? '',
          location: coord,
          distance: dist,
          placeId: p['place_id']?.toString(),
        ),
      );
    }
    list.sort((a, b) => a.distance.compareTo(b.distance));
    return list;
  }

  void _applyResults(List<_HospitalPlace> results) {
    _places.clear();
    _places.addAll(results);
    for (int i = 0; i < _places.length; i++) {
      final h = _places[i];
      _markers.add(
        Marker(
          markerId: MarkerId('hospital_$i'),
          position: h.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: h.name,
            snippet: '${(h.distance / 1000).toStringAsFixed(1)} km',
          ),
          onTap: () => setState(() => _selectedIndex = i),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _animateTo(LatLng target, {double zoom = 15}) async {
    if (!_mapController.isCompleted) return;
    final c = await _mapController.future;
    c.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _openMaps(LatLng loc, String name) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}&destination_place_id=$name&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
    }
  }

  Future<void> _callHospital(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tidak tersedia')),
      );
      return;
    }
    await launchUrl(Uri.parse('tel:${phone.replaceAll(' ', '')}'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1923) : Colors.white,
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _fallback,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              if (!_mapController.isCompleted) _mapController.complete(c);
            },
            onTap: (_) => setState(() => _selectedIndex = -1),
          ),

          // Loading overlay
          if (_loadingLocation || _loadingPlaces)
            Container(
              color: Colors.black38,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _loadingLocation
                            ? 'Mendapatkan lokasi...'
                            : 'Mencari rumah sakit terdekat...',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // AppBar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_places.length} RS Terdekat Ditemukan',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_loadingPlaces)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Error banner
          if (_statusMessage != null)
            Positioned(
              top: 80,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.red,
                      onPressed: _fetchHospitals,
                    ),
                  ],
                ),
              ),
            ),

          // Hospital list bottom
          if (_places.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Route to nearest FAB
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 16, 8),
                      child: FloatingActionButton.extended(
                        onPressed: _places.isNotEmpty
                            ? () => _openMaps(
                                _places.first.location,
                                _places.first.name,
                              )
                            : null,
                        backgroundColor: Colors.red.shade600,
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text(
                          'Rute Terdekat',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  _HospitalListSheet(
                    places: _places,
                    selectedIndex: _selectedIndex,
                    onSelect: (i) {
                      setState(() => _selectedIndex = i);
                      _animateTo(_places[i].location, zoom: 17);
                    },
                    onNavigate: (p) => _openMaps(p.location, p.name),
                    onCall: (p) => _callHospital(p.phone),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Hospital List Sheet ────────────────────────────────────────────────────
class _HospitalListSheet extends StatelessWidget {
  const _HospitalListSheet({
    required this.places,
    required this.selectedIndex,
    required this.onSelect,
    required this.onNavigate,
    required this.onCall,
  });

  final List<_HospitalPlace> places;
  final int selectedIndex;
  final void Function(int) onSelect;
  final void Function(_HospitalPlace) onNavigate;
  final void Function(_HospitalPlace) onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${places.length} Rumah Sakit Ditemukan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              scrollDirection: Axis.vertical,
              itemCount: places.length,
              itemBuilder: (_, i) {
                final p = places[i];
                final sel = selectedIndex == i;
                final distKm = (p.distance / 1000).toStringAsFixed(1);
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? Colors.red.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? Colors.red.shade300 : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.red.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_hospital_rounded,
                            color: sel
                                ? Colors.red.shade600
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: sel
                                      ? Colors.red.shade700
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$distKm km',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (p.address.isNotEmpty) ...[
                                    const Text(
                                      ' · ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Expanded(
                                      child: Text(
                                        p.address,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            _iconBtn(
                              Icons.navigation_rounded,
                              Colors.blue,
                              () => onNavigate(p),
                            ),
                            const SizedBox(width: 4),
                            _iconBtn(
                              Icons.call_rounded,
                              Colors.green,
                              () => onCall(p),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _HospitalPlace {
  final String name;
  final String address;
  final LatLng location;
  final double distance;
  final String? placeId;
  final String? phone;

  const _HospitalPlace({
    required this.name,
    required this.address,
    required this.location,
    required this.distance,
    this.placeId,
    this.phone,
  });
}
