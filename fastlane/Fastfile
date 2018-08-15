lane :screenshots do
  capture_screenshots 
  frame_screenshots(black: true)
  upload_to_app_store
end

# lane :release do
#   capture_screenshots                  # generate new screenshots for the App Store
#   sync_code_signing(type: "appstore")  # see code signing guide for more information
#   build_app(scheme: "MyMonero",
#             workspace: "MyMonero.xcworkspace",
#             include_bitcode: true)
#   upload_to_app_store                  # upload your app to iTunes Connect
# end