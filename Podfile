source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def common_pods
	pod 'BigInt', '~> 3.0.1'
	pod 'SwiftDate', '~> 4.5.1'
	pod 'Alamofire', '~> 4.7.1'
	pod 'RNCryptor', '5.0.3'
	pod 'ReachabilitySwift', '~> 4.1.0'
	pod 'PKHUD', '~> 5.0'
	pod 'AMPopTip', '~> 3.2.1'
	pod 'Popover', '~> 1.2.0'
	pod 'ofxiOSBoost', '~> 1.60.0'
end

target 'MyMonero' do
	common_pods
end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['SWIFT_VERSION'] = '4.0'
		end
	end
end
