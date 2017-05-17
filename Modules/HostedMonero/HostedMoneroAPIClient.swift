//
//  HostedMoneroAPIClient.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/12/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
//
typealias HostedMoneroAPIClient_RequestHandle = String // TODO: via Alamofire
//
struct HostedMoneroAPIClient_Parsing
{
	struct ParsedResult_TXTRecords
	{
		let records: [String]
		let dnssec_used: Bool
		let secured: Bool
		let dnssec_fail_reason: String?
	}
	struct ParsedResult_UnspentOuts
	{
		let unspentOutputs: [MoneroOutputDescription]
		let unusedOutputs: [MoneroOutputDescription]
	}
	struct ParsedResult_RandomOuts
	{
		let amount_outs: [MoneroRandomAmountAndOutputs]
	}
}
//
enum HostedMoneroAPI_Endpoints: String
{
	case UnspentOuts = "get_unspent_outs"
	case RandomOuts = "get_random_outs"
	case TXTRecords = "get_txt_records"
	case SubmitSerializedSignedTransaction = "submit_raw_tx"
}
//
struct HostedMoneroAPIClient_HostConfig
{
	static let hostDomainPlusPortPlusSlash = "api.mymonero.com:8443/"
	static let protocolScheme = "https"
	//
	static let hostingServiceFee_depositAddress = "49VNLa9K5ecJo13bwKYt5HCmA8GkgLwpyFjgGKG6qmp8dqoXww8TKPU2PJaLfAAtoZGgtHfJ1nYY8G2YaewycB4f72yFT6u"
	static let hostingServiceFee_txFeeRatioOfNetworkFee = 0.5 // Service fee relative to tx fee (0.5 => 50%)
	//
	static func HostingServiceChargeForTransaction(with networkFee: MoneroAmount) -> MoneroAmount
	{
		let feeRatioReciprocalInteger = MoneroAmount(UInt(1.0/hostingServiceFee_txFeeRatioOfNetworkFee)) // instead of just *, because ratio is not an integer
		let amount = networkFee / feeRatioReciprocalInteger
		return amount
	}
}
//
class HostedMoneroAPIClient
{
	init() {
		setup()
	}
	func setup()
	{
	}
	
	// 
	//
	// Open alias lookup - this should be replaced with a lookup implemented
	// on the client, so we can actually use DNSSEC etc
	//
	func TXTRecords(
		openAlias_domain: String,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_TXTRecords?
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle?
	{
		let endpointPath = HostedMoneroAPI_Endpoints.TXTRecords
		let requestHandle = "" // TODO
		let err_str: String? = nil
		let records = [String]()
		let result = HostedMoneroAPIClient_Parsing.ParsedResult_TXTRecords(
			records: records,
			dnssec_used: false,
			secured: false,
			dnssec_fail_reason: nil
		)
		DispatchQueue.main.async {
			fn(err_str, result)
		}
		return requestHandle
	}
	//
	//
	// Sending funds
	//
	func UnspentOuts(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		spend_key__public: MoneroKey,
		spend_key__private: MoneroKey,
		mixinNumber: Int,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts?
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle?
	{
		let parameters: [String: Any] =
		[
			"address": address,
			"view_key": view_key__private,
			"amount": "0",
			"mixin": mixinNumber,
			"use_dust": mixinNumber == 0, // Use dust outputs only when we are using no mixins
			"dust_threshold": String(MoneroConstants.dustThreshold, radix: 10)
		]
		let endpointPath = HostedMoneroAPI_Endpoints.UnspentOuts
		let requestHandle = "" // TODO
		var unspentOutputs: [MoneroOutputDescription] = [] // mocked
		var unusedOutputs: [MoneroOutputDescription] = [] // mocked
		//
		let dateFormatter = MyMoneroJSON_dateFormatter
		let unspentOut = MoneroOutputDescription(
			amount: MoneroAmount(""),
			public_key: "",
			index: ,
			globalIndex: ,
			rct: "",
			tx_id: ,
			tx_hash: "",
			tx_pub_key: "",
			tx_prefix_hash: "",
			spend_key_images: [
				"", // TODO
			],
			timestamp: dateFormatter.date(from: "")!,
			height:
		)
		unspentOutputs.append(unspentOut)
		//
		let unusedOut = MoneroOutputDescription(
			amount: MoneroAmount(""),
			public_key: "",
			index: 0,
			globalIndex: ,
			rct: "",
			tx_id: ,
			tx_hash: "",
			tx_pub_key: "",
			tx_prefix_hash: "",
			spend_key_images: [],
			timestamp: dateFormatter.date(from: "")!,
			height:
		)
		unusedOutputs.append(unusedOut)
		//
		let result = HostedMoneroAPIClient_Parsing.ParsedResult_UnspentOuts(
			unspentOutputs: unspentOutputs,
			unusedOutputs: unusedOutputs
		)
		DispatchQueue.main.async {
			fn(nil, result)
		}
		return requestHandle
	}
	func RandomOuts(
		using_outs: [MoneroOutputDescription],
		mixin: Int,
		_ fn: @escaping (
			_ err_str: String?,
			_ result: HostedMoneroAPIClient_Parsing.ParsedResult_RandomOuts?
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle?
	{
		if (mixin < 0) {
			fn("Invalid mixin - must be >= 0", nil)
			return nil
		}
		//
		var amounts = [String]()
		for (_, using_out_desc) in using_outs.enumerated() {
			amounts.append(using_out_desc.rct != nil ? "0" : String(using_out_desc.amount))
		}
		let parameters: [String: Any] =
		[
			"amounts": amounts,
			"count": mixin + 1 // Add one to mixin so we can skip real output key if necessary
		]
		let endpointPath = HostedMoneroAPI_Endpoints.RandomOuts
		let requestHandle = "" // TODO
		var amount_outs: [MoneroRandomAmountAndOutputs] = []
		//
		// MOCKED DATA:
		let amountAndOutputs_1 = MoneroRandomAmountAndOutputs(
			amount: MoneroAmount("0"),
			outputs: [
				MoneroRandomOutputDescription(
					globalIndex: "710877",
					public_key: "6d06a0480b68863604b957d857b9f335ad4c86b275d4d048e1ddeb6d37f0f1ef",
					rct: "b1c12696d8be66ec84e6b0c18c5125a2483d3f6e984ddfb26cb74ae4ff8dcc3ffed779dad241dd0ace12e47de257c5bc6bf13e7b614dc10b824e07300646d60bd7c14fc37fce5a1542ff723dafddd3e5adbd25f11c560c76bb5400ca8332a20b"
				),
				MoneroRandomOutputDescription(
					globalIndex: "477646",
					public_key: "3aeacf5454ce70aa0b6b1d052ab1eff629db62cc3f05bf4294b4567e03e377f2",
					rct: "4466aacb56d1b74d3957f615a6b2414b551ead1f8849f2beb133281127343891c7d95b4169a4d8e6158784c3fa42e85c4c1ab19e32fa4b37309f9b7a8ecdb407bef1b3c41d36911c68995b79530a6459dbc4107b3187b58a550ba6487aba1e07"
				),
				MoneroRandomOutputDescription(
					globalIndex: "755066",
					public_key: "fd103723b9f34130b7ab8ab5f002dc3c1bd76bd9a05106a9100f34671c831a1a",
					rct: "266b948022382f8fe27ab4747a9a641838be2e2d10e1ff3d6bf87d9e2c8b53a71444a64a5530204e11815ef708dada49cc6929da0711bd225851a3e2d19fcf05005f365f1e6841517427850e68288c461aa332e1540163895b9e768598040f09"
				),
				MoneroRandomOutputDescription(
					globalIndex: "590717",
					public_key: "c7d7a77cd2bfbabe2cd2c4d6d8f6f216555a12ae985ba967f63a166964b00787",
					rct: "5e33a6c3ecd7a82a6f52359f59ed236092f4567e4f4e4f858ec4b98619c67c36245474bca43d8ca01994a249a0a03d1936002411e57d6ba615daf61229761808af041c3abaf178f3e15bc12a816379e3e55876547d3e9ef0eab573a84f441f00"
				),
				MoneroRandomOutputDescription(
					globalIndex: "377024",
					public_key: "fde4645959771da72168b105f6dbc09f37d95749a9b8f2e9f637ad30d66b9bd7",
					rct: "8c764493e46c47473013e5990e54f8d0cfa4f6020c3d61aa0f40bebc84540b1700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
				),
				MoneroRandomOutputDescription(
					globalIndex: "461596",
					public_key: "d21c8dcbb3e83b44a39aa100fdc82e2ec267b656578f097233de6360c36b2d10",
					rct: "0b289745ac427678843f9f18c3c7550d5458f95cf779afad83b521762bec613b45429d96eb949435b4e2262de2ce052a1238c60c8d6bf1d4c7865f5c6fa8ad00ff1f4636833dfbf563cdb4588872d3e076ea9e7a31d1d6f61ce60ebf4f279402"
				),
				MoneroRandomOutputDescription(
					globalIndex: "744662",
					public_key: "7166de12b549a18dd2a885ecd99327a0c84b9a800e39b878bcb1d541b74040be",
					rct: "b41df374f4cf31c5624c21afd535a4c769b926a772cb10f6dacc44283f96d8c24d61921a72d0bed8205ed617a54b48b09c205440b46a07e992bed6a4daf7c80ca1422bd9440056c016e18d284b9dc64fd14f1fcfb6b6a7ed3d934e85c0440507"
				),
				MoneroRandomOutputDescription(
					globalIndex: "717488",
					public_key: "a84df4d58462fc6d32c801c5d7b438aa42202ac735cd2117c67ed980078eb7e0",
					rct: "d35dcdd76c1d5d4a119f974aa71e3a85c975b3d676d525dd0594c56c7400f6e2792edf7116fe4a2f588338a9fb7ea81b1835fca2fd4c02ed15f656927e50590993607ec5fd7ba0ad3bd27eaaa09ff42e4037468fc2a6dbf668fa596a4e9de608"
				),
				MoneroRandomOutputDescription(
					globalIndex: "169380",
					public_key: "85189ffed7c1736b5a014b75063151a2288e3469be27a353dbeb0d0b6bbd1bc8",
					rct: "d8a4344e0ab5f3cee934e6a9d1251085d0823cfcc13f830622e72bd4d37b03fd55eebce8cfd546f8ffd20434a186ee09ea39a11e72db76fe39b564e99e452706c57ea0e4b818a168671c63091a2e0e764057cf7738d25a6e08f9cbbde59fe80f"
				),
				MoneroRandomOutputDescription(
					globalIndex: "106629",
					public_key: "f0ee70ef5d075f3f416124ebd261d1e2def574b82acbbc5e027ceaf782bfbfc9",
					rct: "87c48188b15bf80eddc4ab14c43bd9940b73522b6b5424a680c3aaf8633e304b3db9a6eaf30c68f462834a2a608a9f77201568fd37c6c64098aafb8f33f02b069772a264439ddb2a2ebd8432e8829ed28e6d4de6be0f84481c5de4f0a9b11909"
				)
			]
		)
		amount_outs.append(amountAndOutputs_1)
		let amountAndOutputs_2 = MoneroRandomAmountAndOutputs(
			amount: MoneroAmount("0"),
			outputs: [
				MoneroRandomOutputDescription(
					globalIndex: "8857",
					public_key: "3e113f6c698679b2f464391ee941d1bbbba1f46d73e25314e1ac08f5a92e9233",
					rct: "bf01925c1c51511c4b242477c0bb92d0998cfaf451e0e93fdba038f5c5f88771c7e89007dd462f5f0f5697e434711a2efd53b0e96abc06cb81ccee685e31f80ced7b1c5968a0a738bb59d06ee79e62a6f9c31270bd55134bdf6ef4580fe94604"
				),
				MoneroRandomOutputDescription(
					globalIndex: "659954",
					public_key: "071a3509c6ecaa710e103efe6e47e78ade50f75309eec4c8b6136ef76db0f416",
					rct: "83c7a750e163b66a6614095038a12c43edfcaffeef035304b082a1a2619d032a5492dcfa37360287794ff97a9fff65f7197732e9091e5aca160737c6c0665b0bea8cdabf6b861468faec1140b60dd9ebb84eae58ba51e04531d14aa22400950e"
				),
				MoneroRandomOutputDescription(
					globalIndex: "62739",
					public_key: "a5e2a459b05c6092ab42f5c5886a2f910add629ad62424a21d7d629f3f7ad5d7",
					rct: "19b8e9a5d5c2bd941921e8c1d2304c1fabac17c022a16995d01ebbd45d85a472ed26d7a898becc61e1d6b5fbc1e10805bfbb43fc7ae767180beb77b3fa1c7801ab1386a4cd20d6754c2474c7a936eac640ea232311b7eb786d6319aceda75b01"
				),
				MoneroRandomOutputDescription(
					globalIndex: "659697",
					public_key: "a6ef8477708df73a041a84d8340e4a1592ad6fe06b61eab7cd3fa13e2a8d781d",
					rct: "2ea05bcd1d9cd964897355f05412f427a127117f3aa73111b176578051c283e9a6d1d7169813fc21e72553791873d484fd602fc2663e8dd6565404ef72919502bf7d3717a155de8630984cabb4b5c0f5c593ad307cb90bb4fc54a9bfda7a4a0e"
				),
				MoneroRandomOutputDescription(
					globalIndex: "315922",
					public_key: "a92324a738ec40a591a58afe9611b4c35eb9c7647b6bf91d92bfc6fd5fa6034c",
					rct: "b20ef0d6e42941c79ddce2e98d23be4141a79aa348d23b5f5656bc502c29b35cc83c27273ce54bee96d500b9bafd1b82476ed68cd62d6f1e3ffd126e9fd1bd06ab178755907a168160a681ca1ea1eb83380262761c50e4feb2f79be1d62a4601"
				),
				MoneroRandomOutputDescription(
					globalIndex: "582870",
					public_key: "ee822f92beff82b6c55377bca9178feb52a11b82954a929e0f7ccdb6b8d991a7",
					rct: "01bd3d5c340b195826af3c370141c37036bec2451a2e2d4b5c6842830ca1c99733cbe0ee1dcf72ed63224b9cd72cf9ffe211a61050e9a6cd704dc825aa87be00f7ac7c5a13196bc119184d55cb59a74bc4e9b28bc718498af0fc252d4648ec0b"
				),
				MoneroRandomOutputDescription(
					globalIndex: "222834",
					public_key: "ab51d179f8f8e9802aa38aa2442f104423e555c481dd5de26dc84e3c131b89c6",
					rct: "d878a43b218e9b61257b17a9ea74979d30bfc5f3f9cf890fc65cfbe1b266e36c16210c3979c6a00b077a014cf8621a374718e7c5683f2f2d914710c4c680c108e803abcb508d11b738391b86259ee37e2f121050eb5588b1224cb7fb8c78d50a"
				),
				MoneroRandomOutputDescription(
					globalIndex: "463393",
					public_key: "f7ee54f21c8973a28fec93d3bb5bc417b3089036c5df7e7e4ad09c3dc32412fe",
					rct: "d39cb97020b66486ca54aafb1f88d8763f132d0026a7b719fc4e5d23bafd6f012c4e1fc29af9b72b824f64ddeb0f86e4da9fcd264f3fc24143c63cfcd569c702444eb4af535c16182056065e700733ca198ee23d98e0403acb3875499dc3d80f"
				),
				MoneroRandomOutputDescription(
					globalIndex: "307749",
					public_key: "7506142a6d0825dd19a9db429658ec40d19704192bcc2db6c681aa2c521ed3a9",
					rct: "f65cea1eb0ba7be4ae87fe639e265879a8b368bde7a5a94cb48d29587a2344646e2fec78fefacf0464684e6183c2767e14839e1090c5820a74efe608d38e800166b84d0ddd45779dc111730fb0b5585d3b4df96af648d029b79d41272b09610c"
				),
				MoneroRandomOutputDescription(
					globalIndex: "721738",
					public_key: "ff8c5cc2c605048222bd60a99ac47b64b101965a4e5040b988de870e0074f5b6",
					rct: "233de7a2b7a7c2a4824aab2daf4d0541b184149ca823132e26fc3e9900e05bd330975777f23813f27e7f1b7bc0e08b4eb8aebb505d0ab840b262979f417bc302210ea5017ebba8ce02055e9d16195bbb61252312cc06fd49612f2ab8d13d7800"
				)
			]
		)
		amount_outs.append(amountAndOutputs_2)
		//
		let result = HostedMoneroAPIClient_Parsing.ParsedResult_RandomOuts(amount_outs: amount_outs)
		DispatchQueue.main.async {
			fn(nil, result)
		}
		return requestHandle
	}
	func SubmitSerializedSignedTransaction(
		address: MoneroAddress,
		view_key__private: MoneroKey,
		serializedSignedTx: MoneroSerializedSignedTransaction,
		_ fn: @escaping (
			_ err_str: String? // if nil, succeeded
		) -> Void
	) -> HostedMoneroAPIClient_RequestHandle?
	{
		
		let requestHandle = "" // TODO
		fn(nil)
		return requestHandle
	}
}
