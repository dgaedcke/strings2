target 'Strings2' do
	platform :ios, '9.0'
	use_frameworks!
	inhibit_all_warnings!

	pod 'Firebase/Core'
	pod 'Firebase/Auth'
	pod 'Firebase/Database'
	pod 'Firebase/Storage'
	# pod 'Chatto'
	pod 'SDWebImage'
	pod 'SVProgressHUD'
	pod 'SwiftyJSON'
	pod 'Alamofire'
	pod 'ExtraKit'
	pod 'EasyTipView'
	# pod 'FutureKit', :git => 'https://github.com/FutureKit/FutureKit.git', :branch => 'v3'
	# pod 'Classy'
	# pod 'UIImage-ResizeMagick'
end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['ENABLE_BITCODE'] = 'NO'
		end
	end
end
