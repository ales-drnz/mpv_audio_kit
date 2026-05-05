// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do not edit by hand.
// ignore_for_file: constant_identifier_names, camel_case_types, non_constant_identifier_names

enum AcompressorDetection {
  peak,
  rms,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcompressorDetection.peak:
        return 'peak';
      case AcompressorDetection.rms:
        return 'rms';
    }
  }

  /// Parses an mpv wire string back into a [AcompressorDetection].
  /// Unknown / empty input falls back to the first member.
  static AcompressorDetection fromMpv(String? raw) {
    switch (raw) {
      case 'peak':
        return AcompressorDetection.peak;
      case 'rms':
        return AcompressorDetection.rms;
      default:
        return AcompressorDetection.peak;
    }
  }
}

enum AcompressorLink {
  average,
  maximum,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcompressorLink.average:
        return 'average';
      case AcompressorLink.maximum:
        return 'maximum';
    }
  }

  /// Parses an mpv wire string back into a [AcompressorLink].
  /// Unknown / empty input falls back to the first member.
  static AcompressorLink fromMpv(String? raw) {
    switch (raw) {
      case 'average':
        return AcompressorLink.average;
      case 'maximum':
        return AcompressorLink.maximum;
      default:
        return AcompressorLink.average;
    }
  }
}

enum AcompressorMode {
  downward,
  upward,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcompressorMode.downward:
        return 'downward';
      case AcompressorMode.upward:
        return 'upward';
    }
  }

  /// Parses an mpv wire string back into a [AcompressorMode].
  /// Unknown / empty input falls back to the first member.
  static AcompressorMode fromMpv(String? raw) {
    switch (raw) {
      case 'downward':
        return AcompressorMode.downward;
      case 'upward':
        return AcompressorMode.upward;
      default:
        return AcompressorMode.downward;
    }
  }
}

enum AcrusherMode {
  /// linear
  lin,

  /// logarithmic
  log,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcrusherMode.lin:
        return 'lin';
      case AcrusherMode.log:
        return 'log';
    }
  }

  /// Parses an mpv wire string back into a [AcrusherMode].
  /// Unknown / empty input falls back to the first member.
  static AcrusherMode fromMpv(String? raw) {
    switch (raw) {
      case 'lin':
        return AcrusherMode.lin;
      case 'log':
        return AcrusherMode.log;
      default:
        return AcrusherMode.lin;
    }
  }
}

enum AdeclickM {
  /// overlap-add
  add,

  /// overlap-add
  a,

  /// overlap-save
  save,

  /// overlap-save
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdeclickM.add:
        return 'add';
      case AdeclickM.a:
        return 'a';
      case AdeclickM.save:
        return 'save';
      case AdeclickM.s:
        return 's';
    }
  }

  /// Parses an mpv wire string back into a [AdeclickM].
  /// Unknown / empty input falls back to the first member.
  static AdeclickM fromMpv(String? raw) {
    switch (raw) {
      case 'add':
        return AdeclickM.add;
      case 'a':
        return AdeclickM.a;
      case 'save':
        return AdeclickM.save;
      case 's':
        return AdeclickM.s;
      default:
        return AdeclickM.add;
    }
  }
}

enum AdeclipM {
  /// overlap-add
  add,

  /// overlap-add
  a,

  /// overlap-save
  save,

  /// overlap-save
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdeclipM.add:
        return 'add';
      case AdeclipM.a:
        return 'a';
      case AdeclipM.save:
        return 'save';
      case AdeclipM.s:
        return 's';
    }
  }

  /// Parses an mpv wire string back into a [AdeclipM].
  /// Unknown / empty input falls back to the first member.
  static AdeclipM fromMpv(String? raw) {
    switch (raw) {
      case 'add':
        return AdeclipM.add;
      case 'a':
        return AdeclipM.a;
      case 'save':
        return AdeclipM.save;
      case 's':
        return AdeclipM.s;
      default:
        return AdeclipM.add;
    }
  }
}

enum AdenormType {
  dc,
  ac,
  square,
  pulse,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdenormType.dc:
        return 'dc';
      case AdenormType.ac:
        return 'ac';
      case AdenormType.square:
        return 'square';
      case AdenormType.pulse:
        return 'pulse';
    }
  }

  /// Parses an mpv wire string back into a [AdenormType].
  /// Unknown / empty input falls back to the first member.
  static AdenormType fromMpv(String? raw) {
    switch (raw) {
      case 'dc':
        return AdenormType.dc;
      case 'ac':
        return AdenormType.ac;
      case 'square':
        return AdenormType.square;
      case 'pulse':
        return AdenormType.pulse;
      default:
        return AdenormType.dc;
    }
  }
}

enum AdynamicequalizerAuto {
  disabled,
  off,
  on_,
  adaptive,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerAuto.disabled:
        return 'disabled';
      case AdynamicequalizerAuto.off:
        return 'off';
      case AdynamicequalizerAuto.on_:
        return 'on';
      case AdynamicequalizerAuto.adaptive:
        return 'adaptive';
    }
  }

  /// Parses an mpv wire string back into a [AdynamicequalizerAuto].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerAuto fromMpv(String? raw) {
    switch (raw) {
      case 'disabled':
        return AdynamicequalizerAuto.disabled;
      case 'off':
        return AdynamicequalizerAuto.off;
      case 'on':
        return AdynamicequalizerAuto.on_;
      case 'adaptive':
        return AdynamicequalizerAuto.adaptive;
      default:
        return AdynamicequalizerAuto.disabled;
    }
  }
}

enum AdynamicequalizerDftype {
  bandpass,
  lowpass,
  highpass,
  peak,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerDftype.bandpass:
        return 'bandpass';
      case AdynamicequalizerDftype.lowpass:
        return 'lowpass';
      case AdynamicequalizerDftype.highpass:
        return 'highpass';
      case AdynamicequalizerDftype.peak:
        return 'peak';
    }
  }

  /// Parses an mpv wire string back into a [AdynamicequalizerDftype].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerDftype fromMpv(String? raw) {
    switch (raw) {
      case 'bandpass':
        return AdynamicequalizerDftype.bandpass;
      case 'lowpass':
        return AdynamicequalizerDftype.lowpass;
      case 'highpass':
        return AdynamicequalizerDftype.highpass;
      case 'peak':
        return AdynamicequalizerDftype.peak;
      default:
        return AdynamicequalizerDftype.bandpass;
    }
  }
}

enum AdynamicequalizerMode {
  listen,
  cutbelow,
  cutabove,
  boostbelow,
  boostabove,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerMode.listen:
        return 'listen';
      case AdynamicequalizerMode.cutbelow:
        return 'cutbelow';
      case AdynamicequalizerMode.cutabove:
        return 'cutabove';
      case AdynamicequalizerMode.boostbelow:
        return 'boostbelow';
      case AdynamicequalizerMode.boostabove:
        return 'boostabove';
    }
  }

  /// Parses an mpv wire string back into a [AdynamicequalizerMode].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerMode fromMpv(String? raw) {
    switch (raw) {
      case 'listen':
        return AdynamicequalizerMode.listen;
      case 'cutbelow':
        return AdynamicequalizerMode.cutbelow;
      case 'cutabove':
        return AdynamicequalizerMode.cutabove;
      case 'boostbelow':
        return AdynamicequalizerMode.boostbelow;
      case 'boostabove':
        return AdynamicequalizerMode.boostabove;
      default:
        return AdynamicequalizerMode.listen;
    }
  }
}

enum AdynamicequalizerPrecision {
  /// set auto processing precision
  auto,

  /// set single-floating point processing precision
  float,

  /// set double-floating point processing precision
  double_,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerPrecision.auto:
        return 'auto';
      case AdynamicequalizerPrecision.float:
        return 'float';
      case AdynamicequalizerPrecision.double_:
        return 'double';
    }
  }

  /// Parses an mpv wire string back into a [AdynamicequalizerPrecision].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return AdynamicequalizerPrecision.auto;
      case 'float':
        return AdynamicequalizerPrecision.float;
      case 'double':
        return AdynamicequalizerPrecision.double_;
      default:
        return AdynamicequalizerPrecision.auto;
    }
  }
}

enum AdynamicequalizerTftype {
  bell,
  lowshelf,
  highshelf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerTftype.bell:
        return 'bell';
      case AdynamicequalizerTftype.lowshelf:
        return 'lowshelf';
      case AdynamicequalizerTftype.highshelf:
        return 'highshelf';
    }
  }

  /// Parses an mpv wire string back into a [AdynamicequalizerTftype].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerTftype fromMpv(String? raw) {
    switch (raw) {
      case 'bell':
        return AdynamicequalizerTftype.bell;
      case 'lowshelf':
        return AdynamicequalizerTftype.lowshelf;
      case 'highshelf':
        return AdynamicequalizerTftype.highshelf;
      default:
        return AdynamicequalizerTftype.bell;
    }
  }
}

enum AemphasisMode {
  reproduction,
  production,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AemphasisMode.reproduction:
        return 'reproduction';
      case AemphasisMode.production:
        return 'production';
    }
  }

  /// Parses an mpv wire string back into a [AemphasisMode].
  /// Unknown / empty input falls back to the first member.
  static AemphasisMode fromMpv(String? raw) {
    switch (raw) {
      case 'reproduction':
        return AemphasisMode.reproduction;
      case 'production':
        return AemphasisMode.production;
      default:
        return AemphasisMode.reproduction;
    }
  }
}

enum AemphasisType {
  /// Columbia
  col,

  /// EMI
  emi,

  /// BSI (78RPM)
  bsi,

  /// RIAA
  riaa,

  /// Compact Disc (CD)
  cd,

  /// 50µs (FM)
  n50fm,

  /// 75µs (FM)
  n75fm,

  /// 50µs (FM-KF)
  n50kf,

  /// 75µs (FM-KF)
  n75kf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AemphasisType.col:
        return 'col';
      case AemphasisType.emi:
        return 'emi';
      case AemphasisType.bsi:
        return 'bsi';
      case AemphasisType.riaa:
        return 'riaa';
      case AemphasisType.cd:
        return 'cd';
      case AemphasisType.n50fm:
        return '50fm';
      case AemphasisType.n75fm:
        return '75fm';
      case AemphasisType.n50kf:
        return '50kf';
      case AemphasisType.n75kf:
        return '75kf';
    }
  }

  /// Parses an mpv wire string back into a [AemphasisType].
  /// Unknown / empty input falls back to the first member.
  static AemphasisType fromMpv(String? raw) {
    switch (raw) {
      case 'col':
        return AemphasisType.col;
      case 'emi':
        return AemphasisType.emi;
      case 'bsi':
        return AemphasisType.bsi;
      case 'riaa':
        return AemphasisType.riaa;
      case 'cd':
        return AemphasisType.cd;
      case '50fm':
        return AemphasisType.n50fm;
      case '75fm':
        return AemphasisType.n75fm;
      case '50kf':
        return AemphasisType.n50kf;
      case '75kf':
        return AemphasisType.n75kf;
      default:
        return AemphasisType.col;
    }
  }
}

enum AfadeCurve {
  /// no fade; keep audio as-is
  nofade,

  /// linear slope
  tri,

  /// quarter of sine wave
  qsin,

  /// exponential sine wave
  esin,

  /// half of sine wave
  hsin,

  /// logarithmic
  log,

  /// inverted parabola
  ipar,

  /// quadratic
  qua,

  /// cubic
  cub,

  /// square root
  squ,

  /// cubic root
  cbr,

  /// parabola
  par,

  /// exponential
  exp,

  /// inverted quarter of sine wave
  iqsin,

  /// inverted half of sine wave
  ihsin,

  /// double-exponential seat
  dese,

  /// double-exponential sigmoid
  desi,

  /// logistic sigmoid
  losi,

  /// sine cardinal function
  sinc,

  /// inverted sine cardinal function
  isinc,

  /// quartic
  quat,

  /// quartic root
  quatr,

  /// squared quarter of sine wave
  qsin2,

  /// squared half of sine wave
  hsin2,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfadeCurve.nofade:
        return 'nofade';
      case AfadeCurve.tri:
        return 'tri';
      case AfadeCurve.qsin:
        return 'qsin';
      case AfadeCurve.esin:
        return 'esin';
      case AfadeCurve.hsin:
        return 'hsin';
      case AfadeCurve.log:
        return 'log';
      case AfadeCurve.ipar:
        return 'ipar';
      case AfadeCurve.qua:
        return 'qua';
      case AfadeCurve.cub:
        return 'cub';
      case AfadeCurve.squ:
        return 'squ';
      case AfadeCurve.cbr:
        return 'cbr';
      case AfadeCurve.par:
        return 'par';
      case AfadeCurve.exp:
        return 'exp';
      case AfadeCurve.iqsin:
        return 'iqsin';
      case AfadeCurve.ihsin:
        return 'ihsin';
      case AfadeCurve.dese:
        return 'dese';
      case AfadeCurve.desi:
        return 'desi';
      case AfadeCurve.losi:
        return 'losi';
      case AfadeCurve.sinc:
        return 'sinc';
      case AfadeCurve.isinc:
        return 'isinc';
      case AfadeCurve.quat:
        return 'quat';
      case AfadeCurve.quatr:
        return 'quatr';
      case AfadeCurve.qsin2:
        return 'qsin2';
      case AfadeCurve.hsin2:
        return 'hsin2';
    }
  }

  /// Parses an mpv wire string back into a [AfadeCurve].
  /// Unknown / empty input falls back to the first member.
  static AfadeCurve fromMpv(String? raw) {
    switch (raw) {
      case 'nofade':
        return AfadeCurve.nofade;
      case 'tri':
        return AfadeCurve.tri;
      case 'qsin':
        return AfadeCurve.qsin;
      case 'esin':
        return AfadeCurve.esin;
      case 'hsin':
        return AfadeCurve.hsin;
      case 'log':
        return AfadeCurve.log;
      case 'ipar':
        return AfadeCurve.ipar;
      case 'qua':
        return AfadeCurve.qua;
      case 'cub':
        return AfadeCurve.cub;
      case 'squ':
        return AfadeCurve.squ;
      case 'cbr':
        return AfadeCurve.cbr;
      case 'par':
        return AfadeCurve.par;
      case 'exp':
        return AfadeCurve.exp;
      case 'iqsin':
        return AfadeCurve.iqsin;
      case 'ihsin':
        return AfadeCurve.ihsin;
      case 'dese':
        return AfadeCurve.dese;
      case 'desi':
        return AfadeCurve.desi;
      case 'losi':
        return AfadeCurve.losi;
      case 'sinc':
        return AfadeCurve.sinc;
      case 'isinc':
        return AfadeCurve.isinc;
      case 'quat':
        return AfadeCurve.quat;
      case 'quatr':
        return AfadeCurve.quatr;
      case 'qsin2':
        return AfadeCurve.qsin2;
      case 'hsin2':
        return AfadeCurve.hsin2;
      default:
        return AfadeCurve.nofade;
    }
  }
}

enum AfadeType {
  /// fade-in
  in_,

  /// fade-out
  out,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfadeType.in_:
        return 'in';
      case AfadeType.out:
        return 'out';
    }
  }

  /// Parses an mpv wire string back into a [AfadeType].
  /// Unknown / empty input falls back to the first member.
  static AfadeType fromMpv(String? raw) {
    switch (raw) {
      case 'in':
        return AfadeType.in_;
      case 'out':
        return AfadeType.out;
      default:
        return AfadeType.in_;
    }
  }
}

enum AfftdnLink {
  /// none
  none,

  /// min
  min,

  /// max
  max,

  /// average
  average,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnLink.none:
        return 'none';
      case AfftdnLink.min:
        return 'min';
      case AfftdnLink.max:
        return 'max';
      case AfftdnLink.average:
        return 'average';
    }
  }

  /// Parses an mpv wire string back into a [AfftdnLink].
  /// Unknown / empty input falls back to the first member.
  static AfftdnLink fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return AfftdnLink.none;
      case 'min':
        return AfftdnLink.min;
      case 'max':
        return AfftdnLink.max;
      case 'average':
        return AfftdnLink.average;
      default:
        return AfftdnLink.none;
    }
  }
}

enum AfftdnMode {
  /// input
  input,

  /// input
  i,

  /// output
  output,

  /// output
  o,

  /// noise
  noise,

  /// noise
  n,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnMode.input:
        return 'input';
      case AfftdnMode.i:
        return 'i';
      case AfftdnMode.output:
        return 'output';
      case AfftdnMode.o:
        return 'o';
      case AfftdnMode.noise:
        return 'noise';
      case AfftdnMode.n:
        return 'n';
    }
  }

  /// Parses an mpv wire string back into a [AfftdnMode].
  /// Unknown / empty input falls back to the first member.
  static AfftdnMode fromMpv(String? raw) {
    switch (raw) {
      case 'input':
        return AfftdnMode.input;
      case 'i':
        return AfftdnMode.i;
      case 'output':
        return AfftdnMode.output;
      case 'o':
        return AfftdnMode.o;
      case 'noise':
        return AfftdnMode.noise;
      case 'n':
        return AfftdnMode.n;
      default:
        return AfftdnMode.input;
    }
  }
}

enum AfftdnSample {
  /// none
  none,

  /// start
  start,

  /// start
  begin,

  /// stop
  stop,

  /// stop
  end,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnSample.none:
        return 'none';
      case AfftdnSample.start:
        return 'start';
      case AfftdnSample.begin:
        return 'begin';
      case AfftdnSample.stop:
        return 'stop';
      case AfftdnSample.end:
        return 'end';
    }
  }

  /// Parses an mpv wire string back into a [AfftdnSample].
  /// Unknown / empty input falls back to the first member.
  static AfftdnSample fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return AfftdnSample.none;
      case 'start':
        return AfftdnSample.start;
      case 'begin':
        return AfftdnSample.begin;
      case 'stop':
        return AfftdnSample.stop;
      case 'end':
        return AfftdnSample.end;
      default:
        return AfftdnSample.none;
    }
  }
}

enum AfftdnType {
  /// white noise
  white,

  /// white noise
  w,

  /// vinyl noise
  vinyl,

  /// vinyl noise
  v,

  /// shellac noise
  shellac,

  /// shellac noise
  s,

  /// custom noise
  custom,

  /// custom noise
  c,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnType.white:
        return 'white';
      case AfftdnType.w:
        return 'w';
      case AfftdnType.vinyl:
        return 'vinyl';
      case AfftdnType.v:
        return 'v';
      case AfftdnType.shellac:
        return 'shellac';
      case AfftdnType.s:
        return 's';
      case AfftdnType.custom:
        return 'custom';
      case AfftdnType.c:
        return 'c';
    }
  }

  /// Parses an mpv wire string back into a [AfftdnType].
  /// Unknown / empty input falls back to the first member.
  static AfftdnType fromMpv(String? raw) {
    switch (raw) {
      case 'white':
        return AfftdnType.white;
      case 'w':
        return AfftdnType.w;
      case 'vinyl':
        return AfftdnType.vinyl;
      case 'v':
        return AfftdnType.v;
      case 'shellac':
        return AfftdnType.shellac;
      case 's':
        return AfftdnType.s;
      case 'custom':
        return AfftdnType.custom;
      case 'c':
        return AfftdnType.c;
      default:
        return AfftdnType.white;
    }
  }
}

enum AfwtdnWavet {
  /// sym2
  sym2,

  /// sym4
  sym4,

  /// rbior68
  rbior68,

  /// deb10
  deb10,

  /// sym10
  sym10,

  /// coif5
  coif5,

  /// bl3
  bl3,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfwtdnWavet.sym2:
        return 'sym2';
      case AfwtdnWavet.sym4:
        return 'sym4';
      case AfwtdnWavet.rbior68:
        return 'rbior68';
      case AfwtdnWavet.deb10:
        return 'deb10';
      case AfwtdnWavet.sym10:
        return 'sym10';
      case AfwtdnWavet.coif5:
        return 'coif5';
      case AfwtdnWavet.bl3:
        return 'bl3';
    }
  }

  /// Parses an mpv wire string back into a [AfwtdnWavet].
  /// Unknown / empty input falls back to the first member.
  static AfwtdnWavet fromMpv(String? raw) {
    switch (raw) {
      case 'sym2':
        return AfwtdnWavet.sym2;
      case 'sym4':
        return AfwtdnWavet.sym4;
      case 'rbior68':
        return AfwtdnWavet.rbior68;
      case 'deb10':
        return AfwtdnWavet.deb10;
      case 'sym10':
        return AfwtdnWavet.sym10;
      case 'coif5':
        return AfwtdnWavet.coif5;
      case 'bl3':
        return AfwtdnWavet.bl3;
      default:
        return AfwtdnWavet.sym2;
    }
  }
}

enum AgateDetection {
  peak,
  rms,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AgateDetection.peak:
        return 'peak';
      case AgateDetection.rms:
        return 'rms';
    }
  }

  /// Parses an mpv wire string back into a [AgateDetection].
  /// Unknown / empty input falls back to the first member.
  static AgateDetection fromMpv(String? raw) {
    switch (raw) {
      case 'peak':
        return AgateDetection.peak;
      case 'rms':
        return AgateDetection.rms;
      default:
        return AgateDetection.peak;
    }
  }
}

enum AgateLink {
  average,
  maximum,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AgateLink.average:
        return 'average';
      case AgateLink.maximum:
        return 'maximum';
    }
  }

  /// Parses an mpv wire string back into a [AgateLink].
  /// Unknown / empty input falls back to the first member.
  static AgateLink fromMpv(String? raw) {
    switch (raw) {
      case 'average':
        return AgateLink.average;
      case 'maximum':
        return AgateLink.maximum;
      default:
        return AgateLink.average;
    }
  }
}

enum AgateMode {
  downward,
  upward,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AgateMode.downward:
        return 'downward';
      case AgateMode.upward:
        return 'upward';
    }
  }

  /// Parses an mpv wire string back into a [AgateMode].
  /// Unknown / empty input falls back to the first member.
  static AgateMode fromMpv(String? raw) {
    switch (raw) {
      case 'downward':
        return AgateMode.downward;
      case 'upward':
        return AgateMode.upward;
      default:
        return AgateMode.downward;
    }
  }
}

enum AiirFormat {
  /// lattice-ladder function
  ll,

  /// analog transfer function
  sf,

  /// digital transfer function
  tf,

  /// Z-plane zeros/poles
  zp,

  /// Z-plane zeros/poles (polar radians)
  pr,

  /// Z-plane zeros/poles (polar degrees)
  pd,

  /// S-plane zeros/poles
  sp,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AiirFormat.ll:
        return 'll';
      case AiirFormat.sf:
        return 'sf';
      case AiirFormat.tf:
        return 'tf';
      case AiirFormat.zp:
        return 'zp';
      case AiirFormat.pr:
        return 'pr';
      case AiirFormat.pd:
        return 'pd';
      case AiirFormat.sp:
        return 'sp';
    }
  }

  /// Parses an mpv wire string back into a [AiirFormat].
  /// Unknown / empty input falls back to the first member.
  static AiirFormat fromMpv(String? raw) {
    switch (raw) {
      case 'll':
        return AiirFormat.ll;
      case 'sf':
        return AiirFormat.sf;
      case 'tf':
        return AiirFormat.tf;
      case 'zp':
        return AiirFormat.zp;
      case 'pr':
        return AiirFormat.pr;
      case 'pd':
        return AiirFormat.pd;
      case 'sp':
        return AiirFormat.sp;
      default:
        return AiirFormat.ll;
    }
  }
}

enum AiirPrecision {
  /// double-precision floating-point
  dbl,

  /// single-precision floating-point
  flt,

  /// 32-bit integers
  i32,

  /// 16-bit integers
  i16,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AiirPrecision.dbl:
        return 'dbl';
      case AiirPrecision.flt:
        return 'flt';
      case AiirPrecision.i32:
        return 'i32';
      case AiirPrecision.i16:
        return 'i16';
    }
  }

  /// Parses an mpv wire string back into a [AiirPrecision].
  /// Unknown / empty input falls back to the first member.
  static AiirPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'dbl':
        return AiirPrecision.dbl;
      case 'flt':
        return AiirPrecision.flt;
      case 'i32':
        return AiirPrecision.i32;
      case 'i16':
        return AiirPrecision.i16;
      default:
        return AiirPrecision.dbl;
    }
  }
}

enum AiirProcess {
  /// direct
  d,

  /// serial
  s,

  /// parallel
  p,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AiirProcess.d:
        return 'd';
      case AiirProcess.s:
        return 's';
      case AiirProcess.p:
        return 'p';
    }
  }

  /// Parses an mpv wire string back into a [AiirProcess].
  /// Unknown / empty input falls back to the first member.
  static AiirProcess fromMpv(String? raw) {
    switch (raw) {
      case 'd':
        return AiirProcess.d;
      case 's':
        return AiirProcess.s;
      case 'p':
        return AiirProcess.p;
      default:
        return AiirProcess.d;
    }
  }
}

enum AnequalizerFscale {
  /// linear
  lin,

  /// logarithmic
  log,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AnequalizerFscale.lin:
        return 'lin';
      case AnequalizerFscale.log:
        return 'log';
    }
  }

  /// Parses an mpv wire string back into a [AnequalizerFscale].
  /// Unknown / empty input falls back to the first member.
  static AnequalizerFscale fromMpv(String? raw) {
    switch (raw) {
      case 'lin':
        return AnequalizerFscale.lin;
      case 'log':
        return AnequalizerFscale.log;
      default:
        return AnequalizerFscale.lin;
    }
  }
}

enum AnlmdnMode {
  /// input
  i,

  /// output
  o,

  /// noise
  n,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AnlmdnMode.i:
        return 'i';
      case AnlmdnMode.o:
        return 'o';
      case AnlmdnMode.n:
        return 'n';
    }
  }

  /// Parses an mpv wire string back into a [AnlmdnMode].
  /// Unknown / empty input falls back to the first member.
  static AnlmdnMode fromMpv(String? raw) {
    switch (raw) {
      case 'i':
        return AnlmdnMode.i;
      case 'o':
        return AnlmdnMode.o;
      case 'n':
        return AnlmdnMode.n;
      default:
        return AnlmdnMode.i;
    }
  }
}

enum AphaserType {
  triangular,
  t,
  sinusoidal,
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AphaserType.triangular:
        return 'triangular';
      case AphaserType.t:
        return 't';
      case AphaserType.sinusoidal:
        return 'sinusoidal';
      case AphaserType.s:
        return 's';
    }
  }

  /// Parses an mpv wire string back into a [AphaserType].
  /// Unknown / empty input falls back to the first member.
  static AphaserType fromMpv(String? raw) {
    switch (raw) {
      case 'triangular':
        return AphaserType.triangular;
      case 't':
        return AphaserType.t;
      case 'sinusoidal':
        return AphaserType.sinusoidal;
      case 's':
        return AphaserType.s;
      default:
        return AphaserType.triangular;
    }
  }
}

enum ApulsatorMode {
  sine,
  triangle,
  square,
  sawup,
  sawdown,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case ApulsatorMode.sine:
        return 'sine';
      case ApulsatorMode.triangle:
        return 'triangle';
      case ApulsatorMode.square:
        return 'square';
      case ApulsatorMode.sawup:
        return 'sawup';
      case ApulsatorMode.sawdown:
        return 'sawdown';
    }
  }

  /// Parses an mpv wire string back into a [ApulsatorMode].
  /// Unknown / empty input falls back to the first member.
  static ApulsatorMode fromMpv(String? raw) {
    switch (raw) {
      case 'sine':
        return ApulsatorMode.sine;
      case 'triangle':
        return ApulsatorMode.triangle;
      case 'square':
        return ApulsatorMode.square;
      case 'sawup':
        return ApulsatorMode.sawup;
      case 'sawdown':
        return ApulsatorMode.sawdown;
      default:
        return ApulsatorMode.sine;
    }
  }
}

enum ApulsatorTiming {
  bpm,
  ms,
  hz,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case ApulsatorTiming.bpm:
        return 'bpm';
      case ApulsatorTiming.ms:
        return 'ms';
      case ApulsatorTiming.hz:
        return 'hz';
    }
  }

  /// Parses an mpv wire string back into a [ApulsatorTiming].
  /// Unknown / empty input falls back to the first member.
  static ApulsatorTiming fromMpv(String? raw) {
    switch (raw) {
      case 'bpm':
        return ApulsatorTiming.bpm;
      case 'ms':
        return ApulsatorTiming.ms;
      case 'hz':
        return ApulsatorTiming.hz;
      default:
        return ApulsatorTiming.bpm;
    }
  }
}

enum AsoftclipTypes {
  hard,
  tanh,
  atan,
  cubic,
  exp,
  alg,
  quintic,
  sin,
  erf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AsoftclipTypes.hard:
        return 'hard';
      case AsoftclipTypes.tanh:
        return 'tanh';
      case AsoftclipTypes.atan:
        return 'atan';
      case AsoftclipTypes.cubic:
        return 'cubic';
      case AsoftclipTypes.exp:
        return 'exp';
      case AsoftclipTypes.alg:
        return 'alg';
      case AsoftclipTypes.quintic:
        return 'quintic';
      case AsoftclipTypes.sin:
        return 'sin';
      case AsoftclipTypes.erf:
        return 'erf';
    }
  }

  /// Parses an mpv wire string back into a [AsoftclipTypes].
  /// Unknown / empty input falls back to the first member.
  static AsoftclipTypes fromMpv(String? raw) {
    switch (raw) {
      case 'hard':
        return AsoftclipTypes.hard;
      case 'tanh':
        return AsoftclipTypes.tanh;
      case 'atan':
        return AsoftclipTypes.atan;
      case 'cubic':
        return AsoftclipTypes.cubic;
      case 'exp':
        return AsoftclipTypes.exp;
      case 'alg':
        return AsoftclipTypes.alg;
      case 'quintic':
        return AsoftclipTypes.quintic;
      case 'sin':
        return AsoftclipTypes.sin;
      case 'erf':
        return AsoftclipTypes.erf;
      default:
        return AsoftclipTypes.hard;
    }
  }
}

enum DeesserMode {
  /// input
  i,

  /// output
  o,

  /// ess
  e,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case DeesserMode.i:
        return 'i';
      case DeesserMode.o:
        return 'o';
      case DeesserMode.e:
        return 'e';
    }
  }

  /// Parses an mpv wire string back into a [DeesserMode].
  /// Unknown / empty input falls back to the first member.
  static DeesserMode fromMpv(String? raw) {
    switch (raw) {
      case 'i':
        return DeesserMode.i;
      case 'o':
        return DeesserMode.o;
      case 'e':
        return DeesserMode.e;
      default:
        return DeesserMode.i;
    }
  }
}

enum Ebur128Gaugetype {
  /// display momentary value
  momentary,

  /// display momentary value
  m,

  /// display short-term value
  shortterm,

  /// display short-term value
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Gaugetype.momentary:
        return 'momentary';
      case Ebur128Gaugetype.m:
        return 'm';
      case Ebur128Gaugetype.shortterm:
        return 'shortterm';
      case Ebur128Gaugetype.s:
        return 's';
    }
  }

  /// Parses an mpv wire string back into a [Ebur128Gaugetype].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Gaugetype fromMpv(String? raw) {
    switch (raw) {
      case 'momentary':
        return Ebur128Gaugetype.momentary;
      case 'm':
        return Ebur128Gaugetype.m;
      case 'shortterm':
        return Ebur128Gaugetype.shortterm;
      case 's':
        return Ebur128Gaugetype.s;
      default:
        return Ebur128Gaugetype.momentary;
    }
  }
}

enum Ebur128Level {
  /// logging disabled
  quiet,

  /// information logging level
  info,

  /// verbose logging level
  verbose,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Level.quiet:
        return 'quiet';
      case Ebur128Level.info:
        return 'info';
      case Ebur128Level.verbose:
        return 'verbose';
    }
  }

  /// Parses an mpv wire string back into a [Ebur128Level].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Level fromMpv(String? raw) {
    switch (raw) {
      case 'quiet':
        return Ebur128Level.quiet;
      case 'info':
        return Ebur128Level.info;
      case 'verbose':
        return Ebur128Level.verbose;
      default:
        return Ebur128Level.quiet;
    }
  }
}

enum Ebur128Mode {
  /// disable any peak mode
  none,

  /// enable peak-sample mode
  sample,

  /// enable true-peak mode
  true_,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Mode.none:
        return 'none';
      case Ebur128Mode.sample:
        return 'sample';
      case Ebur128Mode.true_:
        return 'true';
    }
  }

  /// Parses an mpv wire string back into a [Ebur128Mode].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Mode fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return Ebur128Mode.none;
      case 'sample':
        return Ebur128Mode.sample;
      case 'true':
        return Ebur128Mode.true_;
      default:
        return Ebur128Mode.none;
    }
  }
}

enum Ebur128Scaletype {
  /// display absolute values (LUFS)
  absolute,

  /// display absolute values (LUFS)
  LUFS,

  /// display values relative to target (LU)
  relative,

  /// display values relative to target (LU)
  LU,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Scaletype.absolute:
        return 'absolute';
      case Ebur128Scaletype.LUFS:
        return 'LUFS';
      case Ebur128Scaletype.relative:
        return 'relative';
      case Ebur128Scaletype.LU:
        return 'LU';
    }
  }

  /// Parses an mpv wire string back into a [Ebur128Scaletype].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Scaletype fromMpv(String? raw) {
    switch (raw) {
      case 'absolute':
        return Ebur128Scaletype.absolute;
      case 'LUFS':
        return Ebur128Scaletype.LUFS;
      case 'relative':
        return Ebur128Scaletype.relative;
      case 'LU':
        return Ebur128Scaletype.LU;
      default:
        return Ebur128Scaletype.absolute;
    }
  }
}

enum FirequalizerScale {
  /// linear-freq linear-gain
  linlin,

  /// linear-freq logarithmic-gain
  linlog,

  /// logarithmic-freq linear-gain
  loglin,

  /// logarithmic-freq logarithmic-gain
  loglog,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FirequalizerScale.linlin:
        return 'linlin';
      case FirequalizerScale.linlog:
        return 'linlog';
      case FirequalizerScale.loglin:
        return 'loglin';
      case FirequalizerScale.loglog:
        return 'loglog';
    }
  }

  /// Parses an mpv wire string back into a [FirequalizerScale].
  /// Unknown / empty input falls back to the first member.
  static FirequalizerScale fromMpv(String? raw) {
    switch (raw) {
      case 'linlin':
        return FirequalizerScale.linlin;
      case 'linlog':
        return FirequalizerScale.linlog;
      case 'loglin':
        return FirequalizerScale.loglin;
      case 'loglog':
        return FirequalizerScale.loglog;
      default:
        return FirequalizerScale.linlin;
    }
  }
}

enum FirequalizerWfunc {
  /// rectangular window
  rectangular,

  /// hann window
  hann,

  /// hamming window
  hamming,

  /// blackman window
  blackman,

  /// 3-term nuttall window
  nuttall3,

  /// minimum 3-term nuttall window
  mnuttall3,

  /// nuttall window
  nuttall,

  /// blackman-nuttall window
  bnuttall,

  /// blackman-harris window
  bharris,

  /// tukey window
  tukey,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FirequalizerWfunc.rectangular:
        return 'rectangular';
      case FirequalizerWfunc.hann:
        return 'hann';
      case FirequalizerWfunc.hamming:
        return 'hamming';
      case FirequalizerWfunc.blackman:
        return 'blackman';
      case FirequalizerWfunc.nuttall3:
        return 'nuttall3';
      case FirequalizerWfunc.mnuttall3:
        return 'mnuttall3';
      case FirequalizerWfunc.nuttall:
        return 'nuttall';
      case FirequalizerWfunc.bnuttall:
        return 'bnuttall';
      case FirequalizerWfunc.bharris:
        return 'bharris';
      case FirequalizerWfunc.tukey:
        return 'tukey';
    }
  }

  /// Parses an mpv wire string back into a [FirequalizerWfunc].
  /// Unknown / empty input falls back to the first member.
  static FirequalizerWfunc fromMpv(String? raw) {
    switch (raw) {
      case 'rectangular':
        return FirequalizerWfunc.rectangular;
      case 'hann':
        return FirequalizerWfunc.hann;
      case 'hamming':
        return FirequalizerWfunc.hamming;
      case 'blackman':
        return FirequalizerWfunc.blackman;
      case 'nuttall3':
        return FirequalizerWfunc.nuttall3;
      case 'mnuttall3':
        return FirequalizerWfunc.mnuttall3;
      case 'nuttall':
        return FirequalizerWfunc.nuttall;
      case 'bnuttall':
        return FirequalizerWfunc.bnuttall;
      case 'bharris':
        return FirequalizerWfunc.bharris;
      case 'tukey':
        return FirequalizerWfunc.tukey;
      default:
        return FirequalizerWfunc.rectangular;
    }
  }
}

enum FlangerItype {
  linear,
  quadratic,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FlangerItype.linear:
        return 'linear';
      case FlangerItype.quadratic:
        return 'quadratic';
    }
  }

  /// Parses an mpv wire string back into a [FlangerItype].
  /// Unknown / empty input falls back to the first member.
  static FlangerItype fromMpv(String? raw) {
    switch (raw) {
      case 'linear':
        return FlangerItype.linear;
      case 'quadratic':
        return FlangerItype.quadratic;
      default:
        return FlangerItype.linear;
    }
  }
}

enum FlangerType {
  triangular,
  t,
  sinusoidal,
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FlangerType.triangular:
        return 'triangular';
      case FlangerType.t:
        return 't';
      case FlangerType.sinusoidal:
        return 'sinusoidal';
      case FlangerType.s:
        return 's';
    }
  }

  /// Parses an mpv wire string back into a [FlangerType].
  /// Unknown / empty input falls back to the first member.
  static FlangerType fromMpv(String? raw) {
    switch (raw) {
      case 'triangular':
        return FlangerType.triangular;
      case 't':
        return FlangerType.t;
      case 'sinusoidal':
        return FlangerType.sinusoidal;
      case 's':
        return FlangerType.s;
      default:
        return FlangerType.triangular;
    }
  }
}

enum HaasSource {
  left,
  right,

  /// L+R
  mid,

  /// L-R
  side,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HaasSource.left:
        return 'left';
      case HaasSource.right:
        return 'right';
      case HaasSource.mid:
        return 'mid';
      case HaasSource.side:
        return 'side';
    }
  }

  /// Parses an mpv wire string back into a [HaasSource].
  /// Unknown / empty input falls back to the first member.
  static HaasSource fromMpv(String? raw) {
    switch (raw) {
      case 'left':
        return HaasSource.left;
      case 'right':
        return HaasSource.right;
      case 'mid':
        return HaasSource.mid;
      case 'side':
        return HaasSource.side;
      default:
        return HaasSource.left;
    }
  }
}

enum HdcdAnalyzeMode {
  off,
  lle,
  pe,
  cdt,
  tgm,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HdcdAnalyzeMode.off:
        return 'off';
      case HdcdAnalyzeMode.lle:
        return 'lle';
      case HdcdAnalyzeMode.pe:
        return 'pe';
      case HdcdAnalyzeMode.cdt:
        return 'cdt';
      case HdcdAnalyzeMode.tgm:
        return 'tgm';
    }
  }

  /// Parses an mpv wire string back into a [HdcdAnalyzeMode].
  /// Unknown / empty input falls back to the first member.
  static HdcdAnalyzeMode fromMpv(String? raw) {
    switch (raw) {
      case 'off':
        return HdcdAnalyzeMode.off;
      case 'lle':
        return HdcdAnalyzeMode.lle;
      case 'pe':
        return HdcdAnalyzeMode.pe;
      case 'cdt':
        return HdcdAnalyzeMode.cdt;
      case 'tgm':
        return HdcdAnalyzeMode.tgm;
      default:
        return HdcdAnalyzeMode.off;
    }
  }
}

enum HdcdBitsPerSample {
  /// 16-bit (in s32 or s16)
  n16,

  /// 20-bit (in s32)
  n20,

  /// 24-bit (in s32)
  n24,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HdcdBitsPerSample.n16:
        return '16';
      case HdcdBitsPerSample.n20:
        return '20';
      case HdcdBitsPerSample.n24:
        return '24';
    }
  }

  /// Parses an mpv wire string back into a [HdcdBitsPerSample].
  /// Unknown / empty input falls back to the first member.
  static HdcdBitsPerSample fromMpv(String? raw) {
    switch (raw) {
      case '16':
        return HdcdBitsPerSample.n16;
      case '20':
        return HdcdBitsPerSample.n20;
      case '24':
        return HdcdBitsPerSample.n24;
      default:
        return HdcdBitsPerSample.n16;
    }
  }
}

enum HeadphoneHrir {
  /// hrir files have exactly 2 channels
  stereo,

  /// single multichannel hrir file
  multich,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HeadphoneHrir.stereo:
        return 'stereo';
      case HeadphoneHrir.multich:
        return 'multich';
    }
  }

  /// Parses an mpv wire string back into a [HeadphoneHrir].
  /// Unknown / empty input falls back to the first member.
  static HeadphoneHrir fromMpv(String? raw) {
    switch (raw) {
      case 'stereo':
        return HeadphoneHrir.stereo;
      case 'multich':
        return HeadphoneHrir.multich;
      default:
        return HeadphoneHrir.stereo;
    }
  }
}

enum HeadphoneType {
  /// time domain
  time,

  /// frequency domain
  freq,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HeadphoneType.time:
        return 'time';
      case HeadphoneType.freq:
        return 'freq';
    }
  }

  /// Parses an mpv wire string back into a [HeadphoneType].
  /// Unknown / empty input falls back to the first member.
  static HeadphoneType fromMpv(String? raw) {
    switch (raw) {
      case 'time':
        return HeadphoneType.time;
      case 'freq':
        return HeadphoneType.freq;
      default:
        return HeadphoneType.time;
    }
  }
}

enum LoudnormPrintFormat {
  none,
  json,
  summary,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LoudnormPrintFormat.none:
        return 'none';
      case LoudnormPrintFormat.json:
        return 'json';
      case LoudnormPrintFormat.summary:
        return 'summary';
    }
  }

  /// Parses an mpv wire string back into a [LoudnormPrintFormat].
  /// Unknown / empty input falls back to the first member.
  static LoudnormPrintFormat fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return LoudnormPrintFormat.none;
      case 'json':
        return LoudnormPrintFormat.json;
      case 'summary':
        return LoudnormPrintFormat.summary;
      default:
        return LoudnormPrintFormat.none;
    }
  }
}

enum RubberbandChannels {
  apart,
  together,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandChannels.apart:
        return 'apart';
      case RubberbandChannels.together:
        return 'together';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandChannels].
  /// Unknown / empty input falls back to the first member.
  static RubberbandChannels fromMpv(String? raw) {
    switch (raw) {
      case 'apart':
        return RubberbandChannels.apart;
      case 'together':
        return RubberbandChannels.together;
      default:
        return RubberbandChannels.apart;
    }
  }
}

enum RubberbandDetector {
  compound,
  percussive,
  soft,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandDetector.compound:
        return 'compound';
      case RubberbandDetector.percussive:
        return 'percussive';
      case RubberbandDetector.soft:
        return 'soft';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandDetector].
  /// Unknown / empty input falls back to the first member.
  static RubberbandDetector fromMpv(String? raw) {
    switch (raw) {
      case 'compound':
        return RubberbandDetector.compound;
      case 'percussive':
        return RubberbandDetector.percussive;
      case 'soft':
        return RubberbandDetector.soft;
      default:
        return RubberbandDetector.compound;
    }
  }
}

enum RubberbandFormant {
  shifted,
  preserved,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandFormant.shifted:
        return 'shifted';
      case RubberbandFormant.preserved:
        return 'preserved';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandFormant].
  /// Unknown / empty input falls back to the first member.
  static RubberbandFormant fromMpv(String? raw) {
    switch (raw) {
      case 'shifted':
        return RubberbandFormant.shifted;
      case 'preserved':
        return RubberbandFormant.preserved;
      default:
        return RubberbandFormant.shifted;
    }
  }
}

enum RubberbandPhase {
  laminar,
  independent,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandPhase.laminar:
        return 'laminar';
      case RubberbandPhase.independent:
        return 'independent';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandPhase].
  /// Unknown / empty input falls back to the first member.
  static RubberbandPhase fromMpv(String? raw) {
    switch (raw) {
      case 'laminar':
        return RubberbandPhase.laminar;
      case 'independent':
        return RubberbandPhase.independent;
      default:
        return RubberbandPhase.laminar;
    }
  }
}

enum RubberbandPitch {
  quality,
  speed,
  consistency,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandPitch.quality:
        return 'quality';
      case RubberbandPitch.speed:
        return 'speed';
      case RubberbandPitch.consistency:
        return 'consistency';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandPitch].
  /// Unknown / empty input falls back to the first member.
  static RubberbandPitch fromMpv(String? raw) {
    switch (raw) {
      case 'quality':
        return RubberbandPitch.quality;
      case 'speed':
        return RubberbandPitch.speed;
      case 'consistency':
        return RubberbandPitch.consistency;
      default:
        return RubberbandPitch.quality;
    }
  }
}

enum RubberbandSmoothing {
  off,
  on_,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandSmoothing.off:
        return 'off';
      case RubberbandSmoothing.on_:
        return 'on';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandSmoothing].
  /// Unknown / empty input falls back to the first member.
  static RubberbandSmoothing fromMpv(String? raw) {
    switch (raw) {
      case 'off':
        return RubberbandSmoothing.off;
      case 'on':
        return RubberbandSmoothing.on_;
      default:
        return RubberbandSmoothing.off;
    }
  }
}

enum RubberbandTransients {
  crisp,
  mixed,
  smooth,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandTransients.crisp:
        return 'crisp';
      case RubberbandTransients.mixed:
        return 'mixed';
      case RubberbandTransients.smooth:
        return 'smooth';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandTransients].
  /// Unknown / empty input falls back to the first member.
  static RubberbandTransients fromMpv(String? raw) {
    switch (raw) {
      case 'crisp':
        return RubberbandTransients.crisp;
      case 'mixed':
        return RubberbandTransients.mixed;
      case 'smooth':
        return RubberbandTransients.smooth;
      default:
        return RubberbandTransients.crisp;
    }
  }
}

enum RubberbandWindow {
  standard,
  short,
  long,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandWindow.standard:
        return 'standard';
      case RubberbandWindow.short:
        return 'short';
      case RubberbandWindow.long:
        return 'long';
    }
  }

  /// Parses an mpv wire string back into a [RubberbandWindow].
  /// Unknown / empty input falls back to the first member.
  static RubberbandWindow fromMpv(String? raw) {
    switch (raw) {
      case 'standard':
        return RubberbandWindow.standard;
      case 'short':
        return RubberbandWindow.short;
      case 'long':
        return RubberbandWindow.long;
      default:
        return RubberbandWindow.standard;
    }
  }
}

enum SilenceremoveDetection {
  /// use mean absolute values of samples
  avg,

  /// use root mean squared values of samples
  rms,

  /// use max absolute values of samples
  peak,

  /// use median of absolute values of samples
  median,

  /// use absolute of max peak to min peak difference
  ptp,

  /// use standard deviation from values of samples
  dev,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SilenceremoveDetection.avg:
        return 'avg';
      case SilenceremoveDetection.rms:
        return 'rms';
      case SilenceremoveDetection.peak:
        return 'peak';
      case SilenceremoveDetection.median:
        return 'median';
      case SilenceremoveDetection.ptp:
        return 'ptp';
      case SilenceremoveDetection.dev:
        return 'dev';
    }
  }

  /// Parses an mpv wire string back into a [SilenceremoveDetection].
  /// Unknown / empty input falls back to the first member.
  static SilenceremoveDetection fromMpv(String? raw) {
    switch (raw) {
      case 'avg':
        return SilenceremoveDetection.avg;
      case 'rms':
        return SilenceremoveDetection.rms;
      case 'peak':
        return SilenceremoveDetection.peak;
      case 'median':
        return SilenceremoveDetection.median;
      case 'ptp':
        return SilenceremoveDetection.ptp;
      case 'dev':
        return SilenceremoveDetection.dev;
      default:
        return SilenceremoveDetection.avg;
    }
  }
}

enum SilenceremoveMode {
  any,
  all,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SilenceremoveMode.any:
        return 'any';
      case SilenceremoveMode.all:
        return 'all';
    }
  }

  /// Parses an mpv wire string back into a [SilenceremoveMode].
  /// Unknown / empty input falls back to the first member.
  static SilenceremoveMode fromMpv(String? raw) {
    switch (raw) {
      case 'any':
        return SilenceremoveMode.any;
      case 'all':
        return SilenceremoveMode.all;
      default:
        return SilenceremoveMode.any;
    }
  }
}

enum SilenceremoveTimestamp {
  /// non-dropped frames are left with same timestamp
  copy,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SilenceremoveTimestamp.copy:
        return 'copy';
    }
  }

  /// Parses an mpv wire string back into a [SilenceremoveTimestamp].
  /// Unknown / empty input falls back to the first member.
  static SilenceremoveTimestamp fromMpv(String? raw) {
    switch (raw) {
      case 'copy':
        return SilenceremoveTimestamp.copy;
      default:
        return SilenceremoveTimestamp.copy;
    }
  }
}

enum StereotoolsBmode {
  balance,
  amplitude,
  power,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case StereotoolsBmode.balance:
        return 'balance';
      case StereotoolsBmode.amplitude:
        return 'amplitude';
      case StereotoolsBmode.power:
        return 'power';
    }
  }

  /// Parses an mpv wire string back into a [StereotoolsBmode].
  /// Unknown / empty input falls back to the first member.
  static StereotoolsBmode fromMpv(String? raw) {
    switch (raw) {
      case 'balance':
        return StereotoolsBmode.balance;
      case 'amplitude':
        return StereotoolsBmode.amplitude;
      case 'power':
        return StereotoolsBmode.power;
      default:
        return StereotoolsBmode.balance;
    }
  }
}

enum StereotoolsMode {
  lr_to_lr,
  lr_to_ms,
  ms_to_lr,
  lr_to_ll,
  lr_to_rr,
  lr_to_l_plus_r,
  lr_to_rl,
  ms_to_ll,
  ms_to_rr,
  ms_to_rl,
  lr_to_l_minus_r,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case StereotoolsMode.lr_to_lr:
        return 'lr>lr';
      case StereotoolsMode.lr_to_ms:
        return 'lr>ms';
      case StereotoolsMode.ms_to_lr:
        return 'ms>lr';
      case StereotoolsMode.lr_to_ll:
        return 'lr>ll';
      case StereotoolsMode.lr_to_rr:
        return 'lr>rr';
      case StereotoolsMode.lr_to_l_plus_r:
        return 'lr>l+r';
      case StereotoolsMode.lr_to_rl:
        return 'lr>rl';
      case StereotoolsMode.ms_to_ll:
        return 'ms>ll';
      case StereotoolsMode.ms_to_rr:
        return 'ms>rr';
      case StereotoolsMode.ms_to_rl:
        return 'ms>rl';
      case StereotoolsMode.lr_to_l_minus_r:
        return 'lr>l-r';
    }
  }

  /// Parses an mpv wire string back into a [StereotoolsMode].
  /// Unknown / empty input falls back to the first member.
  static StereotoolsMode fromMpv(String? raw) {
    switch (raw) {
      case 'lr>lr':
        return StereotoolsMode.lr_to_lr;
      case 'lr>ms':
        return StereotoolsMode.lr_to_ms;
      case 'ms>lr':
        return StereotoolsMode.ms_to_lr;
      case 'lr>ll':
        return StereotoolsMode.lr_to_ll;
      case 'lr>rr':
        return StereotoolsMode.lr_to_rr;
      case 'lr>l+r':
        return StereotoolsMode.lr_to_l_plus_r;
      case 'lr>rl':
        return StereotoolsMode.lr_to_rl;
      case 'ms>ll':
        return StereotoolsMode.ms_to_ll;
      case 'ms>rr':
        return StereotoolsMode.ms_to_rr;
      case 'ms>rl':
        return StereotoolsMode.ms_to_rl;
      case 'lr>l-r':
        return StereotoolsMode.lr_to_l_minus_r;
      default:
        return StereotoolsMode.lr_to_lr;
    }
  }
}

enum SurroundLfeMode {
  /// just add LFE channel
  add,

  /// subtract LFE channel with others
  sub,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SurroundLfeMode.add:
        return 'add';
      case SurroundLfeMode.sub:
        return 'sub';
    }
  }

  /// Parses an mpv wire string back into a [SurroundLfeMode].
  /// Unknown / empty input falls back to the first member.
  static SurroundLfeMode fromMpv(String? raw) {
    switch (raw) {
      case 'add':
        return SurroundLfeMode.add;
      case 'sub':
        return SurroundLfeMode.sub;
      default:
        return SurroundLfeMode.add;
    }
  }
}
