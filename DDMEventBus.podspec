Pod::Spec.new do |s|
  s.name         = "DDMEventBus"
  s.version      = "1.0.0"
  s.summary      = "A brief description of DDMEventBus."
  s.description  = <<-DESC
                   A detailed description of DDMEventBus.
                   DESC
  s.homepage     = "http://example.com/DDMEventBus"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Author" => "author@example.com" }
  s.source       = { :path => "." }

  s.ios.deployment_target = "10.0"
  s.source_files  = "DDMEventBus/**/*.{h,m,swift}"
  s.public_header_files = "EventBus/**/*.h"
  s.frameworks = "Foundation"
  s.requires_arc = true
  s.static_framework = false  # 确保框架是动态的

end
