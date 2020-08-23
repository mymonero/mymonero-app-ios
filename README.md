# MyMonero for iOS

## License and Copyrights

See `LICENSE.txt` for license.

All app source code and assets copyright © 2014-2019 by MyMonero. All rights reserved.

## Architecture Notes

* `MyMoneroCore`: Bridged MyMonero JS app core crypto code via async Swift calls; implemented specific functionality in Swift to keep synchrony 

* `Persistence`, `Lists`, `Passwords`: Object encryption, document persistence, password management, and business object implementations nearly equivalent to [MyMonero JS app](https://github.com/mymonero/mymonero-app-js) with various improvements
	* *Of note:* This iOS app presently encrypts whole document; JS app encrypts values at specified keys. This can and possibly should be ported to the JS app for simplicity.

* `OpenAlias`, `DNSLookup`: DNS lookup of TXT record content for OpenAlias address resolution now implemented via zero-configuration system-level API (`dnssd`) instead of via server API endpoint, enabling proper DNSSEC status validation

* `UICommonComponents`
	* `WalletPicker`: Diverged from JS app and original design due to mobile-specific UI by implementing wallet picker as a custom keyboard rather than hovering dropdown list.
	* `ContactPicker`: Now manages display of any 'Detected' fields (address and payment ID), and now encapsulates actual OA lookup call so it's not repeated. This can/should be ported to the JS app.

* There are still various namespacing improvements which can be made to the earlier Swift code and `Forms` - e.g. `FormViewController` should become `Forms.ViewController`, `FormInputField` should become `Forms.InputField`, etc. in the manner of `UICommonComponents/Details`.


## Repository Setup

### Pre-requisites

* Xcode

* Cocoapods (installable with `sudo gem install cocoapods`)

* Node.JS and npm (to run `setup` script to build `MyMoneroCore` dependency JS bundle file)

### Steps

1. Clone or download this repo.s

2. `cd` into the repo directory.

3. **For development/bleeding edge**: Run `git checkout develop`.

3. **Important:** Run `./bin/setup`. 
	* This will set up `./Modules/MyMoneroCore`, download the required submodules, and do a `pod install`.

	* NOTE: If you ever need to pull the latest submodule commits, you can run `bin/update_submodules`.

## Running the iOS app

1. Open `./MyMonero.xcworkspace` in Xcode.

2. Select the desired target device.

2. Build & run.



--------------

## Contributing

### Testing

Please submit any bugs as Issues unless they have already been reported.

Suggestions and feedback are very welcome!


### Developing

**NOTE:** Not every enhancement or GitHub issue which applies to this repository has been created in this repo in situations where the same item needs to be done for the MyMonero JS app as well. For a complete picture of open items for the iOS app, please also look at Issues labeled "[All app platforms](https://github.com/mymonero/mymonero-app-js/issues?q=is%3Aissue+is%3Aopen+label%3A%22all+app+platforms%22)" on the [JS app repo](https://github.com/mymonero/mymonero-app-js).

If you have an improvement to the MyMonero iOS app source code and would like to have your code considered for usage in the production MyMonero iOS app, we'll be happy to review any pull requests and ship your code in the production app. 

The maintainer will merge nearly anything which is not destructive, which is on-brand from a design standpoint, and generally production-ready in terms of its code quality, case coverage, problem-solution fit, UI implementation parity with exact design, security, performance, et al. Contributors to the MyMonero iOS and JS apps frequently collaborate over IRC private message and in the #mymonero room on freenode.net (Come say hello!), so PR'd submissions do not have to be at all complete or perfect on their first submission. (To submit a draft PR for review, simply mark it as '[DO NOT MERGE]')


### Donating

MyMonero Donation Address (XMR): 48yi8KBxh7fdZzwnX2kFCGALRcN1sNjwBHDfd5i9WLAWKs7G9rVbXNnbJTqZhhZCiudVtaMJKrXxmBeBR9kggBXr8X7PxPT

Proceeds from donations are used to fund development on the MyMonero back-end server (a performant version of which we soon™ plan to open-source for anyone to run their own server at home). Any remaining funds will go towards product (app UI) R&D, and hosting costs.


## Authors & Contributors

We try to credit each contributor in App Store release notes.

* ⛰ `endogenic` ([Paul Shapiro](https://github.com/paulshapiro)) Maintainer; Lead developer

* 🔥 `mds` ([Matt Smith](http://mds.is)) Mobile app variant designer

* 👑 `john_alan` iOS Engineer / Implemented Preferences slider and switch control views 
