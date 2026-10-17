// AUTO-GENERATED: do not edit by hand.
//
// Per-filter param corner-case manifest. See
// test/runtime_extended/audio_effects_param_ranges_test.dart
// for the test that iterates this list. kFilterSamples holds every
// filter at its defaults and the curated presets, which
// test/internal/audio_effects_validation_test.dart passes through
// the effects validator with the corners.

// ignore_for_file: lines_longer_than_80_chars, unnecessary_const, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:mpv_audio_kit/mpv_audio_kit.dart';

typedef ParamCorner = ({String filter, String label, List<AudioEffect> bundle});

const List<ParamCorner> kFilterParamCorners = [
  (
    filter: 'acompressor',
    label: 'attack=attackMin',
    bundle: const [AcompressorEffect(attack: AcompressorEffect.attackMin)],
  ),
  (
    filter: 'acompressor',
    label: 'attack=attackDefault',
    bundle: const [AcompressorEffect(attack: AcompressorEffect.attackDefault)],
  ),
  (
    filter: 'acompressor',
    label: 'attack=attackMax',
    bundle: const [AcompressorEffect(attack: AcompressorEffect.attackMax)],
  ),
  (
    filter: 'acompressor',
    label: 'knee=kneeMin',
    bundle: const [AcompressorEffect(knee: AcompressorEffect.kneeMin)],
  ),
  (
    filter: 'acompressor',
    label: 'knee=kneeDefault',
    bundle: const [AcompressorEffect(knee: AcompressorEffect.kneeDefault)],
  ),
  (
    filter: 'acompressor',
    label: 'knee=kneeMax',
    bundle: const [AcompressorEffect(knee: AcompressorEffect.kneeMax)],
  ),
  (
    filter: 'acompressor',
    label: 'level_in=levelInMin',
    bundle: const [AcompressorEffect(levelIn: AcompressorEffect.levelInMin)],
  ),
  (
    filter: 'acompressor',
    label: 'level_in=levelInDefault',
    bundle: const [
      AcompressorEffect(levelIn: AcompressorEffect.levelInDefault),
    ],
  ),
  (
    filter: 'acompressor',
    label: 'level_in=levelInMax',
    bundle: const [AcompressorEffect(levelIn: AcompressorEffect.levelInMax)],
  ),
  (
    filter: 'acompressor',
    label: 'level_sc=levelScMin',
    bundle: const [AcompressorEffect(levelSc: AcompressorEffect.levelScMin)],
  ),
  (
    filter: 'acompressor',
    label: 'level_sc=levelScDefault',
    bundle: const [
      AcompressorEffect(levelSc: AcompressorEffect.levelScDefault),
    ],
  ),
  (
    filter: 'acompressor',
    label: 'level_sc=levelScMax',
    bundle: const [AcompressorEffect(levelSc: AcompressorEffect.levelScMax)],
  ),
  (
    filter: 'acompressor',
    label: 'makeup=makeupMin',
    bundle: const [AcompressorEffect(makeup: AcompressorEffect.makeupMin)],
  ),
  (
    filter: 'acompressor',
    label: 'makeup=makeupDefault',
    bundle: const [AcompressorEffect(makeup: AcompressorEffect.makeupDefault)],
  ),
  (
    filter: 'acompressor',
    label: 'makeup=makeupMax',
    bundle: const [AcompressorEffect(makeup: AcompressorEffect.makeupMax)],
  ),
  (
    filter: 'acompressor',
    label: 'mix=mixMin',
    bundle: const [AcompressorEffect(mix: AcompressorEffect.mixMin)],
  ),
  (
    filter: 'acompressor',
    label: 'mix=mixDefault',
    bundle: const [AcompressorEffect(mix: AcompressorEffect.mixDefault)],
  ),
  (
    filter: 'acompressor',
    label: 'mix=mixMax',
    bundle: const [AcompressorEffect(mix: AcompressorEffect.mixMax)],
  ),
  (
    filter: 'acompressor',
    label: 'ratio=ratioMin',
    bundle: const [AcompressorEffect(ratio: AcompressorEffect.ratioMin)],
  ),
  (
    filter: 'acompressor',
    label: 'ratio=ratioDefault',
    bundle: const [AcompressorEffect(ratio: AcompressorEffect.ratioDefault)],
  ),
  (
    filter: 'acompressor',
    label: 'ratio=ratioMax',
    bundle: const [AcompressorEffect(ratio: AcompressorEffect.ratioMax)],
  ),
  (
    filter: 'acompressor',
    label: 'release=releaseMin',
    bundle: const [AcompressorEffect(release: AcompressorEffect.releaseMin)],
  ),
  (
    filter: 'acompressor',
    label: 'release=releaseDefault',
    bundle: const [
      AcompressorEffect(release: AcompressorEffect.releaseDefault),
    ],
  ),
  (
    filter: 'acompressor',
    label: 'release=releaseMax',
    bundle: const [AcompressorEffect(release: AcompressorEffect.releaseMax)],
  ),
  (
    filter: 'acompressor',
    label: 'threshold=thresholdMin',
    bundle: const [
      AcompressorEffect(threshold: AcompressorEffect.thresholdMin),
    ],
  ),
  (
    filter: 'acompressor',
    label: 'threshold=thresholdDefault',
    bundle: const [
      AcompressorEffect(threshold: AcompressorEffect.thresholdDefault),
    ],
  ),
  (
    filter: 'acompressor',
    label: 'threshold=thresholdMax',
    bundle: const [
      AcompressorEffect(threshold: AcompressorEffect.thresholdMax),
    ],
  ),
  (
    filter: 'acontrast',
    label: 'contrast=contrastMin',
    bundle: const [AcontrastEffect(contrast: AcontrastEffect.contrastMin)],
  ),
  (
    filter: 'acontrast',
    label: 'contrast=contrastDefault',
    bundle: const [AcontrastEffect(contrast: AcontrastEffect.contrastDefault)],
  ),
  (
    filter: 'acontrast',
    label: 'contrast=contrastMax',
    bundle: const [AcontrastEffect(contrast: AcontrastEffect.contrastMax)],
  ),
  (
    filter: 'acrusher',
    label: 'aa=aaMin',
    bundle: const [AcrusherEffect(aa: AcrusherEffect.aaMin)],
  ),
  (
    filter: 'acrusher',
    label: 'aa=aaDefault',
    bundle: const [AcrusherEffect(aa: AcrusherEffect.aaDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'aa=aaMax',
    bundle: const [AcrusherEffect(aa: AcrusherEffect.aaMax)],
  ),
  (
    filter: 'acrusher',
    label: 'bits=bitsMin',
    bundle: const [AcrusherEffect(bits: AcrusherEffect.bitsMin)],
  ),
  (
    filter: 'acrusher',
    label: 'bits=bitsDefault',
    bundle: const [AcrusherEffect(bits: AcrusherEffect.bitsDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'bits=bitsMax',
    bundle: const [AcrusherEffect(bits: AcrusherEffect.bitsMax)],
  ),
  (
    filter: 'acrusher',
    label: 'dc=dcMin',
    bundle: const [AcrusherEffect(dc: AcrusherEffect.dcMin)],
  ),
  (
    filter: 'acrusher',
    label: 'dc=dcDefault',
    bundle: const [AcrusherEffect(dc: AcrusherEffect.dcDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'dc=dcMax',
    bundle: const [AcrusherEffect(dc: AcrusherEffect.dcMax)],
  ),
  (
    filter: 'acrusher',
    label: 'level_in=levelInMin',
    bundle: const [AcrusherEffect(levelIn: AcrusherEffect.levelInMin)],
  ),
  (
    filter: 'acrusher',
    label: 'level_in=levelInDefault',
    bundle: const [AcrusherEffect(levelIn: AcrusherEffect.levelInDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'level_in=levelInMax',
    bundle: const [AcrusherEffect(levelIn: AcrusherEffect.levelInMax)],
  ),
  (
    filter: 'acrusher',
    label: 'level_out=levelOutMin',
    bundle: const [AcrusherEffect(levelOut: AcrusherEffect.levelOutMin)],
  ),
  (
    filter: 'acrusher',
    label: 'level_out=levelOutDefault',
    bundle: const [AcrusherEffect(levelOut: AcrusherEffect.levelOutDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'level_out=levelOutMax',
    bundle: const [AcrusherEffect(levelOut: AcrusherEffect.levelOutMax)],
  ),
  (
    filter: 'acrusher',
    label: 'lforange=lforangeMin',
    bundle: const [AcrusherEffect(lforange: AcrusherEffect.lforangeMin)],
  ),
  (
    filter: 'acrusher',
    label: 'lforange=lforangeDefault',
    bundle: const [AcrusherEffect(lforange: AcrusherEffect.lforangeDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'lforange=lforangeMax',
    bundle: const [AcrusherEffect(lforange: AcrusherEffect.lforangeMax)],
  ),
  (
    filter: 'acrusher',
    label: 'lforate=lforateMin',
    bundle: const [AcrusherEffect(lforate: AcrusherEffect.lforateMin)],
  ),
  (
    filter: 'acrusher',
    label: 'lforate=lforateDefault',
    bundle: const [AcrusherEffect(lforate: AcrusherEffect.lforateDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'lforate=lforateMax',
    bundle: const [AcrusherEffect(lforate: AcrusherEffect.lforateMax)],
  ),
  (
    filter: 'acrusher',
    label: 'mix=mixMin',
    bundle: const [AcrusherEffect(mix: AcrusherEffect.mixMin)],
  ),
  (
    filter: 'acrusher',
    label: 'mix=mixDefault',
    bundle: const [AcrusherEffect(mix: AcrusherEffect.mixDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'mix=mixMax',
    bundle: const [AcrusherEffect(mix: AcrusherEffect.mixMax)],
  ),
  (
    filter: 'acrusher',
    label: 'samples=samplesMin',
    bundle: const [AcrusherEffect(samples: AcrusherEffect.samplesMin)],
  ),
  (
    filter: 'acrusher',
    label: 'samples=samplesDefault',
    bundle: const [AcrusherEffect(samples: AcrusherEffect.samplesDefault)],
  ),
  (
    filter: 'acrusher',
    label: 'samples=samplesMax',
    bundle: const [AcrusherEffect(samples: AcrusherEffect.samplesMax)],
  ),
  (
    filter: 'adeclick',
    label: 'arorder=arorderMin',
    bundle: const [AdeclickEffect(arorder: AdeclickEffect.arorderMin)],
  ),
  (
    filter: 'adeclick',
    label: 'arorder=arorderDefault',
    bundle: const [AdeclickEffect(arorder: AdeclickEffect.arorderDefault)],
  ),
  (
    filter: 'adeclick',
    label: 'arorder=arorderMax',
    bundle: const [AdeclickEffect(arorder: AdeclickEffect.arorderMax)],
  ),
  (
    filter: 'adeclick',
    label: 'burst=burstMin',
    bundle: const [AdeclickEffect(burst: AdeclickEffect.burstMin)],
  ),
  (
    filter: 'adeclick',
    label: 'burst=burstDefault',
    bundle: const [AdeclickEffect(burst: AdeclickEffect.burstDefault)],
  ),
  (
    filter: 'adeclick',
    label: 'burst=burstMax',
    bundle: const [AdeclickEffect(burst: AdeclickEffect.burstMax)],
  ),
  (
    filter: 'adeclick',
    label: 'overlap=overlapMin',
    bundle: const [AdeclickEffect(overlap: AdeclickEffect.overlapMin)],
  ),
  (
    filter: 'adeclick',
    label: 'overlap=overlapDefault',
    bundle: const [AdeclickEffect(overlap: AdeclickEffect.overlapDefault)],
  ),
  (
    filter: 'adeclick',
    label: 'overlap=overlapMax',
    bundle: const [AdeclickEffect(overlap: AdeclickEffect.overlapMax)],
  ),
  (
    filter: 'adeclick',
    label: 'threshold=thresholdMin',
    bundle: const [AdeclickEffect(threshold: AdeclickEffect.thresholdMin)],
  ),
  (
    filter: 'adeclick',
    label: 'threshold=thresholdDefault',
    bundle: const [AdeclickEffect(threshold: AdeclickEffect.thresholdDefault)],
  ),
  (
    filter: 'adeclick',
    label: 'threshold=thresholdMax',
    bundle: const [AdeclickEffect(threshold: AdeclickEffect.thresholdMax)],
  ),
  (
    filter: 'adeclick',
    label: 'window=windowMin',
    bundle: const [AdeclickEffect(window: AdeclickEffect.windowMin)],
  ),
  (
    filter: 'adeclick',
    label: 'window=windowDefault',
    bundle: const [AdeclickEffect(window: AdeclickEffect.windowDefault)],
  ),
  (
    filter: 'adeclick',
    label: 'window=windowMax',
    bundle: const [AdeclickEffect(window: AdeclickEffect.windowMax)],
  ),
  (
    filter: 'adeclip',
    label: 'arorder=arorderMin',
    bundle: const [AdeclipEffect(arorder: AdeclipEffect.arorderMin)],
  ),
  (
    filter: 'adeclip',
    label: 'arorder=arorderDefault',
    bundle: const [AdeclipEffect(arorder: AdeclipEffect.arorderDefault)],
  ),
  (
    filter: 'adeclip',
    label: 'arorder=arorderMax',
    bundle: const [AdeclipEffect(arorder: AdeclipEffect.arorderMax)],
  ),
  (
    filter: 'adeclip',
    label: 'hsize=hsizeMin',
    bundle: const [AdeclipEffect(hsize: AdeclipEffect.hsizeMin)],
  ),
  (
    filter: 'adeclip',
    label: 'hsize=hsizeDefault',
    bundle: const [AdeclipEffect(hsize: AdeclipEffect.hsizeDefault)],
  ),
  (
    filter: 'adeclip',
    label: 'hsize=hsizeMax',
    bundle: const [AdeclipEffect(hsize: AdeclipEffect.hsizeMax)],
  ),
  (
    filter: 'adeclip',
    label: 'overlap=overlapMin',
    bundle: const [AdeclipEffect(overlap: AdeclipEffect.overlapMin)],
  ),
  (
    filter: 'adeclip',
    label: 'overlap=overlapDefault',
    bundle: const [AdeclipEffect(overlap: AdeclipEffect.overlapDefault)],
  ),
  (
    filter: 'adeclip',
    label: 'overlap=overlapMax',
    bundle: const [AdeclipEffect(overlap: AdeclipEffect.overlapMax)],
  ),
  (
    filter: 'adeclip',
    label: 'threshold=thresholdMin',
    bundle: const [AdeclipEffect(threshold: AdeclipEffect.thresholdMin)],
  ),
  (
    filter: 'adeclip',
    label: 'threshold=thresholdDefault',
    bundle: const [AdeclipEffect(threshold: AdeclipEffect.thresholdDefault)],
  ),
  (
    filter: 'adeclip',
    label: 'threshold=thresholdMax',
    bundle: const [AdeclipEffect(threshold: AdeclipEffect.thresholdMax)],
  ),
  (
    filter: 'adeclip',
    label: 'window=windowMin',
    bundle: const [AdeclipEffect(window: AdeclipEffect.windowMin)],
  ),
  (
    filter: 'adeclip',
    label: 'window=windowDefault',
    bundle: const [AdeclipEffect(window: AdeclipEffect.windowDefault)],
  ),
  (
    filter: 'adeclip',
    label: 'window=windowMax',
    bundle: const [AdeclipEffect(window: AdeclipEffect.windowMax)],
  ),
  (
    filter: 'adecorrelate',
    label: 'seed=seedMin',
    bundle: const [AdecorrelateEffect(seed: AdecorrelateEffect.seedMin)],
  ),
  (
    filter: 'adecorrelate',
    label: 'seed=seedDefault',
    bundle: const [AdecorrelateEffect(seed: AdecorrelateEffect.seedDefault)],
  ),
  (
    filter: 'adecorrelate',
    label: 'seed=seedMax',
    bundle: const [AdecorrelateEffect(seed: AdecorrelateEffect.seedMax)],
  ),
  (
    filter: 'adecorrelate',
    label: 'stages=stagesMin',
    bundle: const [AdecorrelateEffect(stages: AdecorrelateEffect.stagesMin)],
  ),
  (
    filter: 'adecorrelate',
    label: 'stages=stagesDefault',
    bundle: const [
      AdecorrelateEffect(stages: AdecorrelateEffect.stagesDefault),
    ],
  ),
  (
    filter: 'adecorrelate',
    label: 'stages=stagesMax',
    bundle: const [AdecorrelateEffect(stages: AdecorrelateEffect.stagesMax)],
  ),
  (
    filter: 'adenorm',
    label: 'level=levelMin',
    bundle: const [AdenormEffect(level: AdenormEffect.levelMin)],
  ),
  (
    filter: 'adenorm',
    label: 'level=levelDefault',
    bundle: const [AdenormEffect(level: AdenormEffect.levelDefault)],
  ),
  (
    filter: 'adenorm',
    label: 'level=levelMax',
    bundle: const [AdenormEffect(level: AdenormEffect.levelMax)],
  ),
  (
    filter: 'adrc',
    label: 'attack=attackMin',
    bundle: const [AdrcEffect(attack: AdrcEffect.attackMin)],
  ),
  (
    filter: 'adrc',
    label: 'attack=attackDefault',
    bundle: const [AdrcEffect(attack: AdrcEffect.attackDefault)],
  ),
  (
    filter: 'adrc',
    label: 'attack=attackMax',
    bundle: const [AdrcEffect(attack: AdrcEffect.attackMax)],
  ),
  (
    filter: 'adrc',
    label: 'release=releaseMin',
    bundle: const [AdrcEffect(release: AdrcEffect.releaseMin)],
  ),
  (
    filter: 'adrc',
    label: 'release=releaseDefault',
    bundle: const [AdrcEffect(release: AdrcEffect.releaseDefault)],
  ),
  (
    filter: 'adrc',
    label: 'release=releaseMax',
    bundle: const [AdrcEffect(release: AdrcEffect.releaseMax)],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'attack=attackMin',
    bundle: const [
      AdynamicequalizerEffect(attack: AdynamicequalizerEffect.attackMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'attack=attackDefault',
    bundle: const [
      AdynamicequalizerEffect(attack: AdynamicequalizerEffect.attackDefault),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'attack=attackMax',
    bundle: const [
      AdynamicequalizerEffect(attack: AdynamicequalizerEffect.attackMax),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'dfrequency=dfrequencyMin',
    bundle: const [
      AdynamicequalizerEffect(
        dfrequency: AdynamicequalizerEffect.dfrequencyMin,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'dfrequency=dfrequencyDefault',
    bundle: const [
      AdynamicequalizerEffect(
        dfrequency: AdynamicequalizerEffect.dfrequencyDefault,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'dfrequency=dfrequencyMax',
    bundle: const [
      AdynamicequalizerEffect(
        dfrequency: AdynamicequalizerEffect.dfrequencyMax,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'dqfactor=dqfactorMin',
    bundle: const [
      AdynamicequalizerEffect(dqfactor: AdynamicequalizerEffect.dqfactorMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'dqfactor=dqfactorDefault',
    bundle: const [
      AdynamicequalizerEffect(
        dqfactor: AdynamicequalizerEffect.dqfactorDefault,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'dqfactor=dqfactorMax',
    bundle: const [
      AdynamicequalizerEffect(dqfactor: AdynamicequalizerEffect.dqfactorMax),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'makeup=makeupMin',
    bundle: const [
      AdynamicequalizerEffect(makeup: AdynamicequalizerEffect.makeupMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'makeup=makeupDefault',
    bundle: const [
      AdynamicequalizerEffect(makeup: AdynamicequalizerEffect.makeupDefault),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'makeup=makeupMax',
    bundle: const [
      AdynamicequalizerEffect(makeup: AdynamicequalizerEffect.makeupMax),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'range=rangeMin',
    bundle: const [
      AdynamicequalizerEffect(range: AdynamicequalizerEffect.rangeMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'range=rangeDefault',
    bundle: const [
      AdynamicequalizerEffect(range: AdynamicequalizerEffect.rangeDefault),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'range=rangeMax',
    bundle: const [
      AdynamicequalizerEffect(range: AdynamicequalizerEffect.rangeMax),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'ratio=ratioMin',
    bundle: const [
      AdynamicequalizerEffect(ratio: AdynamicequalizerEffect.ratioMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'ratio=ratioDefault',
    bundle: const [
      AdynamicequalizerEffect(ratio: AdynamicequalizerEffect.ratioDefault),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'ratio=ratioMax',
    bundle: const [
      AdynamicequalizerEffect(ratio: AdynamicequalizerEffect.ratioMax),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'release=releaseMin',
    bundle: const [
      AdynamicequalizerEffect(release: AdynamicequalizerEffect.releaseMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'release=releaseDefault',
    bundle: const [
      AdynamicequalizerEffect(release: AdynamicequalizerEffect.releaseDefault),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'release=releaseMax',
    bundle: const [
      AdynamicequalizerEffect(release: AdynamicequalizerEffect.releaseMax),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'tfrequency=tfrequencyMin',
    bundle: const [
      AdynamicequalizerEffect(
        tfrequency: AdynamicequalizerEffect.tfrequencyMin,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'tfrequency=tfrequencyDefault',
    bundle: const [
      AdynamicequalizerEffect(
        tfrequency: AdynamicequalizerEffect.tfrequencyDefault,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'tfrequency=tfrequencyMax',
    bundle: const [
      AdynamicequalizerEffect(
        tfrequency: AdynamicequalizerEffect.tfrequencyMax,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'threshold=thresholdMin',
    bundle: const [
      AdynamicequalizerEffect(threshold: AdynamicequalizerEffect.thresholdMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'threshold=thresholdDefault',
    bundle: const [
      AdynamicequalizerEffect(
        threshold: AdynamicequalizerEffect.thresholdDefault,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'threshold=thresholdMax',
    bundle: const [
      AdynamicequalizerEffect(threshold: AdynamicequalizerEffect.thresholdMax),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'tqfactor=tqfactorMin',
    bundle: const [
      AdynamicequalizerEffect(tqfactor: AdynamicequalizerEffect.tqfactorMin),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'tqfactor=tqfactorDefault',
    bundle: const [
      AdynamicequalizerEffect(
        tqfactor: AdynamicequalizerEffect.tqfactorDefault,
      ),
    ],
  ),
  (
    filter: 'adynamicequalizer',
    label: 'tqfactor=tqfactorMax',
    bundle: const [
      AdynamicequalizerEffect(tqfactor: AdynamicequalizerEffect.tqfactorMax),
    ],
  ),
  (
    filter: 'adynamicsmooth',
    label: 'basefreq=basefreqMin',
    bundle: const [
      AdynamicsmoothEffect(basefreq: AdynamicsmoothEffect.basefreqMin),
    ],
  ),
  (
    filter: 'adynamicsmooth',
    label: 'basefreq=basefreqDefault',
    bundle: const [
      AdynamicsmoothEffect(basefreq: AdynamicsmoothEffect.basefreqDefault),
    ],
  ),
  (
    filter: 'adynamicsmooth',
    label: 'basefreq=basefreqMax',
    bundle: const [
      AdynamicsmoothEffect(basefreq: AdynamicsmoothEffect.basefreqMax),
    ],
  ),
  (
    filter: 'adynamicsmooth',
    label: 'sensitivity=sensitivityMin',
    bundle: const [
      AdynamicsmoothEffect(sensitivity: AdynamicsmoothEffect.sensitivityMin),
    ],
  ),
  (
    filter: 'adynamicsmooth',
    label: 'sensitivity=sensitivityDefault',
    bundle: const [
      AdynamicsmoothEffect(
        sensitivity: AdynamicsmoothEffect.sensitivityDefault,
      ),
    ],
  ),
  (
    filter: 'adynamicsmooth',
    label: 'sensitivity=sensitivityMax',
    bundle: const [
      AdynamicsmoothEffect(sensitivity: AdynamicsmoothEffect.sensitivityMax),
    ],
  ),
  (
    filter: 'aecho',
    label: 'in_gain=inGainMin',
    bundle: const [AechoEffect(inGain: AechoEffect.inGainMin)],
  ),
  (
    filter: 'aecho',
    label: 'in_gain=inGainDefault',
    bundle: const [AechoEffect(inGain: AechoEffect.inGainDefault)],
  ),
  (
    filter: 'aecho',
    label: 'in_gain=inGainMax',
    bundle: const [AechoEffect(inGain: AechoEffect.inGainMax)],
  ),
  (
    filter: 'aecho',
    label: 'out_gain=outGainMin',
    bundle: const [AechoEffect(outGain: AechoEffect.outGainMin)],
  ),
  (
    filter: 'aecho',
    label: 'out_gain=outGainDefault',
    bundle: const [AechoEffect(outGain: AechoEffect.outGainDefault)],
  ),
  (
    filter: 'aecho',
    label: 'out_gain=outGainMax',
    bundle: const [AechoEffect(outGain: AechoEffect.outGainMax)],
  ),
  (
    filter: 'aemphasis',
    label: 'level_in=levelInMin',
    bundle: const [AemphasisEffect(levelIn: AemphasisEffect.levelInMin)],
  ),
  (
    filter: 'aemphasis',
    label: 'level_in=levelInDefault',
    bundle: const [AemphasisEffect(levelIn: AemphasisEffect.levelInDefault)],
  ),
  (
    filter: 'aemphasis',
    label: 'level_in=levelInMax',
    bundle: const [AemphasisEffect(levelIn: AemphasisEffect.levelInMax)],
  ),
  (
    filter: 'aemphasis',
    label: 'level_out=levelOutMin',
    bundle: const [AemphasisEffect(levelOut: AemphasisEffect.levelOutMin)],
  ),
  (
    filter: 'aemphasis',
    label: 'level_out=levelOutDefault',
    bundle: const [AemphasisEffect(levelOut: AemphasisEffect.levelOutDefault)],
  ),
  (
    filter: 'aemphasis',
    label: 'level_out=levelOutMax',
    bundle: const [AemphasisEffect(levelOut: AemphasisEffect.levelOutMax)],
  ),
  (
    filter: 'aexciter',
    label: 'amount=amountMin',
    bundle: const [AexciterEffect(amount: AexciterEffect.amountMin)],
  ),
  (
    filter: 'aexciter',
    label: 'amount=amountDefault',
    bundle: const [AexciterEffect(amount: AexciterEffect.amountDefault)],
  ),
  (
    filter: 'aexciter',
    label: 'amount=amountMax',
    bundle: const [AexciterEffect(amount: AexciterEffect.amountMax)],
  ),
  (
    filter: 'aexciter',
    label: 'blend=blendMin',
    bundle: const [AexciterEffect(blend: AexciterEffect.blendMin)],
  ),
  (
    filter: 'aexciter',
    label: 'blend=blendDefault',
    bundle: const [AexciterEffect(blend: AexciterEffect.blendDefault)],
  ),
  (
    filter: 'aexciter',
    label: 'blend=blendMax',
    bundle: const [AexciterEffect(blend: AexciterEffect.blendMax)],
  ),
  (
    filter: 'aexciter',
    label: 'ceil=ceilMin',
    bundle: const [AexciterEffect(ceil: AexciterEffect.ceilMin)],
  ),
  (
    filter: 'aexciter',
    label: 'ceil=ceilDefault',
    bundle: const [AexciterEffect(ceil: AexciterEffect.ceilDefault)],
  ),
  (
    filter: 'aexciter',
    label: 'ceil=ceilMax',
    bundle: const [AexciterEffect(ceil: AexciterEffect.ceilMax)],
  ),
  (
    filter: 'aexciter',
    label: 'drive=driveMin',
    bundle: const [AexciterEffect(drive: AexciterEffect.driveMin)],
  ),
  (
    filter: 'aexciter',
    label: 'drive=driveDefault',
    bundle: const [AexciterEffect(drive: AexciterEffect.driveDefault)],
  ),
  (
    filter: 'aexciter',
    label: 'drive=driveMax',
    bundle: const [AexciterEffect(drive: AexciterEffect.driveMax)],
  ),
  (
    filter: 'aexciter',
    label: 'freq=freqMin',
    bundle: const [AexciterEffect(freq: AexciterEffect.freqMin)],
  ),
  (
    filter: 'aexciter',
    label: 'freq=freqDefault',
    bundle: const [AexciterEffect(freq: AexciterEffect.freqDefault)],
  ),
  (
    filter: 'aexciter',
    label: 'freq=freqMax',
    bundle: const [AexciterEffect(freq: AexciterEffect.freqMax)],
  ),
  (
    filter: 'aexciter',
    label: 'level_in=levelInMin',
    bundle: const [AexciterEffect(levelIn: AexciterEffect.levelInMin)],
  ),
  (
    filter: 'aexciter',
    label: 'level_in=levelInDefault',
    bundle: const [AexciterEffect(levelIn: AexciterEffect.levelInDefault)],
  ),
  (
    filter: 'aexciter',
    label: 'level_in=levelInMax',
    bundle: const [AexciterEffect(levelIn: AexciterEffect.levelInMax)],
  ),
  (
    filter: 'aexciter',
    label: 'level_out=levelOutMin',
    bundle: const [AexciterEffect(levelOut: AexciterEffect.levelOutMin)],
  ),
  (
    filter: 'aexciter',
    label: 'level_out=levelOutDefault',
    bundle: const [AexciterEffect(levelOut: AexciterEffect.levelOutDefault)],
  ),
  (
    filter: 'aexciter',
    label: 'level_out=levelOutMax',
    bundle: const [AexciterEffect(levelOut: AexciterEffect.levelOutMax)],
  ),
  (
    filter: 'afade',
    label: 'duration=500us',
    bundle: const [AfadeEffect(duration: Duration(microseconds: 500))],
  ),
  (
    filter: 'afade',
    label: 'nb_samples=nbSamplesMin',
    bundle: const [AfadeEffect(nbSamples: AfadeEffect.nbSamplesMin)],
  ),
  (
    filter: 'afade',
    label: 'nb_samples=nbSamplesDefault',
    bundle: const [AfadeEffect(nbSamples: AfadeEffect.nbSamplesDefault)],
  ),
  (
    filter: 'afade',
    label: 'nb_samples=nbSamplesMax',
    bundle: const [AfadeEffect(nbSamples: AfadeEffect.nbSamplesMax)],
  ),
  (
    filter: 'afade',
    label: 'silence=silenceMin',
    bundle: const [AfadeEffect(silence: AfadeEffect.silenceMin)],
  ),
  (
    filter: 'afade',
    label: 'silence=silenceDefault',
    bundle: const [AfadeEffect(silence: AfadeEffect.silenceDefault)],
  ),
  (
    filter: 'afade',
    label: 'silence=silenceMax',
    bundle: const [AfadeEffect(silence: AfadeEffect.silenceMax)],
  ),
  (
    filter: 'afade',
    label: 'start_sample=startSampleMin',
    bundle: const [AfadeEffect(startSample: AfadeEffect.startSampleMin)],
  ),
  (
    filter: 'afade',
    label: 'start_sample=startSampleDefault',
    bundle: const [AfadeEffect(startSample: AfadeEffect.startSampleDefault)],
  ),
  (
    filter: 'afade',
    label: 'start_sample=startSampleMax',
    bundle: const [AfadeEffect(startSample: AfadeEffect.startSampleMax)],
  ),
  (
    filter: 'afade',
    label: 'start_time=500us',
    bundle: const [AfadeEffect(startTime: Duration(microseconds: 500))],
  ),
  (
    filter: 'afade',
    label: 'unity=unityMin',
    bundle: const [AfadeEffect(unity: AfadeEffect.unityMin)],
  ),
  (
    filter: 'afade',
    label: 'unity=unityDefault',
    bundle: const [AfadeEffect(unity: AfadeEffect.unityDefault)],
  ),
  (
    filter: 'afade',
    label: 'unity=unityMax',
    bundle: const [AfadeEffect(unity: AfadeEffect.unityMax)],
  ),
  (
    filter: 'afftdn',
    label: 'adaptivity=adaptivityMin',
    bundle: const [AfftdnEffect(adaptivity: AfftdnEffect.adaptivityMin)],
  ),
  (
    filter: 'afftdn',
    label: 'adaptivity=adaptivityDefault',
    bundle: const [AfftdnEffect(adaptivity: AfftdnEffect.adaptivityDefault)],
  ),
  (
    filter: 'afftdn',
    label: 'adaptivity=adaptivityMax',
    bundle: const [AfftdnEffect(adaptivity: AfftdnEffect.adaptivityMax)],
  ),
  (
    filter: 'afftdn',
    label: 'band_multiplier=bandMultiplierMin',
    bundle: const [
      AfftdnEffect(bandMultiplier: AfftdnEffect.bandMultiplierMin),
    ],
  ),
  (
    filter: 'afftdn',
    label: 'band_multiplier=bandMultiplierDefault',
    bundle: const [
      AfftdnEffect(bandMultiplier: AfftdnEffect.bandMultiplierDefault),
    ],
  ),
  (
    filter: 'afftdn',
    label: 'band_multiplier=bandMultiplierMax',
    bundle: const [
      AfftdnEffect(bandMultiplier: AfftdnEffect.bandMultiplierMax),
    ],
  ),
  (
    filter: 'afftdn',
    label: 'floor_offset=floorOffsetMin',
    bundle: const [AfftdnEffect(floorOffset: AfftdnEffect.floorOffsetMin)],
  ),
  (
    filter: 'afftdn',
    label: 'floor_offset=floorOffsetDefault',
    bundle: const [AfftdnEffect(floorOffset: AfftdnEffect.floorOffsetDefault)],
  ),
  (
    filter: 'afftdn',
    label: 'floor_offset=floorOffsetMax',
    bundle: const [AfftdnEffect(floorOffset: AfftdnEffect.floorOffsetMax)],
  ),
  (
    filter: 'afftdn',
    label: 'gain_smooth=gainSmoothMin',
    bundle: const [AfftdnEffect(gainSmooth: AfftdnEffect.gainSmoothMin)],
  ),
  (
    filter: 'afftdn',
    label: 'gain_smooth=gainSmoothDefault',
    bundle: const [AfftdnEffect(gainSmooth: AfftdnEffect.gainSmoothDefault)],
  ),
  (
    filter: 'afftdn',
    label: 'gain_smooth=gainSmoothMax',
    bundle: const [AfftdnEffect(gainSmooth: AfftdnEffect.gainSmoothMax)],
  ),
  (
    filter: 'afftdn',
    label: 'noise_floor=noiseFloorMin',
    bundle: const [AfftdnEffect(noiseFloor: AfftdnEffect.noiseFloorMin)],
  ),
  (
    filter: 'afftdn',
    label: 'noise_floor=noiseFloorDefault',
    bundle: const [AfftdnEffect(noiseFloor: AfftdnEffect.noiseFloorDefault)],
  ),
  (
    filter: 'afftdn',
    label: 'noise_floor=noiseFloorMax',
    bundle: const [AfftdnEffect(noiseFloor: AfftdnEffect.noiseFloorMax)],
  ),
  (
    filter: 'afftdn',
    label: 'noise_reduction=noiseReductionMin',
    bundle: const [
      AfftdnEffect(noiseReduction: AfftdnEffect.noiseReductionMin),
    ],
  ),
  (
    filter: 'afftdn',
    label: 'noise_reduction=noiseReductionDefault',
    bundle: const [
      AfftdnEffect(noiseReduction: AfftdnEffect.noiseReductionDefault),
    ],
  ),
  (
    filter: 'afftdn',
    label: 'noise_reduction=noiseReductionMax',
    bundle: const [
      AfftdnEffect(noiseReduction: AfftdnEffect.noiseReductionMax),
    ],
  ),
  (
    filter: 'afftdn',
    label: 'residual_floor=residualFloorMin',
    bundle: const [AfftdnEffect(residualFloor: AfftdnEffect.residualFloorMin)],
  ),
  (
    filter: 'afftdn',
    label: 'residual_floor=residualFloorDefault',
    bundle: const [
      AfftdnEffect(residualFloor: AfftdnEffect.residualFloorDefault),
    ],
  ),
  (
    filter: 'afftdn',
    label: 'residual_floor=residualFloorMax',
    bundle: const [AfftdnEffect(residualFloor: AfftdnEffect.residualFloorMax)],
  ),
  (
    filter: 'afftfilt',
    label: 'overlap=overlapMin',
    bundle: const [AfftfiltEffect(overlap: AfftfiltEffect.overlapMin)],
  ),
  (
    filter: 'afftfilt',
    label: 'overlap=overlapDefault',
    bundle: const [AfftfiltEffect(overlap: AfftfiltEffect.overlapDefault)],
  ),
  (
    filter: 'afftfilt',
    label: 'overlap=overlapMax',
    bundle: const [AfftfiltEffect(overlap: AfftfiltEffect.overlapMax)],
  ),
  (
    filter: 'afftfilt',
    label: 'win_size=winSizeMin',
    bundle: const [AfftfiltEffect(winSize: AfftfiltEffect.winSizeMin)],
  ),
  (
    filter: 'afftfilt',
    label: 'win_size=winSizeDefault',
    bundle: const [AfftfiltEffect(winSize: AfftfiltEffect.winSizeDefault)],
  ),
  (
    filter: 'afftfilt',
    label: 'win_size=winSizeMax',
    bundle: const [AfftfiltEffect(winSize: AfftfiltEffect.winSizeMax)],
  ),
  (
    filter: 'afreqshift',
    label: 'level=levelMin',
    bundle: const [AfreqshiftEffect(level: AfreqshiftEffect.levelMin)],
  ),
  (
    filter: 'afreqshift',
    label: 'level=levelDefault',
    bundle: const [AfreqshiftEffect(level: AfreqshiftEffect.levelDefault)],
  ),
  (
    filter: 'afreqshift',
    label: 'level=levelMax',
    bundle: const [AfreqshiftEffect(level: AfreqshiftEffect.levelMax)],
  ),
  (
    filter: 'afreqshift',
    label: 'order=orderMin',
    bundle: const [AfreqshiftEffect(order: AfreqshiftEffect.orderMin)],
  ),
  (
    filter: 'afreqshift',
    label: 'order=orderDefault',
    bundle: const [AfreqshiftEffect(order: AfreqshiftEffect.orderDefault)],
  ),
  (
    filter: 'afreqshift',
    label: 'order=orderMax',
    bundle: const [AfreqshiftEffect(order: AfreqshiftEffect.orderMax)],
  ),
  (
    filter: 'afreqshift',
    label: 'shift=shiftMin',
    bundle: const [AfreqshiftEffect(shift: AfreqshiftEffect.shiftMin)],
  ),
  (
    filter: 'afreqshift',
    label: 'shift=shiftDefault',
    bundle: const [AfreqshiftEffect(shift: AfreqshiftEffect.shiftDefault)],
  ),
  (
    filter: 'afreqshift',
    label: 'shift=shiftMax',
    bundle: const [AfreqshiftEffect(shift: AfreqshiftEffect.shiftMax)],
  ),
  (
    filter: 'afwtdn',
    label: 'levels=levelsMin',
    bundle: const [AfwtdnEffect(levels: AfwtdnEffect.levelsMin)],
  ),
  (
    filter: 'afwtdn',
    label: 'levels=levelsDefault',
    bundle: const [AfwtdnEffect(levels: AfwtdnEffect.levelsDefault)],
  ),
  (
    filter: 'afwtdn',
    label: 'levels=levelsMax',
    bundle: const [AfwtdnEffect(levels: AfwtdnEffect.levelsMax)],
  ),
  (
    filter: 'afwtdn',
    label: 'percent=percentMin',
    bundle: const [AfwtdnEffect(percent: AfwtdnEffect.percentMin)],
  ),
  (
    filter: 'afwtdn',
    label: 'percent=percentDefault',
    bundle: const [AfwtdnEffect(percent: AfwtdnEffect.percentDefault)],
  ),
  (
    filter: 'afwtdn',
    label: 'percent=percentMax',
    bundle: const [AfwtdnEffect(percent: AfwtdnEffect.percentMax)],
  ),
  (
    filter: 'afwtdn',
    label: 'samples=samplesMin',
    bundle: const [AfwtdnEffect(samples: AfwtdnEffect.samplesMin)],
  ),
  (
    filter: 'afwtdn',
    label: 'samples=samplesDefault',
    bundle: const [AfwtdnEffect(samples: AfwtdnEffect.samplesDefault)],
  ),
  (
    filter: 'afwtdn',
    label: 'samples=samplesMax',
    bundle: const [AfwtdnEffect(samples: AfwtdnEffect.samplesMax)],
  ),
  (
    filter: 'afwtdn',
    label: 'sigma=sigmaMin',
    bundle: const [AfwtdnEffect(sigma: AfwtdnEffect.sigmaMin)],
  ),
  (
    filter: 'afwtdn',
    label: 'sigma=sigmaDefault',
    bundle: const [AfwtdnEffect(sigma: AfwtdnEffect.sigmaDefault)],
  ),
  (
    filter: 'afwtdn',
    label: 'sigma=sigmaMax',
    bundle: const [AfwtdnEffect(sigma: AfwtdnEffect.sigmaMax)],
  ),
  (
    filter: 'afwtdn',
    label: 'softness=softnessMin',
    bundle: const [AfwtdnEffect(softness: AfwtdnEffect.softnessMin)],
  ),
  (
    filter: 'afwtdn',
    label: 'softness=softnessDefault',
    bundle: const [AfwtdnEffect(softness: AfwtdnEffect.softnessDefault)],
  ),
  (
    filter: 'afwtdn',
    label: 'softness=softnessMax',
    bundle: const [AfwtdnEffect(softness: AfwtdnEffect.softnessMax)],
  ),
  (
    filter: 'agate',
    label: 'attack=attackMin',
    bundle: const [AgateEffect(attack: AgateEffect.attackMin)],
  ),
  (
    filter: 'agate',
    label: 'attack=attackDefault',
    bundle: const [AgateEffect(attack: AgateEffect.attackDefault)],
  ),
  (
    filter: 'agate',
    label: 'attack=attackMax',
    bundle: const [AgateEffect(attack: AgateEffect.attackMax)],
  ),
  (
    filter: 'agate',
    label: 'knee=kneeMin',
    bundle: const [AgateEffect(knee: AgateEffect.kneeMin)],
  ),
  (
    filter: 'agate',
    label: 'knee=kneeDefault',
    bundle: const [AgateEffect(knee: AgateEffect.kneeDefault)],
  ),
  (
    filter: 'agate',
    label: 'knee=kneeMax',
    bundle: const [AgateEffect(knee: AgateEffect.kneeMax)],
  ),
  (
    filter: 'agate',
    label: 'level_in=levelInMin',
    bundle: const [AgateEffect(levelIn: AgateEffect.levelInMin)],
  ),
  (
    filter: 'agate',
    label: 'level_in=levelInDefault',
    bundle: const [AgateEffect(levelIn: AgateEffect.levelInDefault)],
  ),
  (
    filter: 'agate',
    label: 'level_in=levelInMax',
    bundle: const [AgateEffect(levelIn: AgateEffect.levelInMax)],
  ),
  (
    filter: 'agate',
    label: 'level_sc=levelScMin',
    bundle: const [AgateEffect(levelSc: AgateEffect.levelScMin)],
  ),
  (
    filter: 'agate',
    label: 'level_sc=levelScDefault',
    bundle: const [AgateEffect(levelSc: AgateEffect.levelScDefault)],
  ),
  (
    filter: 'agate',
    label: 'level_sc=levelScMax',
    bundle: const [AgateEffect(levelSc: AgateEffect.levelScMax)],
  ),
  (
    filter: 'agate',
    label: 'makeup=makeupMin',
    bundle: const [AgateEffect(makeup: AgateEffect.makeupMin)],
  ),
  (
    filter: 'agate',
    label: 'makeup=makeupDefault',
    bundle: const [AgateEffect(makeup: AgateEffect.makeupDefault)],
  ),
  (
    filter: 'agate',
    label: 'makeup=makeupMax',
    bundle: const [AgateEffect(makeup: AgateEffect.makeupMax)],
  ),
  (
    filter: 'agate',
    label: 'range=rangeMin',
    bundle: const [AgateEffect(range: AgateEffect.rangeMin)],
  ),
  (
    filter: 'agate',
    label: 'range=rangeDefault',
    bundle: const [AgateEffect(range: AgateEffect.rangeDefault)],
  ),
  (
    filter: 'agate',
    label: 'range=rangeMax',
    bundle: const [AgateEffect(range: AgateEffect.rangeMax)],
  ),
  (
    filter: 'agate',
    label: 'ratio=ratioMin',
    bundle: const [AgateEffect(ratio: AgateEffect.ratioMin)],
  ),
  (
    filter: 'agate',
    label: 'ratio=ratioDefault',
    bundle: const [AgateEffect(ratio: AgateEffect.ratioDefault)],
  ),
  (
    filter: 'agate',
    label: 'ratio=ratioMax',
    bundle: const [AgateEffect(ratio: AgateEffect.ratioMax)],
  ),
  (
    filter: 'agate',
    label: 'release=releaseMin',
    bundle: const [AgateEffect(release: AgateEffect.releaseMin)],
  ),
  (
    filter: 'agate',
    label: 'release=releaseDefault',
    bundle: const [AgateEffect(release: AgateEffect.releaseDefault)],
  ),
  (
    filter: 'agate',
    label: 'release=releaseMax',
    bundle: const [AgateEffect(release: AgateEffect.releaseMax)],
  ),
  (
    filter: 'agate',
    label: 'threshold=thresholdMin',
    bundle: const [AgateEffect(threshold: AgateEffect.thresholdMin)],
  ),
  (
    filter: 'agate',
    label: 'threshold=thresholdDefault',
    bundle: const [AgateEffect(threshold: AgateEffect.thresholdDefault)],
  ),
  (
    filter: 'agate',
    label: 'threshold=thresholdMax',
    bundle: const [AgateEffect(threshold: AgateEffect.thresholdMax)],
  ),
  (
    filter: 'aiir',
    label: 'channel=channelMin',
    bundle: const [AiirEffect(channel: AiirEffect.channelMin)],
  ),
  (
    filter: 'aiir',
    label: 'channel=channelDefault',
    bundle: const [AiirEffect(channel: AiirEffect.channelDefault)],
  ),
  (
    filter: 'aiir',
    label: 'channel=channelMax',
    bundle: const [AiirEffect(channel: AiirEffect.channelMax)],
  ),
  (
    filter: 'aiir',
    label: 'dry=dryMin',
    bundle: const [AiirEffect(dry: AiirEffect.dryMin)],
  ),
  (
    filter: 'aiir',
    label: 'dry=dryDefault',
    bundle: const [AiirEffect(dry: AiirEffect.dryDefault)],
  ),
  (
    filter: 'aiir',
    label: 'dry=dryMax',
    bundle: const [AiirEffect(dry: AiirEffect.dryMax)],
  ),
  (
    filter: 'aiir',
    label: 'mix=mixMin',
    bundle: const [AiirEffect(mix: AiirEffect.mixMin)],
  ),
  (
    filter: 'aiir',
    label: 'mix=mixDefault',
    bundle: const [AiirEffect(mix: AiirEffect.mixDefault)],
  ),
  (
    filter: 'aiir',
    label: 'mix=mixMax',
    bundle: const [AiirEffect(mix: AiirEffect.mixMax)],
  ),
  (
    filter: 'aiir',
    label: 'wet=wetMin',
    bundle: const [AiirEffect(wet: AiirEffect.wetMin)],
  ),
  (
    filter: 'aiir',
    label: 'wet=wetDefault',
    bundle: const [AiirEffect(wet: AiirEffect.wetDefault)],
  ),
  (
    filter: 'aiir',
    label: 'wet=wetMax',
    bundle: const [AiirEffect(wet: AiirEffect.wetMax)],
  ),
  (
    filter: 'alimiter',
    label: 'asc_level=ascLevelMin',
    bundle: const [AlimiterEffect(ascLevel: AlimiterEffect.ascLevelMin)],
  ),
  (
    filter: 'alimiter',
    label: 'asc_level=ascLevelDefault',
    bundle: const [AlimiterEffect(ascLevel: AlimiterEffect.ascLevelDefault)],
  ),
  (
    filter: 'alimiter',
    label: 'asc_level=ascLevelMax',
    bundle: const [AlimiterEffect(ascLevel: AlimiterEffect.ascLevelMax)],
  ),
  (
    filter: 'alimiter',
    label: 'attack=attackMin',
    bundle: const [AlimiterEffect(attack: AlimiterEffect.attackMin)],
  ),
  (
    filter: 'alimiter',
    label: 'attack=attackDefault',
    bundle: const [AlimiterEffect(attack: AlimiterEffect.attackDefault)],
  ),
  (
    filter: 'alimiter',
    label: 'attack=attackMax',
    bundle: const [AlimiterEffect(attack: AlimiterEffect.attackMax)],
  ),
  (
    filter: 'alimiter',
    label: 'level_in=levelInMin',
    bundle: const [AlimiterEffect(levelIn: AlimiterEffect.levelInMin)],
  ),
  (
    filter: 'alimiter',
    label: 'level_in=levelInDefault',
    bundle: const [AlimiterEffect(levelIn: AlimiterEffect.levelInDefault)],
  ),
  (
    filter: 'alimiter',
    label: 'level_in=levelInMax',
    bundle: const [AlimiterEffect(levelIn: AlimiterEffect.levelInMax)],
  ),
  (
    filter: 'alimiter',
    label: 'level_out=levelOutMin',
    bundle: const [AlimiterEffect(levelOut: AlimiterEffect.levelOutMin)],
  ),
  (
    filter: 'alimiter',
    label: 'level_out=levelOutDefault',
    bundle: const [AlimiterEffect(levelOut: AlimiterEffect.levelOutDefault)],
  ),
  (
    filter: 'alimiter',
    label: 'level_out=levelOutMax',
    bundle: const [AlimiterEffect(levelOut: AlimiterEffect.levelOutMax)],
  ),
  (
    filter: 'alimiter',
    label: 'limit=limitMin',
    bundle: const [AlimiterEffect(limit: AlimiterEffect.limitMin)],
  ),
  (
    filter: 'alimiter',
    label: 'limit=limitDefault',
    bundle: const [AlimiterEffect(limit: AlimiterEffect.limitDefault)],
  ),
  (
    filter: 'alimiter',
    label: 'limit=limitMax',
    bundle: const [AlimiterEffect(limit: AlimiterEffect.limitMax)],
  ),
  (
    filter: 'alimiter',
    label: 'release=releaseMin',
    bundle: const [AlimiterEffect(release: AlimiterEffect.releaseMin)],
  ),
  (
    filter: 'alimiter',
    label: 'release=releaseDefault',
    bundle: const [AlimiterEffect(release: AlimiterEffect.releaseDefault)],
  ),
  (
    filter: 'alimiter',
    label: 'release=releaseMax',
    bundle: const [AlimiterEffect(release: AlimiterEffect.releaseMax)],
  ),
  (
    filter: 'allpass',
    label: 'frequency=frequencyMin',
    bundle: const [AllpassEffect(frequency: AllpassEffect.frequencyMin)],
  ),
  (
    filter: 'allpass',
    label: 'frequency=frequencyDefault',
    bundle: const [AllpassEffect(frequency: AllpassEffect.frequencyDefault)],
  ),
  (
    filter: 'allpass',
    label: 'frequency=frequencyMax',
    bundle: const [AllpassEffect(frequency: AllpassEffect.frequencyMax)],
  ),
  (
    filter: 'allpass',
    label: 'mix=mixMin',
    bundle: const [AllpassEffect(mix: AllpassEffect.mixMin)],
  ),
  (
    filter: 'allpass',
    label: 'mix=mixDefault',
    bundle: const [AllpassEffect(mix: AllpassEffect.mixDefault)],
  ),
  (
    filter: 'allpass',
    label: 'mix=mixMax',
    bundle: const [AllpassEffect(mix: AllpassEffect.mixMax)],
  ),
  (
    filter: 'allpass',
    label: 'order=orderMin',
    bundle: const [AllpassEffect(order: AllpassEffect.orderMin)],
  ),
  (
    filter: 'allpass',
    label: 'order=orderDefault',
    bundle: const [AllpassEffect(order: AllpassEffect.orderDefault)],
  ),
  (
    filter: 'allpass',
    label: 'order=orderMax',
    bundle: const [AllpassEffect(order: AllpassEffect.orderMax)],
  ),
  (
    filter: 'allpass',
    label: 'width=widthMin',
    bundle: const [AllpassEffect(width: AllpassEffect.widthMin)],
  ),
  (
    filter: 'allpass',
    label: 'width=widthDefault',
    bundle: const [AllpassEffect(width: AllpassEffect.widthDefault)],
  ),
  (
    filter: 'allpass',
    label: 'width=widthMax',
    bundle: const [AllpassEffect(width: AllpassEffect.widthMax)],
  ),
  (
    filter: 'anequalizer',
    label: 'mgain=mgainMin',
    bundle: const [AnequalizerEffect(mgain: AnequalizerEffect.mgainMin)],
  ),
  (
    filter: 'anequalizer',
    label: 'mgain=mgainDefault',
    bundle: const [AnequalizerEffect(mgain: AnequalizerEffect.mgainDefault)],
  ),
  (
    filter: 'anequalizer',
    label: 'mgain=mgainMax',
    bundle: const [AnequalizerEffect(mgain: AnequalizerEffect.mgainMax)],
  ),
  (
    filter: 'anlmdn',
    label: 'smooth=smoothMin',
    bundle: const [AnlmdnEffect(smooth: AnlmdnEffect.smoothMin)],
  ),
  (
    filter: 'anlmdn',
    label: 'smooth=smoothDefault',
    bundle: const [AnlmdnEffect(smooth: AnlmdnEffect.smoothDefault)],
  ),
  (
    filter: 'anlmdn',
    label: 'smooth=smoothMax',
    bundle: const [AnlmdnEffect(smooth: AnlmdnEffect.smoothMax)],
  ),
  (
    filter: 'anlmdn',
    label: 'strength=strengthMin',
    bundle: const [AnlmdnEffect(strength: AnlmdnEffect.strengthMin)],
  ),
  (
    filter: 'anlmdn',
    label: 'strength=strengthDefault',
    bundle: const [AnlmdnEffect(strength: AnlmdnEffect.strengthDefault)],
  ),
  (
    filter: 'anlmdn',
    label: 'strength=strengthMax',
    bundle: const [AnlmdnEffect(strength: AnlmdnEffect.strengthMax)],
  ),
  (
    filter: 'apad',
    label: 'packet_size=packetSizeMin',
    bundle: const [ApadEffect(packetSize: ApadEffect.packetSizeMin)],
  ),
  (
    filter: 'apad',
    label: 'packet_size=packetSizeDefault',
    bundle: const [ApadEffect(packetSize: ApadEffect.packetSizeDefault)],
  ),
  (
    filter: 'apad',
    label: 'packet_size=packetSizeMax',
    bundle: const [ApadEffect(packetSize: ApadEffect.packetSizeMax)],
  ),
  (
    filter: 'apad',
    label: 'pad_dur=500us',
    bundle: const [ApadEffect(padDur: Duration(microseconds: 500))],
  ),
  (
    filter: 'apad',
    label: 'pad_len=padLenMin',
    bundle: const [ApadEffect(padLen: ApadEffect.padLenMin)],
  ),
  (
    filter: 'apad',
    label: 'pad_len=padLenDefault',
    bundle: const [ApadEffect(padLen: ApadEffect.padLenDefault)],
  ),
  (
    filter: 'apad',
    label: 'pad_len=padLenMax',
    bundle: const [ApadEffect(padLen: ApadEffect.padLenMax)],
  ),
  (
    filter: 'apad',
    label: 'whole_dur=500us',
    bundle: const [ApadEffect(wholeDur: Duration(microseconds: 500))],
  ),
  (
    filter: 'apad',
    label: 'whole_len=wholeLenMin',
    bundle: const [ApadEffect(wholeLen: ApadEffect.wholeLenMin)],
  ),
  (
    filter: 'apad',
    label: 'whole_len=wholeLenDefault',
    bundle: const [ApadEffect(wholeLen: ApadEffect.wholeLenDefault)],
  ),
  (
    filter: 'apad',
    label: 'whole_len=wholeLenMax',
    bundle: const [ApadEffect(wholeLen: ApadEffect.wholeLenMax)],
  ),
  (
    filter: 'aphaser',
    label: 'decay=decayMin',
    bundle: const [AphaserEffect(decay: AphaserEffect.decayMin)],
  ),
  (
    filter: 'aphaser',
    label: 'decay=decayDefault',
    bundle: const [AphaserEffect(decay: AphaserEffect.decayDefault)],
  ),
  (
    filter: 'aphaser',
    label: 'decay=decayMax',
    bundle: const [AphaserEffect(decay: AphaserEffect.decayMax)],
  ),
  (
    filter: 'aphaser',
    label: 'delay=delayMin',
    bundle: const [AphaserEffect(delay: AphaserEffect.delayMin)],
  ),
  (
    filter: 'aphaser',
    label: 'delay=delayDefault',
    bundle: const [AphaserEffect(delay: AphaserEffect.delayDefault)],
  ),
  (
    filter: 'aphaser',
    label: 'delay=delayMax',
    bundle: const [AphaserEffect(delay: AphaserEffect.delayMax)],
  ),
  (
    filter: 'aphaser',
    label: 'in_gain=inGainMin',
    bundle: const [AphaserEffect(inGain: AphaserEffect.inGainMin)],
  ),
  (
    filter: 'aphaser',
    label: 'in_gain=inGainDefault',
    bundle: const [AphaserEffect(inGain: AphaserEffect.inGainDefault)],
  ),
  (
    filter: 'aphaser',
    label: 'in_gain=inGainMax',
    bundle: const [AphaserEffect(inGain: AphaserEffect.inGainMax)],
  ),
  (
    filter: 'aphaser',
    label: 'out_gain=outGainMin',
    bundle: const [AphaserEffect(outGain: AphaserEffect.outGainMin)],
  ),
  (
    filter: 'aphaser',
    label: 'out_gain=outGainDefault',
    bundle: const [AphaserEffect(outGain: AphaserEffect.outGainDefault)],
  ),
  (
    filter: 'aphaser',
    label: 'out_gain=outGainMax',
    bundle: const [AphaserEffect(outGain: AphaserEffect.outGainMax)],
  ),
  (
    filter: 'aphaser',
    label: 'speed=speedMin',
    bundle: const [AphaserEffect(speed: AphaserEffect.speedMin)],
  ),
  (
    filter: 'aphaser',
    label: 'speed=speedDefault',
    bundle: const [AphaserEffect(speed: AphaserEffect.speedDefault)],
  ),
  (
    filter: 'aphaser',
    label: 'speed=speedMax',
    bundle: const [AphaserEffect(speed: AphaserEffect.speedMax)],
  ),
  (
    filter: 'aphaseshift',
    label: 'level=levelMin',
    bundle: const [AphaseshiftEffect(level: AphaseshiftEffect.levelMin)],
  ),
  (
    filter: 'aphaseshift',
    label: 'level=levelDefault',
    bundle: const [AphaseshiftEffect(level: AphaseshiftEffect.levelDefault)],
  ),
  (
    filter: 'aphaseshift',
    label: 'level=levelMax',
    bundle: const [AphaseshiftEffect(level: AphaseshiftEffect.levelMax)],
  ),
  (
    filter: 'aphaseshift',
    label: 'order=orderMin',
    bundle: const [AphaseshiftEffect(order: AphaseshiftEffect.orderMin)],
  ),
  (
    filter: 'aphaseshift',
    label: 'order=orderDefault',
    bundle: const [AphaseshiftEffect(order: AphaseshiftEffect.orderDefault)],
  ),
  (
    filter: 'aphaseshift',
    label: 'order=orderMax',
    bundle: const [AphaseshiftEffect(order: AphaseshiftEffect.orderMax)],
  ),
  (
    filter: 'aphaseshift',
    label: 'shift=shiftMin',
    bundle: const [AphaseshiftEffect(shift: AphaseshiftEffect.shiftMin)],
  ),
  (
    filter: 'aphaseshift',
    label: 'shift=shiftDefault',
    bundle: const [AphaseshiftEffect(shift: AphaseshiftEffect.shiftDefault)],
  ),
  (
    filter: 'aphaseshift',
    label: 'shift=shiftMax',
    bundle: const [AphaseshiftEffect(shift: AphaseshiftEffect.shiftMax)],
  ),
  (
    filter: 'apsyclip',
    label: 'adaptive=adaptiveMin',
    bundle: const [ApsyclipEffect(adaptive: ApsyclipEffect.adaptiveMin)],
  ),
  (
    filter: 'apsyclip',
    label: 'adaptive=adaptiveDefault',
    bundle: const [ApsyclipEffect(adaptive: ApsyclipEffect.adaptiveDefault)],
  ),
  (
    filter: 'apsyclip',
    label: 'adaptive=adaptiveMax',
    bundle: const [ApsyclipEffect(adaptive: ApsyclipEffect.adaptiveMax)],
  ),
  (
    filter: 'apsyclip',
    label: 'clip=clipMin',
    bundle: const [ApsyclipEffect(clip: ApsyclipEffect.clipMin)],
  ),
  (
    filter: 'apsyclip',
    label: 'clip=clipDefault',
    bundle: const [ApsyclipEffect(clip: ApsyclipEffect.clipDefault)],
  ),
  (
    filter: 'apsyclip',
    label: 'clip=clipMax',
    bundle: const [ApsyclipEffect(clip: ApsyclipEffect.clipMax)],
  ),
  (
    filter: 'apsyclip',
    label: 'iterations=iterationsMin',
    bundle: const [ApsyclipEffect(iterations: ApsyclipEffect.iterationsMin)],
  ),
  (
    filter: 'apsyclip',
    label: 'iterations=iterationsDefault',
    bundle: const [
      ApsyclipEffect(iterations: ApsyclipEffect.iterationsDefault),
    ],
  ),
  (
    filter: 'apsyclip',
    label: 'iterations=iterationsMax',
    bundle: const [ApsyclipEffect(iterations: ApsyclipEffect.iterationsMax)],
  ),
  (
    filter: 'apsyclip',
    label: 'level_in=levelInMin',
    bundle: const [ApsyclipEffect(levelIn: ApsyclipEffect.levelInMin)],
  ),
  (
    filter: 'apsyclip',
    label: 'level_in=levelInDefault',
    bundle: const [ApsyclipEffect(levelIn: ApsyclipEffect.levelInDefault)],
  ),
  (
    filter: 'apsyclip',
    label: 'level_in=levelInMax',
    bundle: const [ApsyclipEffect(levelIn: ApsyclipEffect.levelInMax)],
  ),
  (
    filter: 'apsyclip',
    label: 'level_out=levelOutMin',
    bundle: const [ApsyclipEffect(levelOut: ApsyclipEffect.levelOutMin)],
  ),
  (
    filter: 'apsyclip',
    label: 'level_out=levelOutDefault',
    bundle: const [ApsyclipEffect(levelOut: ApsyclipEffect.levelOutDefault)],
  ),
  (
    filter: 'apsyclip',
    label: 'level_out=levelOutMax',
    bundle: const [ApsyclipEffect(levelOut: ApsyclipEffect.levelOutMax)],
  ),
  (
    filter: 'apulsator',
    label: 'amount=amountMin',
    bundle: const [ApulsatorEffect(amount: ApulsatorEffect.amountMin)],
  ),
  (
    filter: 'apulsator',
    label: 'amount=amountDefault',
    bundle: const [ApulsatorEffect(amount: ApulsatorEffect.amountDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'amount=amountMax',
    bundle: const [ApulsatorEffect(amount: ApulsatorEffect.amountMax)],
  ),
  (
    filter: 'apulsator',
    label: 'bpm=bpmMin',
    bundle: const [ApulsatorEffect(bpm: ApulsatorEffect.bpmMin)],
  ),
  (
    filter: 'apulsator',
    label: 'bpm=bpmDefault',
    bundle: const [ApulsatorEffect(bpm: ApulsatorEffect.bpmDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'bpm=bpmMax',
    bundle: const [ApulsatorEffect(bpm: ApulsatorEffect.bpmMax)],
  ),
  (
    filter: 'apulsator',
    label: 'hz=hzMin',
    bundle: const [ApulsatorEffect(hz: ApulsatorEffect.hzMin)],
  ),
  (
    filter: 'apulsator',
    label: 'hz=hzDefault',
    bundle: const [ApulsatorEffect(hz: ApulsatorEffect.hzDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'hz=hzMax',
    bundle: const [ApulsatorEffect(hz: ApulsatorEffect.hzMax)],
  ),
  (
    filter: 'apulsator',
    label: 'level_in=levelInMin',
    bundle: const [ApulsatorEffect(levelIn: ApulsatorEffect.levelInMin)],
  ),
  (
    filter: 'apulsator',
    label: 'level_in=levelInDefault',
    bundle: const [ApulsatorEffect(levelIn: ApulsatorEffect.levelInDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'level_in=levelInMax',
    bundle: const [ApulsatorEffect(levelIn: ApulsatorEffect.levelInMax)],
  ),
  (
    filter: 'apulsator',
    label: 'level_out=levelOutMin',
    bundle: const [ApulsatorEffect(levelOut: ApulsatorEffect.levelOutMin)],
  ),
  (
    filter: 'apulsator',
    label: 'level_out=levelOutDefault',
    bundle: const [ApulsatorEffect(levelOut: ApulsatorEffect.levelOutDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'level_out=levelOutMax',
    bundle: const [ApulsatorEffect(levelOut: ApulsatorEffect.levelOutMax)],
  ),
  (
    filter: 'apulsator',
    label: 'ms=msMin',
    bundle: const [ApulsatorEffect(ms: ApulsatorEffect.msMin)],
  ),
  (
    filter: 'apulsator',
    label: 'ms=msDefault',
    bundle: const [ApulsatorEffect(ms: ApulsatorEffect.msDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'ms=msMax',
    bundle: const [ApulsatorEffect(ms: ApulsatorEffect.msMax)],
  ),
  (
    filter: 'apulsator',
    label: 'offset_l=offsetLMin',
    bundle: const [ApulsatorEffect(offsetL: ApulsatorEffect.offsetLMin)],
  ),
  (
    filter: 'apulsator',
    label: 'offset_l=offsetLDefault',
    bundle: const [ApulsatorEffect(offsetL: ApulsatorEffect.offsetLDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'offset_l=offsetLMax',
    bundle: const [ApulsatorEffect(offsetL: ApulsatorEffect.offsetLMax)],
  ),
  (
    filter: 'apulsator',
    label: 'offset_r=offsetRMin',
    bundle: const [ApulsatorEffect(offsetR: ApulsatorEffect.offsetRMin)],
  ),
  (
    filter: 'apulsator',
    label: 'offset_r=offsetRDefault',
    bundle: const [ApulsatorEffect(offsetR: ApulsatorEffect.offsetRDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'offset_r=offsetRMax',
    bundle: const [ApulsatorEffect(offsetR: ApulsatorEffect.offsetRMax)],
  ),
  (
    filter: 'apulsator',
    label: 'width=widthMin',
    bundle: const [ApulsatorEffect(width: ApulsatorEffect.widthMin)],
  ),
  (
    filter: 'apulsator',
    label: 'width=widthDefault',
    bundle: const [ApulsatorEffect(width: ApulsatorEffect.widthDefault)],
  ),
  (
    filter: 'apulsator',
    label: 'width=widthMax',
    bundle: const [ApulsatorEffect(width: ApulsatorEffect.widthMax)],
  ),
  (
    filter: 'aresample',
    label: 'sample_rate=sampleRateMin',
    bundle: const [AresampleEffect(sampleRate: AresampleEffect.sampleRateMin)],
  ),
  (
    filter: 'aresample',
    label: 'sample_rate=sampleRateDefault',
    bundle: const [
      AresampleEffect(sampleRate: AresampleEffect.sampleRateDefault),
    ],
  ),
  (
    filter: 'aresample',
    label: 'sample_rate=sampleRateMax',
    bundle: const [AresampleEffect(sampleRate: AresampleEffect.sampleRateMax)],
  ),
  (
    filter: 'arnndn',
    label: 'mix=mixMin',
    bundle: const [ArnndnEffect(mix: ArnndnEffect.mixMin, model: '')],
  ),
  (
    filter: 'arnndn',
    label: 'mix=mixDefault',
    bundle: const [ArnndnEffect(mix: ArnndnEffect.mixDefault, model: '')],
  ),
  (
    filter: 'arnndn',
    label: 'mix=mixMax',
    bundle: const [ArnndnEffect(mix: ArnndnEffect.mixMax, model: '')],
  ),
  (
    filter: 'asoftclip',
    label: 'output=outputMin',
    bundle: const [AsoftclipEffect(output: AsoftclipEffect.outputMin)],
  ),
  (
    filter: 'asoftclip',
    label: 'output=outputDefault',
    bundle: const [AsoftclipEffect(output: AsoftclipEffect.outputDefault)],
  ),
  (
    filter: 'asoftclip',
    label: 'output=outputMax',
    bundle: const [AsoftclipEffect(output: AsoftclipEffect.outputMax)],
  ),
  (
    filter: 'asoftclip',
    label: 'oversample=oversampleMin',
    bundle: const [AsoftclipEffect(oversample: AsoftclipEffect.oversampleMin)],
  ),
  (
    filter: 'asoftclip',
    label: 'oversample=oversampleDefault',
    bundle: const [
      AsoftclipEffect(oversample: AsoftclipEffect.oversampleDefault),
    ],
  ),
  (
    filter: 'asoftclip',
    label: 'oversample=oversampleMax',
    bundle: const [AsoftclipEffect(oversample: AsoftclipEffect.oversampleMax)],
  ),
  (
    filter: 'asoftclip',
    label: 'param=paramMin',
    bundle: const [AsoftclipEffect(param: AsoftclipEffect.paramMin)],
  ),
  (
    filter: 'asoftclip',
    label: 'param=paramDefault',
    bundle: const [AsoftclipEffect(param: AsoftclipEffect.paramDefault)],
  ),
  (
    filter: 'asoftclip',
    label: 'param=paramMax',
    bundle: const [AsoftclipEffect(param: AsoftclipEffect.paramMax)],
  ),
  (
    filter: 'asoftclip',
    label: 'threshold=thresholdMin',
    bundle: const [AsoftclipEffect(threshold: AsoftclipEffect.thresholdMin)],
  ),
  (
    filter: 'asoftclip',
    label: 'threshold=thresholdDefault',
    bundle: const [
      AsoftclipEffect(threshold: AsoftclipEffect.thresholdDefault),
    ],
  ),
  (
    filter: 'asoftclip',
    label: 'threshold=thresholdMax',
    bundle: const [AsoftclipEffect(threshold: AsoftclipEffect.thresholdMax)],
  ),
  (
    filter: 'asubboost',
    label: 'boost=boostMin',
    bundle: const [AsubboostEffect(boost: AsubboostEffect.boostMin)],
  ),
  (
    filter: 'asubboost',
    label: 'boost=boostDefault',
    bundle: const [AsubboostEffect(boost: AsubboostEffect.boostDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'boost=boostMax',
    bundle: const [AsubboostEffect(boost: AsubboostEffect.boostMax)],
  ),
  (
    filter: 'asubboost',
    label: 'cutoff=cutoffMin',
    bundle: const [AsubboostEffect(cutoff: AsubboostEffect.cutoffMin)],
  ),
  (
    filter: 'asubboost',
    label: 'cutoff=cutoffDefault',
    bundle: const [AsubboostEffect(cutoff: AsubboostEffect.cutoffDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'cutoff=cutoffMax',
    bundle: const [AsubboostEffect(cutoff: AsubboostEffect.cutoffMax)],
  ),
  (
    filter: 'asubboost',
    label: 'decay=decayMin',
    bundle: const [AsubboostEffect(decay: AsubboostEffect.decayMin)],
  ),
  (
    filter: 'asubboost',
    label: 'decay=decayDefault',
    bundle: const [AsubboostEffect(decay: AsubboostEffect.decayDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'decay=decayMax',
    bundle: const [AsubboostEffect(decay: AsubboostEffect.decayMax)],
  ),
  (
    filter: 'asubboost',
    label: 'delay=delayMin',
    bundle: const [AsubboostEffect(delay: AsubboostEffect.delayMin)],
  ),
  (
    filter: 'asubboost',
    label: 'delay=delayDefault',
    bundle: const [AsubboostEffect(delay: AsubboostEffect.delayDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'delay=delayMax',
    bundle: const [AsubboostEffect(delay: AsubboostEffect.delayMax)],
  ),
  (
    filter: 'asubboost',
    label: 'dry=dryMin',
    bundle: const [AsubboostEffect(dry: AsubboostEffect.dryMin)],
  ),
  (
    filter: 'asubboost',
    label: 'dry=dryDefault',
    bundle: const [AsubboostEffect(dry: AsubboostEffect.dryDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'dry=dryMax',
    bundle: const [AsubboostEffect(dry: AsubboostEffect.dryMax)],
  ),
  (
    filter: 'asubboost',
    label: 'feedback=feedbackMin',
    bundle: const [AsubboostEffect(feedback: AsubboostEffect.feedbackMin)],
  ),
  (
    filter: 'asubboost',
    label: 'feedback=feedbackDefault',
    bundle: const [AsubboostEffect(feedback: AsubboostEffect.feedbackDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'feedback=feedbackMax',
    bundle: const [AsubboostEffect(feedback: AsubboostEffect.feedbackMax)],
  ),
  (
    filter: 'asubboost',
    label: 'slope=slopeMin',
    bundle: const [AsubboostEffect(slope: AsubboostEffect.slopeMin)],
  ),
  (
    filter: 'asubboost',
    label: 'slope=slopeDefault',
    bundle: const [AsubboostEffect(slope: AsubboostEffect.slopeDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'slope=slopeMax',
    bundle: const [AsubboostEffect(slope: AsubboostEffect.slopeMax)],
  ),
  (
    filter: 'asubboost',
    label: 'wet=wetMin',
    bundle: const [AsubboostEffect(wet: AsubboostEffect.wetMin)],
  ),
  (
    filter: 'asubboost',
    label: 'wet=wetDefault',
    bundle: const [AsubboostEffect(wet: AsubboostEffect.wetDefault)],
  ),
  (
    filter: 'asubboost',
    label: 'wet=wetMax',
    bundle: const [AsubboostEffect(wet: AsubboostEffect.wetMax)],
  ),
  (
    filter: 'asubcut',
    label: 'cutoff=cutoffMin',
    bundle: const [AsubcutEffect(cutoff: AsubcutEffect.cutoffMin)],
  ),
  (
    filter: 'asubcut',
    label: 'cutoff=cutoffDefault',
    bundle: const [AsubcutEffect(cutoff: AsubcutEffect.cutoffDefault)],
  ),
  (
    filter: 'asubcut',
    label: 'cutoff=cutoffMax',
    bundle: const [AsubcutEffect(cutoff: AsubcutEffect.cutoffMax)],
  ),
  (
    filter: 'asubcut',
    label: 'level=levelMin',
    bundle: const [AsubcutEffect(level: AsubcutEffect.levelMin)],
  ),
  (
    filter: 'asubcut',
    label: 'level=levelDefault',
    bundle: const [AsubcutEffect(level: AsubcutEffect.levelDefault)],
  ),
  (
    filter: 'asubcut',
    label: 'level=levelMax',
    bundle: const [AsubcutEffect(level: AsubcutEffect.levelMax)],
  ),
  (
    filter: 'asubcut',
    label: 'order=orderMin',
    bundle: const [AsubcutEffect(order: AsubcutEffect.orderMin)],
  ),
  (
    filter: 'asubcut',
    label: 'order=orderDefault',
    bundle: const [AsubcutEffect(order: AsubcutEffect.orderDefault)],
  ),
  (
    filter: 'asubcut',
    label: 'order=orderMax',
    bundle: const [AsubcutEffect(order: AsubcutEffect.orderMax)],
  ),
  (
    filter: 'asupercut',
    label: 'cutoff=cutoffMin',
    bundle: const [AsupercutEffect(cutoff: AsupercutEffect.cutoffMin)],
  ),
  (
    filter: 'asupercut',
    label: 'cutoff=cutoffDefault',
    bundle: const [AsupercutEffect(cutoff: AsupercutEffect.cutoffDefault)],
  ),
  (
    filter: 'asupercut',
    label: 'cutoff=cutoffMax',
    bundle: const [AsupercutEffect(cutoff: AsupercutEffect.cutoffMax)],
  ),
  (
    filter: 'asupercut',
    label: 'level=levelMin',
    bundle: const [AsupercutEffect(level: AsupercutEffect.levelMin)],
  ),
  (
    filter: 'asupercut',
    label: 'level=levelDefault',
    bundle: const [AsupercutEffect(level: AsupercutEffect.levelDefault)],
  ),
  (
    filter: 'asupercut',
    label: 'level=levelMax',
    bundle: const [AsupercutEffect(level: AsupercutEffect.levelMax)],
  ),
  (
    filter: 'asupercut',
    label: 'order=orderMin',
    bundle: const [AsupercutEffect(order: AsupercutEffect.orderMin)],
  ),
  (
    filter: 'asupercut',
    label: 'order=orderDefault',
    bundle: const [AsupercutEffect(order: AsupercutEffect.orderDefault)],
  ),
  (
    filter: 'asupercut',
    label: 'order=orderMax',
    bundle: const [AsupercutEffect(order: AsupercutEffect.orderMax)],
  ),
  (
    filter: 'asuperpass',
    label: 'centerf=centerfMin',
    bundle: const [AsuperpassEffect(centerf: AsuperpassEffect.centerfMin)],
  ),
  (
    filter: 'asuperpass',
    label: 'centerf=centerfDefault',
    bundle: const [AsuperpassEffect(centerf: AsuperpassEffect.centerfDefault)],
  ),
  (
    filter: 'asuperpass',
    label: 'centerf=centerfMax',
    bundle: const [AsuperpassEffect(centerf: AsuperpassEffect.centerfMax)],
  ),
  (
    filter: 'asuperpass',
    label: 'level=levelMin',
    bundle: const [AsuperpassEffect(level: AsuperpassEffect.levelMin)],
  ),
  (
    filter: 'asuperpass',
    label: 'level=levelDefault',
    bundle: const [AsuperpassEffect(level: AsuperpassEffect.levelDefault)],
  ),
  (
    filter: 'asuperpass',
    label: 'level=levelMax',
    bundle: const [AsuperpassEffect(level: AsuperpassEffect.levelMax)],
  ),
  (
    filter: 'asuperpass',
    label: 'order=orderMin',
    bundle: const [AsuperpassEffect(order: AsuperpassEffect.orderMin)],
  ),
  (
    filter: 'asuperpass',
    label: 'order=orderDefault',
    bundle: const [AsuperpassEffect(order: AsuperpassEffect.orderDefault)],
  ),
  (
    filter: 'asuperpass',
    label: 'order=orderMax',
    bundle: const [AsuperpassEffect(order: AsuperpassEffect.orderMax)],
  ),
  (
    filter: 'asuperpass',
    label: 'qfactor=qfactorMin',
    bundle: const [AsuperpassEffect(qfactor: AsuperpassEffect.qfactorMin)],
  ),
  (
    filter: 'asuperpass',
    label: 'qfactor=qfactorDefault',
    bundle: const [AsuperpassEffect(qfactor: AsuperpassEffect.qfactorDefault)],
  ),
  (
    filter: 'asuperpass',
    label: 'qfactor=qfactorMax',
    bundle: const [AsuperpassEffect(qfactor: AsuperpassEffect.qfactorMax)],
  ),
  (
    filter: 'asuperstop',
    label: 'centerf=centerfMin',
    bundle: const [AsuperstopEffect(centerf: AsuperstopEffect.centerfMin)],
  ),
  (
    filter: 'asuperstop',
    label: 'centerf=centerfDefault',
    bundle: const [AsuperstopEffect(centerf: AsuperstopEffect.centerfDefault)],
  ),
  (
    filter: 'asuperstop',
    label: 'centerf=centerfMax',
    bundle: const [AsuperstopEffect(centerf: AsuperstopEffect.centerfMax)],
  ),
  (
    filter: 'asuperstop',
    label: 'level=levelMin',
    bundle: const [AsuperstopEffect(level: AsuperstopEffect.levelMin)],
  ),
  (
    filter: 'asuperstop',
    label: 'level=levelDefault',
    bundle: const [AsuperstopEffect(level: AsuperstopEffect.levelDefault)],
  ),
  (
    filter: 'asuperstop',
    label: 'level=levelMax',
    bundle: const [AsuperstopEffect(level: AsuperstopEffect.levelMax)],
  ),
  (
    filter: 'asuperstop',
    label: 'order=orderMin',
    bundle: const [AsuperstopEffect(order: AsuperstopEffect.orderMin)],
  ),
  (
    filter: 'asuperstop',
    label: 'order=orderDefault',
    bundle: const [AsuperstopEffect(order: AsuperstopEffect.orderDefault)],
  ),
  (
    filter: 'asuperstop',
    label: 'order=orderMax',
    bundle: const [AsuperstopEffect(order: AsuperstopEffect.orderMax)],
  ),
  (
    filter: 'asuperstop',
    label: 'qfactor=qfactorMin',
    bundle: const [AsuperstopEffect(qfactor: AsuperstopEffect.qfactorMin)],
  ),
  (
    filter: 'asuperstop',
    label: 'qfactor=qfactorDefault',
    bundle: const [AsuperstopEffect(qfactor: AsuperstopEffect.qfactorDefault)],
  ),
  (
    filter: 'asuperstop',
    label: 'qfactor=qfactorMax',
    bundle: const [AsuperstopEffect(qfactor: AsuperstopEffect.qfactorMax)],
  ),
  (
    filter: 'atempo',
    label: 'tempo=tempoMin',
    bundle: const [AtempoEffect(tempo: AtempoEffect.tempoMin)],
  ),
  (
    filter: 'atempo',
    label: 'tempo=tempoDefault',
    bundle: const [AtempoEffect(tempo: AtempoEffect.tempoDefault)],
  ),
  (
    filter: 'atempo',
    label: 'tempo=tempoMax',
    bundle: const [AtempoEffect(tempo: AtempoEffect.tempoMax)],
  ),
  (
    filter: 'atilt',
    label: 'freq=freqMin',
    bundle: const [AtiltEffect(freq: AtiltEffect.freqMin)],
  ),
  (
    filter: 'atilt',
    label: 'freq=freqDefault',
    bundle: const [AtiltEffect(freq: AtiltEffect.freqDefault)],
  ),
  (
    filter: 'atilt',
    label: 'freq=freqMax',
    bundle: const [AtiltEffect(freq: AtiltEffect.freqMax)],
  ),
  (
    filter: 'atilt',
    label: 'level=levelMin',
    bundle: const [AtiltEffect(level: AtiltEffect.levelMin)],
  ),
  (
    filter: 'atilt',
    label: 'level=levelDefault',
    bundle: const [AtiltEffect(level: AtiltEffect.levelDefault)],
  ),
  (
    filter: 'atilt',
    label: 'level=levelMax',
    bundle: const [AtiltEffect(level: AtiltEffect.levelMax)],
  ),
  (
    filter: 'atilt',
    label: 'order=orderMin',
    bundle: const [AtiltEffect(order: AtiltEffect.orderMin)],
  ),
  (
    filter: 'atilt',
    label: 'order=orderDefault',
    bundle: const [AtiltEffect(order: AtiltEffect.orderDefault)],
  ),
  (
    filter: 'atilt',
    label: 'order=orderMax',
    bundle: const [AtiltEffect(order: AtiltEffect.orderMax)],
  ),
  (
    filter: 'atilt',
    label: 'slope=slopeMin',
    bundle: const [AtiltEffect(slope: AtiltEffect.slopeMin)],
  ),
  (
    filter: 'atilt',
    label: 'slope=slopeDefault',
    bundle: const [AtiltEffect(slope: AtiltEffect.slopeDefault)],
  ),
  (
    filter: 'atilt',
    label: 'slope=slopeMax',
    bundle: const [AtiltEffect(slope: AtiltEffect.slopeMax)],
  ),
  (
    filter: 'atilt',
    label: 'width=widthMin',
    bundle: const [AtiltEffect(width: AtiltEffect.widthMin)],
  ),
  (
    filter: 'atilt',
    label: 'width=widthDefault',
    bundle: const [AtiltEffect(width: AtiltEffect.widthDefault)],
  ),
  (
    filter: 'atilt',
    label: 'width=widthMax',
    bundle: const [AtiltEffect(width: AtiltEffect.widthMax)],
  ),
  (
    filter: 'bandpass',
    label: 'blocksize=blocksizeMin',
    bundle: const [BandpassEffect(blocksize: BandpassEffect.blocksizeMin)],
  ),
  (
    filter: 'bandpass',
    label: 'blocksize=blocksizeDefault',
    bundle: const [BandpassEffect(blocksize: BandpassEffect.blocksizeDefault)],
  ),
  (
    filter: 'bandpass',
    label: 'blocksize=blocksizeMax',
    bundle: const [BandpassEffect(blocksize: BandpassEffect.blocksizeMax)],
  ),
  (
    filter: 'bandpass',
    label: 'frequency=frequencyMin',
    bundle: const [BandpassEffect(frequency: BandpassEffect.frequencyMin)],
  ),
  (
    filter: 'bandpass',
    label: 'frequency=frequencyDefault',
    bundle: const [BandpassEffect(frequency: BandpassEffect.frequencyDefault)],
  ),
  (
    filter: 'bandpass',
    label: 'frequency=frequencyMax',
    bundle: const [BandpassEffect(frequency: BandpassEffect.frequencyMax)],
  ),
  (
    filter: 'bandpass',
    label: 'mix=mixMin',
    bundle: const [BandpassEffect(mix: BandpassEffect.mixMin)],
  ),
  (
    filter: 'bandpass',
    label: 'mix=mixDefault',
    bundle: const [BandpassEffect(mix: BandpassEffect.mixDefault)],
  ),
  (
    filter: 'bandpass',
    label: 'mix=mixMax',
    bundle: const [BandpassEffect(mix: BandpassEffect.mixMax)],
  ),
  (
    filter: 'bandpass',
    label: 'width=widthMin',
    bundle: const [BandpassEffect(width: BandpassEffect.widthMin)],
  ),
  (
    filter: 'bandpass',
    label: 'width=widthDefault',
    bundle: const [BandpassEffect(width: BandpassEffect.widthDefault)],
  ),
  (
    filter: 'bandpass',
    label: 'width=widthMax',
    bundle: const [BandpassEffect(width: BandpassEffect.widthMax)],
  ),
  (
    filter: 'bandreject',
    label: 'blocksize=blocksizeMin',
    bundle: const [BandrejectEffect(blocksize: BandrejectEffect.blocksizeMin)],
  ),
  (
    filter: 'bandreject',
    label: 'blocksize=blocksizeDefault',
    bundle: const [
      BandrejectEffect(blocksize: BandrejectEffect.blocksizeDefault),
    ],
  ),
  (
    filter: 'bandreject',
    label: 'blocksize=blocksizeMax',
    bundle: const [BandrejectEffect(blocksize: BandrejectEffect.blocksizeMax)],
  ),
  (
    filter: 'bandreject',
    label: 'frequency=frequencyMin',
    bundle: const [BandrejectEffect(frequency: BandrejectEffect.frequencyMin)],
  ),
  (
    filter: 'bandreject',
    label: 'frequency=frequencyDefault',
    bundle: const [
      BandrejectEffect(frequency: BandrejectEffect.frequencyDefault),
    ],
  ),
  (
    filter: 'bandreject',
    label: 'frequency=frequencyMax',
    bundle: const [BandrejectEffect(frequency: BandrejectEffect.frequencyMax)],
  ),
  (
    filter: 'bandreject',
    label: 'mix=mixMin',
    bundle: const [BandrejectEffect(mix: BandrejectEffect.mixMin)],
  ),
  (
    filter: 'bandreject',
    label: 'mix=mixDefault',
    bundle: const [BandrejectEffect(mix: BandrejectEffect.mixDefault)],
  ),
  (
    filter: 'bandreject',
    label: 'mix=mixMax',
    bundle: const [BandrejectEffect(mix: BandrejectEffect.mixMax)],
  ),
  (
    filter: 'bandreject',
    label: 'width=widthMin',
    bundle: const [BandrejectEffect(width: BandrejectEffect.widthMin)],
  ),
  (
    filter: 'bandreject',
    label: 'width=widthDefault',
    bundle: const [BandrejectEffect(width: BandrejectEffect.widthDefault)],
  ),
  (
    filter: 'bandreject',
    label: 'width=widthMax',
    bundle: const [BandrejectEffect(width: BandrejectEffect.widthMax)],
  ),
  (
    filter: 'bass',
    label: 'blocksize=blocksizeMin',
    bundle: const [BassEffect(blocksize: BassEffect.blocksizeMin)],
  ),
  (
    filter: 'bass',
    label: 'blocksize=blocksizeDefault',
    bundle: const [BassEffect(blocksize: BassEffect.blocksizeDefault)],
  ),
  (
    filter: 'bass',
    label: 'blocksize=blocksizeMax',
    bundle: const [BassEffect(blocksize: BassEffect.blocksizeMax)],
  ),
  (
    filter: 'bass',
    label: 'frequency=frequencyMin',
    bundle: const [BassEffect(frequency: BassEffect.frequencyMin)],
  ),
  (
    filter: 'bass',
    label: 'frequency=frequencyDefault',
    bundle: const [BassEffect(frequency: BassEffect.frequencyDefault)],
  ),
  (
    filter: 'bass',
    label: 'frequency=frequencyMax',
    bundle: const [BassEffect(frequency: BassEffect.frequencyMax)],
  ),
  (
    filter: 'bass',
    label: 'gain=gainMin',
    bundle: const [BassEffect(gain: BassEffect.gainMin)],
  ),
  (
    filter: 'bass',
    label: 'gain=gainDefault',
    bundle: const [BassEffect(gain: BassEffect.gainDefault)],
  ),
  (
    filter: 'bass',
    label: 'gain=gainMax',
    bundle: const [BassEffect(gain: BassEffect.gainMax)],
  ),
  (
    filter: 'bass',
    label: 'mix=mixMin',
    bundle: const [BassEffect(mix: BassEffect.mixMin)],
  ),
  (
    filter: 'bass',
    label: 'mix=mixDefault',
    bundle: const [BassEffect(mix: BassEffect.mixDefault)],
  ),
  (
    filter: 'bass',
    label: 'mix=mixMax',
    bundle: const [BassEffect(mix: BassEffect.mixMax)],
  ),
  (
    filter: 'bass',
    label: 'poles=polesMin',
    bundle: const [BassEffect(poles: BassEffect.polesMin)],
  ),
  (
    filter: 'bass',
    label: 'poles=polesDefault',
    bundle: const [BassEffect(poles: BassEffect.polesDefault)],
  ),
  (
    filter: 'bass',
    label: 'poles=polesMax',
    bundle: const [BassEffect(poles: BassEffect.polesMax)],
  ),
  (
    filter: 'bass',
    label: 'width=widthMin',
    bundle: const [BassEffect(width: BassEffect.widthMin)],
  ),
  (
    filter: 'bass',
    label: 'width=widthDefault',
    bundle: const [BassEffect(width: BassEffect.widthDefault)],
  ),
  (
    filter: 'bass',
    label: 'width=widthMax',
    bundle: const [BassEffect(width: BassEffect.widthMax)],
  ),
  (
    filter: 'biquad',
    label: 'a0=a0Min',
    bundle: const [BiquadEffect(a0: BiquadEffect.a0Min)],
  ),
  (
    filter: 'biquad',
    label: 'a0=a0Default',
    bundle: const [BiquadEffect(a0: BiquadEffect.a0Default)],
  ),
  (
    filter: 'biquad',
    label: 'a0=a0Max',
    bundle: const [BiquadEffect(a0: BiquadEffect.a0Max)],
  ),
  (
    filter: 'biquad',
    label: 'a1=a1Min',
    bundle: const [BiquadEffect(a1: BiquadEffect.a1Min)],
  ),
  (
    filter: 'biquad',
    label: 'a1=a1Default',
    bundle: const [BiquadEffect(a1: BiquadEffect.a1Default)],
  ),
  (
    filter: 'biquad',
    label: 'a1=a1Max',
    bundle: const [BiquadEffect(a1: BiquadEffect.a1Max)],
  ),
  (
    filter: 'biquad',
    label: 'a2=a2Min',
    bundle: const [BiquadEffect(a2: BiquadEffect.a2Min)],
  ),
  (
    filter: 'biquad',
    label: 'a2=a2Default',
    bundle: const [BiquadEffect(a2: BiquadEffect.a2Default)],
  ),
  (
    filter: 'biquad',
    label: 'a2=a2Max',
    bundle: const [BiquadEffect(a2: BiquadEffect.a2Max)],
  ),
  (
    filter: 'biquad',
    label: 'b0=b0Min',
    bundle: const [BiquadEffect(b0: BiquadEffect.b0Min)],
  ),
  (
    filter: 'biquad',
    label: 'b0=b0Default',
    bundle: const [BiquadEffect(b0: BiquadEffect.b0Default)],
  ),
  (
    filter: 'biquad',
    label: 'b0=b0Max',
    bundle: const [BiquadEffect(b0: BiquadEffect.b0Max)],
  ),
  (
    filter: 'biquad',
    label: 'b1=b1Min',
    bundle: const [BiquadEffect(b1: BiquadEffect.b1Min)],
  ),
  (
    filter: 'biquad',
    label: 'b1=b1Default',
    bundle: const [BiquadEffect(b1: BiquadEffect.b1Default)],
  ),
  (
    filter: 'biquad',
    label: 'b1=b1Max',
    bundle: const [BiquadEffect(b1: BiquadEffect.b1Max)],
  ),
  (
    filter: 'biquad',
    label: 'b2=b2Min',
    bundle: const [BiquadEffect(b2: BiquadEffect.b2Min)],
  ),
  (
    filter: 'biquad',
    label: 'b2=b2Default',
    bundle: const [BiquadEffect(b2: BiquadEffect.b2Default)],
  ),
  (
    filter: 'biquad',
    label: 'b2=b2Max',
    bundle: const [BiquadEffect(b2: BiquadEffect.b2Max)],
  ),
  (
    filter: 'biquad',
    label: 'blocksize=blocksizeMin',
    bundle: const [BiquadEffect(blocksize: BiquadEffect.blocksizeMin)],
  ),
  (
    filter: 'biquad',
    label: 'blocksize=blocksizeDefault',
    bundle: const [BiquadEffect(blocksize: BiquadEffect.blocksizeDefault)],
  ),
  (
    filter: 'biquad',
    label: 'blocksize=blocksizeMax',
    bundle: const [BiquadEffect(blocksize: BiquadEffect.blocksizeMax)],
  ),
  (
    filter: 'biquad',
    label: 'mix=mixMin',
    bundle: const [BiquadEffect(mix: BiquadEffect.mixMin)],
  ),
  (
    filter: 'biquad',
    label: 'mix=mixDefault',
    bundle: const [BiquadEffect(mix: BiquadEffect.mixDefault)],
  ),
  (
    filter: 'biquad',
    label: 'mix=mixMax',
    bundle: const [BiquadEffect(mix: BiquadEffect.mixMax)],
  ),
  (
    filter: 'chorus',
    label: 'in_gain=inGainMin',
    bundle: const [
      ChorusEffect(
        inGain: ChorusEffect.inGainMin,
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'in_gain=inGainDefault',
    bundle: const [
      ChorusEffect(
        inGain: ChorusEffect.inGainDefault,
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'in_gain=inGainMax',
    bundle: const [
      ChorusEffect(
        inGain: ChorusEffect.inGainMax,
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'out_gain=outGainMin',
    bundle: const [
      ChorusEffect(
        outGain: ChorusEffect.outGainMin,
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'out_gain=outGainDefault',
    bundle: const [
      ChorusEffect(
        outGain: ChorusEffect.outGainDefault,
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'out_gain=outGainMax',
    bundle: const [
      ChorusEffect(
        outGain: ChorusEffect.outGainMax,
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (
    filter: 'compand',
    label: 'delay=delayMin',
    bundle: const [CompandEffect(delay: CompandEffect.delayMin)],
  ),
  (
    filter: 'compand',
    label: 'delay=delayDefault',
    bundle: const [CompandEffect(delay: CompandEffect.delayDefault)],
  ),
  (
    filter: 'compand',
    label: 'delay=delayMax',
    bundle: const [CompandEffect(delay: CompandEffect.delayMax)],
  ),
  (
    filter: 'compand',
    label: 'gain=gainMin',
    bundle: const [CompandEffect(gain: CompandEffect.gainMin)],
  ),
  (
    filter: 'compand',
    label: 'gain=gainDefault',
    bundle: const [CompandEffect(gain: CompandEffect.gainDefault)],
  ),
  (
    filter: 'compand',
    label: 'gain=gainMax',
    bundle: const [CompandEffect(gain: CompandEffect.gainMax)],
  ),
  (
    filter: 'compand',
    label: 'volume=volumeMin',
    bundle: const [CompandEffect(volume: CompandEffect.volumeMin)],
  ),
  (
    filter: 'compand',
    label: 'volume=volumeDefault',
    bundle: const [CompandEffect(volume: CompandEffect.volumeDefault)],
  ),
  (
    filter: 'compand',
    label: 'volume=volumeMax',
    bundle: const [CompandEffect(volume: CompandEffect.volumeMax)],
  ),
  (
    filter: 'compensationdelay',
    label: 'cm=cmMin',
    bundle: const [CompensationdelayEffect(cm: CompensationdelayEffect.cmMin)],
  ),
  (
    filter: 'compensationdelay',
    label: 'cm=cmDefault',
    bundle: const [
      CompensationdelayEffect(cm: CompensationdelayEffect.cmDefault),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'cm=cmMax',
    bundle: const [CompensationdelayEffect(cm: CompensationdelayEffect.cmMax)],
  ),
  (
    filter: 'compensationdelay',
    label: 'dry=dryMin',
    bundle: const [
      CompensationdelayEffect(dry: CompensationdelayEffect.dryMin),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'dry=dryDefault',
    bundle: const [
      CompensationdelayEffect(dry: CompensationdelayEffect.dryDefault),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'dry=dryMax',
    bundle: const [
      CompensationdelayEffect(dry: CompensationdelayEffect.dryMax),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'm=mMin',
    bundle: const [CompensationdelayEffect(m: CompensationdelayEffect.mMin)],
  ),
  (
    filter: 'compensationdelay',
    label: 'm=mDefault',
    bundle: const [
      CompensationdelayEffect(m: CompensationdelayEffect.mDefault),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'm=mMax',
    bundle: const [CompensationdelayEffect(m: CompensationdelayEffect.mMax)],
  ),
  (
    filter: 'compensationdelay',
    label: 'mm=mmMin',
    bundle: const [CompensationdelayEffect(mm: CompensationdelayEffect.mmMin)],
  ),
  (
    filter: 'compensationdelay',
    label: 'mm=mmDefault',
    bundle: const [
      CompensationdelayEffect(mm: CompensationdelayEffect.mmDefault),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'mm=mmMax',
    bundle: const [CompensationdelayEffect(mm: CompensationdelayEffect.mmMax)],
  ),
  (
    filter: 'compensationdelay',
    label: 'temp=tempMin',
    bundle: const [
      CompensationdelayEffect(temp: CompensationdelayEffect.tempMin),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'temp=tempDefault',
    bundle: const [
      CompensationdelayEffect(temp: CompensationdelayEffect.tempDefault),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'temp=tempMax',
    bundle: const [
      CompensationdelayEffect(temp: CompensationdelayEffect.tempMax),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'wet=wetMin',
    bundle: const [
      CompensationdelayEffect(wet: CompensationdelayEffect.wetMin),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'wet=wetDefault',
    bundle: const [
      CompensationdelayEffect(wet: CompensationdelayEffect.wetDefault),
    ],
  ),
  (
    filter: 'compensationdelay',
    label: 'wet=wetMax',
    bundle: const [
      CompensationdelayEffect(wet: CompensationdelayEffect.wetMax),
    ],
  ),
  (
    filter: 'crossfeed',
    label: 'block_size=blockSizeMin',
    bundle: const [CrossfeedEffect(blockSize: CrossfeedEffect.blockSizeMin)],
  ),
  (
    filter: 'crossfeed',
    label: 'block_size=blockSizeDefault',
    bundle: const [
      CrossfeedEffect(blockSize: CrossfeedEffect.blockSizeDefault),
    ],
  ),
  (
    filter: 'crossfeed',
    label: 'block_size=blockSizeMax',
    bundle: const [CrossfeedEffect(blockSize: CrossfeedEffect.blockSizeMax)],
  ),
  (
    filter: 'crossfeed',
    label: 'level_in=levelInMin',
    bundle: const [CrossfeedEffect(levelIn: CrossfeedEffect.levelInMin)],
  ),
  (
    filter: 'crossfeed',
    label: 'level_in=levelInDefault',
    bundle: const [CrossfeedEffect(levelIn: CrossfeedEffect.levelInDefault)],
  ),
  (
    filter: 'crossfeed',
    label: 'level_in=levelInMax',
    bundle: const [CrossfeedEffect(levelIn: CrossfeedEffect.levelInMax)],
  ),
  (
    filter: 'crossfeed',
    label: 'level_out=levelOutMin',
    bundle: const [CrossfeedEffect(levelOut: CrossfeedEffect.levelOutMin)],
  ),
  (
    filter: 'crossfeed',
    label: 'level_out=levelOutDefault',
    bundle: const [CrossfeedEffect(levelOut: CrossfeedEffect.levelOutDefault)],
  ),
  (
    filter: 'crossfeed',
    label: 'level_out=levelOutMax',
    bundle: const [CrossfeedEffect(levelOut: CrossfeedEffect.levelOutMax)],
  ),
  (
    filter: 'crossfeed',
    label: 'range=rangeMin',
    bundle: const [CrossfeedEffect(range: CrossfeedEffect.rangeMin)],
  ),
  (
    filter: 'crossfeed',
    label: 'range=rangeDefault',
    bundle: const [CrossfeedEffect(range: CrossfeedEffect.rangeDefault)],
  ),
  (
    filter: 'crossfeed',
    label: 'range=rangeMax',
    bundle: const [CrossfeedEffect(range: CrossfeedEffect.rangeMax)],
  ),
  (
    filter: 'crossfeed',
    label: 'slope=slopeMin',
    bundle: const [CrossfeedEffect(slope: CrossfeedEffect.slopeMin)],
  ),
  (
    filter: 'crossfeed',
    label: 'slope=slopeDefault',
    bundle: const [CrossfeedEffect(slope: CrossfeedEffect.slopeDefault)],
  ),
  (
    filter: 'crossfeed',
    label: 'slope=slopeMax',
    bundle: const [CrossfeedEffect(slope: CrossfeedEffect.slopeMax)],
  ),
  (
    filter: 'crossfeed',
    label: 'strength=strengthMin',
    bundle: const [CrossfeedEffect(strength: CrossfeedEffect.strengthMin)],
  ),
  (
    filter: 'crossfeed',
    label: 'strength=strengthDefault',
    bundle: const [CrossfeedEffect(strength: CrossfeedEffect.strengthDefault)],
  ),
  (
    filter: 'crossfeed',
    label: 'strength=strengthMax',
    bundle: const [CrossfeedEffect(strength: CrossfeedEffect.strengthMax)],
  ),
  (
    filter: 'crystalizer',
    label: 'i=iMin',
    bundle: const [CrystalizerEffect(i: CrystalizerEffect.iMin)],
  ),
  (
    filter: 'crystalizer',
    label: 'i=iDefault',
    bundle: const [CrystalizerEffect(i: CrystalizerEffect.iDefault)],
  ),
  (
    filter: 'crystalizer',
    label: 'i=iMax',
    bundle: const [CrystalizerEffect(i: CrystalizerEffect.iMax)],
  ),
  (
    filter: 'dcshift',
    label: 'limitergain=limitergainMin',
    bundle: const [DcshiftEffect(limitergain: DcshiftEffect.limitergainMin)],
  ),
  (
    filter: 'dcshift',
    label: 'limitergain=limitergainDefault',
    bundle: const [
      DcshiftEffect(limitergain: DcshiftEffect.limitergainDefault),
    ],
  ),
  (
    filter: 'dcshift',
    label: 'limitergain=limitergainMax',
    bundle: const [DcshiftEffect(limitergain: DcshiftEffect.limitergainMax)],
  ),
  (
    filter: 'dcshift',
    label: 'shift=shiftMin',
    bundle: const [DcshiftEffect(shift: DcshiftEffect.shiftMin)],
  ),
  (
    filter: 'dcshift',
    label: 'shift=shiftDefault',
    bundle: const [DcshiftEffect(shift: DcshiftEffect.shiftDefault)],
  ),
  (
    filter: 'dcshift',
    label: 'shift=shiftMax',
    bundle: const [DcshiftEffect(shift: DcshiftEffect.shiftMax)],
  ),
  (
    filter: 'deesser',
    label: 'f=fMin',
    bundle: const [DeesserEffect(f: DeesserEffect.fMin)],
  ),
  (
    filter: 'deesser',
    label: 'f=fDefault',
    bundle: const [DeesserEffect(f: DeesserEffect.fDefault)],
  ),
  (
    filter: 'deesser',
    label: 'f=fMax',
    bundle: const [DeesserEffect(f: DeesserEffect.fMax)],
  ),
  (
    filter: 'deesser',
    label: 'i=iMin',
    bundle: const [DeesserEffect(i: DeesserEffect.iMin)],
  ),
  (
    filter: 'deesser',
    label: 'i=iDefault',
    bundle: const [DeesserEffect(i: DeesserEffect.iDefault)],
  ),
  (
    filter: 'deesser',
    label: 'i=iMax',
    bundle: const [DeesserEffect(i: DeesserEffect.iMax)],
  ),
  (
    filter: 'deesser',
    label: 'm=mMin',
    bundle: const [DeesserEffect(m: DeesserEffect.mMin)],
  ),
  (
    filter: 'deesser',
    label: 'm=mDefault',
    bundle: const [DeesserEffect(m: DeesserEffect.mDefault)],
  ),
  (
    filter: 'deesser',
    label: 'm=mMax',
    bundle: const [DeesserEffect(m: DeesserEffect.mMax)],
  ),
  (
    filter: 'dialoguenhance',
    label: 'enhance=enhanceMin',
    bundle: const [
      DialoguenhanceEffect(enhance: DialoguenhanceEffect.enhanceMin),
    ],
  ),
  (
    filter: 'dialoguenhance',
    label: 'enhance=enhanceDefault',
    bundle: const [
      DialoguenhanceEffect(enhance: DialoguenhanceEffect.enhanceDefault),
    ],
  ),
  (
    filter: 'dialoguenhance',
    label: 'enhance=enhanceMax',
    bundle: const [
      DialoguenhanceEffect(enhance: DialoguenhanceEffect.enhanceMax),
    ],
  ),
  (
    filter: 'dialoguenhance',
    label: 'original=originalMin',
    bundle: const [
      DialoguenhanceEffect(original: DialoguenhanceEffect.originalMin),
    ],
  ),
  (
    filter: 'dialoguenhance',
    label: 'original=originalDefault',
    bundle: const [
      DialoguenhanceEffect(original: DialoguenhanceEffect.originalDefault),
    ],
  ),
  (
    filter: 'dialoguenhance',
    label: 'original=originalMax',
    bundle: const [
      DialoguenhanceEffect(original: DialoguenhanceEffect.originalMax),
    ],
  ),
  (
    filter: 'dialoguenhance',
    label: 'voice=voiceMin',
    bundle: const [DialoguenhanceEffect(voice: DialoguenhanceEffect.voiceMin)],
  ),
  (
    filter: 'dialoguenhance',
    label: 'voice=voiceDefault',
    bundle: const [
      DialoguenhanceEffect(voice: DialoguenhanceEffect.voiceDefault),
    ],
  ),
  (
    filter: 'dialoguenhance',
    label: 'voice=voiceMax',
    bundle: const [DialoguenhanceEffect(voice: DialoguenhanceEffect.voiceMax)],
  ),
  (
    filter: 'drmeter',
    label: 'length=lengthMin',
    bundle: const [DrmeterEffect(length: DrmeterEffect.lengthMin)],
  ),
  (
    filter: 'drmeter',
    label: 'length=lengthDefault',
    bundle: const [DrmeterEffect(length: DrmeterEffect.lengthDefault)],
  ),
  (
    filter: 'drmeter',
    label: 'length=lengthMax',
    bundle: const [DrmeterEffect(length: DrmeterEffect.lengthMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'compress=compressMin',
    bundle: const [DynaudnormEffect(compress: DynaudnormEffect.compressMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'compress=compressDefault',
    bundle: const [
      DynaudnormEffect(compress: DynaudnormEffect.compressDefault),
    ],
  ),
  (
    filter: 'dynaudnorm',
    label: 'compress=compressMax',
    bundle: const [DynaudnormEffect(compress: DynaudnormEffect.compressMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'framelen=framelenMin',
    bundle: const [DynaudnormEffect(framelen: DynaudnormEffect.framelenMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'framelen=framelenDefault',
    bundle: const [
      DynaudnormEffect(framelen: DynaudnormEffect.framelenDefault),
    ],
  ),
  (
    filter: 'dynaudnorm',
    label: 'framelen=framelenMax',
    bundle: const [DynaudnormEffect(framelen: DynaudnormEffect.framelenMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'gausssize=gausssizeMin',
    bundle: const [DynaudnormEffect(gausssize: DynaudnormEffect.gausssizeMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'gausssize=gausssizeDefault',
    bundle: const [
      DynaudnormEffect(gausssize: DynaudnormEffect.gausssizeDefault),
    ],
  ),
  (
    filter: 'dynaudnorm',
    label: 'gausssize=gausssizeMax',
    bundle: const [DynaudnormEffect(gausssize: DynaudnormEffect.gausssizeMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'maxgain=maxgainMin',
    bundle: const [DynaudnormEffect(maxgain: DynaudnormEffect.maxgainMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'maxgain=maxgainDefault',
    bundle: const [DynaudnormEffect(maxgain: DynaudnormEffect.maxgainDefault)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'maxgain=maxgainMax',
    bundle: const [DynaudnormEffect(maxgain: DynaudnormEffect.maxgainMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'overlap=overlapMin',
    bundle: const [DynaudnormEffect(overlap: DynaudnormEffect.overlapMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'overlap=overlapDefault',
    bundle: const [DynaudnormEffect(overlap: DynaudnormEffect.overlapDefault)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'overlap=overlapMax',
    bundle: const [DynaudnormEffect(overlap: DynaudnormEffect.overlapMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'peak=peakMin',
    bundle: const [DynaudnormEffect(peak: DynaudnormEffect.peakMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'peak=peakDefault',
    bundle: const [DynaudnormEffect(peak: DynaudnormEffect.peakDefault)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'peak=peakMax',
    bundle: const [DynaudnormEffect(peak: DynaudnormEffect.peakMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'targetrms=targetrmsMin',
    bundle: const [DynaudnormEffect(targetrms: DynaudnormEffect.targetrmsMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'targetrms=targetrmsDefault',
    bundle: const [
      DynaudnormEffect(targetrms: DynaudnormEffect.targetrmsDefault),
    ],
  ),
  (
    filter: 'dynaudnorm',
    label: 'targetrms=targetrmsMax',
    bundle: const [DynaudnormEffect(targetrms: DynaudnormEffect.targetrmsMax)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'threshold=thresholdMin',
    bundle: const [DynaudnormEffect(threshold: DynaudnormEffect.thresholdMin)],
  ),
  (
    filter: 'dynaudnorm',
    label: 'threshold=thresholdDefault',
    bundle: const [
      DynaudnormEffect(threshold: DynaudnormEffect.thresholdDefault),
    ],
  ),
  (
    filter: 'dynaudnorm',
    label: 'threshold=thresholdMax',
    bundle: const [DynaudnormEffect(threshold: DynaudnormEffect.thresholdMax)],
  ),
  (
    filter: 'ebur128',
    label: 'meter=meterMin',
    bundle: const [Ebur128Effect(meter: Ebur128Effect.meterMin)],
  ),
  (
    filter: 'ebur128',
    label: 'meter=meterDefault',
    bundle: const [Ebur128Effect(meter: Ebur128Effect.meterDefault)],
  ),
  (
    filter: 'ebur128',
    label: 'meter=meterMax',
    bundle: const [Ebur128Effect(meter: Ebur128Effect.meterMax)],
  ),
  (
    filter: 'ebur128',
    label: 'panlaw=panlawMin',
    bundle: const [Ebur128Effect(panlaw: Ebur128Effect.panlawMin)],
  ),
  (
    filter: 'ebur128',
    label: 'panlaw=panlawDefault',
    bundle: const [Ebur128Effect(panlaw: Ebur128Effect.panlawDefault)],
  ),
  (
    filter: 'ebur128',
    label: 'panlaw=panlawMax',
    bundle: const [Ebur128Effect(panlaw: Ebur128Effect.panlawMax)],
  ),
  (
    filter: 'ebur128',
    label: 'target=targetMin',
    bundle: const [Ebur128Effect(target: Ebur128Effect.targetMin)],
  ),
  (
    filter: 'ebur128',
    label: 'target=targetDefault',
    bundle: const [Ebur128Effect(target: Ebur128Effect.targetDefault)],
  ),
  (
    filter: 'ebur128',
    label: 'target=targetMax',
    bundle: const [Ebur128Effect(target: Ebur128Effect.targetMax)],
  ),
  (
    filter: 'equalizer',
    label: 'blocksize=blocksizeMin',
    bundle: const [EqualizerEffect(blocksize: EqualizerEffect.blocksizeMin)],
  ),
  (
    filter: 'equalizer',
    label: 'blocksize=blocksizeDefault',
    bundle: const [
      EqualizerEffect(blocksize: EqualizerEffect.blocksizeDefault),
    ],
  ),
  (
    filter: 'equalizer',
    label: 'blocksize=blocksizeMax',
    bundle: const [EqualizerEffect(blocksize: EqualizerEffect.blocksizeMax)],
  ),
  (
    filter: 'equalizer',
    label: 'frequency=frequencyMin',
    bundle: const [EqualizerEffect(frequency: EqualizerEffect.frequencyMin)],
  ),
  (
    filter: 'equalizer',
    label: 'frequency=frequencyDefault',
    bundle: const [
      EqualizerEffect(frequency: EqualizerEffect.frequencyDefault),
    ],
  ),
  (
    filter: 'equalizer',
    label: 'frequency=frequencyMax',
    bundle: const [EqualizerEffect(frequency: EqualizerEffect.frequencyMax)],
  ),
  (
    filter: 'equalizer',
    label: 'gain=gainMin',
    bundle: const [EqualizerEffect(gain: EqualizerEffect.gainMin)],
  ),
  (
    filter: 'equalizer',
    label: 'gain=gainDefault',
    bundle: const [EqualizerEffect(gain: EqualizerEffect.gainDefault)],
  ),
  (
    filter: 'equalizer',
    label: 'gain=gainMax',
    bundle: const [EqualizerEffect(gain: EqualizerEffect.gainMax)],
  ),
  (
    filter: 'equalizer',
    label: 'mix=mixMin',
    bundle: const [EqualizerEffect(mix: EqualizerEffect.mixMin)],
  ),
  (
    filter: 'equalizer',
    label: 'mix=mixDefault',
    bundle: const [EqualizerEffect(mix: EqualizerEffect.mixDefault)],
  ),
  (
    filter: 'equalizer',
    label: 'mix=mixMax',
    bundle: const [EqualizerEffect(mix: EqualizerEffect.mixMax)],
  ),
  (
    filter: 'equalizer',
    label: 'width=widthMin',
    bundle: const [EqualizerEffect(width: EqualizerEffect.widthMin)],
  ),
  (
    filter: 'equalizer',
    label: 'width=widthDefault',
    bundle: const [EqualizerEffect(width: EqualizerEffect.widthDefault)],
  ),
  (
    filter: 'equalizer',
    label: 'width=widthMax',
    bundle: const [EqualizerEffect(width: EqualizerEffect.widthMax)],
  ),
  (
    filter: 'extrastereo',
    label: 'm=mMin',
    bundle: const [ExtrastereoEffect(m: ExtrastereoEffect.mMin)],
  ),
  (
    filter: 'extrastereo',
    label: 'm=mDefault',
    bundle: const [ExtrastereoEffect(m: ExtrastereoEffect.mDefault)],
  ),
  (
    filter: 'extrastereo',
    label: 'm=mMax',
    bundle: const [ExtrastereoEffect(m: ExtrastereoEffect.mMax)],
  ),
  (
    filter: 'firequalizer',
    label: 'accuracy=accuracyMin',
    bundle: const [
      FirequalizerEffect(accuracy: FirequalizerEffect.accuracyMin),
    ],
  ),
  (
    filter: 'firequalizer',
    label: 'accuracy=accuracyDefault',
    bundle: const [
      FirequalizerEffect(accuracy: FirequalizerEffect.accuracyDefault),
    ],
  ),
  (
    filter: 'firequalizer',
    label: 'accuracy=accuracyMax',
    bundle: const [
      FirequalizerEffect(accuracy: FirequalizerEffect.accuracyMax),
    ],
  ),
  (
    filter: 'firequalizer',
    label: 'delay=delayMin',
    bundle: const [FirequalizerEffect(delay: FirequalizerEffect.delayMin)],
  ),
  (
    filter: 'firequalizer',
    label: 'delay=delayDefault',
    bundle: const [FirequalizerEffect(delay: FirequalizerEffect.delayDefault)],
  ),
  (
    filter: 'firequalizer',
    label: 'delay=delayMax',
    bundle: const [FirequalizerEffect(delay: FirequalizerEffect.delayMax)],
  ),
  (
    filter: 'flanger',
    label: 'delay=delayMin',
    bundle: const [FlangerEffect(delay: FlangerEffect.delayMin)],
  ),
  (
    filter: 'flanger',
    label: 'delay=delayDefault',
    bundle: const [FlangerEffect(delay: FlangerEffect.delayDefault)],
  ),
  (
    filter: 'flanger',
    label: 'delay=delayMax',
    bundle: const [FlangerEffect(delay: FlangerEffect.delayMax)],
  ),
  (
    filter: 'flanger',
    label: 'depth=depthMin',
    bundle: const [FlangerEffect(depth: FlangerEffect.depthMin)],
  ),
  (
    filter: 'flanger',
    label: 'depth=depthDefault',
    bundle: const [FlangerEffect(depth: FlangerEffect.depthDefault)],
  ),
  (
    filter: 'flanger',
    label: 'depth=depthMax',
    bundle: const [FlangerEffect(depth: FlangerEffect.depthMax)],
  ),
  (
    filter: 'flanger',
    label: 'phase=phaseMin',
    bundle: const [FlangerEffect(phase: FlangerEffect.phaseMin)],
  ),
  (
    filter: 'flanger',
    label: 'phase=phaseDefault',
    bundle: const [FlangerEffect(phase: FlangerEffect.phaseDefault)],
  ),
  (
    filter: 'flanger',
    label: 'phase=phaseMax',
    bundle: const [FlangerEffect(phase: FlangerEffect.phaseMax)],
  ),
  (
    filter: 'flanger',
    label: 'regen=regenMin',
    bundle: const [FlangerEffect(regen: FlangerEffect.regenMin)],
  ),
  (
    filter: 'flanger',
    label: 'regen=regenDefault',
    bundle: const [FlangerEffect(regen: FlangerEffect.regenDefault)],
  ),
  (
    filter: 'flanger',
    label: 'regen=regenMax',
    bundle: const [FlangerEffect(regen: FlangerEffect.regenMax)],
  ),
  (
    filter: 'flanger',
    label: 'speed=speedMin',
    bundle: const [FlangerEffect(speed: FlangerEffect.speedMin)],
  ),
  (
    filter: 'flanger',
    label: 'speed=speedDefault',
    bundle: const [FlangerEffect(speed: FlangerEffect.speedDefault)],
  ),
  (
    filter: 'flanger',
    label: 'speed=speedMax',
    bundle: const [FlangerEffect(speed: FlangerEffect.speedMax)],
  ),
  (
    filter: 'flanger',
    label: 'width=widthMin',
    bundle: const [FlangerEffect(width: FlangerEffect.widthMin)],
  ),
  (
    filter: 'flanger',
    label: 'width=widthDefault',
    bundle: const [FlangerEffect(width: FlangerEffect.widthDefault)],
  ),
  (
    filter: 'flanger',
    label: 'width=widthMax',
    bundle: const [FlangerEffect(width: FlangerEffect.widthMax)],
  ),
  (
    filter: 'haas',
    label: 'left_balance=leftBalanceMin',
    bundle: const [HaasEffect(leftBalance: HaasEffect.leftBalanceMin)],
  ),
  (
    filter: 'haas',
    label: 'left_balance=leftBalanceDefault',
    bundle: const [HaasEffect(leftBalance: HaasEffect.leftBalanceDefault)],
  ),
  (
    filter: 'haas',
    label: 'left_balance=leftBalanceMax',
    bundle: const [HaasEffect(leftBalance: HaasEffect.leftBalanceMax)],
  ),
  (
    filter: 'haas',
    label: 'left_delay=leftDelayMin',
    bundle: const [HaasEffect(leftDelay: HaasEffect.leftDelayMin)],
  ),
  (
    filter: 'haas',
    label: 'left_delay=leftDelayDefault',
    bundle: const [HaasEffect(leftDelay: HaasEffect.leftDelayDefault)],
  ),
  (
    filter: 'haas',
    label: 'left_delay=leftDelayMax',
    bundle: const [HaasEffect(leftDelay: HaasEffect.leftDelayMax)],
  ),
  (
    filter: 'haas',
    label: 'left_gain=leftGainMin',
    bundle: const [HaasEffect(leftGain: HaasEffect.leftGainMin)],
  ),
  (
    filter: 'haas',
    label: 'left_gain=leftGainDefault',
    bundle: const [HaasEffect(leftGain: HaasEffect.leftGainDefault)],
  ),
  (
    filter: 'haas',
    label: 'left_gain=leftGainMax',
    bundle: const [HaasEffect(leftGain: HaasEffect.leftGainMax)],
  ),
  (
    filter: 'haas',
    label: 'level_in=levelInMin',
    bundle: const [HaasEffect(levelIn: HaasEffect.levelInMin)],
  ),
  (
    filter: 'haas',
    label: 'level_in=levelInDefault',
    bundle: const [HaasEffect(levelIn: HaasEffect.levelInDefault)],
  ),
  (
    filter: 'haas',
    label: 'level_in=levelInMax',
    bundle: const [HaasEffect(levelIn: HaasEffect.levelInMax)],
  ),
  (
    filter: 'haas',
    label: 'level_out=levelOutMin',
    bundle: const [HaasEffect(levelOut: HaasEffect.levelOutMin)],
  ),
  (
    filter: 'haas',
    label: 'level_out=levelOutDefault',
    bundle: const [HaasEffect(levelOut: HaasEffect.levelOutDefault)],
  ),
  (
    filter: 'haas',
    label: 'level_out=levelOutMax',
    bundle: const [HaasEffect(levelOut: HaasEffect.levelOutMax)],
  ),
  (
    filter: 'haas',
    label: 'right_balance=rightBalanceMin',
    bundle: const [HaasEffect(rightBalance: HaasEffect.rightBalanceMin)],
  ),
  (
    filter: 'haas',
    label: 'right_balance=rightBalanceDefault',
    bundle: const [HaasEffect(rightBalance: HaasEffect.rightBalanceDefault)],
  ),
  (
    filter: 'haas',
    label: 'right_balance=rightBalanceMax',
    bundle: const [HaasEffect(rightBalance: HaasEffect.rightBalanceMax)],
  ),
  (
    filter: 'haas',
    label: 'right_delay=rightDelayMin',
    bundle: const [HaasEffect(rightDelay: HaasEffect.rightDelayMin)],
  ),
  (
    filter: 'haas',
    label: 'right_delay=rightDelayDefault',
    bundle: const [HaasEffect(rightDelay: HaasEffect.rightDelayDefault)],
  ),
  (
    filter: 'haas',
    label: 'right_delay=rightDelayMax',
    bundle: const [HaasEffect(rightDelay: HaasEffect.rightDelayMax)],
  ),
  (
    filter: 'haas',
    label: 'right_gain=rightGainMin',
    bundle: const [HaasEffect(rightGain: HaasEffect.rightGainMin)],
  ),
  (
    filter: 'haas',
    label: 'right_gain=rightGainDefault',
    bundle: const [HaasEffect(rightGain: HaasEffect.rightGainDefault)],
  ),
  (
    filter: 'haas',
    label: 'right_gain=rightGainMax',
    bundle: const [HaasEffect(rightGain: HaasEffect.rightGainMax)],
  ),
  (
    filter: 'haas',
    label: 'side_gain=sideGainMin',
    bundle: const [HaasEffect(sideGain: HaasEffect.sideGainMin)],
  ),
  (
    filter: 'haas',
    label: 'side_gain=sideGainDefault',
    bundle: const [HaasEffect(sideGain: HaasEffect.sideGainDefault)],
  ),
  (
    filter: 'haas',
    label: 'side_gain=sideGainMax',
    bundle: const [HaasEffect(sideGain: HaasEffect.sideGainMax)],
  ),
  (
    filter: 'hdcd',
    label: 'cdt_ms=cdtMsMin',
    bundle: const [HdcdEffect(cdtMs: HdcdEffect.cdtMsMin)],
  ),
  (
    filter: 'hdcd',
    label: 'cdt_ms=cdtMsDefault',
    bundle: const [HdcdEffect(cdtMs: HdcdEffect.cdtMsDefault)],
  ),
  (
    filter: 'hdcd',
    label: 'cdt_ms=cdtMsMax',
    bundle: const [HdcdEffect(cdtMs: HdcdEffect.cdtMsMax)],
  ),
  (
    filter: 'highpass',
    label: 'blocksize=blocksizeMin',
    bundle: const [HighpassEffect(blocksize: HighpassEffect.blocksizeMin)],
  ),
  (
    filter: 'highpass',
    label: 'blocksize=blocksizeDefault',
    bundle: const [HighpassEffect(blocksize: HighpassEffect.blocksizeDefault)],
  ),
  (
    filter: 'highpass',
    label: 'blocksize=blocksizeMax',
    bundle: const [HighpassEffect(blocksize: HighpassEffect.blocksizeMax)],
  ),
  (
    filter: 'highpass',
    label: 'frequency=frequencyMin',
    bundle: const [HighpassEffect(frequency: HighpassEffect.frequencyMin)],
  ),
  (
    filter: 'highpass',
    label: 'frequency=frequencyDefault',
    bundle: const [HighpassEffect(frequency: HighpassEffect.frequencyDefault)],
  ),
  (
    filter: 'highpass',
    label: 'frequency=frequencyMax',
    bundle: const [HighpassEffect(frequency: HighpassEffect.frequencyMax)],
  ),
  (
    filter: 'highpass',
    label: 'mix=mixMin',
    bundle: const [HighpassEffect(mix: HighpassEffect.mixMin)],
  ),
  (
    filter: 'highpass',
    label: 'mix=mixDefault',
    bundle: const [HighpassEffect(mix: HighpassEffect.mixDefault)],
  ),
  (
    filter: 'highpass',
    label: 'mix=mixMax',
    bundle: const [HighpassEffect(mix: HighpassEffect.mixMax)],
  ),
  (
    filter: 'highpass',
    label: 'poles=polesMin',
    bundle: const [HighpassEffect(poles: HighpassEffect.polesMin)],
  ),
  (
    filter: 'highpass',
    label: 'poles=polesDefault',
    bundle: const [HighpassEffect(poles: HighpassEffect.polesDefault)],
  ),
  (
    filter: 'highpass',
    label: 'poles=polesMax',
    bundle: const [HighpassEffect(poles: HighpassEffect.polesMax)],
  ),
  (
    filter: 'highpass',
    label: 'width=widthMin',
    bundle: const [HighpassEffect(width: HighpassEffect.widthMin)],
  ),
  (
    filter: 'highpass',
    label: 'width=widthDefault',
    bundle: const [HighpassEffect(width: HighpassEffect.widthDefault)],
  ),
  (
    filter: 'highpass',
    label: 'width=widthMax',
    bundle: const [HighpassEffect(width: HighpassEffect.widthMax)],
  ),
  (
    filter: 'highshelf',
    label: 'blocksize=blocksizeMin',
    bundle: const [HighshelfEffect(blocksize: HighshelfEffect.blocksizeMin)],
  ),
  (
    filter: 'highshelf',
    label: 'blocksize=blocksizeDefault',
    bundle: const [
      HighshelfEffect(blocksize: HighshelfEffect.blocksizeDefault),
    ],
  ),
  (
    filter: 'highshelf',
    label: 'blocksize=blocksizeMax',
    bundle: const [HighshelfEffect(blocksize: HighshelfEffect.blocksizeMax)],
  ),
  (
    filter: 'highshelf',
    label: 'frequency=frequencyMin',
    bundle: const [HighshelfEffect(frequency: HighshelfEffect.frequencyMin)],
  ),
  (
    filter: 'highshelf',
    label: 'frequency=frequencyDefault',
    bundle: const [
      HighshelfEffect(frequency: HighshelfEffect.frequencyDefault),
    ],
  ),
  (
    filter: 'highshelf',
    label: 'frequency=frequencyMax',
    bundle: const [HighshelfEffect(frequency: HighshelfEffect.frequencyMax)],
  ),
  (
    filter: 'highshelf',
    label: 'gain=gainMin',
    bundle: const [HighshelfEffect(gain: HighshelfEffect.gainMin)],
  ),
  (
    filter: 'highshelf',
    label: 'gain=gainDefault',
    bundle: const [HighshelfEffect(gain: HighshelfEffect.gainDefault)],
  ),
  (
    filter: 'highshelf',
    label: 'gain=gainMax',
    bundle: const [HighshelfEffect(gain: HighshelfEffect.gainMax)],
  ),
  (
    filter: 'highshelf',
    label: 'mix=mixMin',
    bundle: const [HighshelfEffect(mix: HighshelfEffect.mixMin)],
  ),
  (
    filter: 'highshelf',
    label: 'mix=mixDefault',
    bundle: const [HighshelfEffect(mix: HighshelfEffect.mixDefault)],
  ),
  (
    filter: 'highshelf',
    label: 'mix=mixMax',
    bundle: const [HighshelfEffect(mix: HighshelfEffect.mixMax)],
  ),
  (
    filter: 'highshelf',
    label: 'poles=polesMin',
    bundle: const [HighshelfEffect(poles: HighshelfEffect.polesMin)],
  ),
  (
    filter: 'highshelf',
    label: 'poles=polesDefault',
    bundle: const [HighshelfEffect(poles: HighshelfEffect.polesDefault)],
  ),
  (
    filter: 'highshelf',
    label: 'poles=polesMax',
    bundle: const [HighshelfEffect(poles: HighshelfEffect.polesMax)],
  ),
  (
    filter: 'highshelf',
    label: 'width=widthMin',
    bundle: const [HighshelfEffect(width: HighshelfEffect.widthMin)],
  ),
  (
    filter: 'highshelf',
    label: 'width=widthDefault',
    bundle: const [HighshelfEffect(width: HighshelfEffect.widthDefault)],
  ),
  (
    filter: 'highshelf',
    label: 'width=widthMax',
    bundle: const [HighshelfEffect(width: HighshelfEffect.widthMax)],
  ),
  (
    filter: 'loudnorm',
    label: 'i=iMin',
    bundle: const [LoudnormEffect(i: LoudnormEffect.iMin)],
  ),
  (
    filter: 'loudnorm',
    label: 'i=iDefault',
    bundle: const [LoudnormEffect(i: LoudnormEffect.iDefault)],
  ),
  (
    filter: 'loudnorm',
    label: 'i=iMax',
    bundle: const [LoudnormEffect(i: LoudnormEffect.iMax)],
  ),
  (
    filter: 'loudnorm',
    label: 'lra=lraMin',
    bundle: const [LoudnormEffect(lra: LoudnormEffect.lraMin)],
  ),
  (
    filter: 'loudnorm',
    label: 'lra=lraDefault',
    bundle: const [LoudnormEffect(lra: LoudnormEffect.lraDefault)],
  ),
  (
    filter: 'loudnorm',
    label: 'lra=lraMax',
    bundle: const [LoudnormEffect(lra: LoudnormEffect.lraMax)],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_i=measuredIMin',
    bundle: const [LoudnormEffect(measuredI: LoudnormEffect.measuredIMin)],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_i=measuredIDefault',
    bundle: const [LoudnormEffect(measuredI: LoudnormEffect.measuredIDefault)],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_i=measuredIMax',
    bundle: const [LoudnormEffect(measuredI: LoudnormEffect.measuredIMax)],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_lra=measuredLraMin',
    bundle: const [LoudnormEffect(measuredLra: LoudnormEffect.measuredLraMin)],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_lra=measuredLraDefault',
    bundle: const [
      LoudnormEffect(measuredLra: LoudnormEffect.measuredLraDefault),
    ],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_lra=measuredLraMax',
    bundle: const [LoudnormEffect(measuredLra: LoudnormEffect.measuredLraMax)],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_thresh=measuredThreshMin',
    bundle: const [
      LoudnormEffect(measuredThresh: LoudnormEffect.measuredThreshMin),
    ],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_thresh=measuredThreshDefault',
    bundle: const [
      LoudnormEffect(measuredThresh: LoudnormEffect.measuredThreshDefault),
    ],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_thresh=measuredThreshMax',
    bundle: const [
      LoudnormEffect(measuredThresh: LoudnormEffect.measuredThreshMax),
    ],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_tp=measuredTpMin',
    bundle: const [LoudnormEffect(measuredTp: LoudnormEffect.measuredTpMin)],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_tp=measuredTpDefault',
    bundle: const [
      LoudnormEffect(measuredTp: LoudnormEffect.measuredTpDefault),
    ],
  ),
  (
    filter: 'loudnorm',
    label: 'measured_tp=measuredTpMax',
    bundle: const [LoudnormEffect(measuredTp: LoudnormEffect.measuredTpMax)],
  ),
  (
    filter: 'loudnorm',
    label: 'offset=offsetMin',
    bundle: const [LoudnormEffect(offset: LoudnormEffect.offsetMin)],
  ),
  (
    filter: 'loudnorm',
    label: 'offset=offsetDefault',
    bundle: const [LoudnormEffect(offset: LoudnormEffect.offsetDefault)],
  ),
  (
    filter: 'loudnorm',
    label: 'offset=offsetMax',
    bundle: const [LoudnormEffect(offset: LoudnormEffect.offsetMax)],
  ),
  (
    filter: 'loudnorm',
    label: 'tp=tpMin',
    bundle: const [LoudnormEffect(tp: LoudnormEffect.tpMin)],
  ),
  (
    filter: 'loudnorm',
    label: 'tp=tpDefault',
    bundle: const [LoudnormEffect(tp: LoudnormEffect.tpDefault)],
  ),
  (
    filter: 'loudnorm',
    label: 'tp=tpMax',
    bundle: const [LoudnormEffect(tp: LoudnormEffect.tpMax)],
  ),
  (
    filter: 'lowpass',
    label: 'blocksize=blocksizeMin',
    bundle: const [LowpassEffect(blocksize: LowpassEffect.blocksizeMin)],
  ),
  (
    filter: 'lowpass',
    label: 'blocksize=blocksizeDefault',
    bundle: const [LowpassEffect(blocksize: LowpassEffect.blocksizeDefault)],
  ),
  (
    filter: 'lowpass',
    label: 'blocksize=blocksizeMax',
    bundle: const [LowpassEffect(blocksize: LowpassEffect.blocksizeMax)],
  ),
  (
    filter: 'lowpass',
    label: 'frequency=frequencyMin',
    bundle: const [LowpassEffect(frequency: LowpassEffect.frequencyMin)],
  ),
  (
    filter: 'lowpass',
    label: 'frequency=frequencyDefault',
    bundle: const [LowpassEffect(frequency: LowpassEffect.frequencyDefault)],
  ),
  (
    filter: 'lowpass',
    label: 'frequency=frequencyMax',
    bundle: const [LowpassEffect(frequency: LowpassEffect.frequencyMax)],
  ),
  (
    filter: 'lowpass',
    label: 'mix=mixMin',
    bundle: const [LowpassEffect(mix: LowpassEffect.mixMin)],
  ),
  (
    filter: 'lowpass',
    label: 'mix=mixDefault',
    bundle: const [LowpassEffect(mix: LowpassEffect.mixDefault)],
  ),
  (
    filter: 'lowpass',
    label: 'mix=mixMax',
    bundle: const [LowpassEffect(mix: LowpassEffect.mixMax)],
  ),
  (
    filter: 'lowpass',
    label: 'poles=polesMin',
    bundle: const [LowpassEffect(poles: LowpassEffect.polesMin)],
  ),
  (
    filter: 'lowpass',
    label: 'poles=polesDefault',
    bundle: const [LowpassEffect(poles: LowpassEffect.polesDefault)],
  ),
  (
    filter: 'lowpass',
    label: 'poles=polesMax',
    bundle: const [LowpassEffect(poles: LowpassEffect.polesMax)],
  ),
  (
    filter: 'lowpass',
    label: 'width=widthMin',
    bundle: const [LowpassEffect(width: LowpassEffect.widthMin)],
  ),
  (
    filter: 'lowpass',
    label: 'width=widthDefault',
    bundle: const [LowpassEffect(width: LowpassEffect.widthDefault)],
  ),
  (
    filter: 'lowpass',
    label: 'width=widthMax',
    bundle: const [LowpassEffect(width: LowpassEffect.widthMax)],
  ),
  (
    filter: 'lowshelf',
    label: 'blocksize=blocksizeMin',
    bundle: const [LowshelfEffect(blocksize: LowshelfEffect.blocksizeMin)],
  ),
  (
    filter: 'lowshelf',
    label: 'blocksize=blocksizeDefault',
    bundle: const [LowshelfEffect(blocksize: LowshelfEffect.blocksizeDefault)],
  ),
  (
    filter: 'lowshelf',
    label: 'blocksize=blocksizeMax',
    bundle: const [LowshelfEffect(blocksize: LowshelfEffect.blocksizeMax)],
  ),
  (
    filter: 'lowshelf',
    label: 'frequency=frequencyMin',
    bundle: const [LowshelfEffect(frequency: LowshelfEffect.frequencyMin)],
  ),
  (
    filter: 'lowshelf',
    label: 'frequency=frequencyDefault',
    bundle: const [LowshelfEffect(frequency: LowshelfEffect.frequencyDefault)],
  ),
  (
    filter: 'lowshelf',
    label: 'frequency=frequencyMax',
    bundle: const [LowshelfEffect(frequency: LowshelfEffect.frequencyMax)],
  ),
  (
    filter: 'lowshelf',
    label: 'gain=gainMin',
    bundle: const [LowshelfEffect(gain: LowshelfEffect.gainMin)],
  ),
  (
    filter: 'lowshelf',
    label: 'gain=gainDefault',
    bundle: const [LowshelfEffect(gain: LowshelfEffect.gainDefault)],
  ),
  (
    filter: 'lowshelf',
    label: 'gain=gainMax',
    bundle: const [LowshelfEffect(gain: LowshelfEffect.gainMax)],
  ),
  (
    filter: 'lowshelf',
    label: 'mix=mixMin',
    bundle: const [LowshelfEffect(mix: LowshelfEffect.mixMin)],
  ),
  (
    filter: 'lowshelf',
    label: 'mix=mixDefault',
    bundle: const [LowshelfEffect(mix: LowshelfEffect.mixDefault)],
  ),
  (
    filter: 'lowshelf',
    label: 'mix=mixMax',
    bundle: const [LowshelfEffect(mix: LowshelfEffect.mixMax)],
  ),
  (
    filter: 'lowshelf',
    label: 'poles=polesMin',
    bundle: const [LowshelfEffect(poles: LowshelfEffect.polesMin)],
  ),
  (
    filter: 'lowshelf',
    label: 'poles=polesDefault',
    bundle: const [LowshelfEffect(poles: LowshelfEffect.polesDefault)],
  ),
  (
    filter: 'lowshelf',
    label: 'poles=polesMax',
    bundle: const [LowshelfEffect(poles: LowshelfEffect.polesMax)],
  ),
  (
    filter: 'lowshelf',
    label: 'width=widthMin',
    bundle: const [LowshelfEffect(width: LowshelfEffect.widthMin)],
  ),
  (
    filter: 'lowshelf',
    label: 'width=widthDefault',
    bundle: const [LowshelfEffect(width: LowshelfEffect.widthDefault)],
  ),
  (
    filter: 'lowshelf',
    label: 'width=widthMax',
    bundle: const [LowshelfEffect(width: LowshelfEffect.widthMax)],
  ),
  (
    filter: 'rubberband',
    label: 'pitch=pitchMin',
    bundle: const [RubberbandEffect(pitch: RubberbandEffect.pitchMin)],
  ),
  (
    filter: 'rubberband',
    label: 'pitch=pitchDefault',
    bundle: const [RubberbandEffect(pitch: RubberbandEffect.pitchDefault)],
  ),
  (
    filter: 'rubberband',
    label: 'pitch=pitchMax',
    bundle: const [RubberbandEffect(pitch: RubberbandEffect.pitchMax)],
  ),
  (
    filter: 'rubberband',
    label: 'tempo=tempoMin',
    bundle: const [RubberbandEffect(tempo: RubberbandEffect.tempoMin)],
  ),
  (
    filter: 'rubberband',
    label: 'tempo=tempoDefault',
    bundle: const [RubberbandEffect(tempo: RubberbandEffect.tempoDefault)],
  ),
  (
    filter: 'rubberband',
    label: 'tempo=tempoMax',
    bundle: const [RubberbandEffect(tempo: RubberbandEffect.tempoMax)],
  ),
  (
    filter: 'silenceremove',
    label: 'start_duration=500us',
    bundle: const [
      SilenceremoveEffect(startDuration: Duration(microseconds: 500)),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'start_periods=startPeriodsMin',
    bundle: const [
      SilenceremoveEffect(startPeriods: SilenceremoveEffect.startPeriodsMin),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'start_periods=startPeriodsDefault',
    bundle: const [
      SilenceremoveEffect(
        startPeriods: SilenceremoveEffect.startPeriodsDefault,
      ),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'start_periods=startPeriodsMax',
    bundle: const [
      SilenceremoveEffect(startPeriods: SilenceremoveEffect.startPeriodsMax),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'start_silence=500us',
    bundle: const [
      SilenceremoveEffect(startSilence: Duration(microseconds: 500)),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'start_threshold=startThresholdMin',
    bundle: const [
      SilenceremoveEffect(
        startThreshold: SilenceremoveEffect.startThresholdMin,
      ),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'start_threshold=startThresholdDefault',
    bundle: const [
      SilenceremoveEffect(
        startThreshold: SilenceremoveEffect.startThresholdDefault,
      ),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'start_threshold=startThresholdMax',
    bundle: const [
      SilenceremoveEffect(
        startThreshold: SilenceremoveEffect.startThresholdMax,
      ),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_duration=500us',
    bundle: const [
      SilenceremoveEffect(stopDuration: Duration(microseconds: 500)),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_periods=stopPeriodsMin',
    bundle: const [
      SilenceremoveEffect(stopPeriods: SilenceremoveEffect.stopPeriodsMin),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_periods=stopPeriodsDefault',
    bundle: const [
      SilenceremoveEffect(stopPeriods: SilenceremoveEffect.stopPeriodsDefault),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_periods=stopPeriodsMax',
    bundle: const [
      SilenceremoveEffect(stopPeriods: SilenceremoveEffect.stopPeriodsMax),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_silence=500us',
    bundle: const [
      SilenceremoveEffect(stopSilence: Duration(microseconds: 500)),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_threshold=stopThresholdMin',
    bundle: const [
      SilenceremoveEffect(stopThreshold: SilenceremoveEffect.stopThresholdMin),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_threshold=stopThresholdDefault',
    bundle: const [
      SilenceremoveEffect(
        stopThreshold: SilenceremoveEffect.stopThresholdDefault,
      ),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'stop_threshold=stopThresholdMax',
    bundle: const [
      SilenceremoveEffect(stopThreshold: SilenceremoveEffect.stopThresholdMax),
    ],
  ),
  (
    filter: 'silenceremove',
    label: 'window=500us',
    bundle: const [SilenceremoveEffect(window: Duration(microseconds: 500))],
  ),
  (
    filter: 'speechnorm',
    label: 'compression=compressionMin',
    bundle: const [
      SpeechnormEffect(compression: SpeechnormEffect.compressionMin),
    ],
  ),
  (
    filter: 'speechnorm',
    label: 'compression=compressionDefault',
    bundle: const [
      SpeechnormEffect(compression: SpeechnormEffect.compressionDefault),
    ],
  ),
  (
    filter: 'speechnorm',
    label: 'compression=compressionMax',
    bundle: const [
      SpeechnormEffect(compression: SpeechnormEffect.compressionMax),
    ],
  ),
  (
    filter: 'speechnorm',
    label: 'expansion=expansionMin',
    bundle: const [SpeechnormEffect(expansion: SpeechnormEffect.expansionMin)],
  ),
  (
    filter: 'speechnorm',
    label: 'expansion=expansionDefault',
    bundle: const [
      SpeechnormEffect(expansion: SpeechnormEffect.expansionDefault),
    ],
  ),
  (
    filter: 'speechnorm',
    label: 'expansion=expansionMax',
    bundle: const [SpeechnormEffect(expansion: SpeechnormEffect.expansionMax)],
  ),
  (
    filter: 'speechnorm',
    label: 'fall=fallMin',
    bundle: const [SpeechnormEffect(fall: SpeechnormEffect.fallMin)],
  ),
  (
    filter: 'speechnorm',
    label: 'fall=fallDefault',
    bundle: const [SpeechnormEffect(fall: SpeechnormEffect.fallDefault)],
  ),
  (
    filter: 'speechnorm',
    label: 'fall=fallMax',
    bundle: const [SpeechnormEffect(fall: SpeechnormEffect.fallMax)],
  ),
  (
    filter: 'speechnorm',
    label: 'peak=peakMin',
    bundle: const [SpeechnormEffect(peak: SpeechnormEffect.peakMin)],
  ),
  (
    filter: 'speechnorm',
    label: 'peak=peakDefault',
    bundle: const [SpeechnormEffect(peak: SpeechnormEffect.peakDefault)],
  ),
  (
    filter: 'speechnorm',
    label: 'peak=peakMax',
    bundle: const [SpeechnormEffect(peak: SpeechnormEffect.peakMax)],
  ),
  (
    filter: 'speechnorm',
    label: 'raise=raiseMin',
    bundle: const [SpeechnormEffect(raise: SpeechnormEffect.raiseMin)],
  ),
  (
    filter: 'speechnorm',
    label: 'raise=raiseDefault',
    bundle: const [SpeechnormEffect(raise: SpeechnormEffect.raiseDefault)],
  ),
  (
    filter: 'speechnorm',
    label: 'raise=raiseMax',
    bundle: const [SpeechnormEffect(raise: SpeechnormEffect.raiseMax)],
  ),
  (
    filter: 'speechnorm',
    label: 'rms=rmsMin',
    bundle: const [SpeechnormEffect(rms: SpeechnormEffect.rmsMin)],
  ),
  (
    filter: 'speechnorm',
    label: 'rms=rmsDefault',
    bundle: const [SpeechnormEffect(rms: SpeechnormEffect.rmsDefault)],
  ),
  (
    filter: 'speechnorm',
    label: 'rms=rmsMax',
    bundle: const [SpeechnormEffect(rms: SpeechnormEffect.rmsMax)],
  ),
  (
    filter: 'speechnorm',
    label: 'threshold=thresholdMin',
    bundle: const [SpeechnormEffect(threshold: SpeechnormEffect.thresholdMin)],
  ),
  (
    filter: 'speechnorm',
    label: 'threshold=thresholdDefault',
    bundle: const [
      SpeechnormEffect(threshold: SpeechnormEffect.thresholdDefault),
    ],
  ),
  (
    filter: 'speechnorm',
    label: 'threshold=thresholdMax',
    bundle: const [SpeechnormEffect(threshold: SpeechnormEffect.thresholdMax)],
  ),
  (
    filter: 'stereotools',
    label: 'balance_in=balanceInMin',
    bundle: const [
      StereotoolsEffect(balanceIn: StereotoolsEffect.balanceInMin),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'balance_in=balanceInDefault',
    bundle: const [
      StereotoolsEffect(balanceIn: StereotoolsEffect.balanceInDefault),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'balance_in=balanceInMax',
    bundle: const [
      StereotoolsEffect(balanceIn: StereotoolsEffect.balanceInMax),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'balance_out=balanceOutMin',
    bundle: const [
      StereotoolsEffect(balanceOut: StereotoolsEffect.balanceOutMin),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'balance_out=balanceOutDefault',
    bundle: const [
      StereotoolsEffect(balanceOut: StereotoolsEffect.balanceOutDefault),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'balance_out=balanceOutMax',
    bundle: const [
      StereotoolsEffect(balanceOut: StereotoolsEffect.balanceOutMax),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'base=baseMin',
    bundle: const [StereotoolsEffect(base: StereotoolsEffect.baseMin)],
  ),
  (
    filter: 'stereotools',
    label: 'base=baseDefault',
    bundle: const [StereotoolsEffect(base: StereotoolsEffect.baseDefault)],
  ),
  (
    filter: 'stereotools',
    label: 'base=baseMax',
    bundle: const [StereotoolsEffect(base: StereotoolsEffect.baseMax)],
  ),
  (
    filter: 'stereotools',
    label: 'delay=delayMin',
    bundle: const [StereotoolsEffect(delay: StereotoolsEffect.delayMin)],
  ),
  (
    filter: 'stereotools',
    label: 'delay=delayDefault',
    bundle: const [StereotoolsEffect(delay: StereotoolsEffect.delayDefault)],
  ),
  (
    filter: 'stereotools',
    label: 'delay=delayMax',
    bundle: const [StereotoolsEffect(delay: StereotoolsEffect.delayMax)],
  ),
  (
    filter: 'stereotools',
    label: 'level_in=levelInMin',
    bundle: const [StereotoolsEffect(levelIn: StereotoolsEffect.levelInMin)],
  ),
  (
    filter: 'stereotools',
    label: 'level_in=levelInDefault',
    bundle: const [
      StereotoolsEffect(levelIn: StereotoolsEffect.levelInDefault),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'level_in=levelInMax',
    bundle: const [StereotoolsEffect(levelIn: StereotoolsEffect.levelInMax)],
  ),
  (
    filter: 'stereotools',
    label: 'level_out=levelOutMin',
    bundle: const [StereotoolsEffect(levelOut: StereotoolsEffect.levelOutMin)],
  ),
  (
    filter: 'stereotools',
    label: 'level_out=levelOutDefault',
    bundle: const [
      StereotoolsEffect(levelOut: StereotoolsEffect.levelOutDefault),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'level_out=levelOutMax',
    bundle: const [StereotoolsEffect(levelOut: StereotoolsEffect.levelOutMax)],
  ),
  (
    filter: 'stereotools',
    label: 'mlev=mlevMin',
    bundle: const [StereotoolsEffect(mlev: StereotoolsEffect.mlevMin)],
  ),
  (
    filter: 'stereotools',
    label: 'mlev=mlevDefault',
    bundle: const [StereotoolsEffect(mlev: StereotoolsEffect.mlevDefault)],
  ),
  (
    filter: 'stereotools',
    label: 'mlev=mlevMax',
    bundle: const [StereotoolsEffect(mlev: StereotoolsEffect.mlevMax)],
  ),
  (
    filter: 'stereotools',
    label: 'mpan=mpanMin',
    bundle: const [StereotoolsEffect(mpan: StereotoolsEffect.mpanMin)],
  ),
  (
    filter: 'stereotools',
    label: 'mpan=mpanDefault',
    bundle: const [StereotoolsEffect(mpan: StereotoolsEffect.mpanDefault)],
  ),
  (
    filter: 'stereotools',
    label: 'mpan=mpanMax',
    bundle: const [StereotoolsEffect(mpan: StereotoolsEffect.mpanMax)],
  ),
  (
    filter: 'stereotools',
    label: 'phase=phaseMin',
    bundle: const [StereotoolsEffect(phase: StereotoolsEffect.phaseMin)],
  ),
  (
    filter: 'stereotools',
    label: 'phase=phaseDefault',
    bundle: const [StereotoolsEffect(phase: StereotoolsEffect.phaseDefault)],
  ),
  (
    filter: 'stereotools',
    label: 'phase=phaseMax',
    bundle: const [StereotoolsEffect(phase: StereotoolsEffect.phaseMax)],
  ),
  (
    filter: 'stereotools',
    label: 'sbal=sbalMin',
    bundle: const [StereotoolsEffect(sbal: StereotoolsEffect.sbalMin)],
  ),
  (
    filter: 'stereotools',
    label: 'sbal=sbalDefault',
    bundle: const [StereotoolsEffect(sbal: StereotoolsEffect.sbalDefault)],
  ),
  (
    filter: 'stereotools',
    label: 'sbal=sbalMax',
    bundle: const [StereotoolsEffect(sbal: StereotoolsEffect.sbalMax)],
  ),
  (
    filter: 'stereotools',
    label: 'sclevel=sclevelMin',
    bundle: const [StereotoolsEffect(sclevel: StereotoolsEffect.sclevelMin)],
  ),
  (
    filter: 'stereotools',
    label: 'sclevel=sclevelDefault',
    bundle: const [
      StereotoolsEffect(sclevel: StereotoolsEffect.sclevelDefault),
    ],
  ),
  (
    filter: 'stereotools',
    label: 'sclevel=sclevelMax',
    bundle: const [StereotoolsEffect(sclevel: StereotoolsEffect.sclevelMax)],
  ),
  (
    filter: 'stereotools',
    label: 'slev=slevMin',
    bundle: const [StereotoolsEffect(slev: StereotoolsEffect.slevMin)],
  ),
  (
    filter: 'stereotools',
    label: 'slev=slevDefault',
    bundle: const [StereotoolsEffect(slev: StereotoolsEffect.slevDefault)],
  ),
  (
    filter: 'stereotools',
    label: 'slev=slevMax',
    bundle: const [StereotoolsEffect(slev: StereotoolsEffect.slevMax)],
  ),
  (
    filter: 'stereowiden',
    label: 'crossfeed=crossfeedMin',
    bundle: const [
      StereowidenEffect(crossfeed: StereowidenEffect.crossfeedMin),
    ],
  ),
  (
    filter: 'stereowiden',
    label: 'crossfeed=crossfeedDefault',
    bundle: const [
      StereowidenEffect(crossfeed: StereowidenEffect.crossfeedDefault),
    ],
  ),
  (
    filter: 'stereowiden',
    label: 'crossfeed=crossfeedMax',
    bundle: const [
      StereowidenEffect(crossfeed: StereowidenEffect.crossfeedMax),
    ],
  ),
  (
    filter: 'stereowiden',
    label: 'delay=delayMin',
    bundle: const [StereowidenEffect(delay: StereowidenEffect.delayMin)],
  ),
  (
    filter: 'stereowiden',
    label: 'delay=delayDefault',
    bundle: const [StereowidenEffect(delay: StereowidenEffect.delayDefault)],
  ),
  (
    filter: 'stereowiden',
    label: 'delay=delayMax',
    bundle: const [StereowidenEffect(delay: StereowidenEffect.delayMax)],
  ),
  (
    filter: 'stereowiden',
    label: 'drymix=drymixMin',
    bundle: const [StereowidenEffect(drymix: StereowidenEffect.drymixMin)],
  ),
  (
    filter: 'stereowiden',
    label: 'drymix=drymixDefault',
    bundle: const [StereowidenEffect(drymix: StereowidenEffect.drymixDefault)],
  ),
  (
    filter: 'stereowiden',
    label: 'drymix=drymixMax',
    bundle: const [StereowidenEffect(drymix: StereowidenEffect.drymixMax)],
  ),
  (
    filter: 'stereowiden',
    label: 'feedback=feedbackMin',
    bundle: const [StereowidenEffect(feedback: StereowidenEffect.feedbackMin)],
  ),
  (
    filter: 'stereowiden',
    label: 'feedback=feedbackDefault',
    bundle: const [
      StereowidenEffect(feedback: StereowidenEffect.feedbackDefault),
    ],
  ),
  (
    filter: 'stereowiden',
    label: 'feedback=feedbackMax',
    bundle: const [StereowidenEffect(feedback: StereowidenEffect.feedbackMax)],
  ),
  (
    filter: 'surround',
    label: 'allx=allxMin',
    bundle: const [SurroundEffect(allx: SurroundEffect.allxMin)],
  ),
  (
    filter: 'surround',
    label: 'allx=allxDefault',
    bundle: const [SurroundEffect(allx: SurroundEffect.allxDefault)],
  ),
  (
    filter: 'surround',
    label: 'allx=allxMax',
    bundle: const [SurroundEffect(allx: SurroundEffect.allxMax)],
  ),
  (
    filter: 'surround',
    label: 'ally=allyMin',
    bundle: const [SurroundEffect(ally: SurroundEffect.allyMin)],
  ),
  (
    filter: 'surround',
    label: 'ally=allyDefault',
    bundle: const [SurroundEffect(ally: SurroundEffect.allyDefault)],
  ),
  (
    filter: 'surround',
    label: 'ally=allyMax',
    bundle: const [SurroundEffect(ally: SurroundEffect.allyMax)],
  ),
  (
    filter: 'surround',
    label: 'angle=angleMin',
    bundle: const [SurroundEffect(angle: SurroundEffect.angleMin)],
  ),
  (
    filter: 'surround',
    label: 'angle=angleDefault',
    bundle: const [SurroundEffect(angle: SurroundEffect.angleDefault)],
  ),
  (
    filter: 'surround',
    label: 'angle=angleMax',
    bundle: const [SurroundEffect(angle: SurroundEffect.angleMax)],
  ),
  (
    filter: 'surround',
    label: 'bc_in=bcInMin',
    bundle: const [SurroundEffect(bcIn: SurroundEffect.bcInMin)],
  ),
  (
    filter: 'surround',
    label: 'bc_in=bcInDefault',
    bundle: const [SurroundEffect(bcIn: SurroundEffect.bcInDefault)],
  ),
  (
    filter: 'surround',
    label: 'bc_in=bcInMax',
    bundle: const [SurroundEffect(bcIn: SurroundEffect.bcInMax)],
  ),
  (
    filter: 'surround',
    label: 'bc_out=bcOutMin',
    bundle: const [SurroundEffect(bcOut: SurroundEffect.bcOutMin)],
  ),
  (
    filter: 'surround',
    label: 'bc_out=bcOutDefault',
    bundle: const [SurroundEffect(bcOut: SurroundEffect.bcOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'bc_out=bcOutMax',
    bundle: const [SurroundEffect(bcOut: SurroundEffect.bcOutMax)],
  ),
  (
    filter: 'surround',
    label: 'bcx=bcxMin',
    bundle: const [SurroundEffect(bcx: SurroundEffect.bcxMin)],
  ),
  (
    filter: 'surround',
    label: 'bcx=bcxDefault',
    bundle: const [SurroundEffect(bcx: SurroundEffect.bcxDefault)],
  ),
  (
    filter: 'surround',
    label: 'bcx=bcxMax',
    bundle: const [SurroundEffect(bcx: SurroundEffect.bcxMax)],
  ),
  (
    filter: 'surround',
    label: 'bcy=bcyMin',
    bundle: const [SurroundEffect(bcy: SurroundEffect.bcyMin)],
  ),
  (
    filter: 'surround',
    label: 'bcy=bcyDefault',
    bundle: const [SurroundEffect(bcy: SurroundEffect.bcyDefault)],
  ),
  (
    filter: 'surround',
    label: 'bcy=bcyMax',
    bundle: const [SurroundEffect(bcy: SurroundEffect.bcyMax)],
  ),
  (
    filter: 'surround',
    label: 'bl_in=blInMin',
    bundle: const [SurroundEffect(blIn: SurroundEffect.blInMin)],
  ),
  (
    filter: 'surround',
    label: 'bl_in=blInDefault',
    bundle: const [SurroundEffect(blIn: SurroundEffect.blInDefault)],
  ),
  (
    filter: 'surround',
    label: 'bl_in=blInMax',
    bundle: const [SurroundEffect(blIn: SurroundEffect.blInMax)],
  ),
  (
    filter: 'surround',
    label: 'bl_out=blOutMin',
    bundle: const [SurroundEffect(blOut: SurroundEffect.blOutMin)],
  ),
  (
    filter: 'surround',
    label: 'bl_out=blOutDefault',
    bundle: const [SurroundEffect(blOut: SurroundEffect.blOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'bl_out=blOutMax',
    bundle: const [SurroundEffect(blOut: SurroundEffect.blOutMax)],
  ),
  (
    filter: 'surround',
    label: 'blx=blxMin',
    bundle: const [SurroundEffect(blx: SurroundEffect.blxMin)],
  ),
  (
    filter: 'surround',
    label: 'blx=blxDefault',
    bundle: const [SurroundEffect(blx: SurroundEffect.blxDefault)],
  ),
  (
    filter: 'surround',
    label: 'blx=blxMax',
    bundle: const [SurroundEffect(blx: SurroundEffect.blxMax)],
  ),
  (
    filter: 'surround',
    label: 'bly=blyMin',
    bundle: const [SurroundEffect(bly: SurroundEffect.blyMin)],
  ),
  (
    filter: 'surround',
    label: 'bly=blyDefault',
    bundle: const [SurroundEffect(bly: SurroundEffect.blyDefault)],
  ),
  (
    filter: 'surround',
    label: 'bly=blyMax',
    bundle: const [SurroundEffect(bly: SurroundEffect.blyMax)],
  ),
  (
    filter: 'surround',
    label: 'br_in=brInMin',
    bundle: const [SurroundEffect(brIn: SurroundEffect.brInMin)],
  ),
  (
    filter: 'surround',
    label: 'br_in=brInDefault',
    bundle: const [SurroundEffect(brIn: SurroundEffect.brInDefault)],
  ),
  (
    filter: 'surround',
    label: 'br_in=brInMax',
    bundle: const [SurroundEffect(brIn: SurroundEffect.brInMax)],
  ),
  (
    filter: 'surround',
    label: 'br_out=brOutMin',
    bundle: const [SurroundEffect(brOut: SurroundEffect.brOutMin)],
  ),
  (
    filter: 'surround',
    label: 'br_out=brOutDefault',
    bundle: const [SurroundEffect(brOut: SurroundEffect.brOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'br_out=brOutMax',
    bundle: const [SurroundEffect(brOut: SurroundEffect.brOutMax)],
  ),
  (
    filter: 'surround',
    label: 'brx=brxMin',
    bundle: const [SurroundEffect(brx: SurroundEffect.brxMin)],
  ),
  (
    filter: 'surround',
    label: 'brx=brxDefault',
    bundle: const [SurroundEffect(brx: SurroundEffect.brxDefault)],
  ),
  (
    filter: 'surround',
    label: 'brx=brxMax',
    bundle: const [SurroundEffect(brx: SurroundEffect.brxMax)],
  ),
  (
    filter: 'surround',
    label: 'bry=bryMin',
    bundle: const [SurroundEffect(bry: SurroundEffect.bryMin)],
  ),
  (
    filter: 'surround',
    label: 'bry=bryDefault',
    bundle: const [SurroundEffect(bry: SurroundEffect.bryDefault)],
  ),
  (
    filter: 'surround',
    label: 'bry=bryMax',
    bundle: const [SurroundEffect(bry: SurroundEffect.bryMax)],
  ),
  (
    filter: 'surround',
    label: 'fc_in=fcInMin',
    bundle: const [SurroundEffect(fcIn: SurroundEffect.fcInMin)],
  ),
  (
    filter: 'surround',
    label: 'fc_in=fcInDefault',
    bundle: const [SurroundEffect(fcIn: SurroundEffect.fcInDefault)],
  ),
  (
    filter: 'surround',
    label: 'fc_in=fcInMax',
    bundle: const [SurroundEffect(fcIn: SurroundEffect.fcInMax)],
  ),
  (
    filter: 'surround',
    label: 'fc_out=fcOutMin',
    bundle: const [SurroundEffect(fcOut: SurroundEffect.fcOutMin)],
  ),
  (
    filter: 'surround',
    label: 'fc_out=fcOutDefault',
    bundle: const [SurroundEffect(fcOut: SurroundEffect.fcOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'fc_out=fcOutMax',
    bundle: const [SurroundEffect(fcOut: SurroundEffect.fcOutMax)],
  ),
  (
    filter: 'surround',
    label: 'fcx=fcxMin',
    bundle: const [SurroundEffect(fcx: SurroundEffect.fcxMin)],
  ),
  (
    filter: 'surround',
    label: 'fcx=fcxDefault',
    bundle: const [SurroundEffect(fcx: SurroundEffect.fcxDefault)],
  ),
  (
    filter: 'surround',
    label: 'fcx=fcxMax',
    bundle: const [SurroundEffect(fcx: SurroundEffect.fcxMax)],
  ),
  (
    filter: 'surround',
    label: 'fcy=fcyMin',
    bundle: const [SurroundEffect(fcy: SurroundEffect.fcyMin)],
  ),
  (
    filter: 'surround',
    label: 'fcy=fcyDefault',
    bundle: const [SurroundEffect(fcy: SurroundEffect.fcyDefault)],
  ),
  (
    filter: 'surround',
    label: 'fcy=fcyMax',
    bundle: const [SurroundEffect(fcy: SurroundEffect.fcyMax)],
  ),
  (
    filter: 'surround',
    label: 'fl_in=flInMin',
    bundle: const [SurroundEffect(flIn: SurroundEffect.flInMin)],
  ),
  (
    filter: 'surround',
    label: 'fl_in=flInDefault',
    bundle: const [SurroundEffect(flIn: SurroundEffect.flInDefault)],
  ),
  (
    filter: 'surround',
    label: 'fl_in=flInMax',
    bundle: const [SurroundEffect(flIn: SurroundEffect.flInMax)],
  ),
  (
    filter: 'surround',
    label: 'fl_out=flOutMin',
    bundle: const [SurroundEffect(flOut: SurroundEffect.flOutMin)],
  ),
  (
    filter: 'surround',
    label: 'fl_out=flOutDefault',
    bundle: const [SurroundEffect(flOut: SurroundEffect.flOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'fl_out=flOutMax',
    bundle: const [SurroundEffect(flOut: SurroundEffect.flOutMax)],
  ),
  (
    filter: 'surround',
    label: 'flx=flxMin',
    bundle: const [SurroundEffect(flx: SurroundEffect.flxMin)],
  ),
  (
    filter: 'surround',
    label: 'flx=flxDefault',
    bundle: const [SurroundEffect(flx: SurroundEffect.flxDefault)],
  ),
  (
    filter: 'surround',
    label: 'flx=flxMax',
    bundle: const [SurroundEffect(flx: SurroundEffect.flxMax)],
  ),
  (
    filter: 'surround',
    label: 'fly=flyMin',
    bundle: const [SurroundEffect(fly: SurroundEffect.flyMin)],
  ),
  (
    filter: 'surround',
    label: 'fly=flyDefault',
    bundle: const [SurroundEffect(fly: SurroundEffect.flyDefault)],
  ),
  (
    filter: 'surround',
    label: 'fly=flyMax',
    bundle: const [SurroundEffect(fly: SurroundEffect.flyMax)],
  ),
  (
    filter: 'surround',
    label: 'focus=focusMin',
    bundle: const [SurroundEffect(focus: SurroundEffect.focusMin)],
  ),
  (
    filter: 'surround',
    label: 'focus=focusDefault',
    bundle: const [SurroundEffect(focus: SurroundEffect.focusDefault)],
  ),
  (
    filter: 'surround',
    label: 'focus=focusMax',
    bundle: const [SurroundEffect(focus: SurroundEffect.focusMax)],
  ),
  (
    filter: 'surround',
    label: 'fr_in=frInMin',
    bundle: const [SurroundEffect(frIn: SurroundEffect.frInMin)],
  ),
  (
    filter: 'surround',
    label: 'fr_in=frInDefault',
    bundle: const [SurroundEffect(frIn: SurroundEffect.frInDefault)],
  ),
  (
    filter: 'surround',
    label: 'fr_in=frInMax',
    bundle: const [SurroundEffect(frIn: SurroundEffect.frInMax)],
  ),
  (
    filter: 'surround',
    label: 'fr_out=frOutMin',
    bundle: const [SurroundEffect(frOut: SurroundEffect.frOutMin)],
  ),
  (
    filter: 'surround',
    label: 'fr_out=frOutDefault',
    bundle: const [SurroundEffect(frOut: SurroundEffect.frOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'fr_out=frOutMax',
    bundle: const [SurroundEffect(frOut: SurroundEffect.frOutMax)],
  ),
  (
    filter: 'surround',
    label: 'frx=frxMin',
    bundle: const [SurroundEffect(frx: SurroundEffect.frxMin)],
  ),
  (
    filter: 'surround',
    label: 'frx=frxDefault',
    bundle: const [SurroundEffect(frx: SurroundEffect.frxDefault)],
  ),
  (
    filter: 'surround',
    label: 'frx=frxMax',
    bundle: const [SurroundEffect(frx: SurroundEffect.frxMax)],
  ),
  (
    filter: 'surround',
    label: 'fry=fryMin',
    bundle: const [SurroundEffect(fry: SurroundEffect.fryMin)],
  ),
  (
    filter: 'surround',
    label: 'fry=fryDefault',
    bundle: const [SurroundEffect(fry: SurroundEffect.fryDefault)],
  ),
  (
    filter: 'surround',
    label: 'fry=fryMax',
    bundle: const [SurroundEffect(fry: SurroundEffect.fryMax)],
  ),
  (
    filter: 'surround',
    label: 'level_in=levelInMin',
    bundle: const [SurroundEffect(levelIn: SurroundEffect.levelInMin)],
  ),
  (
    filter: 'surround',
    label: 'level_in=levelInDefault',
    bundle: const [SurroundEffect(levelIn: SurroundEffect.levelInDefault)],
  ),
  (
    filter: 'surround',
    label: 'level_in=levelInMax',
    bundle: const [SurroundEffect(levelIn: SurroundEffect.levelInMax)],
  ),
  (
    filter: 'surround',
    label: 'level_out=levelOutMin',
    bundle: const [SurroundEffect(levelOut: SurroundEffect.levelOutMin)],
  ),
  (
    filter: 'surround',
    label: 'level_out=levelOutDefault',
    bundle: const [SurroundEffect(levelOut: SurroundEffect.levelOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'level_out=levelOutMax',
    bundle: const [SurroundEffect(levelOut: SurroundEffect.levelOutMax)],
  ),
  (
    filter: 'surround',
    label: 'lfe_high=lfeHighMin',
    bundle: const [SurroundEffect(lfeHigh: SurroundEffect.lfeHighMin)],
  ),
  (
    filter: 'surround',
    label: 'lfe_high=lfeHighDefault',
    bundle: const [SurroundEffect(lfeHigh: SurroundEffect.lfeHighDefault)],
  ),
  (
    filter: 'surround',
    label: 'lfe_high=lfeHighMax',
    bundle: const [SurroundEffect(lfeHigh: SurroundEffect.lfeHighMax)],
  ),
  (
    filter: 'surround',
    label: 'lfe_in=lfeInMin',
    bundle: const [SurroundEffect(lfeIn: SurroundEffect.lfeInMin)],
  ),
  (
    filter: 'surround',
    label: 'lfe_in=lfeInDefault',
    bundle: const [SurroundEffect(lfeIn: SurroundEffect.lfeInDefault)],
  ),
  (
    filter: 'surround',
    label: 'lfe_in=lfeInMax',
    bundle: const [SurroundEffect(lfeIn: SurroundEffect.lfeInMax)],
  ),
  (
    filter: 'surround',
    label: 'lfe_low=lfeLowMin',
    bundle: const [SurroundEffect(lfeLow: SurroundEffect.lfeLowMin)],
  ),
  (
    filter: 'surround',
    label: 'lfe_low=lfeLowDefault',
    bundle: const [SurroundEffect(lfeLow: SurroundEffect.lfeLowDefault)],
  ),
  (
    filter: 'surround',
    label: 'lfe_low=lfeLowMax',
    bundle: const [SurroundEffect(lfeLow: SurroundEffect.lfeLowMax)],
  ),
  (
    filter: 'surround',
    label: 'lfe_out=lfeOutMin',
    bundle: const [SurroundEffect(lfeOut: SurroundEffect.lfeOutMin)],
  ),
  (
    filter: 'surround',
    label: 'lfe_out=lfeOutDefault',
    bundle: const [SurroundEffect(lfeOut: SurroundEffect.lfeOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'lfe_out=lfeOutMax',
    bundle: const [SurroundEffect(lfeOut: SurroundEffect.lfeOutMax)],
  ),
  (
    filter: 'surround',
    label: 'overlap=overlapMin',
    bundle: const [SurroundEffect(overlap: SurroundEffect.overlapMin)],
  ),
  (
    filter: 'surround',
    label: 'overlap=overlapDefault',
    bundle: const [SurroundEffect(overlap: SurroundEffect.overlapDefault)],
  ),
  (
    filter: 'surround',
    label: 'overlap=overlapMax',
    bundle: const [SurroundEffect(overlap: SurroundEffect.overlapMax)],
  ),
  (
    filter: 'surround',
    label: 'sl_in=slInMin',
    bundle: const [SurroundEffect(slIn: SurroundEffect.slInMin)],
  ),
  (
    filter: 'surround',
    label: 'sl_in=slInDefault',
    bundle: const [SurroundEffect(slIn: SurroundEffect.slInDefault)],
  ),
  (
    filter: 'surround',
    label: 'sl_in=slInMax',
    bundle: const [SurroundEffect(slIn: SurroundEffect.slInMax)],
  ),
  (
    filter: 'surround',
    label: 'sl_out=slOutMin',
    bundle: const [SurroundEffect(slOut: SurroundEffect.slOutMin)],
  ),
  (
    filter: 'surround',
    label: 'sl_out=slOutDefault',
    bundle: const [SurroundEffect(slOut: SurroundEffect.slOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'sl_out=slOutMax',
    bundle: const [SurroundEffect(slOut: SurroundEffect.slOutMax)],
  ),
  (
    filter: 'surround',
    label: 'slx=slxMin',
    bundle: const [SurroundEffect(slx: SurroundEffect.slxMin)],
  ),
  (
    filter: 'surround',
    label: 'slx=slxDefault',
    bundle: const [SurroundEffect(slx: SurroundEffect.slxDefault)],
  ),
  (
    filter: 'surround',
    label: 'slx=slxMax',
    bundle: const [SurroundEffect(slx: SurroundEffect.slxMax)],
  ),
  (
    filter: 'surround',
    label: 'sly=slyMin',
    bundle: const [SurroundEffect(sly: SurroundEffect.slyMin)],
  ),
  (
    filter: 'surround',
    label: 'sly=slyDefault',
    bundle: const [SurroundEffect(sly: SurroundEffect.slyDefault)],
  ),
  (
    filter: 'surround',
    label: 'sly=slyMax',
    bundle: const [SurroundEffect(sly: SurroundEffect.slyMax)],
  ),
  (
    filter: 'surround',
    label: 'smooth=smoothMin',
    bundle: const [SurroundEffect(smooth: SurroundEffect.smoothMin)],
  ),
  (
    filter: 'surround',
    label: 'smooth=smoothDefault',
    bundle: const [SurroundEffect(smooth: SurroundEffect.smoothDefault)],
  ),
  (
    filter: 'surround',
    label: 'smooth=smoothMax',
    bundle: const [SurroundEffect(smooth: SurroundEffect.smoothMax)],
  ),
  (
    filter: 'surround',
    label: 'sr_in=srInMin',
    bundle: const [SurroundEffect(srIn: SurroundEffect.srInMin)],
  ),
  (
    filter: 'surround',
    label: 'sr_in=srInDefault',
    bundle: const [SurroundEffect(srIn: SurroundEffect.srInDefault)],
  ),
  (
    filter: 'surround',
    label: 'sr_in=srInMax',
    bundle: const [SurroundEffect(srIn: SurroundEffect.srInMax)],
  ),
  (
    filter: 'surround',
    label: 'sr_out=srOutMin',
    bundle: const [SurroundEffect(srOut: SurroundEffect.srOutMin)],
  ),
  (
    filter: 'surround',
    label: 'sr_out=srOutDefault',
    bundle: const [SurroundEffect(srOut: SurroundEffect.srOutDefault)],
  ),
  (
    filter: 'surround',
    label: 'sr_out=srOutMax',
    bundle: const [SurroundEffect(srOut: SurroundEffect.srOutMax)],
  ),
  (
    filter: 'surround',
    label: 'srx=srxMin',
    bundle: const [SurroundEffect(srx: SurroundEffect.srxMin)],
  ),
  (
    filter: 'surround',
    label: 'srx=srxDefault',
    bundle: const [SurroundEffect(srx: SurroundEffect.srxDefault)],
  ),
  (
    filter: 'surround',
    label: 'srx=srxMax',
    bundle: const [SurroundEffect(srx: SurroundEffect.srxMax)],
  ),
  (
    filter: 'surround',
    label: 'sry=sryMin',
    bundle: const [SurroundEffect(sry: SurroundEffect.sryMin)],
  ),
  (
    filter: 'surround',
    label: 'sry=sryDefault',
    bundle: const [SurroundEffect(sry: SurroundEffect.sryDefault)],
  ),
  (
    filter: 'surround',
    label: 'sry=sryMax',
    bundle: const [SurroundEffect(sry: SurroundEffect.sryMax)],
  ),
  (
    filter: 'surround',
    label: 'win_size=winSizeMin',
    bundle: const [SurroundEffect(winSize: SurroundEffect.winSizeMin)],
  ),
  (
    filter: 'surround',
    label: 'win_size=winSizeDefault',
    bundle: const [SurroundEffect(winSize: SurroundEffect.winSizeDefault)],
  ),
  (
    filter: 'surround',
    label: 'win_size=winSizeMax',
    bundle: const [SurroundEffect(winSize: SurroundEffect.winSizeMax)],
  ),
  (
    filter: 'tiltshelf',
    label: 'blocksize=blocksizeMin',
    bundle: const [TiltshelfEffect(blocksize: TiltshelfEffect.blocksizeMin)],
  ),
  (
    filter: 'tiltshelf',
    label: 'blocksize=blocksizeDefault',
    bundle: const [
      TiltshelfEffect(blocksize: TiltshelfEffect.blocksizeDefault),
    ],
  ),
  (
    filter: 'tiltshelf',
    label: 'blocksize=blocksizeMax',
    bundle: const [TiltshelfEffect(blocksize: TiltshelfEffect.blocksizeMax)],
  ),
  (
    filter: 'tiltshelf',
    label: 'frequency=frequencyMin',
    bundle: const [TiltshelfEffect(frequency: TiltshelfEffect.frequencyMin)],
  ),
  (
    filter: 'tiltshelf',
    label: 'frequency=frequencyDefault',
    bundle: const [
      TiltshelfEffect(frequency: TiltshelfEffect.frequencyDefault),
    ],
  ),
  (
    filter: 'tiltshelf',
    label: 'frequency=frequencyMax',
    bundle: const [TiltshelfEffect(frequency: TiltshelfEffect.frequencyMax)],
  ),
  (
    filter: 'tiltshelf',
    label: 'gain=gainMin',
    bundle: const [TiltshelfEffect(gain: TiltshelfEffect.gainMin)],
  ),
  (
    filter: 'tiltshelf',
    label: 'gain=gainDefault',
    bundle: const [TiltshelfEffect(gain: TiltshelfEffect.gainDefault)],
  ),
  (
    filter: 'tiltshelf',
    label: 'gain=gainMax',
    bundle: const [TiltshelfEffect(gain: TiltshelfEffect.gainMax)],
  ),
  (
    filter: 'tiltshelf',
    label: 'mix=mixMin',
    bundle: const [TiltshelfEffect(mix: TiltshelfEffect.mixMin)],
  ),
  (
    filter: 'tiltshelf',
    label: 'mix=mixDefault',
    bundle: const [TiltshelfEffect(mix: TiltshelfEffect.mixDefault)],
  ),
  (
    filter: 'tiltshelf',
    label: 'mix=mixMax',
    bundle: const [TiltshelfEffect(mix: TiltshelfEffect.mixMax)],
  ),
  (
    filter: 'tiltshelf',
    label: 'poles=polesMin',
    bundle: const [TiltshelfEffect(poles: TiltshelfEffect.polesMin)],
  ),
  (
    filter: 'tiltshelf',
    label: 'poles=polesDefault',
    bundle: const [TiltshelfEffect(poles: TiltshelfEffect.polesDefault)],
  ),
  (
    filter: 'tiltshelf',
    label: 'poles=polesMax',
    bundle: const [TiltshelfEffect(poles: TiltshelfEffect.polesMax)],
  ),
  (
    filter: 'tiltshelf',
    label: 'width=widthMin',
    bundle: const [TiltshelfEffect(width: TiltshelfEffect.widthMin)],
  ),
  (
    filter: 'tiltshelf',
    label: 'width=widthDefault',
    bundle: const [TiltshelfEffect(width: TiltshelfEffect.widthDefault)],
  ),
  (
    filter: 'tiltshelf',
    label: 'width=widthMax',
    bundle: const [TiltshelfEffect(width: TiltshelfEffect.widthMax)],
  ),
  (
    filter: 'treble',
    label: 'blocksize=blocksizeMin',
    bundle: const [TrebleEffect(blocksize: TrebleEffect.blocksizeMin)],
  ),
  (
    filter: 'treble',
    label: 'blocksize=blocksizeDefault',
    bundle: const [TrebleEffect(blocksize: TrebleEffect.blocksizeDefault)],
  ),
  (
    filter: 'treble',
    label: 'blocksize=blocksizeMax',
    bundle: const [TrebleEffect(blocksize: TrebleEffect.blocksizeMax)],
  ),
  (
    filter: 'treble',
    label: 'frequency=frequencyMin',
    bundle: const [TrebleEffect(frequency: TrebleEffect.frequencyMin)],
  ),
  (
    filter: 'treble',
    label: 'frequency=frequencyDefault',
    bundle: const [TrebleEffect(frequency: TrebleEffect.frequencyDefault)],
  ),
  (
    filter: 'treble',
    label: 'frequency=frequencyMax',
    bundle: const [TrebleEffect(frequency: TrebleEffect.frequencyMax)],
  ),
  (
    filter: 'treble',
    label: 'gain=gainMin',
    bundle: const [TrebleEffect(gain: TrebleEffect.gainMin)],
  ),
  (
    filter: 'treble',
    label: 'gain=gainDefault',
    bundle: const [TrebleEffect(gain: TrebleEffect.gainDefault)],
  ),
  (
    filter: 'treble',
    label: 'gain=gainMax',
    bundle: const [TrebleEffect(gain: TrebleEffect.gainMax)],
  ),
  (
    filter: 'treble',
    label: 'mix=mixMin',
    bundle: const [TrebleEffect(mix: TrebleEffect.mixMin)],
  ),
  (
    filter: 'treble',
    label: 'mix=mixDefault',
    bundle: const [TrebleEffect(mix: TrebleEffect.mixDefault)],
  ),
  (
    filter: 'treble',
    label: 'mix=mixMax',
    bundle: const [TrebleEffect(mix: TrebleEffect.mixMax)],
  ),
  (
    filter: 'treble',
    label: 'poles=polesMin',
    bundle: const [TrebleEffect(poles: TrebleEffect.polesMin)],
  ),
  (
    filter: 'treble',
    label: 'poles=polesDefault',
    bundle: const [TrebleEffect(poles: TrebleEffect.polesDefault)],
  ),
  (
    filter: 'treble',
    label: 'poles=polesMax',
    bundle: const [TrebleEffect(poles: TrebleEffect.polesMax)],
  ),
  (
    filter: 'treble',
    label: 'width=widthMin',
    bundle: const [TrebleEffect(width: TrebleEffect.widthMin)],
  ),
  (
    filter: 'treble',
    label: 'width=widthDefault',
    bundle: const [TrebleEffect(width: TrebleEffect.widthDefault)],
  ),
  (
    filter: 'treble',
    label: 'width=widthMax',
    bundle: const [TrebleEffect(width: TrebleEffect.widthMax)],
  ),
  (
    filter: 'tremolo',
    label: 'd=dMin',
    bundle: const [TremoloEffect(d: TremoloEffect.dMin)],
  ),
  (
    filter: 'tremolo',
    label: 'd=dDefault',
    bundle: const [TremoloEffect(d: TremoloEffect.dDefault)],
  ),
  (
    filter: 'tremolo',
    label: 'd=dMax',
    bundle: const [TremoloEffect(d: TremoloEffect.dMax)],
  ),
  (
    filter: 'tremolo',
    label: 'f=fMin',
    bundle: const [TremoloEffect(f: TremoloEffect.fMin)],
  ),
  (
    filter: 'tremolo',
    label: 'f=fDefault',
    bundle: const [TremoloEffect(f: TremoloEffect.fDefault)],
  ),
  (
    filter: 'tremolo',
    label: 'f=fMax',
    bundle: const [TremoloEffect(f: TremoloEffect.fMax)],
  ),
  (
    filter: 'vibrato',
    label: 'd=dMin',
    bundle: const [VibratoEffect(d: VibratoEffect.dMin)],
  ),
  (
    filter: 'vibrato',
    label: 'd=dDefault',
    bundle: const [VibratoEffect(d: VibratoEffect.dDefault)],
  ),
  (
    filter: 'vibrato',
    label: 'd=dMax',
    bundle: const [VibratoEffect(d: VibratoEffect.dMax)],
  ),
  (
    filter: 'vibrato',
    label: 'f=fMin',
    bundle: const [VibratoEffect(f: VibratoEffect.fMin)],
  ),
  (
    filter: 'vibrato',
    label: 'f=fDefault',
    bundle: const [VibratoEffect(f: VibratoEffect.fDefault)],
  ),
  (
    filter: 'vibrato',
    label: 'f=fMax',
    bundle: const [VibratoEffect(f: VibratoEffect.fMax)],
  ),
  (
    filter: 'virtualbass',
    label: 'cutoff=cutoffMin',
    bundle: const [VirtualbassEffect(cutoff: VirtualbassEffect.cutoffMin)],
  ),
  (
    filter: 'virtualbass',
    label: 'cutoff=cutoffDefault',
    bundle: const [VirtualbassEffect(cutoff: VirtualbassEffect.cutoffDefault)],
  ),
  (
    filter: 'virtualbass',
    label: 'cutoff=cutoffMax',
    bundle: const [VirtualbassEffect(cutoff: VirtualbassEffect.cutoffMax)],
  ),
  (
    filter: 'virtualbass',
    label: 'strength=strengthMin',
    bundle: const [VirtualbassEffect(strength: VirtualbassEffect.strengthMin)],
  ),
  (
    filter: 'virtualbass',
    label: 'strength=strengthDefault',
    bundle: const [
      VirtualbassEffect(strength: VirtualbassEffect.strengthDefault),
    ],
  ),
  (
    filter: 'virtualbass',
    label: 'strength=strengthMax',
    bundle: const [VirtualbassEffect(strength: VirtualbassEffect.strengthMax)],
  ),
];

const List<ParamCorner> kFilterSamples = [
  (
    filter: 'acompressor',
    label: 'defaults',
    bundle: const [AcompressorEffect()],
  ),
  (filter: 'acontrast', label: 'defaults', bundle: const [AcontrastEffect()]),
  (filter: 'acrusher', label: 'defaults', bundle: const [AcrusherEffect()]),
  (filter: 'adeclick', label: 'defaults', bundle: const [AdeclickEffect()]),
  (filter: 'adeclip', label: 'defaults', bundle: const [AdeclipEffect()]),
  (
    filter: 'adecorrelate',
    label: 'defaults',
    bundle: const [AdecorrelateEffect()],
  ),
  (filter: 'adelay', label: 'defaults', bundle: const [AdelayEffect()]),
  (filter: 'adenorm', label: 'defaults', bundle: const [AdenormEffect()]),
  (
    filter: 'aderivative',
    label: 'defaults',
    bundle: const [AderivativeEffect()],
  ),
  (filter: 'adrc', label: 'defaults', bundle: const [AdrcEffect()]),
  (
    filter: 'adynamicequalizer',
    label: 'defaults',
    bundle: const [AdynamicequalizerEffect()],
  ),
  (
    filter: 'adynamicsmooth',
    label: 'defaults',
    bundle: const [AdynamicsmoothEffect()],
  ),
  (filter: 'aecho', label: 'defaults', bundle: const [AechoEffect()]),
  (filter: 'aemphasis', label: 'defaults', bundle: const [AemphasisEffect()]),
  (
    filter: 'aeval',
    label: 'defaults',
    bundle: const [AevalEffect(exprs: 'val(0)|val(1)')],
  ),
  (
    filter: 'aeval',
    label: 'preset Passthrough',
    bundle: const [AevalEffect(exprs: 'val(0)|val(1)')],
  ),
  (
    filter: 'aeval',
    label: 'preset Mute',
    bundle: const [AevalEffect(exprs: '0|0')],
  ),
  (
    filter: 'aeval',
    label: 'preset Mono sum',
    bundle: const [
      AevalEffect(exprs: '0.5*val(0)+0.5*val(1)|0.5*val(0)+0.5*val(1)'),
    ],
  ),
  (
    filter: 'aeval',
    label: 'preset Invert phase',
    bundle: const [AevalEffect(exprs: '-val(0)|-val(1)')],
  ),
  (filter: 'aexciter', label: 'defaults', bundle: const [AexciterEffect()]),
  (filter: 'afade', label: 'defaults', bundle: const [AfadeEffect()]),
  (filter: 'afftdn', label: 'defaults', bundle: const [AfftdnEffect()]),
  (filter: 'afftfilt', label: 'defaults', bundle: const [AfftfiltEffect()]),
  (filter: 'aformat', label: 'defaults', bundle: const [AformatEffect()]),
  (filter: 'afreqshift', label: 'defaults', bundle: const [AfreqshiftEffect()]),
  (filter: 'afwtdn', label: 'defaults', bundle: const [AfwtdnEffect()]),
  (filter: 'agate', label: 'defaults', bundle: const [AgateEffect()]),
  (filter: 'aiir', label: 'defaults', bundle: const [AiirEffect()]),
  (filter: 'aintegral', label: 'defaults', bundle: const [AintegralEffect()]),
  (filter: 'alimiter', label: 'defaults', bundle: const [AlimiterEffect()]),
  (filter: 'allpass', label: 'defaults', bundle: const [AllpassEffect()]),
  (
    filter: 'anequalizer',
    label: 'defaults',
    bundle: const [AnequalizerEffect()],
  ),
  (filter: 'anlmdn', label: 'defaults', bundle: const [AnlmdnEffect()]),
  (filter: 'apad', label: 'defaults', bundle: const [ApadEffect()]),
  (filter: 'aphaser', label: 'defaults', bundle: const [AphaserEffect()]),
  (
    filter: 'aphaseshift',
    label: 'defaults',
    bundle: const [AphaseshiftEffect()],
  ),
  (filter: 'apsyclip', label: 'defaults', bundle: const [ApsyclipEffect()]),
  (filter: 'apulsator', label: 'defaults', bundle: const [ApulsatorEffect()]),
  (filter: 'aresample', label: 'defaults', bundle: const [AresampleEffect()]),
  (filter: 'asetrate', label: 'defaults', bundle: const [AsetrateEffect()]),
  (filter: 'asoftclip', label: 'defaults', bundle: const [AsoftclipEffect()]),
  (filter: 'asubboost', label: 'defaults', bundle: const [AsubboostEffect()]),
  (filter: 'asubcut', label: 'defaults', bundle: const [AsubcutEffect()]),
  (filter: 'asupercut', label: 'defaults', bundle: const [AsupercutEffect()]),
  (filter: 'asuperpass', label: 'defaults', bundle: const [AsuperpassEffect()]),
  (filter: 'asuperstop', label: 'defaults', bundle: const [AsuperstopEffect()]),
  (filter: 'atempo', label: 'defaults', bundle: const [AtempoEffect()]),
  (filter: 'atilt', label: 'defaults', bundle: const [AtiltEffect()]),
  (filter: 'bandpass', label: 'defaults', bundle: const [BandpassEffect()]),
  (filter: 'bandreject', label: 'defaults', bundle: const [BandrejectEffect()]),
  (filter: 'bass', label: 'defaults', bundle: const [BassEffect()]),
  (filter: 'biquad', label: 'defaults', bundle: const [BiquadEffect()]),
  (
    filter: 'channelmap',
    label: 'defaults',
    bundle: const [ChannelmapEffect(map: '0|1')],
  ),
  (
    filter: 'channelmap',
    label: 'preset Stereo (0|1)',
    bundle: const [ChannelmapEffect(map: '0|1')],
  ),
  (
    filter: 'channelmap',
    label: 'preset Swap (1|0)',
    bundle: const [ChannelmapEffect(map: '1|0')],
  ),
  (
    filter: 'chorus',
    label: 'defaults',
    bundle: const [
      ChorusEffect(
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'preset Subtle',
    bundle: const [
      ChorusEffect(
        delays: '40|50',
        decays: '0.4|0.3',
        speeds: '0.25|0.4',
        depths: '1.5|1.0',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'preset Lush',
    bundle: const [
      ChorusEffect(
        delays: '55|60|70',
        decays: '0.5|0.4|0.3',
        speeds: '0.3|0.4|0.5',
        depths: '3|2.5|2',
      ),
    ],
  ),
  (
    filter: 'chorus',
    label: 'preset Vintage',
    bundle: const [
      ChorusEffect(delays: '50', decays: '0.4', speeds: '0.25', depths: '2'),
    ],
  ),
  (filter: 'compand', label: 'defaults', bundle: const [CompandEffect()]),
  (
    filter: 'compensationdelay',
    label: 'defaults',
    bundle: const [CompensationdelayEffect()],
  ),
  (filter: 'crossfeed', label: 'defaults', bundle: const [CrossfeedEffect()]),
  (
    filter: 'crystalizer',
    label: 'defaults',
    bundle: const [CrystalizerEffect()],
  ),
  (filter: 'dcshift', label: 'defaults', bundle: const [DcshiftEffect()]),
  (filter: 'deesser', label: 'defaults', bundle: const [DeesserEffect()]),
  (
    filter: 'dialoguenhance',
    label: 'defaults',
    bundle: const [DialoguenhanceEffect()],
  ),
  (filter: 'drmeter', label: 'defaults', bundle: const [DrmeterEffect()]),
  (filter: 'dynaudnorm', label: 'defaults', bundle: const [DynaudnormEffect()]),
  (filter: 'earwax', label: 'defaults', bundle: const [EarwaxEffect()]),
  (filter: 'ebur128', label: 'defaults', bundle: const [Ebur128Effect()]),
  (filter: 'equalizer', label: 'defaults', bundle: const [EqualizerEffect()]),
  (
    filter: 'extrastereo',
    label: 'defaults',
    bundle: const [ExtrastereoEffect()],
  ),
  (
    filter: 'firequalizer',
    label: 'defaults',
    bundle: const [FirequalizerEffect()],
  ),
  (filter: 'flanger', label: 'defaults', bundle: const [FlangerEffect()]),
  (filter: 'haas', label: 'defaults', bundle: const [HaasEffect()]),
  (filter: 'hdcd', label: 'defaults', bundle: const [HdcdEffect()]),
  (filter: 'highpass', label: 'defaults', bundle: const [HighpassEffect()]),
  (filter: 'highshelf', label: 'defaults', bundle: const [HighshelfEffect()]),
  (filter: 'loudnorm', label: 'defaults', bundle: const [LoudnormEffect()]),
  (filter: 'lowpass', label: 'defaults', bundle: const [LowpassEffect()]),
  (filter: 'lowshelf', label: 'defaults', bundle: const [LowshelfEffect()]),
  (filter: 'mcompand', label: 'defaults', bundle: const [McompandEffect()]),
  (
    filter: 'pan',
    label: 'defaults',
    bundle: const [PanEffect(args: 'stereo|c0=c0|c1=c1')],
  ),
  (
    filter: 'pan',
    label: 'preset Passthrough (stereo)',
    bundle: const [PanEffect(args: 'stereo|c0=c0|c1=c1')],
  ),
  (
    filter: 'pan',
    label: 'preset Swap L / R',
    bundle: const [PanEffect(args: 'stereo|c0=c1|c1=c0')],
  ),
  (
    filter: 'pan',
    label: 'preset Mono to both',
    bundle: const [PanEffect(args: 'stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0+0.5*c1')],
  ),
  (
    filter: 'pan',
    label: 'preset Karaoke (center cut)',
    bundle: const [PanEffect(args: 'stereo|c0=c0-c1|c1=c1-c0')],
  ),
  (filter: 'rubberband', label: 'defaults', bundle: const [RubberbandEffect()]),
  (
    filter: 'silenceremove',
    label: 'defaults',
    bundle: const [SilenceremoveEffect()],
  ),
  (filter: 'speechnorm', label: 'defaults', bundle: const [SpeechnormEffect()]),
  (
    filter: 'stereotools',
    label: 'defaults',
    bundle: const [StereotoolsEffect()],
  ),
  (
    filter: 'stereowiden',
    label: 'defaults',
    bundle: const [StereowidenEffect()],
  ),
  (
    filter: 'superequalizer',
    label: 'defaults',
    bundle: const [SuperequalizerEffect()],
  ),
  (filter: 'surround', label: 'defaults', bundle: const [SurroundEffect()]),
  (filter: 'tiltshelf', label: 'defaults', bundle: const [TiltshelfEffect()]),
  (filter: 'treble', label: 'defaults', bundle: const [TrebleEffect()]),
  (filter: 'tremolo', label: 'defaults', bundle: const [TremoloEffect()]),
  (filter: 'vibrato', label: 'defaults', bundle: const [VibratoEffect()]),
  (
    filter: 'virtualbass',
    label: 'defaults',
    bundle: const [VirtualbassEffect()],
  ),
];
