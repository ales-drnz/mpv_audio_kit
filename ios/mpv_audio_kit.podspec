#
# mpv_audio_kit iOS podspec
#
# libmpv su iOS deve essere distribuita come XCFramework statica.
# Usa il progetto mpv-build oppure scarica un binario precompilato.
# Metti il file in ios/Frameworks/libmpv.xcframework
#
# Alternativa: compilare da source con:
#   https://github.com/mpv-player/mpv/blob/master/DOCS/compile-howto.rst
#
Pod::Spec.new do |s|
  s.name             = 'mpv_audio_kit'
  s.version          = '0.0.1'
  s.summary          = 'Flutter audio player powered by libmpv.'
  s.description      = <<-DESC
    High-quality audio player for Flutter, based on libmpv.
    Supports audio filters, all media formats, and streaming protocols.
  DESC
  s.homepage         = 'https://github.com/your-org/mpv_audio_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mpv_audio_kit' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # Necessario per gestire la Audio Session
  s.frameworks = 'AVFoundation', 'AudioToolbox', 'Security', 'CoreFoundation'

  # ── libmpv XCFramework statica ────────────────────────────────────────────
  # Metti ios/Frameworks/libmpv.xcframework per includerla automaticamente.
  if File.exist?(File.join(__dir__, 'Frameworks', 'libmpv.xcframework'))
    s.vendored_frameworks = 'Frameworks/libmpv.xcframework'
  end

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                      => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_BITCODE'                      => 'NO',
    'OTHER_LDFLAGS'                       => '-liconv',
  }
  s.swift_version = '5.0'
end
