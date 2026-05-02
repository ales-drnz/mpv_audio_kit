// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// How [Player.setAudioChannels] should resolve mpv's `audio-channels`
/// property.
///
/// Sealed union over:
/// - the special modes [auto] and [autoSafe] (let mpv pick),
/// - the 41 named layouts mpv recognises (mirror of mpv's
///   `std_layout_names[]` table — every variant qualifier preserved),
/// - [Channels.custom] for raw mpv strings (comma-separated
///   layouts or speaker-tag arrays such as
///   `'fl-fr-fc-bl-br-sl-sr-lfe'`).
///
/// Use the static fields at call-site:
///
/// ```dart
/// await player.setAudioChannels(Channels.stereo);
/// await player.setAudioChannels(Channels.fiveOneSide);
/// await player.setAudioChannels(Channels.custom('fl-fr-lfe'));
/// ```
sealed class Channels {
  const Channels._();

  /// Defer to mpv's automatic channel-layout choice. Equivalent to
  /// mpv's `audio-channels=auto`.
  static const Channels auto = ChannelsAuto._();

  /// Same as [auto] but reject multichannel layouts unless the audio
  /// device explicitly advertises support. Equivalent to mpv's
  /// `audio-channels=auto-safe`.
  static const Channels autoSafe = ChannelsAutoSafe._();

  // ── Named layouts (mirror of mpv's std_layout_names[] table) ────────

  /// `mono` — single front-centre channel.
  static const Channels mono = ChannelsMono._();

  /// `1.0` — alias of [mono].
  static const Channels oneZero = ChannelsOneZero._();

  /// `stereo` — front-left + front-right.
  static const Channels stereo = ChannelsStereo._();

  /// `2.0` — alias of [stereo].
  static const Channels twoZero = ChannelsTwoZero._();

  /// `2.1` — two main channels + LFE.
  static const Channels twoOne = ChannelsTwoOne._();

  /// `3.0` — front-left + front-right + front-centre.
  static const Channels threeZero = ChannelsThreeZero._();

  /// `3.0(back)` — front pair + back-centre.
  static const Channels threeZeroBack = ChannelsThreeZeroBack._();

  /// `4.0` — front pair + front-centre + back-centre.
  static const Channels fourZero = ChannelsFourZero._();

  /// `quad` — front pair + back pair.
  static const Channels quad = ChannelsQuad._();

  /// `quad(side)` — front pair + side surrounds (instead of back).
  static const Channels quadSide = ChannelsQuadSide._();

  /// `3.1` — three main channels + LFE.
  static const Channels threeOne = ChannelsThreeOne._();

  /// `3.1(back)` — 3.1 with back-centre.
  static const Channels threeOneBack = ChannelsThreeOneBack._();

  /// `5.0` — five main channels (front + back surrounds), no LFE.
  static const Channels fiveZero = ChannelsFiveZero._();

  /// `5.0(alsa)` — 5.0 in ALSA channel order.
  static const Channels fiveZeroAlsa = ChannelsFiveZeroAlsa._();

  /// `5.0(side)` — 5.0 with side surrounds (instead of back).
  static const Channels fiveZeroSide = ChannelsFiveZeroSide._();

  /// `4.1` — four main channels + LFE.
  static const Channels fourOne = ChannelsFourOne._();

  /// `4.1(alsa)` — 4.1 in ALSA channel order.
  static const Channels fourOneAlsa = ChannelsFourOneAlsa._();

  /// `5.1` — five main channels + LFE, back surrounds (DVD / Dolby
  /// Digital canonical).
  static const Channels fiveOne = ChannelsFiveOne._();

  /// `5.1(alsa)` — 5.1 in ALSA channel order.
  static const Channels fiveOneAlsa = ChannelsFiveOneAlsa._();

  /// `5.1(side)` — five main channels + LFE, side surrounds (DTS /
  /// ATSC).
  static const Channels fiveOneSide = ChannelsFiveOneSide._();

  /// `6.0` — front + back-centre + side surrounds, no LFE.
  static const Channels sixZero = ChannelsSixZero._();

  /// `6.0(front)` — 6.0 with front-left/right-of-centre instead of
  /// back-centre.
  static const Channels sixZeroFront = ChannelsSixZeroFront._();

  /// `hexagonal` — six-channel hexagonal layout.
  static const Channels hexagonal = ChannelsHexagonal._();

  /// `6.1` — six main channels + LFE.
  static const Channels sixOne = ChannelsSixOne._();

  /// `6.1(back)` — 6.1 with back surrounds.
  static const Channels sixOneBack = ChannelsSixOneBack._();

  /// `6.1(top)` — 6.1 with top-centre channel.
  static const Channels sixOneTop = ChannelsSixOneTop._();

  /// `6.1(front)` — 6.1 with front-left/right-of-centre.
  static const Channels sixOneFront = ChannelsSixOneFront._();

  /// `7.0` — seven main channels (front + back + side), no LFE.
  static const Channels sevenZero = ChannelsSevenZero._();

  /// `7.0(front)` — 7.0 with front wide channels (instead of back
  /// surrounds).
  static const Channels sevenZeroFront = ChannelsSevenZeroFront._();

  /// `7.0(rear)` — 7.0 with surround-direct-left/right (rear).
  static const Channels sevenZeroRear = ChannelsSevenZeroRear._();

  /// `7.1` — seven main channels + LFE, canonical layout.
  static const Channels sevenOne = ChannelsSevenOne._();

  /// `7.1(alsa)` — 7.1 in ALSA channel order.
  static const Channels sevenOneAlsa = ChannelsSevenOneAlsa._();

  /// `7.1(wide)` — 7.1 with front wide channels (instead of side
  /// surrounds).
  static const Channels sevenOneWide = ChannelsSevenOneWide._();

  /// `7.1(wide-side)` — 7.1 with both wide-fronts AND side surrounds
  /// (no back surrounds).
  static const Channels sevenOneWideSide =
      ChannelsSevenOneWideSide._();

  /// `7.1(top)` — 7.1 with top-front-left/right (height channels).
  static const Channels sevenOneTop = ChannelsSevenOneTop._();

  /// `7.1(rear)` — 7.1 with surround-direct-left/right (rear).
  static const Channels sevenOneRear = ChannelsSevenOneRear._();

  /// `octagonal` — eight-channel octagonal layout.
  static const Channels octagonal = ChannelsOctagonal._();

  /// `cube` — front pair + back pair + four top channels.
  static const Channels cube = ChannelsCube._();

  /// `hexadecagonal` — 16-channel cinema-grade overhead array.
  static const Channels hexadecagonal = ChannelsHexadecagonal._();

  /// `downmix` — stereo downmix (semantic alias of [stereo]).
  static const Channels downmix = ChannelsDownmix._();

  /// `22.2` — NHK / ITU-R BS.775 immersive layout (24 channels).
  static const Channels surround222 = ChannelsSurround222._();

  // ── Escape ─────────────────────────────────────────────────────────

  /// Any other mpv-recognised channel string — comma-separated layouts
  /// or raw speaker-tag lists (e.g. `'fl-fr-fc-bl-br-sl-sr-lfe'`).
  /// Forwarded to mpv verbatim.
  const factory Channels.custom(String mpvLayout) = ChannelsCustom._;

  /// The wire-level string mpv expects on the `audio-channels` property.
  String get mpvValue => switch (this) {
        ChannelsAuto() => 'auto',
        ChannelsAutoSafe() => 'auto-safe',
        ChannelsMono() => 'mono',
        ChannelsOneZero() => '1.0',
        ChannelsStereo() => 'stereo',
        ChannelsTwoZero() => '2.0',
        ChannelsTwoOne() => '2.1',
        ChannelsThreeZero() => '3.0',
        ChannelsThreeZeroBack() => '3.0(back)',
        ChannelsFourZero() => '4.0',
        ChannelsQuad() => 'quad',
        ChannelsQuadSide() => 'quad(side)',
        ChannelsThreeOne() => '3.1',
        ChannelsThreeOneBack() => '3.1(back)',
        ChannelsFiveZero() => '5.0',
        ChannelsFiveZeroAlsa() => '5.0(alsa)',
        ChannelsFiveZeroSide() => '5.0(side)',
        ChannelsFourOne() => '4.1',
        ChannelsFourOneAlsa() => '4.1(alsa)',
        ChannelsFiveOne() => '5.1',
        ChannelsFiveOneAlsa() => '5.1(alsa)',
        ChannelsFiveOneSide() => '5.1(side)',
        ChannelsSixZero() => '6.0',
        ChannelsSixZeroFront() => '6.0(front)',
        ChannelsHexagonal() => 'hexagonal',
        ChannelsSixOne() => '6.1',
        ChannelsSixOneBack() => '6.1(back)',
        ChannelsSixOneTop() => '6.1(top)',
        ChannelsSixOneFront() => '6.1(front)',
        ChannelsSevenZero() => '7.0',
        ChannelsSevenZeroFront() => '7.0(front)',
        ChannelsSevenZeroRear() => '7.0(rear)',
        ChannelsSevenOne() => '7.1',
        ChannelsSevenOneAlsa() => '7.1(alsa)',
        ChannelsSevenOneWide() => '7.1(wide)',
        ChannelsSevenOneWideSide() => '7.1(wide-side)',
        ChannelsSevenOneTop() => '7.1(top)',
        ChannelsSevenOneRear() => '7.1(rear)',
        ChannelsOctagonal() => 'octagonal',
        ChannelsCube() => 'cube',
        ChannelsHexadecagonal() => 'hexadecagonal',
        ChannelsDownmix() => 'downmix',
        ChannelsSurround222() => '22.2',
        ChannelsCustom(:final mpvLayout) => mpvLayout,
      };

  /// Maps a raw mpv-side value back to the typed surface. Recognises
  /// `auto`, `auto-safe`, and every entry of mpv's `std_layout_names[]`;
  /// anything else falls through to [Channels.custom] so external
  /// mutations (raw `setRawProperty`, future mpv versions, or arbitrary
  /// speaker-tag layouts) are still observable.
  static Channels fromMpv(String raw) => switch (raw) {
        '' || 'auto' => Channels.auto,
        'auto-safe' => Channels.autoSafe,
        'mono' => Channels.mono,
        '1.0' => Channels.oneZero,
        'stereo' => Channels.stereo,
        '2.0' => Channels.twoZero,
        '2.1' => Channels.twoOne,
        '3.0' => Channels.threeZero,
        '3.0(back)' => Channels.threeZeroBack,
        '4.0' => Channels.fourZero,
        'quad' => Channels.quad,
        'quad(side)' => Channels.quadSide,
        '3.1' => Channels.threeOne,
        '3.1(back)' => Channels.threeOneBack,
        '5.0' => Channels.fiveZero,
        '5.0(alsa)' => Channels.fiveZeroAlsa,
        '5.0(side)' => Channels.fiveZeroSide,
        '4.1' => Channels.fourOne,
        '4.1(alsa)' => Channels.fourOneAlsa,
        '5.1' => Channels.fiveOne,
        '5.1(alsa)' => Channels.fiveOneAlsa,
        '5.1(side)' => Channels.fiveOneSide,
        '6.0' => Channels.sixZero,
        '6.0(front)' => Channels.sixZeroFront,
        'hexagonal' => Channels.hexagonal,
        '6.1' => Channels.sixOne,
        '6.1(back)' => Channels.sixOneBack,
        '6.1(top)' => Channels.sixOneTop,
        '6.1(front)' => Channels.sixOneFront,
        '7.0' => Channels.sevenZero,
        '7.0(front)' => Channels.sevenZeroFront,
        '7.0(rear)' => Channels.sevenZeroRear,
        '7.1' => Channels.sevenOne,
        '7.1(alsa)' => Channels.sevenOneAlsa,
        '7.1(wide)' => Channels.sevenOneWide,
        '7.1(wide-side)' => Channels.sevenOneWideSide,
        '7.1(top)' => Channels.sevenOneTop,
        '7.1(rear)' => Channels.sevenOneRear,
        'octagonal' => Channels.octagonal,
        'cube' => Channels.cube,
        'hexadecagonal' => Channels.hexadecagonal,
        'downmix' => Channels.downmix,
        '22.2' => Channels.surround222,
        _ => Channels.custom(raw),
      };
}

// ── Subclasses (all final, sealed-derived) ─────────────────────────────

final class ChannelsAuto extends Channels {
  const ChannelsAuto._() : super._();
}

final class ChannelsAutoSafe extends Channels {
  const ChannelsAutoSafe._() : super._();
}

final class ChannelsMono extends Channels {
  const ChannelsMono._() : super._();
}

final class ChannelsOneZero extends Channels {
  const ChannelsOneZero._() : super._();
}

final class ChannelsStereo extends Channels {
  const ChannelsStereo._() : super._();
}

final class ChannelsTwoZero extends Channels {
  const ChannelsTwoZero._() : super._();
}

final class ChannelsTwoOne extends Channels {
  const ChannelsTwoOne._() : super._();
}

final class ChannelsThreeZero extends Channels {
  const ChannelsThreeZero._() : super._();
}

final class ChannelsThreeZeroBack extends Channels {
  const ChannelsThreeZeroBack._() : super._();
}

final class ChannelsFourZero extends Channels {
  const ChannelsFourZero._() : super._();
}

final class ChannelsQuad extends Channels {
  const ChannelsQuad._() : super._();
}

final class ChannelsQuadSide extends Channels {
  const ChannelsQuadSide._() : super._();
}

final class ChannelsThreeOne extends Channels {
  const ChannelsThreeOne._() : super._();
}

final class ChannelsThreeOneBack extends Channels {
  const ChannelsThreeOneBack._() : super._();
}

final class ChannelsFiveZero extends Channels {
  const ChannelsFiveZero._() : super._();
}

final class ChannelsFiveZeroAlsa extends Channels {
  const ChannelsFiveZeroAlsa._() : super._();
}

final class ChannelsFiveZeroSide extends Channels {
  const ChannelsFiveZeroSide._() : super._();
}

final class ChannelsFourOne extends Channels {
  const ChannelsFourOne._() : super._();
}

final class ChannelsFourOneAlsa extends Channels {
  const ChannelsFourOneAlsa._() : super._();
}

final class ChannelsFiveOne extends Channels {
  const ChannelsFiveOne._() : super._();
}

final class ChannelsFiveOneAlsa extends Channels {
  const ChannelsFiveOneAlsa._() : super._();
}

final class ChannelsFiveOneSide extends Channels {
  const ChannelsFiveOneSide._() : super._();
}

final class ChannelsSixZero extends Channels {
  const ChannelsSixZero._() : super._();
}

final class ChannelsSixZeroFront extends Channels {
  const ChannelsSixZeroFront._() : super._();
}

final class ChannelsHexagonal extends Channels {
  const ChannelsHexagonal._() : super._();
}

final class ChannelsSixOne extends Channels {
  const ChannelsSixOne._() : super._();
}

final class ChannelsSixOneBack extends Channels {
  const ChannelsSixOneBack._() : super._();
}

final class ChannelsSixOneTop extends Channels {
  const ChannelsSixOneTop._() : super._();
}

final class ChannelsSixOneFront extends Channels {
  const ChannelsSixOneFront._() : super._();
}

final class ChannelsSevenZero extends Channels {
  const ChannelsSevenZero._() : super._();
}

final class ChannelsSevenZeroFront extends Channels {
  const ChannelsSevenZeroFront._() : super._();
}

final class ChannelsSevenZeroRear extends Channels {
  const ChannelsSevenZeroRear._() : super._();
}

final class ChannelsSevenOne extends Channels {
  const ChannelsSevenOne._() : super._();
}

final class ChannelsSevenOneAlsa extends Channels {
  const ChannelsSevenOneAlsa._() : super._();
}

final class ChannelsSevenOneWide extends Channels {
  const ChannelsSevenOneWide._() : super._();
}

final class ChannelsSevenOneWideSide extends Channels {
  const ChannelsSevenOneWideSide._() : super._();
}

final class ChannelsSevenOneTop extends Channels {
  const ChannelsSevenOneTop._() : super._();
}

final class ChannelsSevenOneRear extends Channels {
  const ChannelsSevenOneRear._() : super._();
}

final class ChannelsOctagonal extends Channels {
  const ChannelsOctagonal._() : super._();
}

final class ChannelsCube extends Channels {
  const ChannelsCube._() : super._();
}

final class ChannelsHexadecagonal extends Channels {
  const ChannelsHexadecagonal._() : super._();
}

final class ChannelsDownmix extends Channels {
  const ChannelsDownmix._() : super._();
}

final class ChannelsSurround222 extends Channels {
  const ChannelsSurround222._() : super._();
}

final class ChannelsCustom extends Channels {
  final String mpvLayout;
  const ChannelsCustom._(this.mpvLayout) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelsCustom && other.mpvLayout == mpvLayout;

  @override
  int get hashCode => Object.hash(ChannelsCustom, mpvLayout);

  @override
  String toString() => 'Channels.custom($mpvLayout)';
}
