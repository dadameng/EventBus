Pod::Spec.new do |s|
  s.name         = "DDMEventBus"
  s.version      = "2.1.0"
  s.summary      = "EventBus is a lightweight, protocol-oriented event bus framework for Swift."
  s.description  = <<-DESC
                    EventBus is a lightweight, protocol-oriented event bus framework for Swift. It facilitates communication between components in an application without requiring the components to have direct references to each other, which helps in reducing coupling and enhancing modularity.
                   DESC
  s.homepage     = "https://github.com/dadameng/EventBus"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Author" => "https://github.com/dadameng" }
  s.source       = { :git => 'https://github.com/dadameng/EventBus.git', :tag => s.version.to_s }

  s.ios.deployment_target = "13.0"
  s.source_files  = "DDMEventBus/**/*.{h,m,swift}"
  s.public_header_files = "DDMEventBus/**/*.h"
  s.frameworks = "Foundation"
  s.requires_arc = true
  s.static_framework = false

  s.module_name = 'DDMEventBus'
  s.swift_version = '5.0'
end
