source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def common_pods
	pod 'BigInt', '3.1.0'
	pod 'SwiftDate', '4.5.1'
	pod 'Alamofire', '4.7.3'
	pod 'RNCryptor', '5.0.3'
	pod 'ReachabilitySwift', '4.3.0'
	pod 'PKHUD', '5.2.0'
	pod 'AMPopTip', '3.5.0'
	pod 'Popover', '1.2.0'
	pod 'ofxiOSBoost', '1.60.0'
	pod 'OpenSSL-Universal', '1.0.2.13'
end

target 'MyMonero' do
	common_pods
end

# pending https://github.com/CocoaPods/CocoaPods/issues/7134

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
		    if target.name == 'Popover'
				config.build_settings['SWIFT_VERSION'] = '4.0'
		    else
				config.build_settings['SWIFT_VERSION'] = '4.2'
			end
	    end

	end
end

