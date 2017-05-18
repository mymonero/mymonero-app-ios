# MyMonero iOS App (Swift)

## Status

1. Built working port of MyMonero core code from JS with certain elements ported directly to Swift to retain synchrony and the remainder executed within a Swift-bridged `WKWebView`

2. Built initial `HostedMoneroAPIClient` implementation via Alamofire (account info and OA endpoints TODO)

3. Prototype tests currently reside in `Modules/App/Controllers/RuntimeController` and will be moved to a unit test or temporary location.

## Next milestones

1. Minor cleanups & review

2. Business logic, persistence

3. UI

## Installation

### Pre-requisites

1. Xcode
2. Cocoapods (installable with `sudo gem install cocoapods`)
3. Node.JS and npm

### Instructions

1. Clone or download this repo

2. `cd` into the repo directory

3. Run `./bin/setup`. This will set up `./Modules/MyMoneroCore` and do a `pod install`.

## Running

1. Open `./MyMonero.xcworkspace` in Xcode

2. Build & run
