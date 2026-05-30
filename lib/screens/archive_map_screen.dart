import 'package:flutter/material.dart';
import 'dart:async';
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
import 'package:geolocator/geolocator.dart';
import '../widgets/municipality_panel.dart';
import '../widgets/brand_button.dart';
import '../widgets/cached_tile_provider.dart';
import '../widgets/brand_search_bar.dart';
import '../services/supabase_storage_service.dart';
import '../providers/search_history_provider.dart';

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
  bool _showHeatmap = false;
  LatLng? _userLocation;
  bool _followUser = false;
  StreamSubscription<Position>? _positionStream;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

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
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus;
      });
    });
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    _positionStream?.cancel();
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
                  final List<GeoRecording> filtered = [];

                  for (final rec in municipalities) {
                    try {
                      final query = _searchQuery.toLowerCase().trim();
                      final currentProv = _selectedProvince ?? '';

                      // 1. Filter Logic (Province and Dialect Chips) - This is now the primary constraint
                      final matchesProvince = currentProv.isEmpty ||
                          rec.province.toLowerCase() == currentProv.toLowerCase();

                      final matchesDialect = _selectedLanguages.isEmpty ||
                          _selectedLanguages.any((lang) {
                            final String l = lang.trim().toLowerCase();
                            return rec.dialect.trim().toLowerCase() == l ||
                                (rec.safeSupportedDialects.any((sd) => sd.trim().toLowerCase() == l));
                          });

                      // 2. Search Query Filter - Now acts as a sub-filter within selected province/dialect
                      final isSearchActive = query.isNotEmpty;
                      final matchesSearch = !isSearchActive ||
                          rec.title.toLowerCase().contains(query) ||
                          rec.province.toLowerCase().contains(query) ||
                          rec.dialect.toLowerCase().contains(query) ||
                          (rec.safeSupportedDialects.any((sd) => sd.toLowerCase().contains(query)));

                      // 3. Initial State Guard: If nothing selected and no search, we show nothing
                      if (currentProv.isEmpty && !isSearchActive && _selectedLanguages.isEmpty) {
                        continue;
                      }

                      // Apply all constraints together
                      // Exception: If a user types the EXACT municipality name, we show it regardless of other filters
                      // to avoid a "dead end" where a user searches for a town they can see the name of but it's hidden.
                      final isExactMatch = isSearchActive && rec.title.toLowerCase() == query;

                      if (isExactMatch || (matchesProvince && matchesDialect && matchesSearch)) {
                        filtered.add(rec);
                      }
                    } catch (e) {
                      debugPrint('Error filtering municipality ${rec.title}: $e');
                    }
                  }

                  return Stack(
                    children: [
                      _buildMap(filtered),
                      if (filtered.isEmpty && _searchQuery.isNotEmpty)
                        _buildEmptyState(
                          "No municipalities found matching '$_searchQuery'",
                        ),
                      if (filtered.isEmpty && _searchQuery.isEmpty && _selectedProvince == null && _selectedLanguages.isEmpty)
                        _buildEmptyState(
                          "Discover the voices of Mindanao. Select a province above to browse cultural sites, or search for a specific dialect or town.",
                          isGuidance: true,
                        ),
                      if (filtered.isEmpty && _searchQuery.isEmpty && (_selectedProvince != null || _selectedLanguages.isNotEmpty))
                        _buildEmptyState(
                          "No approved recordings found matching your filters yet.",
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
                if (_showSuggestions)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: _buildSuggestionsList(),
                  ),
                const SizedBox(height: 12),
                _buildActiveFilters(),
                const SizedBox(height: 12),
                _buildProvinceChips(),
              ],
            ),
          ),

          // Heatmap Legend
          if (_showHeatmap)
            Positioned(
              left: 20,
              bottom: _selectedRecording != null ? 380 : 40,
              child: GlassBox(
                borderRadius: 12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DOCUMENTATION DENSITY',
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLegendItem('HIGH', Colors.red),
                          const SizedBox(width: 8),
                          _buildLegendItem('MED', AppColors.terracotta),
                          const SizedBox(width: 8),
                          _buildLegendItem('LOW', AppColors.gold500),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().slideX(begin: -0.2),

          // Floating Map Controls (Right Side)
          Positioned(
            right: 20,
            bottom: _selectedRecording != null
                ? 380
                : 100, // Move up if panel is open
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (_selectedProvince != null || _searchQuery.isNotEmpty || _selectedLanguages.isNotEmpty) ? 1.0 : 0.4,
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
                    _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                    () => _toggleFollowMe(),
                    isActive: _followUser,
                  ),
                  const SizedBox(height: 12),
                  _buildMapControl(
                    _showHeatmap ? Icons.layers_rounded : Icons.layers_outlined,
                    () => setState(() => _showHeatmap = !_showHeatmap),
                    isActive: _showHeatmap,
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
                    onTogglePlay: (audio) => _handlePlayback(audio),
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
        minZoom: 8.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(5.0, 121.0), // South West Mindanao
            const LatLng(10.0, 127.5), // North East Mindanao
          ),
        ),
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

        if (_showHeatmap)
          CircleLayer(
            circles: municipalities.expand((rec) {
              // Calculate density factor based on supported dialects
              final double weight = (rec.safeSupportedDialects.length.toDouble().clamp(1.0, 5.0)) / 2.0;
              
              return [
                CircleMarker(
                  point: rec.location,
                  radius: 50 * weight,
                  useRadiusInMeter: false,
                  color: AppColors.gold500.withValues(alpha: 0.1),
                ),
                CircleMarker(
                  point: rec.location,
                  radius: 25 * weight,
                  useRadiusInMeter: false,
                  color: AppColors.terracotta.withValues(alpha: 0.15),
                ),
                CircleMarker(
                  point: rec.location,
                  radius: 10 * weight,
                  useRadiusInMeter: false,
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ];
            }).toList(),
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

  Widget _buildActiveFilters() {
    if (_selectedLanguages.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _selectedLanguages.map((lang) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.gold500.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Text(
                lang.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.gold500),
              onDeleted: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedLanguages.remove(lang);
                });
              },
            ),
          );
        }).toList(),
      ),
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
                  if (_selectedProvince == p) {
                    _selectedProvince = null;
                  } else {
                    _selectedProvince = p;
                  }
                  _selectedRecording = null;
                });

                if (_selectedProvince == null) return;

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

  Widget _buildMapControl(IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassBox(
        borderRadius: 25,
        blur: 15,
        opacity: isActive ? 0.3 : 0.15,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.gold500.withValues(alpha: 0.2) : null,
            border: Border.all(
              color: isActive ? AppColors.gold500 : Colors.white.withValues(alpha: 0.1),
              width: isActive ? 2 : 1,
            ),
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
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Search municipalities or dialects...',
      showFilter: showFilter,
      onFilterTap: _showFilterSheet,
      isMinimal: true,
      onSubmitted: (val) {
        setState(() {
          _searchQuery = val;
        });
        if (val.trim().isNotEmpty) {
          ref.read(searchHistoryProvider.notifier).addTerm(val.trim());
        }
        _searchFocusNode.unfocus();
      },
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
          // Smart Province Switch: If user types an exact municipality name,
          // find its province and switch the chip automatically.
          if (val.length > 2) {
            ref.read(mapMarkersStreamProvider).whenData((muniList) {
              try {
                final match = muniList.firstWhere(
                    (m) => m.title.toLowerCase().trim() == val.toLowerCase().trim());
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

  Widget _buildSuggestionsList() {
    final history = ref.watch(searchHistoryProvider);
    final municipalitiesAsync = ref.watch(mapMarkersStreamProvider);

    return municipalitiesAsync.when(
      data: (muniList) {
        final query = _searchQuery.toLowerCase().trim();

        // Combined suggestions: History (filtered) + Municipality Titles + Dialects
        final List<String> suggestions = [];

        if (query.isEmpty) {
          suggestions.addAll(history);
        } else {
          // Filter history
          suggestions.addAll(history.where((item) => item.toLowerCase().contains(query)));

          // Add municipalities matching query
          final muniMatches = muniList
              .where((m) => m.title.toLowerCase().contains(query))
              .map((m) => m.title)
              .toList();
          for (var m in muniMatches) {
            if (!suggestions.any((s) => s.toLowerCase() == m.toLowerCase())) {
              suggestions.add(m);
            }
          }

          // Add dialects matching query
          final dialectMatches = muniList
              .where((m) => m.dialect.toLowerCase().contains(query))
              .map((m) => m.dialect)
              .toSet()
              .toList();
          for (var d in dialectMatches) {
            if (!suggestions.any((s) => s.toLowerCase() == d.toLowerCase())) {
              suggestions.add(d);
            }
          }
        }

        if (suggestions.isEmpty) return const SizedBox.shrink();

        return GlassBox(
          borderRadius: 20,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: suggestions.length > 6 ? 6 : suggestions.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final isHistory = history.contains(suggestion);

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isHistory ? Icons.history_rounded : Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.gold500.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    suggestion,
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  trailing: isHistory
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white38),
                          onPressed: () {
                            ref.read(searchHistoryProvider.notifier).removeTerm(suggestion);
                          },
                        )
                      : const Icon(Icons.north_west_rounded, size: 14, color: Colors.white30),
                  onTap: () {
                    setState(() {
                      _searchQuery = suggestion;
                      _searchController.text = suggestion;
                      _showSuggestions = false;
                    });
                    ref.read(searchHistoryProvider.notifier).addTerm(suggestion);
                    _searchFocusNode.unfocus();

                    // Trigger map movement if it's a municipality
                    try {
                      final match = muniList.firstWhere(
                          (m) => m.title.toLowerCase() == suggestion.toLowerCase());
                      setState(() => _selectedProvince = match.province);
                      _mapController.move(match.location, 11.0);
                    } catch (_) {}
                  },
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
                ['Mandaya', 'Mansaka'];

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

  Future<void> _toggleFollowMe() async {
    if (_followUser) {
      _positionStream?.cancel();
      setState(() => _followUser = false);
      return;
    }

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

    setState(() => _followUser = true);
    HapticFeedback.mediumImpact();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;

      final latLng = LatLng(position.latitude, position.longitude);

      // Check if within Mindanao bounds (Lat: 5.0-10.0, Lng: 121.0-127.5)
      final bool isWithinBounds = position.latitude >= 5.0 &&
          position.latitude <= 10.0 &&
          position.longitude >= 121.0 &&
          position.longitude <= 127.5;

      setState(() {
        _userLocation = latLng;
        if (_followUser) {
          _mapController.move(latLng, 13.0);
        }
      });

      if (!isWithinBounds && _followUser) {
        _positionStream?.cancel();
        setState(() => _followUser = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are outside the covered cultural regions of Mindanao.'),
            backgroundColor: AppColors.terracotta,
          ),
        );
      }
    });
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: Colors.white70,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

