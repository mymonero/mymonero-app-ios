source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def common_pods
	pod 'BigInt', '~> 3.0.0'
	pod 'SwiftDate', '~> 4.4.1'
	pod 'Alamofire', '~> 4.5.1'
	pod 'RNCryptor', '~> 5.0.1'
	pod 'ReachabilitySwift', '~> 3.0'
	pod 'PKHUD', :git => 'https://github.com/pkluz/PKHUD.git', :branch => 'release/swift4'
	pod 'AMPopTip', '~> 3.0.0'
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
