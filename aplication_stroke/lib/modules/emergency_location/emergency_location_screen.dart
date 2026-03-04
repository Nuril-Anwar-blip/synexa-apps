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
  // -------------------------------
  // 🔥 GANTI API KEY DI SINI
  // -------------------------------
  static const String apiKey = "AIzaSyBggaOmseqyHiiS7KYgOwquqXkdXJgc5dY";

  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLatLng;

  bool _loadingLocation = true;
  bool _loadingPlaces = false;
  String? _error;

  final Set<Marker> _markers = {};
  final List<_HospitalPlace> _places = [];

  static const LatLng fallbackCenter = LatLng(-6.1754, 106.8272);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    debugPrint("SOS: Initializing EmergencyLocationScreen...");
    await _getLocation();
    if (_currentLatLng != null) {
      debugPrint("SOS: Location found, fetching hospitals...");
      await _fetchHospitalsGuaranteed();
    } else {
      debugPrint("SOS: Failed to obtain current location.");
    }
  }

  // ================================
  // 📍 AMBIL LOKASI
  // ================================
  Future<void> _getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _error = "Layanan lokasi perangkat nonaktif.";
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
          distanceFilter: 10,
        ),
      );
      _currentLatLng = LatLng(pos.latitude, pos.longitude);

      // Log to database
      _logEmergency(pos.latitude, pos.longitude);

      _markers.add(
        Marker(
          markerId: const MarkerId("you"),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: "Lokasi Anda"),
        ),
      );

      if (!mounted) return;
      setState(() => _loadingLocation = false);
      _animateTo(_currentLatLng!, zoom: 15);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _error = "Gagal mendapatkan lokasi: $e";
      });
    }
  }

  Future<void> _logEmergency(double lat, double lng) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('emergency_logs').insert({
        'user_id': user.id,
        'location_lat': lat,
        'location_long': lng,
        'status': 'active',
      });
      debugPrint("SOS: Emergency log created for user ${user.id}");
    } catch (e) {
      debugPrint("SOS: Failed to log emergency: $e");
    }
  }

  /// Metode utama untuk mengambil daftar rumah sakit terdekat dengan strategi fallback.
  Future<void> _fetchHospitalsGuaranteed() async {
    setState(() {
      _loadingPlaces = true;
      _error = null;
    });

    debugPrint("SOS: Memulai Pencarian Utama (Text Search)...");
    
    // STRATEGI: Menggunakan kueri yang lebih luas untuk mencakup berbagai fasilitas medis di Indonesia.
    final queries = ["Rumah Sakit", "RS", "Puskesmas", "Klinik"];
    List<_HospitalPlace> combinedResults = [];

    for (final q in queries) {
      final results = await _searchByText(query: q);
      combinedResults.addAll(results);
      if (combinedResults.length >= 10) break; // Jika sudah cukup, hentikan pencarian
    }

    if (combinedResults.isNotEmpty) {
      // Hapus duplikat berdasarkan nama
      final seen = <String>{};
      _places.clear();
      _places.addAll(combinedResults.where((p) => seen.add(p.name)));
      
      debugPrint("SOS: Text Search berhasil (${_places.length} tempat ditemukan)");
      setState(() => _loadingPlaces = false);
      return;
    }

    debugPrint("SOS: Text Search gagal, mencoba Nearby Search (Fallback)...");
    final tier1Results = await _searchNearby(
      types: ["hospital", "medical_clinic", "doctor", "health_care_provider", "health"],
    );

    if (tier1Results.isNotEmpty) {
      _places.clear();
      _places.addAll(tier1Results);
      debugPrint("SOS: Nearby Search berhasil (${tier1Results.length} tempat ditemukan)");
      setState(() => _loadingPlaces = false);
      return;
    }

    setState(() {
      _loadingPlaces = false;
      _error = "TIDAK ADA HASIL DITEMUKAN\n"
          "----------------------------------\n"
          "Lokasi: ${_currentLatLng?.latitude}, ${_currentLatLng?.longitude}\n"
          "Radius: 20km\n"
          "----------------------------------\n"
          "Tips:\n"
          "1. Pastikan GPS/Layanan Lokasi aktif.\n"
          "2. Pastikan koneksi internet stabil.\n"
          "3. Coba 'Hot Restart' aplikasi jika masalah berlanjut.";
    });
  }

  // =============================================================
  // 🔥 FUNCTION PLACES API NEW v1
  // =============================================================
  Future<List<_HospitalPlace>> _searchNearby({
    required List<String> types,
  }) async {
    if (_currentLatLng == null) return [];

    final url = Uri.parse(
      "https://places.googleapis.com/v1/places:searchNearby",
    );

    final payload = {
      "includedTypes": types,
      "languageCode": "id",
      "maxResultCount": 20,
      "rankPreference": "DISTANCE", // Cari yang benar-benar TERDEKAT
      "locationRestriction": {
        "circle": {
          "center": {
            "latitude": _currentLatLng!.latitude,
            "longitude": _currentLatLng!.longitude,
          },
          "radius": 20000.0, // Jangkauan dibatasi hingga 20km sesuai permintaan
        },
      },
    };

    final headers = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask":
          "places.displayName,places.formattedAddress,places.location,places.rating,places.nationalPhoneNumber",
    };

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200) {
        debugPrint("SOS: Nearby Search Error ${res.statusCode}: ${res.body}");
        if (mounted) {
          setState(() {
            _error = "API Error (Nearby): ${res.statusCode}\nDetail: ${res.body}";
          });
        }
        return [];
      }

      final decoded = jsonDecode(res.body);

      if (decoded["places"] == null) return [];

      final List<_HospitalPlace> result = [];

      for (final p in decoded["places"]) {
        final loc = p["location"];
        result.add(
          _HospitalPlace.fromApi(
            p,
            LatLng(
              (loc["latitude"] as num).toDouble(),
              (loc["longitude"] as num).toDouble(),
            ),
            _currentLatLng!,
          ),
        );
      }

      result.sort((a, b) => a.distance.compareTo(b.distance));

      // update markers
      for (final hospital in result) {
        _markers.add(
          Marker(
            markerId: MarkerId(hospital.name),
            position: hospital.location,
            infoWindow: InfoWindow(
              title: hospital.name,
              snippet:
                  "${(hospital.distance / 1000).toStringAsFixed(2)} km • ${hospital.address}",
            ),
          ),
        );
      }

      if (mounted) setState(() {});
      return result;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat tempat: $e";
        });
      }
      return [];
    }
  }

  // =============================================================
  // 🔍 TEXT SEARCH New (v1)
  // Untuk mencari institusi berdasarkan nama "Rumah Sakit"
  // =============================================================
  Future<List<_HospitalPlace>> _searchByText({
    required String query,
  }) async {
    if (_currentLatLng == null) return [];

    final url = Uri.parse("https://places.googleapis.com/v1/places:searchText");

    final payload = {
      "textQuery": query,
      "languageCode": "id",
      "locationBias": {
        "circle": {
          "center": {
            "latitude": _currentLatLng!.latitude,
            "longitude": _currentLatLng!.longitude,
          },
          "radius": 20000.0, // Diperbarui menjadi 20km sesuai permintaan
        },
      },
    };

    final headers = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask":
          "places.displayName,places.formattedAddress,places.location,places.rating,places.nationalPhoneNumber",
    };

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200) {
        debugPrint("SOS: Text Search Error ${res.statusCode}: ${res.body}");
        return [];
      }

      final decoded = jsonDecode(res.body);
      if (decoded["places"] == null) return [];

      final List<_HospitalPlace> result = [];
      for (final p in decoded["places"]) {
        final loc = p["location"];
        result.add(
          _HospitalPlace.fromApi(
            p,
            LatLng(
              (loc["latitude"] as num).toDouble(),
              (loc["longitude"] as num).toDouble(),
            ),
            _currentLatLng!,
          ),
        );
      }

      // Sync markers
      for (final hospital in result) {
        _markers.add(
          Marker(
            markerId: MarkerId(hospital.name),
            position: hospital.location,
            infoWindow: InfoWindow(
              title: hospital.name,
              snippet:
                  "${(hospital.distance / 1000).toStringAsFixed(2)} km • ${hospital.address}",
            ),
          ),
        );
      }

      if (mounted) setState(() {});
      return result;
    } catch (e) {
      debugPrint("SOS: TextSearch error: $e");
      return [];
    }
  }

  // =============================================================
  Future<void> _animateTo(LatLng target, {double zoom = 15}) async {
    if (!_mapController.isCompleted) return;
    final c = await _mapController.future;
    c.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _openGoogleMaps(LatLng loc) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}&travelmode=driving",
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka Maps: $e')));
      }
    }
  }

  Future<void> _routeToNearest() async {
    try {
      if (_places.isEmpty) {
        await _fetchHospitalsGuaranteed();
      }
      if (_places.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ditemukan RS terdekat')),
          );
        }
        return;
      }
      await _openGoogleMaps(_places.first.location);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka rute: $e')));
      }
    }
  }

  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rumah Sakit Terdekat")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: fallbackCenter,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            onMapCreated: (c) {
              debugPrint("SOS: Map created successfully.");
              if (!_mapController.isCompleted) {
                _mapController.complete(c);
              }
            },
          ),

          if (_loadingLocation || _loadingPlaces)
            Container(
              color: Colors.white70,
              child: const Center(child: CircularProgressIndicator()),
            ),

          if (_error != null)
            Positioned(
              top: 30,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

          if (_places.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _HospitalList(
                places: _places,
                onNavigate: (p) => _openGoogleMaps(p.location),
                onSelect: (p) => _animateTo(p.location),
                onCall: (p) async {
                  final phone = p.phoneNumber;
                  if (phone == null || phone.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nomor telepon rumah sakit tidak tersedia',
                        ),
                      ),
                    );
                    return;
                  }
                  final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
                  await launchUrl(uri);
                },
              ),
            ),
          Positioned(
            right: 16,
            bottom: _places.isNotEmpty ? 270 : 16,
            child: FloatingActionButton.extended(
              onPressed: _routeToNearest,
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Rute RS Terdekat'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// MODEL
// =============================================================
class _HospitalPlace {
  final String name;
  final String address;
  final LatLng location;
  final double distance;
  final String? phoneNumber;

  _HospitalPlace({
    required this.name,
    required this.address,
    required this.location,
    required this.distance,
    this.phoneNumber,
  });

  factory _HospitalPlace.fromApi(
    Map<String, dynamic> json,
    LatLng coord,
    LatLng origin,
  ) {
    double dist = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      coord.latitude,
      coord.longitude,
    );

    final dn = json["displayName"];
    final name = dn is Map && dn["text"] is String
        ? (dn["text"] as String)
        : (dn?.toString() ?? "Tanpa Nama");
    final address =
        json["formattedAddress"]?.toString() ?? "Alamat tidak tersedia";
    final phone = json["nationalPhoneNumber"]?.toString();

    return _HospitalPlace(
      name: name,
      address: address,
      location: coord,
      distance: dist,
      phoneNumber: phone,
    );
  }
}

// =============================================================
// LIST WIDGET
// =============================================================
class _HospitalList extends StatelessWidget {
  final List<_HospitalPlace> places;
  final void Function(_HospitalPlace) onNavigate;
  final void Function(_HospitalPlace) onSelect;
  final void Function(_HospitalPlace) onCall;

  const _HospitalList({
    required this.places,
    required this.onNavigate,
    required this.onSelect,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: Colors.white,
      child: ListView.builder(
        itemCount: places.length,
        itemBuilder: (context, i) {
          final p = places[i];
          return ListTile(
            title: Text(p.name),
            subtitle: Text(
              "${(p.distance / 1000).toStringAsFixed(2)} km • ${p.address}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call_rounded, color: Colors.green),
                  onPressed: () => onCall(p),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.blue,
                  ),
                  onPressed: () => onNavigate(p),
                ),
              ],
            ),
            onTap: () => onSelect(p),
          );
        },
      ),
    );
  }
}

