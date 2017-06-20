source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'MyMonero' do
	pod 'BigInt', '~> 2.1'
	pod 'SwiftDate', '~> 4.0'
	pod 'Alamofire', '~> 4.4'
	pod 'RNCryptor'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end