Pod::Spec.new do |s|

  s.name         = "UIImageColorRatio"
  s.version      = "1.0.0"
  s.summary      = "A tool to calculate the color ratio of UIImage in iOS."

  s.description  = <<-DESC
  					This is a library to calculate the color ratio of UIImage in iOS.
                   DESC

  s.homepage     = "https://github.com/623637646/UIImageColorRatio"

  s.license      = "MIT"

  s.author       = { "Yanni Wang" => "wy19900729@gmail.com" }

  s.platform     = :ios, "10.0"
  
  s.swift_versions = "5"

  s.source       = { :git => "https://github.com/623637646/UIImageColorRatio.git", :tag => "#{s.version}" }

  s.source_files  = "UIImageColorRatio/**/*.{swift}"

end
