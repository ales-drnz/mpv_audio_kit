import 'package:flutter/material.dart';
import 'package:mpv_audio_pro_kit/mpv_audio_pro_kit.dart';
import '../../widgets/ui_helpers.dart';

class NetworkTab extends StatefulWidget {
  final Player player;
  const NetworkTab({super.key, required this.player});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  double _networkTimeout = 60.0;
  bool _ytdl = true;
  String _cache = 'auto';
  bool _cacheOnDisk = false;
  double _cacheSecs = 10.0;
  bool _cachePause = true;
  double _cachePauseWait = 1.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<Duration>(
          stream: widget.player.stream.buffer,
          builder: (context, snapshot) {
            final seconds = (snapshot.data?.inMilliseconds ?? 0) / 1000.0;
            return buildSectionCard(context, 'Real-time Buffer Status', [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seconds Buffered:'),
                  Text(
                    '${seconds.toStringAsFixed(2)}s',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: seconds > 0 ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (seconds / _cacheSecs).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[800],
              ),
            ]);
          },
        ),
        const SizedBox(height: 16),
        buildSectionCard(context, 'Network Settings', [
          buildSliderRow('Timeout (s)', _networkTimeout, 5.0, 120.0, (v) {
            setState(() => _networkTimeout = v);
            widget.player.setNetworkTimeout(v);
          }),
          Wrap(
            spacing: 16,
            children: [
              buildToggle('YouTube-DL Hook', _ytdl, (v) {
                setState(() => _ytdl = v);
                widget.player.setRawProperty('ytdl', v ? 'yes' : 'no');
              }),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        buildSectionCard(context, 'Cache Management', [
          buildDropdownRow<String>(
            'Cache Mode',
            _cache,
            [
              'auto',
              'yes',
              'no',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _cache = v);
                widget.player.setCache(v);
              }
            },
          ),
          buildSliderRow('Cache Size (secs)', _cacheSecs, 0.0, 300.0, (v) {
            setState(() => _cacheSecs = v);
            widget.player.setCacheSecs(v);
          }),
          Wrap(
            spacing: 16,
            children: [
              buildToggle('Cache on Disk (\$--cache-on-disk)', _cacheOnDisk, (
                v,
              ) {
                setState(() => _cacheOnDisk = v);
                widget.player.setCacheOnDisk(v);
              }),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        buildSectionCard(context, 'Under/Over Run (Buffering)', [
          Wrap(
            spacing: 16,
            children: [
              buildToggle('Enable Buffering Stops', _cachePause, (v) {
                setState(() => _cachePause = v);
                widget.player.setCachePause(v);
              }),
            ],
          ),
          buildSliderRow('Resume Wait (secs)', _cachePauseWait, 0.0, 30.0, (
            v,
          ) {
            setState(() => _cachePauseWait = v);
            widget.player.setCachePauseWait(v);
          }),
        ]),
      ],
    );
  }
}
