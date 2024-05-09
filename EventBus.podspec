
Pod::Spec.new do |s|
  s.name             = 'EventBus'
  s.version          = 'v1.0.0'
  s.summary          = 'A lightweight, protocol-oriented event bus framework for Swift.'
  s.description      = <<-DESC
                        EventBus is a lightweight, protocol-oriented event bus framework for Swift. It facilitates communication between components in an application without requiring the components to have direct references to each other.
                      DESC
  s.homepage         = 'https://github.com/dadameng/EventBus'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dadameng' => 'email@example.com' }
  s.source           = { :git => 'https://github.com/dadameng/EventBus.git', :tag => s.version.to_s }
  s.platform     = :ios, '13.0'
  s.swift_version = '5.0'
  s.source_files  = 'Sources/**/*.{swift}'
  s.requires_arc = true
end
