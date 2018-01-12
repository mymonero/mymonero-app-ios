source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def common_pods
	pod 'BigInt', :git => 'https://github.com/mymonero/BigInt.git', :tag => 'v3.0.2'
	pod 'SipHash', :git => 'https://github.com/mymonero/SipHash.git', :tag => 'v1.2.0'
	# ^- BigInt relies upon SipHash, so specifying our fork here

	pod 'SwiftDate', :git => 'https://github.com/mymonero/SwiftDate.git', :tag => '4.5.1'
	pod 'Alamofire', :git => 'https://github.com/mymonero/Alamofire.git', :tag => '4.6.0'
	pod 'RNCryptor', :git => 'https://github.com/mymonero/RNCryptor.git', :tag => 'RNCryptor-5.0.2'

#	pod 'ReachabilitySwift', :git => 'https://github.com/mymonero/Reachability.swift.git', :tag => 'v4.1.0'
# ^- vendored in App currently due to https://github.com/ashleymills/Reachability.swift/issues/257 

	pod 'PKHUD', :git => 'https://github.com/mymonero/PKHUD.git', :tag => '5.0.0'
	pod 'AMPopTip', :git => 'https://github.com/mymonero/AMPopTip.git', :tag => '3.0.0'
	pod 'Popover', :git => 'https://github.com/mymonero/Popover.git', :tag => '1.2.0'
	pod 'ofxiOSBoost', :git => 'https://github.com/mymonero/ofxiOSBoost.git', :tag => '1.60.0'
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
