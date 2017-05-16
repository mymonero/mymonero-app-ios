//
//  HostedMonero_SendingFunds.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/9/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation
import BigInt
//
struct SendFundsTargetDescription
{
	let address: MoneroAddress
	let amount: MoneroAmount
}
//
func FixedMixin() -> Int
{
	return 9 // for now
}
struct HostedMonero_SendFunds
{
	static func estimatedRingCTSize(
		_ numberOfInputs: Int,
		_ mixin: Int,
		_ numberOfOutputs: Int
	) -> Int
	{
		var size = 0
		size += numberOfOutputs * 6306
		size += ((mixin + 1) * 4 + 32 + 8) * numberOfInputs //key offsets + key image + amount
		size += 64 * (mixin + 1) * numberOfInputs + 64 * numberOfInputs //signature + pseudoOuts/cc
		size += 74 //extra + whatever, assume long payment ID
		//
		return size
	}
	static func estimatedRingCTSize_numKB(
		_ numberOfInputs: Int,
		_ mixin: Int,
		_ numberOfOutputs: Int
	) -> Int
	{
		let numKB = Int(ceil(
			Double(estimatedRingCTSize(numberOfInputs, mixin, numberOfOutputs)) / 1024.0
		))
		//
		return numKB
	}
	static func estimatedRingCT_neededNetworkFee(
		_ numberOfInputs: Int,
		_ mixin: Int,
		_ numberOfOutputs: Int
	) -> MoneroAmount
	{
		let est_numKB = estimatedRingCTSize_numKB(numberOfInputs, mixin, numberOfOutputs)
		let est_amount = MoneroAmount("\(est_numKB)")! * MoneroConstants.feePerKB
		//
		return est_amount
	}
}
//
func SendFunds(
	target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
	amount: HumanUnderstandableCurrencyAmountDouble, // human-understandable number, e.g. input 0.5 for 0.5 XMR
	wallet__public_address: MoneroAddress,
	wallet__private_keys: MoneroKeyDuo,
	wallet__public_keys: MoneroKeyDuo,
	mymoneroCore: MyMoneroCore,
	hostedMoneroAPIClient: HostedMoneroAPIClient,
	payment_id: MoneroPaymentID?,
	success_fn: @escaping (
		_ moneroReady_targetDescription_address: MoneroAddress,
		_ final__payment_id: MoneroPaymentID?,
		_ tx_hash: MoneroTransactionHash?,
		_ tx_fee: MoneroAmount
	) -> Void,
	failWithErr_fn: @escaping (
		_ err_str: String
	) -> Void
)
{
	//
	// some callback trampoline func declarations…
	func __trampolineFor_success(
		moneroReady_targetDescription_address: MoneroAddress,
		final__payment_id: MoneroPaymentID?,
		tx_hash: MoneroTransactionHash?,
		tx_fee: MoneroAmount
	) -> Void
	{
		success_fn(
			moneroReady_targetDescription_address,
			final__payment_id,
			tx_hash,
			tx_fee
		)
	}
	func __trampolineFor_err_withStr(err_str: String) -> Void
	{
		NSLog("❌  SendFunds(): \(err_str)")
		failWithErr_fn(err_str)
	}
	// status: preparing to send funds…
	if amount <= 0 {
		__trampolineFor_err_withStr(err_str: "The amount you've entered is too low")
		return
	}
	let totalMoneroAmountWithoutFee = MoneroAmountFromDouble(amount)
	let targetDescription = SendFundsTargetDescription(
		address: target_address,
		amount: totalMoneroAmountWithoutFee
	)
	NSLog("targetDescription \(targetDescription)")
	NSLog("💬  Total to send, before fee: \(totalMoneroAmountWithoutFee)")
	//
	// Derive/finalize some values…
	var final__payment_id = payment_id == "" ? nil : payment_id
	var final__pid_encrypt = false // we don't want to encrypt payment ID unless we find an integrated one
	let final__mixin = FixedMixin()
	if final__mixin < 0 {
		__trampolineFor_err_withStr(err_str: "Invalid mixin")
		return
	}
	mymoneroCore.DecodeAddress(target_address)
	{ (err, decodedAddress) in
		if let _ = err {
			NSLog("TODO: extract error string from error") // TODO: this is not done yet cause i don't know the format of the error yet
			__trampolineFor_err_withStr(err_str: "Error decoding recipient Monero address.")
			return
		}
		guard let decodedAddress = decodedAddress else {
			__trampolineFor_err_withStr(err_str: "Error obtaining decoded recipient Monero address.")
			return
		}
		if decodedAddress.intPaymentId != nil && payment_id != nil {
			__trampolineFor_err_withStr(err_str: "Payment ID field must be blank when using an Integrated Address")
			return
		}
		if decodedAddress.intPaymentId != nil {
			final__payment_id = decodedAddress.intPaymentId
			final__pid_encrypt = true // we do want to encrypt if using an integrated address
		}
		if MyMoneroCoreUtils.IsValidPaymentIDOrNoPaymentID(final__payment_id) == false { // Validation
			__trampolineFor_err_withStr(err_str: "The payment ID you've entered is not valid")
			return
		}
		_proceedTo_getUnspentOutsUsableForMixin()
	}
	func _proceedTo_getUnspentOutsUsableForMixin()
	{
		let _ = hostedMoneroAPIClient.UnspentOuts(
			address: wallet__public_address,
			view_key__private: wallet__private_keys.view,
			spend_key__public: wallet__public_keys.spend,
			spend_key__private: wallet__private_keys.spend,
			mixinNumber: final__mixin,
			{ (err_str, result) in
				if let err_str = err_str {
					__trampolineFor_err_withStr(err_str: err_str)
					return
				}
				_proceedTo_constructTransferListAndSendFundsWithUnusedUnspentOuts(
					result!.unusedOutputs
				)
			}
		)
	}
	func _proceedTo_constructTransferListAndSendFundsWithUnusedUnspentOuts(
		_ unusedOuts: [HostedMoneroAPIClient_Parsing.OutputDescription]
	)
	{ // status: constructing transaction…
		let feePerKB = MoneroConstants.feePerKB
		// Transaction will need at least 1KB fee (13KB for RingCT)
		let network_minimumTXSize_kb = 13 // because isRingCT=true
		let network_minimumFee = feePerKB * BigInt(network_minimumTXSize_kb)
		// ^-- now we're going to try using this minimum fee but the codepath has to be able to be re-entered if we find after constructing the whole tx that it is larger in kb than the minimum fee we're attempting to send it off with
		__reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
			unusedOuts,
			network_minimumFee
		)
	}
	func __reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
		_ unusedOuts: [HostedMoneroAPIClient_Parsing.OutputDescription],
		_ passedIn_attemptAt_network_minimumFee: MoneroAmount
	)
	{ // Now we need to establish some values for balance validation and to construct the transaction
		NSLog("Entered re-enterable tx building codepath…", unusedOuts)
		var attemptAt_network_minimumFee = passedIn_attemptAt_network_minimumFee // we may change this if isRingCT
		let _/*hostingService_chargeAmount*/ = HostedMoneroAPIClient_HostConfig.HostingServiceChargeForTransaction(
			with: attemptAt_network_minimumFee
		)
		var totalAmountIncludingFees = totalMoneroAmountWithoutFee + attemptAt_network_minimumFee/* + hostingService_chargeAmount NOTE service fee removed for now */
		let usableOutputsAndAmounts = _outputsAndAmountToUseForMixin(
			target_amount: totalAmountIncludingFees,
			unusedOuts: unusedOuts
		)
		
		NSLog("usableOutputsAndAmounts \(usableOutputsAndAmounts)")
		
		// v-- now, since isRingCT=true, compute fee as closely as possible before hand
		var usingOuts = usableOutputsAndAmounts.usingOuts
		var usingOutsAmount = usableOutputsAndAmounts.usingOutsAmount
		var remaining_unusedOuts = usableOutputsAndAmounts.remaining_unusedOuts
		if usingOuts.count > 1 {
			var newNeededFee = HostedMonero_SendFunds.estimatedRingCT_neededNetworkFee(usingOuts.count, final__mixin, 2)
			totalAmountIncludingFees = totalMoneroAmountWithoutFee + newNeededFee/* NOTE service fee removed for now, but when we add it back, don't we need to add it to here here? */
			// add outputs 1 at a time till we either have them all or can meet the fee
			while usingOutsAmount < totalAmountIncludingFees && remaining_unusedOuts.count > 0 {
				// pop and return random element from list
				let idx = __randomIndex(remaining_unusedOuts)
				let out = remaining_unusedOuts[idx]
				remaining_unusedOuts.remove(at: idx)
				//
				usingOuts.append(out)
				usingOutsAmount = usingOutsAmount + out.amount
				NSLog("Using output: \(FormattedString(fromMoneroAmount: out.amount)) - \(out)")
				newNeededFee = HostedMonero_SendFunds.estimatedRingCT_neededNetworkFee(usingOuts.count, final__mixin, 2)
				totalAmountIncludingFees = totalMoneroAmountWithoutFee + newNeededFee
			}
			NSLog("New fee: \(FormattedString(fromMoneroAmount: newNeededFee)) for \(usingOuts.count) inputs")
			attemptAt_network_minimumFee = newNeededFee
		}
		NSLog("~ Balance required: \(FormattedString(fromMoneroAmount: totalAmountIncludingFees))")
		// Now we can validate available balance with usingOutsAmount (TODO? maybe this check can be done before selecting outputs?)
		if usingOutsAmount < totalAmountIncludingFees {
			__trampolineFor_err_withStr(err_str:
				"Not enough spendable outputs / balance too low (have: \(FormattedString(fromMoneroAmount: usingOutsAmount)), need: \(FormattedString(fromMoneroAmount: totalAmountIncludingFees)))"
			)
			return
		}
		// Now we can put together the list of fund transfers we need to perform
		var fundTransferDescriptions: [SendFundsTargetDescription] = [] // to build…
		// I. the actual transaction the user is asking to do
		fundTransferDescriptions.append(
			SendFundsTargetDescription(
				address: target_address,
				amount: totalMoneroAmountWithoutFee
			)
		)
		// II. the fee that the hosting provider charges
		// NOTE: The fee has been removed for RCT until a later date
		// fundTransferDescriptions.push({
		//             address: hostedMoneroAPIClient.HostingServiceFeeDepositAddress(),
		//             amount: hostingService_chargeAmount
		// })
		// III. some amount of the total outputs will likely need to be returned to the user as "change":
		func ___proceed()
		{
			__proceedTo__getRandomOutsAndCreateTx(
				fundTransferDescriptions: fundTransferDescriptions,
				usingOuts: usingOuts
			)
		}
		if usingOutsAmount > totalAmountIncludingFees {
			let changeAmount = usingOutsAmount - totalAmountIncludingFees
			NSLog("changeAmount \(changeAmount)")
			// for RCT we don't presently care about dustiness so add entire change amount
			NSLog("Sending change of \(FormattedString(fromMoneroAmount: changeAmount)) to \(wallet__public_address)")
			fundTransferDescriptions.append(
				SendFundsTargetDescription(
					address: wallet__public_address,
					amount: changeAmount
				)
			)
			___proceed()
			//
			return
		}
		if usingOutsAmount == totalMoneroAmountWithoutFee {
			// because isRingCT=true, create random destination to keep 2 outputs always in case of 0 change
			// TODO: would be nice to avoid this asynchrony so ___proceed() can be dispensed with
			mymoneroCore.New_FakeAddressForRCTTx({ (err_str, fakeAddress) in
				NSLog("Sending 0 XMR to a fake address to keep tx uniform (no change exists): \(fakeAddress.debugDescription)")
				if let err_str = err_str {
					__trampolineFor_err_withStr(err_str: err_str)
					return
				}
				fundTransferDescriptions.append(
					SendFundsTargetDescription(
						address: fakeAddress!,
						amount: 0
					)
				)
				___proceed()
			})
			//
			return
		}
		___proceed()
	}
	func __proceedTo__getRandomOutsAndCreateTx(
		fundTransferDescriptions: [SendFundsTargetDescription],
		usingOuts: [HostedMoneroAPIClient_Parsing.OutputDescription]
	)
	{
		NSLog("fundTransferDescriptions so far \(fundTransferDescriptions)")
		// since final__mixin is always going to be > 0, since this function is not specced to support sweep_all…
		let _ = hostedMoneroAPIClient.RandomOuts(
			using_outs: usingOuts,
			mixin: final__mixin,
			{ (err_str, result) in
				if let err_str = err_str {
					__trampolineFor_err_withStr(err_str: err_str)
					return
				}
				__proceedTo_createTxAndAttemptToSend(
					mix_outs: result!.amount_outs
				)
			}
		)
	}
	func __proceedTo_createTxAndAttemptToSend(
		mix_outs: [HostedMoneroAPIClient_Parsing.RandomOuts_AmountAndOutputs]
	)
	{
//		var signedTx;
//		try {
//		NSLog("Destinations: ")
//		monero_utils.printDsts(fundTransferDescriptions)
//		//
//		var realDestViewKey // need to get viewkey for encrypting here, because of splitting and sorting
//		if (final__pid_encrypt) {
//		realDestViewKey = monero_utils.decode_address(moneroReady_targetDescription_address).view
//		NSLog("got realDestViewKey" , realDestViewKey)
//		}
//		var splitDestinations = monero_utils.decompose_tx_destinations(
//		fundTransferDescriptions,
//		isRingCT
//		)
//		NSLog("Decomposed destinations:")
//		monero_utils.printDsts(splitDestinations)
//		//
//		signedTx = monero_utils.create_transaction(
//		wallet__public_keys,
//		wallet__private_keys,
//		splitDestinations,
//		usingOuts,
//		mix_outs,
//		mixin,
//		attemptAt_network_minimumFee,
//		final__payment_id,
//		final__pid_encrypt,
//		realDestViewKey,
//		0,
//		isRingCT
//		)
//		} catch (e) {
//		var errStr;
//		if (e) {
//		errStr = typeof e == "string" ? e : e.toString()
//		} else {
//		errStr = "Failed to create transaction with unknown error."
//		}
//		__trampolineFor_err_withStr(errStr)
//		return
//		}
//		NSLog("signed tx: ", JSON.stringify(signedTx))
//		//
//		var serialized_signedTx;
//		var tx_hash;
//		if (signedTx.version === 1) {
//			serialized_signedTx = monero_utils.serialize_tx(signedTx)
//			tx_hash = monero_utils.cn_fast_hash(raw_tx)
//		} else {
//			let raw_tx_and_hash = monero_utils.serialize_rct_tx_with_hash(signedTx)
//			serialized_signedTx = raw_tx_and_hash.raw
//			tx_hash = raw_tx_and_hash.hash
//		}
//		NSLog("tx serialized: " + serialized_signedTx)
//		NSLog("Tx hash: " + tx_hash)
//		//
//		// work out per-kb fee for transaction and verify that it's enough
//		var txBlobBytes = serialized_signedTx.length / 2
//		var numKB = Math.floor(txBlobBytes / 1024)
//		if (txBlobBytes % 1024) {
//			numKB++
//		}
//		NSLog(txBlobBytes + " bytes <= " + numKB + " KB (current fee: " + monero_utils.formatMoneyFull(attemptAt_network_minimumFee) + ")")
//		let feeActuallyNeededByNetwork = monero_config.feePerKB_JSBigInt.multiply(numKB)
//		// if we need a higher fee
//		if (feeActuallyNeededByNetwork.compare(attemptAt_network_minimumFee) > 0) {
//			NSLog("💬  Need to reconstruct the tx with enough of a network fee. Previous fee: " + monero_utils.formatMoneyFull(attemptAt_network_minimumFee) + " New fee: " + monero_utils.formatMoneyFull(feeActuallyNeededByNetwork))
//			__reenterable_constructFundTransferListAndSendFunds_findingLowestNetworkFee(
//				moneroReady_targetDescription_address,
//				totalAmountWithoutFee_JSBigInt,
//				final__payment_id,
//				final__pid_encrypt,
//				unusedOuts,
//				feeActuallyNeededByNetwork // we are re-entering this codepath after changing this feeActuallyNeededByNetwork
//			)
//			//
//			return
//		}
//		//
//		// generated with correct per-kb fee
//		let final_networkFee = attemptAt_network_minimumFee // just to make things clear
//		NSLog("💬  Successful tx generation, submitting tx. Going with final_networkFee of ", monero_utils.formatMoney(final_networkFee))
//		// status: submitting…
//		hostedMoneroAPIClient.SubmitSerializedSignedTransaction(
//			wallet__public_address,
//			wallet__private_keys.view,
//			serialized_signedTx,
//			{ (err) in
//				if (err) {
//					__trampolineFor_err_withStr("Something unexpected occurred when submitting your transaction:", err)
//					return
//				}
//				let tx_fee = final_networkFee/*.add(hostingService_chargeAmount) NOTE: Service charge removed to reduce bloat for now */
//				__trampolineFor_success(
//					moneroReady_targetDescription_address,
//					amount,
//					final__payment_id,
//					tx_hash,
//					tx_fee
//				) // 🎉
//			}
//		)
	}
}
//
func __randomIndex(_ list: [Any]) -> Int
{
	let randomIndex = Int(arc4random_uniform(UInt32(list.count)))
	return randomIndex
}
func _outputsAndAmountToUseForMixin(
	target_amount: MoneroAmount,
	unusedOuts: [HostedMoneroAPIClient_Parsing.OutputDescription]
) -> (
	usingOuts: [HostedMoneroAPIClient_Parsing.OutputDescription],
	usingOutsAmount: MoneroAmount,
	remaining_unusedOuts: [HostedMoneroAPIClient_Parsing.OutputDescription]
)
{
	NSLog("Selecting outputs to use. target: \(FormattedString(fromMoneroAmount: target_amount))")
	var toFinalize_usingOutsAmount = MoneroAmount(0)
	var toFinalize_usingOuts: [HostedMoneroAPIClient_Parsing.OutputDescription] = []
	var remaining_unusedOuts = unusedOuts // take 'copy' instead of using original so as to prevent issue if we must re-enter tx building fn if fee too low after building
	while toFinalize_usingOutsAmount < target_amount && remaining_unusedOuts.count > 0 {
		// now select and remove a random element from the unused outputs
		let idx = __randomIndex(remaining_unusedOuts)
		let out = remaining_unusedOuts[idx]
		remaining_unusedOuts.remove(at: idx)
		// now select it for usage
		let out_amount = out.amount
		toFinalize_usingOuts.append(out)
		toFinalize_usingOutsAmount = toFinalize_usingOutsAmount + out_amount
		NSLog("Using output: \(FormattedString(fromMoneroAmount: out_amount)) - \(out)")
	}
	return (
		usingOuts: toFinalize_usingOuts,
		usingOutsAmount: toFinalize_usingOutsAmount,
		remaining_unusedOuts: remaining_unusedOuts
	)
}
