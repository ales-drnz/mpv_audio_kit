// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:meta/meta.dart';

import 'mpv_module.dart';

/// Test-only: gets a line for each step of the page's output (init,
/// resume, route).
@visibleForTesting
void Function(String line)? debugWebAudioTrace;

@JS('document.createElement')
external JSObject _createElement(String tag);

/// The property of the module instance that holds the remover of the
/// page's state listener.
const String _kStateListener = '__makStateListenerOff';

/// The page's audio output: the AudioContext of `Module.makWebAudio`, which
/// mpv's webaudio output plays into, shared by every player of the page.
///
/// It is made before any core starts, so the output always finds it: a
/// core without one would fall back to the null output, silent. The
/// autoplay policy starts the context suspended until a user gesture; the
/// module resumes it at every gesture while it is not running, and
/// [resume] does it at a play. [needsGesture] says whether the sound is
/// held meanwhile.
///
/// Output 0 goes to the context's destination, or, with [routeToElement],
/// through a MediaStreamAudioDestinationNode into an `<audio>` element,
/// which the browsers want before they show the media session's controls.
@internal
final class WebAudioOutput {
  WebAudioOutput._(this._module);

  final MpvModule _module;
  MakWebAudio get _audio => _module.c.makWebAudio;
  final StreamController<bool> _gesture = StreamController<bool>.broadcast();
  String _state = 'none';
  int _sampleRate = 0;
  bool _toElement = false;
  JSObject? _element;
  JSObject? _stream;

  /// Makes the context of [module] and loads the worklet; a context of a
  /// replaced program is closed first. Throws when either fails.
  static Future<WebAudioOutput> start(MpvModule module) async {
    final output = WebAudioOutput._(module);
    // One listener per page: a program a Hot Restart replaced left its own
    // on the module.
    final instance = module.instance;
    final previous = instance[_kStateListener];
    if (previous.isA<JSFunction>()) {
      (previous as JSFunction).callAsFunction();
    }
    instance[_kStateListener] = output._audio.onStateChange(
      output._onState.toJS,
    );
    await output._init();
    return output;
  }

  Future<void> _init() async {
    final options = JSObject();
    final processor = _module.processorUrl;
    if (processor != null) options['processorUrl'] = processor.toJS;
    if (_sampleRate > 0) options['sampleRate'] = _sampleRate.toJS;
    debugWebAudioTrace?.call('init $_sampleRate');
    await _audio.init(options).toDart;
    _onState(_audio.state);
    if (_toElement) _route();
  }

  void _onState(String state) {
    final before = needsGesture;
    _state = state;
    if (state == 'running') _playElement();
    if (needsGesture != before) _gesture.add(needsGesture);
  }

  /// Whether the browser holds the sound until a user gesture: the context
  /// is suspended (or, on iOS, interrupted).
  bool get needsGesture => _state == 'suspended' || _state == 'interrupted';

  /// [needsGesture] at each change.
  Stream<bool> get needsGestureChanges => _gesture.stream;

  /// Resumes a context the autoplay policy holds. Called at a play, where a
  /// user gesture is likely; the module also resumes at each gesture.
  void resume() {
    if (!needsGesture) return;
    debugWebAudioTrace?.call('resume');
    _audio.resume().toDart.ignore();
  }

  /// Makes a new context at [rate] (Hz; `0` for the device's), so mpv
  /// resamples to it once and the browser not at all. Every player of the
  /// page plays at that rate: open outputs reopen on the new context.
  Future<void> setSampleRate(int rate) async {
    if (rate == _sampleRate) return;
    _sampleRate = rate;
    await _init();
  }

  /// Sends output 0 through an `<audio>` element ([on]) or straight to the
  /// context's destination.
  void routeToElement(bool on) {
    if (on == _toElement) return;
    _toElement = on;
    _route();
  }

  void _route() {
    final context = _audio.context;
    if (context == null) return;
    final node = _audio.output(0);
    node.callMethod('disconnect'.toJS);
    debugWebAudioTrace?.call('route ${_toElement ? 'element' : 'destination'}');
    if (!_toElement) {
      _element?.callMethod('pause'.toJS);
      _element?['srcObject'] = null;
      node.callMethod('connect'.toJS, context['destination']);
      return;
    }
    final destination =
        context.callMethod('createMediaStreamDestination'.toJS) as JSObject;
    node.callMethod('connect'.toJS, destination);
    _stream = destination['stream'] as JSObject;
    final element = _element ??= _createElement('audio');
    element['srcObject'] = _stream;
    _playElement();
  }

  /// The `<audio>` element output 0 plays through, while routed there.
  JSObject? get element => _toElement ? _element : null;

  void _playElement() {
    final element = this.element;
    if (element == null) return;
    // Refused until a user gesture: the next running state plays it.
    element.callMethod<JSPromise?>('play'.toJS)?.toDart.ignore();
  }
}
