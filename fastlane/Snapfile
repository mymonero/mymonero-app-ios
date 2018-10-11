# Uncomment the lines below you want to change by removing the # in the beginning

# A list of devices you want to take the screenshots from
devices([
	"iPhone X"#,
	# "iPhone 8",
	# "iPhone 8 Plus"#,
	# "iPhone SE",
	# "iPad Pro (12.9-inch)"
])

languages([
  "en-US"
])

# Arguments to pass to the app on launch. See https://github.com/fastlane/snapshot#launch_arguments
# launch_arguments("-favColor red")

# The name of the scheme which contains the UI Tests
scheme "MyMonero"
workspace "./MyMonero.xcworkspace"
# app_identifier "com.mymonero.mymonero-app-testing" #using the same bundle ID as app store
# ios_version "11.3"  # will this need to be set?

# clear_previous_screenshots true
number_of_retries 0 # it's not going to be able to clear the Sim between retries (apparently) so it's not useful
# reinstall_app true #may get tripped up otherwise?
stop_after_first_error true
concurrent_simulators false #can it handle it?
# clean true #may get tripped up otherwise?
# erase_simulator true #may get tripped up otherwise?

output_directory "./screenshots"

# For more information about all available options run
# snapshot --help
