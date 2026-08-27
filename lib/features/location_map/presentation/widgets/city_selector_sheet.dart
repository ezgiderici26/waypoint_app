import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/turkey_provinces.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/location_providers.dart';
import '../providers/province_providers.dart';

class CitySelectorSheet extends ConsumerStatefulWidget {
  final Function(TurkeyProvince)? onProvinceSelected;

  const CitySelectorSheet({super.key, this.onProvinceSelected});

  static Future<TurkeyProvince?> show(
    BuildContext context, {
    Function(TurkeyProvince)? onProvinceSelected,
  }) {
    return showModalBottomSheet<TurkeyProvince>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitySelectorSheet(
        onProvinceSelected: onProvinceSelected,
      ),
    );
  }

  @override
  ConsumerState<CitySelectorSheet> createState() => _CitySelectorSheetState();
}

class _CitySelectorSheetState extends ConsumerState<CitySelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'Tümü';
  List<TurkeyProvince> _filteredProvinces = TurkeyProvinces.all;

  static const List<String> _regions = [
    'Tümü',
    'Marmara',
    'İç Anadolu',
    'Ege',
    'Akdeniz',
    'Karadeniz',
    'Güneydoğu Anadolu',
    'Doğu Anadolu',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    List<TurkeyProvince> results = TurkeyProvinces.search(query);

    if (_selectedRegion != 'Tümü') {
      results = results.where((p) => p.region == _selectedRegion).toList();
    }

    setState(() {
      _filteredProvinces = results;
    });
  }

  void _selectRegion(String region) {
    setState(() {
      _selectedRegion = region;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final userLocationAsync = ref.watch(locationStreamProvider);
    final userLocation = userLocationAsync.value;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.primary, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x6600D2FF),
            blurRadius: 25,
            spreadRadius: -5,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(100),
                        ),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TÜRKİYE 81 İL SEÇİCİ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "Hedef Geofence ve Kontrol Bölgesi Belirleyin",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Quick GPS Auto-Detect Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (userLocation != null) {
                    final detected = ref
                        .read(selectedProvinceProvider.notifier)
                        .autoDetectNearest(userLocation);

                    widget.onProvinceSelected?.call(detected);
                    Navigator.pop(context, detected);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "📍 GPS Konumunuz Algılandı: ${detected.formattedPlate} - ${detected.name} (${detected.defaultCheckpointName})",
                        ),
                        backgroundColor: AppTheme.safe,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "⚠️ GPS konumu henüz alınamadı. Lütfen konum izinlerini kontrol edin.",
                        ),
                        backgroundColor: AppTheme.suspicious,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withAlpha(40),
                        AppTheme.secondary.withAlpha(30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(120),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 16,
                          color: Color(0xFF0A0E1A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GPS ile En Yakın İlimi Otomatik Bul",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              "Canlı GPS koordinatınızdan ili anında tespit eder",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: "İl adı (Ankara, İzmir) veya Plaka (06, 34)...",
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(140),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2A3547)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF2A3547)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ),

          // Region Filter Pills
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _regions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = _selectedRegion == region;
                return ChoiceChip(
                  label: Text(
                    region,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : AppTheme.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFF2A3547),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) => _selectRegion(region),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFF2A3547)),

          // 81 Provinces List
          Expanded(
            child: _filteredProvinces.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_rounded,
                          size: 48,
                          color: AppTheme.textSecondary.withAlpha(100),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "\"${_searchController.text}\" ile eşleşen il bulunamadı",
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _filteredProvinces.length,
                    itemBuilder: (context, index) {
                      final province = _filteredProvinces[index];
                      final isSelected =
                          province.plateCode == selectedProvince.plateCode;

                      // Calculate distance if user location is known
                      String? distanceStr;
                      if (userLocation != null) {
                        final dMeters = province.distanceFrom(
                          userLocation.latitude,
                          userLocation.longitude,
                        );
                        if (dMeters < 1000) {
                          distanceStr = "${dMeters.round()} m";
                        } else {
                          distanceStr = "${(dMeters / 1000).toStringAsFixed(1)} km";
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              ref
                                  .read(selectedProvinceProvider.notifier)
                                  .selectProvince(province);

                              widget.onProvinceSelected?.call(province);
                              Navigator.pop(context, province);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "📍 Hedef Bölge Değiştirildi: ${province.formattedPlate} - ${province.name} (${province.defaultCheckpointName})",
                                  ),
                                  backgroundColor: AppTheme.safe,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withAlpha(25)
                                    : AppTheme.surface.withAlpha(150),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFF2A3547),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Plate Badge
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        province.formattedPlate,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: isSelected
                                              ? Colors.black
                                              : AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Province & Checkpoint Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              province.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? AppTheme.primary
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E293B),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                province.region,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Kontrol Noktası: ${province.defaultCheckpointName}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary
                                                .withAlpha(200),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Distance & Active Status
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            "AKTİF HEDEF",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        )
                                      else if (distanceStr != null)
                                        Text(
                                          distanceStr,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
}
