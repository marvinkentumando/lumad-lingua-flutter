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
import '../services/supabase_storage_service.dart';

class ArchiveMapScreen extends ConsumerStatefulWidget {
  const ArchiveMapScreen({super.key});

  @override
  ConsumerState<ArchiveMapScreen> createState() => _ArchiveMapScreenState();
}

class _ArchiveMapScreenState extends ConsumerState<ArchiveMapScreen> {
  final MapController _mapController = MapController();
  GeoRecording? _selectedRecording;
  String? _playingAudioId;
  final Set<String> _selectedLanguages = {};
  String? _selectedProvince;
  String _searchQuery = '';
  bool _isSatellite = true;
  LatLng? _userLocation;

  final List<String> _provinces = [
    'Davao de Oro',
    'Davao del Sur',
    'Davao del Norte',
    'Davao Oriental',
    'Davao Occidental',
  ];

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
                    final query = _searchQuery.toLowerCase().trim();

                    // Province check (Priority: Search takes precedence for finding across provinces)
                    final currentProv = _selectedProvince ?? '';
                    final matchesProvince = currentProv.isEmpty ||
                        rec.province.toLowerCase() == currentProv.toLowerCase();

                    // If municipality searched specifically, ignore province filter to find it
                    if (query.isNotEmpty && rec.title.toLowerCase() == query) {
                       return true;
                    }

                    // Search Query Filter
                    final matchesSearch = query.isEmpty ||
                        rec.title.toLowerCase().contains(query) ||
                        rec.province.toLowerCase().contains(query) ||
                        rec.dialect.toLowerCase().contains(query);

                    // Dialect Chip Filter
                    final matchesDialect = _selectedLanguages.isEmpty ||
                        _selectedLanguages.any((lang) =>
                          rec.dialect.toLowerCase() == lang.toLowerCase()
                        );

                    // If nothing selected and no search, we show nothing (to avoid overwhelming)
                    if (currentProv.isEmpty && query.isEmpty && _selectedLanguages.isEmpty) {
                      return false;
                    }

                    return matchesProvince && matchesSearch && matchesDialect;
                  }).toList();

                  return Stack(
                    children: [
                      _buildMap(filtered),
                      if (filtered.isEmpty && _searchQuery.isNotEmpty)
                        _buildEmptyState(
                          "No municipalities found matching '$_searchQuery'",
                        ),
                      if (filtered.isEmpty && _searchQuery.isEmpty && _selectedProvince == null)
                        _buildEmptyState(
                          "Discover the voices of Mindanao. Select a province above to browse cultural sites, or search for a specific dialect or town.",
                          isGuidance: true,
                        ),
                      if (filtered.isEmpty && _searchQuery.isEmpty && _selectedProvince != null)
                        _buildEmptyState(
                          "No approved recordings found in $_selectedProvince yet.",
                        ),
                    ],
                  );
                },
                loading: () => _buildLoadingOverlay(),
                error: (e, _) => Center(child: Text('Error loading map: $e')),
              ),

          // Top Search & Filter Bar
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 12),
                _buildProvinceChips(),
              ],
            ),
          ),

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
                return Dismissible(
                  key: ValueKey('dismiss_${_selectedRecording!.id}'),
                  direction: DismissDirection.down,
                  onDismissed: (_) => setState(() => _selectedRecording = null),
                  child: MunicipalityPanel(
                    rec: _selectedRecording!,
                    scrollController: scrollController,
                    playingAudioId: _playingAudioId,
                    duration: _duration,
                    position: _position,
                    selectedDialects: _selectedLanguages,
                    onTogglePlay: (audio) => _handlePlayback(audio as Map<String, dynamic>),
                    onSeek: (value) =>
                        _audioPlayer.seek(Duration(milliseconds: value.toInt())),
                    onClose: () => setState(() => _selectedRecording = null),
                    formatDuration: _formatDuration,
                  ),
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
                  ? AppColors.forest900.withValues(alpha: 0.5)
                  : const Color(0xFFD4B886).withValues(alpha: 0.2),
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

        MarkerLayer(
          markers: municipalities.map((rec) {
            final isSelected = _selectedRecording?.id == rec.id;
            return Marker(
              point: rec.location,
              width: 120,
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
                                  color: AppColors.gold500.withValues(alpha: 0.4),
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
                                    ? AppColors.gold500.withValues(alpha: 0.6)
                                    : Colors.black.withValues(alpha: 0.5),
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
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected ? Border.all(color: AppColors.gold500, width: 1) : null,
                      ),
                      child: Text(
                        rec.title.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: isSelected ? Colors.white : AppColors.gold500,
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

  Widget _buildProvinceChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _provinces.map((p) {
          final isSelected = _selectedProvince == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedProvince = p;
                  _selectedRecording = null;
                });

                // Center map on the selected province
                switch (p) {
                  case 'Davao de Oro':
                    _mapController.move(const LatLng(7.33, 126.11), 9.5);
                    break;
                  case 'Davao del Sur':
                    _mapController.move(const LatLng(6.75, 125.35), 9.5);
                    break;
                  case 'Davao del Norte':
                    _mapController.move(const LatLng(7.45, 125.81), 9.5);
                    break;
                  case 'Davao Oriental':
                    _mapController.move(const LatLng(7.05, 126.45), 9.5);
                    break;
                  case 'Davao Occidental':
                    _mapController.move(const LatLng(6.41, 125.61), 9.5);
                    break;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold500 : Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.gold500 : Colors.white10,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : [],
                ),
                child: Text(
                  p.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
        final resolvedUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(audioUrl);
        await _audioPlayer.play(UrlSource(resolvedUrl));
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
    final showFilter = _selectedProvince != null || _searchQuery.length > 1;
    return BrandSearchBar(
      hintText: 'Search municipalities or dialects...',
      showFilter: showFilter,
      onFilterTap: _showFilterSheet,
      isMinimal: true,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;

          // Smart Province Switch: If user types an exact municipality name,
          // find its province and switch the chip automatically.
          if (val.length > 2) {
             ref.read(mapMarkersStreamProvider).whenData((muniList) {
               try {
                 final match = muniList.firstWhere(
                   (m) => m.title.toLowerCase().trim() == val.toLowerCase().trim()
                 );
                 if (_selectedProvince != match.province) {
                    setState(() {
                      _selectedProvince = match.province;
                    });
                    _mapController.move(match.location, 11.0);
                 }
               } catch (_) {}
             });
          }
        });
      },
    );
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final dialectsAsync = ref.watch(dialectsProvider);
            final dialects = dialectsAsync.value
                    ?.where((d) => d != "All")
                    .toList() ??
                ['Mandaya', 'Mansaka', 'Lumad', 'Manobo'];

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
                    'Filter Archive',
                    style: AppTypography.h2.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Province Selector
                  Text(
                    'PROVINCE',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Provinces'),
                          selected: _selectedProvince == null,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => _selectedProvince = null);
                              setState(() {});
                            }
                          },
                        ),
                        ..._provinces.map((p) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(p),
                            selected: _selectedProvince == p,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => _selectedProvince = p);
                                setState(() {});
                              }
                            },
                          ),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'DIALECTS',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dialects.map((lang) {
                      final isSelected = _selectedLanguages.contains(lang);
                      return ChoiceChip(
                        label: Text(lang),
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
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 16),
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
      color: Colors.black.withValues(alpha: 0.3),
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

  Widget _buildEmptyState(String message, {bool isGuidance = false}) {
    return Center(
      child: GlassBox(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGuidance ? Icons.map_outlined : Icons.location_off_rounded,
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
              if (!isGuidance) ...[
                const SizedBox(height: 24),
                BrandButton(
                  text: "Clear Search",
                  type: BrandButtonType.secondary,
                  onTap: () => setState(() => _searchQuery = ''),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

