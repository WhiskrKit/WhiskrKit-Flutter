#
# CocoaPods fallback for apps that have not enabled Flutter's Swift Package
# Manager support. The preferred integration is SwiftPM (see
# flutter_whiskrkit/Package.swift, which declares the WhiskrKit dependency
# directly). In CocoaPods mode the consuming app's Podfile must supply the
# WhiskrKit Swift package via the cocoapods-spm plugin:
#
#   plugin 'cocoapods-spm'
#   target 'Runner' do
#     spm_pkg "WhiskrKit",
#             :url => "https://github.com/whiskrkit/whiskrkit-swift.git",
#             :version => "0.2.0"
#     ...
#   end
#
Pod::Spec.new do |s|
  s.name             = 'flutter_whiskrkit'
  s.version          = '0.2.0'
  s.summary          = 'Flutter wrapper for the WhiskrKit in-app survey SDK.'
  s.description      = <<-DESC
Flutter wrapper for WhiskrKit, the native in-app survey SDK. Surveys render as
fully native UI; this plugin only triggers presentation.
                       DESC
  s.homepage         = 'https://whiskrkit.eu'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dennis Vermeulen' => 'd.vermeulen@me.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_whiskrkit/Sources/flutter_whiskrkit/**/*'
  s.dependency 'Flutter'

  # WhiskrKit requires iOS 17.
  s.platform = :ios, '17.0'

  # The native WhiskrKit SDK as a Swift package (requires the consuming app's
  # Podfile to use the cocoapods-spm plugin — see the header of this file).
  s.spm_dependency 'WhiskrKit/WhiskrKit'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
