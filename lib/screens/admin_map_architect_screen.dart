import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/geo_recording.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_box.dart';
import '../widgets/cached_tile_provider.dart';
import 'package:flutter/services.dart';

class AdminMapArchitectScreen extends ConsumerStatefulWidget {
  const AdminMapArchitectScreen({super.key});

  @override
  ConsumerState<AdminMapArchitectScreen> createState() => _AdminMapArchitectScreenState();
}

class _AdminMapArchitectScreenState extends ConsumerState<AdminMapArchitectScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isSatellite = true;

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    _showEditDialog(latLng);
  }

  void _showEditDialog([LatLng? location, GeoRecording? existing]) {
    final nameController = TextEditingController(text: existing?.title ?? '');
    final provinceController = TextEditingController(text: existing?.province ?? 'Davao Region');
    RecordingLanguage selectedLang = existing?.language ?? RecordingLanguage.mansaka;
    final lat = location?.latitude ?? existing?.location.latitude ?? 0.0;
    final lng = location?.longitude ?? existing?.location.longitude ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.forest900,
          title: Text(
            existing == null ? 'Add Cultural Site' : 'Edit Cultural Site',
            style: AppTypography.h3.copyWith(color: AppColors.gold500),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Site/Municipality Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: provinceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Province'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RecordingLanguage>(
                  initialValue: selectedLang,
                  dropdownColor: AppColors.forest800,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Primary Dialect'),
                  items: RecordingLanguage.values.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedLang = val!),
                ),
                const SizedBox(height: 16),
                Text(
                  "Coordinates: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}",
                  style: AppTypography.label.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
            ),
            if (existing != null)
              TextButton(
                onPressed: () => _deleteMunicipality(existing.id),
                child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
              onPressed: () {
                final data = {
                  'name': nameController.text,
                  'province': provinceController.text,
                  'dialect': selectedLang.name,
                  'coords': GeoPoint(lat, lng),
                  'status': 'validated',
                };
                if (existing == null) {
                  _addMunicipality(data);
                } else {
                  _updateMunicipality(existing.id, data);
                }
                Navigator.pop(context);
              },
              child: Text(
                existing == null ? 'CREATE' : 'SAVE',
                style: const TextStyle(color: AppColors.forest900, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gold500),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold500)),
    );
  }

  Future<void> _addMunicipality(Map<String, dynamic> data) async {
    try {
      await ref.read(firebaseServiceProvider).addMunicipality(data);
      _showSnackBar('Cultural site added successfully!');
    } catch (e) {
      _showSnackBar('Error adding site: $e');
    }
  }

  Future<void> _updateMunicipality(String id, Map<String, dynamic> data) async {
    try {
      await ref.read(firebaseServiceProvider).updateMunicipality(id, data);
      _showSnackBar('Cultural site updated!');
    } catch (e) {
      _showSnackBar('Error updating site: $e');
    }
  }

  Future<void> _deleteMunicipality(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to remove this cultural site?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(firebaseServiceProvider).deleteMunicipality(id);
        if (mounted) Navigator.pop(context);
        _showSnackBar('Site removed.');
      } catch (e) {
        _showSnackBar('Error deleting site: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final municipalitiesAsync = ref.watch(mapMarkersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('MAP ARCHITECT', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
        backgroundColor: AppColors.forest900,
        actions: [
          IconButton(
            icon: Icon(_isSatellite ? Icons.map_outlined : Icons.satellite_alt_rounded),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(7.13, 125.90),
              initialZoom: 9.0,
              onTap: _handleMapTap,
            ),
            children: [
              if (_isSatellite)
                TileLayer(
                  urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.lumadlingua.app',
                  tileProvider: CachedTileProvider(),
                )
              else
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.lumadlingua.app',
                  tileProvider: CachedTileProvider(),
                ),

              municipalitiesAsync.when(
                data: (list) => MarkerLayer(
                  markers: list.map((m) => Marker(
                    point: m.location,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showEditDialog(null, m);
                      },
                      child: Column(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.gold500, size: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m.title,
                              style: const TextStyle(color: Colors.white, fontSize: 8),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),

              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GlassBox(
              borderRadius: 16,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "TAP ANYWHERE TO ADD A SITE",
                      style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap existing markers to edit or delete coordinates.",
                      style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
