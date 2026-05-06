import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/geo_recording.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_box.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/municipality_panel.dart';
import '../widgets/brand_button.dart';
import '../widgets/cached_tile_provider.dart';
import '../widgets/brand_search_bar.dart';

class ArchiveMapScreen extends ConsumerStatefulWidget {
  const ArchiveMapScreen({super.key});

  @override
  ConsumerState<ArchiveMapScreen> createState() => _ArchiveMapScreenState();
}

class _ArchiveMapScreenState extends ConsumerState<ArchiveMapScreen> {
  final MapController _mapController = MapController();
  GeoRecording? _selectedRecording;
  final Set<String> _favorites = {};
  String? _playingAudioId;
  final Set<RecordingLanguage> _selectedLanguages = {};
  String _searchQuery = '';
  bool _isSatellite = true;
  LatLng? _userLocation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingAudioId = null;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Map Layer
          ref
              .watch(mapMarkersStreamProvider)
              .when(
                data: (municipalities) {
                  final filtered = municipalities.where((rec) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        rec.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        rec.province.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        rec.language.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                    return matchesSearch;
                  }).toList();

                  return Stack(
                    children: [
                      _buildMap(filtered),
                      if (filtered.isEmpty && _searchQuery.isNotEmpty)
                        _buildEmptyState(
                          "No municipalities found matching '$_searchQuery'",
                        ),
                      if (filtered.isEmpty && _searchQuery.isEmpty)
                        _buildEmptyState(
                          "The archive is currently empty. Check back soon!",
                        ),
                    ],
                  );
                },
                loading: () => _buildLoadingOverlay(),
                error: (e, _) => Center(child: Text('Error loading map: $e')),
              ),

          // Top Search & Filter Bar
          Positioned(top: 120, left: 20, right: 20, child: _buildSearchBar()),

          // Floating Map Controls (Right Side)
          Positioned(
            right: 20,
            bottom: _selectedRecording != null
                ? 380
                : 100, // Move up if panel is open
            child: Column(
              children: [
                _buildMapControl(Icons.add_rounded, () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom + 1);
                }),
                const SizedBox(height: 12),
                _buildMapControl(Icons.remove_rounded, () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom - 1);
                }),
                const SizedBox(height: 12),
                _buildMapControl(
                  Icons.my_location,
                  () => _getCurrentLocation(),
                ),
                const SizedBox(height: 12),
                _buildMapControl(
                  _isSatellite
                      ? Icons.map_outlined
                      : Icons.satellite_alt_rounded,
                  () => setState(() => _isSatellite = !_isSatellite),
                ),
              ],
            ),
          ),

          // Selection Panel (Sheet)
          if (_selectedRecording != null)
            DraggableScrollableSheet(
              key: ValueKey(_selectedRecording!.id),
              initialChildSize: 0.45,
              minChildSize: 0.2,
              maxChildSize: 0.85,
              snap: true,
              builder: (sheetContext, scrollController) {
                return MunicipalityPanel(
                  rec: _selectedRecording!,
                  scrollController: scrollController,
                  favorites: _favorites,
                  playingAudioId: _playingAudioId,
                  duration: _duration,
                  position: _position,
                  onTogglePlay: (audio) => _handlePlayback(audio),
                  onSeek: (value) =>
                      _audioPlayer.seek(Duration(milliseconds: value.toInt())),
                  onToggleFavorite: (id) => setState(() {
                    if (_favorites.contains(id)) {
                      _favorites.remove(id);
                    } else {
                      _favorites.add(id);
                    }
                  }),
                  formatDuration: _formatDuration,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMap(List<GeoRecording> municipalities) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(7.13, 125.90), // Centered on Pantukan
        initialZoom: 10.0,
        onTap: (_, __) => setState(() => _selectedRecording = null),
      ),
      children: [
        if (_isSatellite)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              isDark
                  ? AppColors.forest900.withOpacity(0.5)
                  : const Color(0xFFD4B886).withOpacity(0.2),
              BlendMode.darken,
            ),
            child: TileLayer(
              urlTemplate:
                  'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'com.lumadlingua.app',
              tileProvider: CachedTileProvider(),
            ),
          )
        else
          TileLayer(
            urlTemplate: isDark
                ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.lumadlingua.app',
            tileProvider: CachedTileProvider(),
          ),

        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50),
            maxZoom: 15,
            markers: municipalities.map((rec) {
              final isSelected = _selectedRecording?.id == rec.id;
              return Marker(
                point: rec.location,
                width: 100,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _selectedRecording = rec);
                    _mapController.move(rec.location, 11.0);
                  },
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.gold500.withOpacity(0.4),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  end: const Offset(1.5, 1.5),
                                  duration: 1500.ms,
                                )
                                .fadeOut(duration: 1500.ms),
                          Container(
                            width: isSelected ? 24 : 16,
                            height: isSelected ? 24 : 16,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold500
                                  : AppColors.forest700,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.gold500,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.gold500.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.5),
                                  blurRadius: isSelected ? 15 : 5,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.blur_circular_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rec.title.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: AppColors.gold500,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.gold500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold500.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: AppTypography.label.copyWith(
                      color: AppColors.forest900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: AppColors.terracotta,
                  size: 32,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassBox(
        borderRadius: 25,
        blur: 15,
        opacity: 0.15,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: AppColors.gold500, size: 22),
        ),
      ),
    );
  }

  Future<void> _handlePlayback(Map<String, dynamic> audio) async {
    final audioUrl = audio['audioUrl'];
    if (audioUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio URL missing for this recording.'),
          ),
        );
      }
      return;
    }

    final isPlaying = _playingAudioId == audio['id'];
    HapticFeedback.lightImpact();

    try {
      if (isPlaying) {
        await _audioPlayer.pause();
        setState(() => _playingAudioId = null);
      } else {
        await _audioPlayer.play(UrlSource(audioUrl));
        setState(() => _playingAudioId = audio['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing ${audio['title'] ?? "Recording"}...'),
              backgroundColor: AppColors.forest900,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playback failed: $e')));
      }
    }
  }

  Widget _buildSearchBar() {
    return BrandSearchBar(
      hintText: 'Search municipalities or dialects...',
      showFilter: true,
      onFilterTap: _showFilterSheet,
      isMinimal: true,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
    );
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.forest900 : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Dialect',
                    style: AppTypography.h2.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RecordingLanguage.values.map((lang) {
                      final isSelected = _selectedLanguages.contains(lang);
                      final langName =
                          lang.name[0].toUpperCase() + lang.name.substring(1);
                      return ChoiceChip(
                        label: Text(langName),
                        selected: isSelected,
                        selectedColor: AppColors.gold500,
                        backgroundColor: isDark
                            ? AppColors.forest800
                            : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.forest900
                              : (isDark ? Colors.white : Colors.black),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          setSheetState(() {
                            if (selected) {
                              _selectedLanguages.add(lang);
                            } else {
                              _selectedLanguages.remove(lang);
                            }
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: AppColors.forest900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are disabled.'),
            action: SnackBarAction(
              label: 'ENABLE',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are permanently denied.'),
            action: SnackBarAction(
              label: 'SETTINGS',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_userLocation!, 13.0);
    });
    HapticFeedback.heavyImpact();
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.gold500),
            const SizedBox(height: 16),
            Text(
              "CALIBRATING MAP...",
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: GlassBox(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_rounded,
                color: AppColors.gold500,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              BrandButton(
                text: "Clear Search",
                type: BrandButtonType.secondary,
                onTap: () => setState(() => _searchQuery = ''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
