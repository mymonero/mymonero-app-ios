# MyMonero for iOS

## License and Copyrights

See `LICENSE.txt` for license.

All app source code and assets copyright © 2014-2017 by MyMonero. All rights reserved.

## Architecture Notes

* `MyMoneroCore`: Bridged MyMonero JS app core crypto code via async Swift calls; implemented specific functionality in Swift to keep synchrony 

* `Persistence`, `Lists`, `Passwords`: Object encryption, document persistence, password management, and business object implementations nearly equivalent to [MyMonero JS app](https://github.com/mymonero/mymonero-app-js) with various improvements
	* *Of note:* This iOS app presently encrypts whole document; JS app encrypts values at specified keys

* `OpenAlias`, `DNSLookup`: DNS lookup of TXT record content for OpenAlias address resolution now implemented via zero-configuration system-level API (`dnssd`) instead of via server API endpoint, enabling proper DNSSEC status validation

* `UICommonComponents/WalletPicker`: Diverged from JS app and original design due to mobile-specific UI by implementing wallet picker as a custom keyboard rather than hovering dropdown list.

## Repository Setup

### Pre-requisites

* Xcode

* Cocoapods (installable with `sudo gem install cocoapods`)

* Node.JS and npm (to run `setup` script to build `MyMoneroCore` dependency JS bundle file)

### Steps

1. Clone or download this repo.s

2. `cd` into the repo directory.

3. **Important:** Run `./bin/setup`. 
	* This will set up `./Modules/MyMoneroCore` and do a `pod install`.

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

If you have an improvement to the MyMonero iOS app source code and would like to have your code considered for usage in the production MyMonero iOS app, we'll be happy to review any pull requests. 

The maintainer will merge nearly anything which is not destructive, which is on-brand from a design standpoint, and generally production-ready in terms of its code quality, case coverage, problem-solution fit, UI implementation parity with exact design, security, performance, et al. The maintainer enjoys collaborating with contributors to the MyMonero iOS and JS apps over IRC private message and the #mymonero room on freenode.net (Come say hello!), so PR'd submissions do not have to be at all complete or perfect on their first submission. (To submit a draft PR for review, simply mark it as '[DO NOT MERGE]')


### Donating

MyMonero Donation Address (XMR): 48yi8KBxh7fdZzwnX2kFCGALRcN1sNjwBHDfd5i9WLAWKs7G9rVbXNnbJTqZhhZCiudVtaMJKrXxmBeBR9kggBXr8X7PxPT

Proceeds from donations are used to fund development on the MyMonero back-end server (a performant version of which we soon™ plan to open-source for anyone to run their own server at home). Any remaining funds will go towards product (app UI) R&D, and hosting costs.


## Main Contributors

Contributors to each release are credited in release notes.

### Core

* ⛰ `endogenic` ([Paul Shapiro](https://github.com/paulshapiro)) Repo maintainer; Lead developer; MyMonero partner

* 🌅 `vtnerd` ([Lee Clagett](https://github.com/vtnerd)) MyMonero lead back-end developer

* 🐴 `fluffypony` ([Riccardo Spagni](https://github.com/fluffypony)) Advisor; MyMonero partner; Monero core team member

* 🍄 `luigi` Monero tech advisor; Main MyMonero JS core crypto contributor


### Ongoing Volunteers

* 👑 `john_alan` iOS engineer