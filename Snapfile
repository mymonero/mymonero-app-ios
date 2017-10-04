# Uncomment the lines below you want to change by removing the # in the beginning

# A list of devices you want to take the screenshots from
devices([
  "iPhone2017-C", #"iPhone X",
  "iPhone2017-A", # "iPhone 8"
  "iPhone2017-B", # "iPhone 8 Plus"
  "iPhone SE",
  "iPad (5th generation)",
  "iPad Pro (10.5-inch)"
])

languages([
  "en-US"
])

# Arguments to pass to the app on launch. See https://github.com/fastlane/snapshot#launch_arguments
# launch_arguments("-favColor red")

# The name of the scheme which contains the UI Tests
scheme "MyMonero"

output_directory "./screenshots"

clear_previous_screenshots true
concurrent_simulators false # doesn't seem to be able to handle it just yet

workspace "./MyMonero.xcworkspace"

# For more information about all available options run
# snapshot --help
