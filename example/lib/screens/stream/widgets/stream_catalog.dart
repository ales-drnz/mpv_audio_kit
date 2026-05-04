class StreamItem {
  final String label;
  final String url;
  const StreamItem({required this.label, required this.url});
}

class StreamCategory {
  final String name;
  final List<StreamItem> items;
  const StreamCategory({required this.name, required this.items});
}

const streamCategories = <StreamCategory>[
  StreamCategory(
    name: 'MP3 Reference',
    items: [
      StreamItem(
        label: 'MP3 128k Stereo (Standard)',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo',
      ),
      StreamItem(
        label: 'MP3 128k Stereo (with Preroll)',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo-preroll',
      ),
      StreamItem(
        label: 'MP3 32k Mono (Low-Bandwidth)',
        url: 'https://streams.radiomast.io/ref-32k-mp3-mono',
      ),
    ],
  ),
  StreamCategory(
    name: 'AAC Reference (Advanced Audio Coding)',
    items: [
      StreamItem(
        label: 'AAC-LC 128k Stereo',
        url: 'https://streams.radiomast.io/ref-128k-aaclc-stereo',
      ),
      StreamItem(
        label: 'HE-AAC v1 64k Stereo (SBR)',
        url: 'https://streams.radiomast.io/ref-64k-heaacv1-stereo',
      ),
      StreamItem(
        label: 'HE-AAC v2 64k Stereo (SBR+PS)',
        url: 'https://streams.radiomast.io/ref-64k-heaacv2-stereo',
      ),
      StreamItem(
        label: 'HE-AAC v1 24k Mono',
        url: 'https://streams.radiomast.io/ref-24k-heaacv1-mono',
      ),
    ],
  ),
  StreamCategory(
    name: 'Ogg / Open Formats',
    items: [
      StreamItem(
        label: 'Ogg Vorbis 64k Stereo',
        url: 'https://streams.radiomast.io/ref-64k-ogg-vorbis-stereo',
      ),
      StreamItem(
        label: 'Ogg Opus 64k Stereo',
        url: 'https://streams.radiomast.io/ref-64k-ogg-opus-stereo',
      ),
    ],
  ),
  StreamCategory(
    name: 'Lossless & High-Fidelity',
    items: [
      StreamItem(
        label: 'Ogg FLAC (16-bit Lossless)',
        url: 'https://streams.radiomast.io/ref-lossless-ogg-flac-stereo',
      ),
      StreamItem(
        label: 'Radio Paradise (Main Mix FLAC)',
        url: 'http://stream.radioparadise.com/flacm',
      ),
    ],
  ),
  StreamCategory(
    name: 'HLS (HTTP Live Streaming)',
    items: [
      StreamItem(
        label: 'MP3 128k HLS Adaptive',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo/hls.m3u8',
      ),
      StreamItem(
        label: 'AAC-LC 128k HLS Adaptive',
        url: 'https://streams.radiomast.io/ref-128k-aaclc-stereo/hls.m3u8',
      ),
      StreamItem(
        label: 'Apple BipBop (HLS Audio)',
        url:
            'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8',
      ),
    ],
  ),
];
