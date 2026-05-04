import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

class PrefetchPage extends StatelessWidget {
  final Player player;
  const PrefetchPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Playlist Prefetch'),
        StreamBuilder<bool>(
          stream: player.stream.prefetchPlaylist,
          initialData: player.state.prefetchPlaylist,
          builder: (_, snap) {
            final enabled = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Prefetch Next Track',
              subtitle: 'prefetch-playlist=${enabled ? 'yes' : 'no'}',
              icon: Icons.fast_forward_rounded,
              value: enabled,
              onChanged: player.setPrefetchPlaylist,
            );
          },
        ),
        StreamBuilder<MpvPrefetchState>(
          stream: player.stream.prefetchState,
          initialData: MpvPrefetchState.idle,
          builder: (_, snap) {
            final state = snap.data ?? MpvPrefetchState.idle;
            return PropertyBaseCard(
              title: 'Prefetch State',
              subtitle: 'prefetch-state=${state.name}',
              icon: Icons.swap_calls_rounded,
              isActive: state != MpvPrefetchState.idle,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
