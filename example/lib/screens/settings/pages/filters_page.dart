import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../../../shared/property_cards.dart';
import 'filters/filters_cut_pass_page.dart';
import 'filters/filters_denoise_page.dart';
import 'filters/filters_dynamics_page.dart';
import 'filters/filters_eq_page.dart';
import 'filters/filters_modulation_page.dart';
import 'filters/filters_pitch_time_page.dart';
import 'filters/filters_stereo_page.dart';
import 'filters/filters_utility_page.dart';

/// Index of all DSP filters shipped with the build, grouped into the
/// same eight categories as the README catalogue. Tap a tile to open a
/// dedicated page with one [ExpandableFilterCard] per filter.
class FiltersPage extends StatelessWidget {
  final Player player;
  const FiltersPage({super.key, required this.player});

  static const _categories = <_FilterCategory>[
    _FilterCategory(
      title: 'Dynamics & loudness',
      subtitle: '20 filters',
      icon: Icons.compress_rounded,
    ),
    _FilterCategory(
      title: 'Equalization & tone',
      subtitle: '12 filters',
      icon: Icons.equalizer_rounded,
    ),
    _FilterCategory(
      title: 'Filters (cut / pass)',
      subtitle: '9 filters',
      icon: Icons.tune_rounded,
    ),
    _FilterCategory(
      title: 'Pitch, tempo & time',
      subtitle: '11 filters',
      icon: Icons.speed_rounded,
    ),
    _FilterCategory(
      title: 'Stereo, channels & spatial',
      subtitle: '12 filters',
      icon: Icons.surround_sound_rounded,
    ),
    _FilterCategory(
      title: 'Modulation & creative',
      subtitle: '13 filters',
      icon: Icons.auto_fix_high_rounded,
    ),
    _FilterCategory(
      title: 'Denoise & restoration',
      subtitle: '12 filters',
      icon: Icons.graphic_eq_rounded,
    ),
    _FilterCategory(
      title: 'Analysis, fade & utilities',
      subtitle: '25 filters',
      icon: Icons.science_rounded,
    ),
  ];

  static Widget _build(int index, Player player) {
    switch (index) {
      case 0:
        return FiltersDynamicsPage(player: player);
      case 1:
        return FiltersEqualizationPage(player: player);
      case 2:
        return FiltersCutPassPage(player: player);
      case 3:
        return FiltersPitchTimePage(player: player);
      case 4:
        return FiltersStereoPage(player: player);
      case 5:
        return FiltersModulationPage(player: player);
      case 6:
        return FiltersDenoisePage(player: player);
      case 7:
        return FiltersUtilityPage(player: player);
      default:
        throw StateError('unknown category index $index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final cat = _categories[i];
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.surfaceContainerLow,
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, size: 20, color: cs.primary),
            ),
            title: Text(
              cat.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(cat.subtitle, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: Text(cat.title),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  body: _build(i, player),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterCategory {
  final String title;
  final String subtitle;
  final IconData icon;

  const _FilterCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
