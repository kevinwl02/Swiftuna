Pod::Spec.new do |s|
  s.name         = "Swiftuna"
  s.version      = "0.0.3"
  s.summary      = "Decorator library that lets any view have a cool swipe-to-reveal options menu"
  s.homepage     = "https://github.com/kevinwl02/Swiftuna"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = {'Kevin Wong' => 'kevin.wl.02@gmail.com'}
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/kevinwl02/Swiftuna.git", :tag => "#{s.version}" }
  s.source_files  = "Swiftuna/Swiftuna/*.{swift,h,m}", "Swiftuna/Swiftuna/**/*.{swift,h,m}"

  s.requires_arc = true
end