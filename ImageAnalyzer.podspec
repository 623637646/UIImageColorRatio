Pod::Spec.new do |s|

  s.name         = "ImageAnalyzer"
  s.version      = "1.0.0"
  s.summary      = "Help to analyze UIImage in iOS."

  s.description  = <<-DESC
  					This is a library to help to analyze UIImage in iOS..
                   DESC

  s.homepage     = "https://github.com/623637646/ImageAnalyzer"

  s.license      = "MIT"

  s.author       = { "Yanni Wang" => "wy19900729@gmail.com" }

  s.platform     = :ios, "10.0"
  
  s.swift_versions = "5"

  s.source       = { :git => "https://github.com/623637646/ImageAnalyzer.git", :tag => "#{s.version}" }

  s.source_files  = "ImageAnalyzer/**/*.{swift}"

end
