// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// Real-framework test driver for MediaSessionPlugin. Compiled + run via
// `test/media_session/darwin/run.sh`, which links MediaSessionPlugin.swift
// against the FlutterMacOS framework from the example app's build output
// plus MediaPlayer.framework.
//
// Every assertion reads the REAL `MPNowPlayingInfoCenter.default()` and
// `MPRemoteCommandCenter.shared()` — the same process singletons the OS
// reads — so a green run means the OS would see exactly this Now Playing
// state. The plugin is a stateless renderer, so each method-channel call
// publishes synchronously on the main thread; no run-loop spinning, no
// timers, no seek state machine to reason about.

import Foundation
import AppKit
import MediaPlayer
import FlutterMacOS

// ── OS-visible snapshot ──────────────────────────────────────────────────

struct Frame {
  let elapsed: Double?
  let duration: Double?
  let rate: Double
  let playbackState: MPNowPlayingPlaybackState
  let isLiveStream: Bool
  let mediaType: MPNowPlayingInfoMediaType?
  let title: String?

  static func capture() -> Frame {
    let center = MPNowPlayingInfoCenter.default()
    let info = center.nowPlayingInfo ?? [:]
    return Frame(
      elapsed: (info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? NSNumber)?.doubleValue,
      duration: (info[MPMediaItemPropertyPlaybackDuration] as? NSNumber)?.doubleValue,
      rate: (info[MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber)?.doubleValue ?? 0,
      playbackState: center.playbackState,
      isLiveStream: (info[MPNowPlayingInfoPropertyIsLiveStream] as? NSNumber)?.boolValue ?? false,
      mediaType: (info[MPNowPlayingInfoPropertyMediaType] as? NSNumber).flatMap {
        MPNowPlayingInfoMediaType(rawValue: $0.uintValue)
      },
      title: info[MPMediaItemPropertyTitle] as? String)
  }

  var description: String {
    let state: String
    switch playbackState {
    case .playing: state = "playing"
    case .paused: state = "paused"
    case .stopped: state = "stopped"
    case .interrupted: state = "interrupted"
    default: state = "unknown"
    }
    let el = elapsed.map { String(format: "%.2f", $0) } ?? "—"
    return "elapsed=\(el) rate=\(rate) state=\(state)"
  }
}

// ── Harness ──────────────────────────────────────────────────────────────

final class Harness {
  let plugin = MediaSessionPlugin()
  var emitted: [[String: Any]] = []

  init() {
    _ = plugin.onListen(withArguments: nil) { event in
      if let dict = event as? [String: Any] { self.emitted.append(dict) }
    }
  }

  /// Drives a method-channel call. The plugin publishes synchronously
  /// on the main thread, so the OS-visible state is settled on return.
  func call(_ method: String, args: Any?) {
    let mc = FlutterMethodCall(methodName: method, arguments: args)
    plugin.handle(mc) { _ in }
  }

  /// `call` that returns the plugin's answer: nil, a value or a
  /// FlutterError. On the main thread the plugin answers before returning.
  func callResult(_ method: String, args: Any?) -> Any? {
    var reply: Any?
    let mc = FlutterMethodCall(methodName: method, arguments: args)
    plugin.handle(mc) { reply = $0 }
    return reply
  }

  func reset() {
    call("disable", args: nil)
    emitted.removeAll()
  }

  func lastSeekTo() -> [String: Any]? {
    emitted.last { ($0["type"] as? String) == "seekTo" }
  }
}

// ── Assertion helpers ────────────────────────────────────────────────────

var failures: [(scenario: String, message: String)] = []
var currentScenario: String = ""

func check(_ condition: Bool, _ message: @autoclosure () -> String) {
  if !condition {
    failures.append((currentScenario, message()))
    print("  ❌ \(message())")
  }
}

func scenario(_ name: String, _ body: () -> Void) {
  currentScenario = name
  print("▶ \(name)")
  body()
  print("")
}

// ── Fixtures ─────────────────────────────────────────────────────────────

let defaultConfig: [String: Any] = [
  "actions": ["play", "pause", "playPause", "next", "previous", "seek"],
  "interruptionPolicy": "pauseAndResume",
  "fastForwardIntervalMs": 15000,
  "rewindIntervalMs": 15000,
  "supportedPlaybackRates": [0.5, 1.0, 1.5, 2.0],
]

func makeMetadata(durationMs: Int = 300_000) -> [String: Any] {
  [
    "title": "Test Track",
    "artist": "Test Artist",
    "album": "Test Album",
    "durationMs": durationMs,
  ]
}

func makePlayback(playing: Bool = true,
                  positionMs: Int = 30_000,
                  rate: Double = 1.0,
                  seekable: Bool = true,
                  loop: String = "off",
                  shuffle: Bool = false) -> [String: Any]
{
  [
    "playing": playing,
    "positionMs": positionMs,
    "rate": rate,
    "seekable": seekable,
    "loop": loop,
    "shuffle": shuffle,
  ]
}

func enable(_ h: Harness,
            config: [String: Any] = defaultConfig,
            metadata: [String: Any]? = nil,
            playback: [String: Any]? = nil)
{
  h.call("enable", args: [
    "config": config,
    "metadata": metadata ?? makeMetadata(),
    "playback": playback ?? makePlayback(),
  ])
}

// ── Scenarios ────────────────────────────────────────────────────────────

func runEnablePublishesMetadata() {
  scenario("enable publishes title/artist/duration/elapsed/rate + audio type") {
    let h = Harness(); defer { h.reset() }
    enable(h, playback: makePlayback(playing: true, positionMs: 30_000))

    let f = Frame.capture()
    check(f.playbackState == .playing, "must be .playing, got \(f.description)")
    check(f.elapsed == 30.0, "elapsed must be 30.0, got \(f.description)")
    check(f.duration == 300.0, "duration must be 300.0, got \(f.description)")
    check(f.rate == 1.0, "rate must be 1.0, got \(f.description)")
    check(f.title == "Test Track", "title must publish, got \(String(describing: f.title))")
    check(f.mediaType == .audio, "mediaType must be .audio")
    check(!f.isLiveStream, "a seekable source is not a live stream")
  }
}

func runPauseAndResume() {
  scenario("pause → rate 0 / .paused, resume → rate 1 / .playing") {
    let h = Harness(); defer { h.reset() }
    enable(h, playback: makePlayback(playing: true, positionMs: 30_000))

    h.call("updatePlayback", args: makePlayback(playing: false, positionMs: 30_000))
    var f = Frame.capture()
    check(f.playbackState == .paused, "pause must be .paused, got \(f.description)")
    check(f.rate == 0.0, "pause must publish rate 0, got \(f.description)")

    h.call("updatePlayback", args: makePlayback(playing: true, positionMs: 30_000))
    f = Frame.capture()
    check(f.playbackState == .playing, "resume must be .playing, got \(f.description)")
    check(f.rate == 1.0, "resume must publish rate 1, got \(f.description)")
  }
}

func runScrubFreezeThenLand() {
  scenario("scrub pins the slider (rate 0) then the landed push releases it") {
    let h = Harness(); defer { h.reset() }
    enable(h, playback: makePlayback(playing: true, positionMs: 30_000))

    // User drops the Control Center scrubber at 60s.
    h.plugin.handleScrub(to: 60.0)
    let frozen = Frame.capture()
    check(frozen.elapsed == 60.0, "slider must pin at 60.0, got \(frozen.description)")
    check(frozen.rate == 0.0, "freeze must publish rate 0, got \(frozen.description)")
    check(frozen.playbackState == .playing,
          "freeze keeps the play intent, got \(frozen.description)")
    check(h.plugin.frozenElapsed == 60.0, "frozenElapsed must be set")

    let seekTo = h.lastSeekTo()
    check(seekTo != nil, "a seekTo must be forwarded to Dart")
    check((seekTo?["positionMs"] as? Int) == 60_000,
          "seekTo must carry 60000 ms, got \(String(describing: seekTo))")
    check(seekTo?["seekId"] == nil, "no seekId in the simplified protocol")

    // Dart pushes the landed position (the seek completed). The freeze
    // releases and the real position takes over.
    h.call("updatePlayback", args: makePlayback(playing: true, positionMs: 60_000))
    let landed = Frame.capture()
    check(h.plugin.frozenElapsed == nil, "landed push must clear the freeze")
    check(landed.elapsed == 60.0, "landed elapsed must be 60.0, got \(landed.description)")
    check(landed.rate == 1.0, "landed rate must be 1.0, got \(landed.description)")
    check(landed.playbackState == .playing, "still .playing after landing")
  }
}

func runScrubWhilePaused() {
  scenario("scrub while paused keeps .paused, pins the target") {
    let h = Harness(); defer { h.reset() }
    enable(h, playback: makePlayback(playing: false, positionMs: 30_000))
    check(Frame.capture().playbackState == .paused, "baseline must be .paused")

    h.plugin.handleScrub(to: 60.0)
    let f = Frame.capture()
    check(f.elapsed == 60.0, "slider must pin at 60.0, got \(f.description)")
    check(f.rate == 0.0, "rate 0, got \(f.description)")
    check(f.playbackState == .paused, "must stay .paused, got \(f.description)")
    check((h.lastSeekTo()?["positionMs"] as? Int) == 60_000, "seekTo must carry 60000")
  }
}

func runLiveStreamSuppressesScrubber() {
  scenario("non-seekable source → live stream, no elapsed, scrubber disabled") {
    let h = Harness(); defer { h.reset() }
    enable(h,
           metadata: makeMetadata(durationMs: 0),
           playback: makePlayback(playing: true, positionMs: 0, seekable: false))

    let f = Frame.capture()
    check(f.isLiveStream, "non-seekable must publish IsLiveStream")
    check(f.elapsed == nil, "live stream must not publish elapsed, got \(f.description)")
    check(!MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled,
          "scrubber must be disabled for a live stream")
  }
}

func runCommandGating() {
  scenario("only configured actions enable their commands") {
    let h = Harness(); defer { h.reset() }
    enable(h)  // actions: play, pause, playPause, next, previous, seek

    let c = MPRemoteCommandCenter.shared()
    check(c.playCommand.isEnabled, "play must be enabled")
    check(c.pauseCommand.isEnabled, "pause must be enabled")
    check(c.nextTrackCommand.isEnabled, "next must be enabled")
    check(c.previousTrackCommand.isEnabled, "previous must be enabled")
    check(c.changePlaybackPositionCommand.isEnabled, "seek must be enabled")
    check(!c.stopCommand.isEnabled, "stop must be disabled (not in actions)")
    check(!c.changeRepeatModeCommand.isEnabled, "repeat off by default")
    // Unsupported commands are always pinned off.
    check(!c.likeCommand.isEnabled, "like must be pinned disabled")
    check(!c.seekForwardCommand.isEnabled, "seekForward must be pinned disabled")

    // Reconfigure to a narrower set.
    var cfg = defaultConfig
    cfg["actions"] = ["play"]
    h.call("updateConfig", args: cfg)
    check(c.playCommand.isEnabled, "play stays enabled")
    check(!c.pauseCommand.isEnabled, "pause now disabled")
    check(!c.nextTrackCommand.isEnabled, "next now disabled")
  }
}

func runRepeatShuffleVisualState() {
  scenario("loop / shuffle drive the OS repeat / shuffle indicators") {
    let h = Harness(); defer { h.reset() }
    enable(h, playback: makePlayback(loop: "playlist", shuffle: true))

    let c = MPRemoteCommandCenter.shared()
    check(c.changeRepeatModeCommand.currentRepeatType == .all,
          "loop=playlist → repeat .all")
    check(c.changeShuffleModeCommand.currentShuffleType == .items,
          "shuffle=true → shuffle .items")

    h.call("updatePlayback", args: makePlayback(loop: "file", shuffle: false))
    check(c.changeRepeatModeCommand.currentRepeatType == .one,
          "loop=file → repeat .one")
    check(c.changeShuffleModeCommand.currentShuffleType == .off,
          "shuffle=false → shuffle .off")
  }
}

func runDedupCoalescesIdenticalPushes() {
  scenario("an identical updatePlayback dedups (no redundant publish)") {
    let h = Harness(); defer { h.reset() }
    enable(h, playback: makePlayback(playing: true, positionMs: 30_000))

    let baseline = h.plugin.publishCount
    // Same values → composed dict is identical → dedup.
    h.call("updatePlayback", args: makePlayback(playing: true, positionMs: 30_000))
    check(h.plugin.publishCount == baseline,
          "identical push must dedup; publishCount went \(baseline)→\(h.plugin.publishCount)")

    // A real change publishes.
    h.call("updatePlayback", args: makePlayback(playing: false, positionMs: 30_000))
    check(h.plugin.publishCount == baseline + 1, "a real change must publish")
  }
}

func runDisableClearsNowPlaying() {
  scenario("disable clears Now Playing and marks .stopped") {
    let h = Harness()
    enable(h, playback: makePlayback(playing: true, positionMs: 30_000))
    check(Frame.capture().title == "Test Track", "precondition: published")

    h.call("disable", args: nil)
    let f = Frame.capture()
    check(f.title == nil, "disable must clear nowPlayingInfo, got \(String(describing: f.title))")
    check(f.elapsed == nil, "disable must clear elapsed")
    check(f.playbackState == .stopped, "disable must mark .stopped, got \(f.description)")
  }
}

/// macOS "poison" guard: enabling with no title (the app-launch case,
/// before any media is loaded) must NOT publish a content-less entry —
/// that drops the app from Control Center. Once a real title arrives, it
/// publishes normally.
func runNoTitlePoisonGuard() {
  scenario("no-title enable does not publish (macOS poison guard)") {
    let h = Harness(); defer { h.reset() }

    h.call("enable", args: [
      "config": defaultConfig,
      "metadata": ["durationMs": 0],  // no title — nothing loaded yet
      "playback": makePlayback(playing: false, positionMs: 0),
    ])
    check(h.plugin.publishCount == 0,
          "content-less enable must not publish; got \(h.plugin.publishCount)")
    check(Frame.capture().title == nil, "no title must reach the OS")

    // A real title + playing → now it publishes.
    h.call("updateMetadata", args: makeMetadata())
    h.call("updatePlayback", args: makePlayback(playing: true, positionMs: 0))
    let f = Frame.capture()
    check(f.title == "Test Track",
          "publishes once a title exists; got \(String(describing: f.title))")
    check(f.playbackState == .playing, "and reflects playing; got \(f.description)")
    check(h.plugin.publishCount > 0, "publishCount must increase once content exists")
  }
}

/// A routine push (loop/shuffle/rate) that lands while a scrub-initiated
/// seek is still in flight carries the stale pre-seek position. It must NOT
/// release the freeze — otherwise the slider snaps back from the drop
/// target to the old position. Only a push whose position reached the
/// frozen target releases it.
func runFreezeHeldOnStalePush() {
  scenario("a stale routine push during an in-flight seek keeps the scrub freeze") {
    let h = Harness(); defer { h.reset() }
    enable(h, playback: makePlayback(playing: true, positionMs: 30_000))

    h.plugin.handleScrub(to: 60.0)
    check(h.plugin.frozenElapsed == 60.0, "precondition: frozen at 60")

    // Loop-mode change pushes while the seek is in flight, still at 30s.
    h.call("updatePlayback",
           args: makePlayback(playing: true, positionMs: 30_000, loop: "file"))
    check(h.plugin.frozenElapsed == 60.0,
          "stale push must keep the freeze; got \(String(describing: h.plugin.frozenElapsed))")
    let held = Frame.capture()
    check(held.elapsed == 60.0, "slider must stay pinned at 60, got \(held.description)")
    check(held.rate == 0.0, "frozen rate stays 0, got \(held.description)")

    // The landed push (position ≈ frozen target) releases the freeze.
    h.call("updatePlayback",
           args: makePlayback(playing: true, positionMs: 60_000, loop: "file"))
    check(h.plugin.frozenElapsed == nil, "landed push must release the freeze")
    check(Frame.capture().elapsed == 60.0, "elapsed tracks the landed position")
  }
}

func runNonSeekableWithDurationIsNotLive() {
  scenario("non-seekable but known-duration source is NOT treated as live") {
    let h = Harness(); defer { h.reset() }
    enable(h,
           metadata: makeMetadata(durationMs: 300_000),
           playback: makePlayback(playing: true, positionMs: 30_000, seekable: false))

    let f = Frame.capture()
    check(!f.isLiveStream, "known duration ⇒ not live, got \(f.description)")
    check(f.duration == 300.0, "duration must publish, got \(f.description)")
    check(f.elapsed == 30.0, "elapsed must publish, got \(f.description)")
    // Scrubber stays disabled — seek is gated on `seekable`, independent of live.
    check(!MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled,
          "scrubber disabled because the source isn't seekable")
  }
}

/// Two engines (add-to-app): A owns the session and plays, B's enable was
/// refused. B's Player still sends `disable` when it is disposed, and that
/// must not retire A's entry or its commands.
func runNonOwnerDisableKeepsOwnerEntry() {
  scenario("a disable from an engine that does not own the session keeps the owner's") {
    let a = Harness(); defer { a.reset() }
    enable(a, playback: makePlayback(playing: true, positionMs: 30_000))
    let b = Harness()
    enable(b)
    check(!b.plugin.enabled, "precondition: the second engine's enable is refused")

    b.call("disable", args: nil)
    let f = Frame.capture()
    check(f.title == "Test Track",
          "the owner's entry must stay, got \(String(describing: f.title))")
    check(f.playbackState == .playing, "the owner's state must stay, got \(f.description)")
    check(MPRemoteCommandCenter.shared().playCommand.isEnabled,
          "the owner's commands must stay enabled")
  }
}

/// Two engines: A owns the session. B's enable is refused with the error
/// Dart turns into a StateError, and B's pushes leave A's entry alone. Once
/// A disables, B's enable is accepted.
func runSecondEngineEnableIsRefused() {
  scenario("a second engine's enable is refused as already_owned, its pushes ignored") {
    let a = Harness()
    enable(a, playback: makePlayback(playing: true, positionMs: 30_000))
    let b = Harness(); defer { b.reset() }
    var other = makeMetadata()
    other["title"] = "Second Engine"
    let reply = b.callResult("enable", args: [
      "config": defaultConfig,
      "metadata": other,
      "playback": makePlayback(playing: false, positionMs: 0),
    ])
    check((reply as? FlutterError)?.code == "already_owned",
          "the refusal must reach Dart as already_owned, got \(String(describing: reply))")

    b.call("updateMetadata", args: other)
    b.call("updatePlayback", args: makePlayback(playing: false, positionMs: 0))
    let f = Frame.capture()
    check(f.title == "Test Track",
          "B's metadata must not reach the entry, got \(String(describing: f.title))")
    check(f.playbackState == .playing, "B's playback must not reach the entry, got \(f.description)")

    a.reset()
    let accepted = b.callResult("enable", args: [
      "config": defaultConfig,
      "metadata": other,
      "playback": makePlayback(playing: false, positionMs: 0),
    ])
    check(accepted == nil && b.plugin.enabled,
          "B's enable must be accepted once A disabled, got \(String(describing: accepted))")
    check(Frame.capture().title == "Second Engine", "B's entry must be published")
  }
}

/// An engine released without its Dart side calling `disable` (add-to-app):
/// its detach retires the entry, so no Now Playing entry is left whose
/// commands fail. The detach of another engine leaves the
/// owner's entry alone.
func runDetachRetiresTheOwnersEntry() {
  scenario("the owner's engine detach retires the entry, another engine's does not") {
    let a = Harness()
    enable(a, playback: makePlayback(playing: true, positionMs: 30_000))
    let b = Harness()

    b.plugin.detachEngine()
    check(Frame.capture().title == "Test Track",
          "another engine's detach must keep the owner's entry")

    a.plugin.detachEngine()
    let f = Frame.capture()
    check(f.title == nil, "the owner's detach must clear the entry, got \(f.description)")
    check(f.playbackState == .stopped, "the owner's detach must mark .stopped, got \(f.description)")
    check(!MPRemoteCommandCenter.shared().playCommand.isEnabled,
          "the owner's detach must disable the commands")

    // The session is free for another engine.
    let c = Harness(); defer { c.reset() }
    enable(c)
    check(c.plugin.enabled, "a new engine can enable after the detach")
  }
}

/// Artwork arrives as bytes only: Dart downloads a remote cover and reads
/// a file:// one. The bytes publish it, metadata without them retires it,
/// and a URL on its own publishes nothing.
func runArtworkFromBytesOnly() {
  scenario("artwork bytes publish the cover, their absence removes it") {
    let h = Harness(); defer { h.reset() }
    // A 1x1 PNG.
    let png = Data(base64Encoded:
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
    func artwork() -> Any? {
      MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork]
    }

    var withArt = makeMetadata()
    withArt["artworkBytes"] = FlutterStandardTypedData(bytes: png)
    withArt["artworkMime"] = "image/png"
    enable(h, metadata: withArt)
    check(artwork() is MPMediaItemArtwork, "the bytes must publish the artwork")

    h.call("updateMetadata", args: makeMetadata())
    check(artwork() == nil, "metadata without bytes must remove the artwork")

    var withUrl = makeMetadata()
    withUrl["artworkUri"] = "file:///covers/a.png"
    h.call("updateMetadata", args: withUrl)
    check(artwork() == nil, "a URL alone must not publish artwork")
  }
}

// ── Entry point ──────────────────────────────────────────────────────────

print("=== MediaSessionPlugin renderer tests ===\n")

runEnablePublishesMetadata()
runPauseAndResume()
runScrubFreezeThenLand()
runScrubWhilePaused()
runFreezeHeldOnStalePush()
runLiveStreamSuppressesScrubber()
runNonSeekableWithDurationIsNotLive()
runCommandGating()
runRepeatShuffleVisualState()
runDedupCoalescesIdenticalPushes()
runDisableClearsNowPlaying()
runNoTitlePoisonGuard()
runNonOwnerDisableKeepsOwnerEntry()
runSecondEngineEnableIsRefused()
runDetachRetiresTheOwnersEntry()
runArtworkFromBytesOnly()

print("=== Summary ===")
if failures.isEmpty {
  print("✅ all checks passed")
  exit(0)
} else {
  print("❌ \(failures.count) failure(s):")
  for (scen, msg) in failures {
    print("  • [\(scen)] \(msg)")
  }
  exit(1)
}
