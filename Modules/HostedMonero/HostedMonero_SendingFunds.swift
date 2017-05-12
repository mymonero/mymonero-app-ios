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
	let amount: HumanUnderstandableCurrencyAmountDouble
}
//
func SendFunds(
	target_address: MoneroAddress, // currency-ready wallet address, but not an OA address (resolve before calling)
	amount: HumanUnderstandableCurrencyAmountDouble, // human-understandable number, e.g. input 0.5 for 0.5 XMR
	wallet__public_address: MoneroAddress,
	wallet__private_keys: MoneroKeyDuo,
	wallet__public_keys: MoneroKeyDuo,
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
	//
	// parse & normalize the target descriptions by mapping them to Monero addresses & amounts
	let targetDescription = SendFundsTargetDescription(
		address: target_address,
		amount: amount
	)
	NSLog("targetDescription \(targetDescription)")
//	let totalAmountWithoutFee_BigInt = BigInt.init(
//		var totalAmountWithoutFee_JSBigInt = (new JSBigInt(0)).add(moneroReady_targetDescription_amount)
//		NSLog("💬  Total to send, before fee: " + monero_utils.formatMoney(totalAmountWithoutFee_JSBigInt));
//		if (totalAmountWithoutFee_JSBigInt.compare(0) <= 0) {
//			let errStr = "The amount you've entered is too low"
//			__trampolineFor_err_withStr(errStr)
//			return
//		}
//		//
//		// Derive/finalize some values…
//		var final__payment_id = payment_id
//		var final__pid_encrypt = false // we don't want to encrypt payment ID unless we find an integrated one
//		var address__decode_result;
//		try {
//		address__decode_result = monero_utils.decode_address(moneroReady_targetDescription_address)
//		} catch (e) {
//		__trampolineFor_err_withStr(typeof e === 'string' ? e : e.toString())
//		return
//		}
//		if (address__decode_result.intPaymentId && payment_id) {
//			let errStr = "Payment ID field must be blank when using an Integrated Address"
//			__trampolineFor_err_withStr(errStr)
//			return
//		}
//		if (address__decode_result.intPaymentId) {
//			final__payment_id = address__decode_result.intPaymentId
//			final__pid_encrypt = true // we do want to encrypt if using an integrated address
//		}
//		//
//		// Validation
//		if (monero_paymentID_utils.IsValidPaymentIDOrNoPaymentID(final__payment_id) === false) {
//			let errStr = "The payment ID you've entered is not valid"
//			__trampolineFor_err_withStr(errStr)
//			return
//		}
//		//
//		_proceedTo_getUnspentOutsUsableForMixin(
//			moneroReady_targetDescription_address,
//			totalAmountWithoutFee_JSBigInt,
//			final__payment_id,
//			final__pid_encrypt
//		)
//	}
//	func _proceedTo_getUnspentOutsUsableForMixin(
//		moneroReady_targetDescription_address,
//		totalAmountWithoutFee_JSBigInt,
//		final__payment_id, // non-existent or valid
//		final__pid_encrypt // true or false
//		)
//	{
//		hostedMoneroAPIClient.UnspentOuts(
//			wallet__public_address,
//			wallet__private_keys.view,
//			wallet__public_keys.spend,
//			wallet__private_keys.spend,
//			mixin,
//			{(
//				err,
//				unspentOuts,
//				unusedOuts
//				) in
//			
//				if (err) {
//					__trampolineFor_err_withErr(err)
//					return
//				}
//				_proceedTo_letructFundTransferListAndSendFundsByUsingUnusedUnspentOutsForMixin(
//					moneroReady_targetDescription_address,
//					totalAmountWithoutFee_JSBigInt,
//					final__payment_id,
//					final__pid_encrypt,
//					unusedOuts
//				)
//			}
//		)
//	}
//	func _proceedTo_letructFundTransferListAndSendFundsByUsingUnusedUnspentOutsForMixin(
//		moneroReady_targetDescription_address,
//		totalAmountWithoutFee_JSBigInt,
//		final__payment_id,
//		final__pid_encrypt,
//		unusedOuts
//		)
//	{
//		// status: letructing transaction…
//		let feePerKB_JSBigInt = monero_config.feePerKB_JSBigInt
//		// Transaction will need at least 1KB fee (13KB for RingCT)
//		let network_minimumTXSize_kb = isRingCT ? 13 : 1
//		var network_minimumFee = feePerKB_JSBigInt.multiply(network_minimumTXSize_kb)
//		// ^-- now we're going to try using this minimum fee but the codepath has to be able to be re-entered if we find after letructing the whole tx that it is larger in kb than the minimum fee we're attempting to send it off with
//		__reenterable_letructFundTransferListAndSendFunds_findingLowestNetworkFee(
//			moneroReady_targetDescription_address,
//			totalAmountWithoutFee_JSBigInt,
//			final__payment_id,
//			final__pid_encrypt,
//			unusedOuts,
//			network_minimumFee
//		)
//	}
//	func __reenterable_letructFundTransferListAndSendFunds_findingLowestNetworkFee(
//		moneroReady_targetDescription_address,
//		totalAmountWithoutFee_JSBigInt,
//		final__payment_id,
//		final__pid_encrypt,
//		unusedOuts,
//		passedIn_attemptAt_network_minimumFee
//		)
//	{ // Now we need to establish some values for balance validation and to letruct the transaction
//		NSLog("Entered re-enterable tx building codepath…", unusedOuts)
//		var attemptAt_network_minimumFee = passedIn_attemptAt_network_minimumFee // we may change this if isRingCT
//		// let hostingService_chargeAmount = hostedMoneroAPIClient.HostingServiceChargeFor_transactionWithNetworkFee(attemptAt_network_minimumFee)
//		var totalAmountIncludingFees = totalAmountWithoutFee_JSBigInt.add(attemptAt_network_minimumFee)/*.add(hostingService_chargeAmount) NOTE service fee removed for now */
//		let usableOutputsAndAmounts = _outputsAndAmountToUseForMixin(
//			totalAmountIncludingFees,
//			unusedOuts,
//			isRingCT
//		)
//		// v-- now if RingCT compute fee as closely as possible before hand
//		var usingOuts = usableOutputsAndAmounts.usingOuts
//		var usingOutsAmount = usableOutputsAndAmounts.usingOutsAmount
//		var remaining_unusedOuts = usingOutsAmount.remaining_unusedOuts
//		if (isRingCT) {
//			if (usingOuts.length > 1) {
//				var newNeededFee = new JSBigInt(Math.ceil(monero_utils.estimateRctSize(usingOuts.length, mixin, 2) / 1024)).multiply(monero_config.feePerKB_JSBigInt)
//				totalAmountIncludingFees = totalAmountWithoutFee_JSBigInt.add(newNeededFee)
//				// add outputs 1 at a time till we either have them all or can meet the fee
//				while (usingOutsAmount.compare(totalAmountIncludingFees) < 0 && remaining_unusedOuts.length > 0) {
//					let out = _popAndReturnRandomElementFromList(remaining_unusedOuts)
//					usingOuts.push(out)
//					usingOutsAmount = usingOutsAmount.add(out.amount)
//					NSLog("Using output: " + monero_utils.formatMoney(out.amount) + " - " + JSON.stringify(out))
//					newNeededFee = new JSBigInt(
//						Math.ceil(monero_utils.estimateRctSize(usingOuts.length, mixin, 2) / 1024)
//						).multiply(monero_config.feePerKB_JSBigInt)
//					totalAmountIncludingFees = totalAmountWithoutFee_JSBigInt.add(newNeededFee)
//				}
//				NSLog("New fee: " + monero_utils.formatMoneySymbol(newNeededFee) + " for " + usingOuts.length + " inputs")
//				attemptAt_network_minimumFee = newNeededFee
//			}
//		}
//		NSLog("~ Balance required: " + monero_utils.formatMoneySymbol(totalAmountIncludingFees))
//		// Now we can validate available balance with usingOutsAmount (TODO? maybe this check can be done before selecting outputs?)
//		let usingOutsAmount_comparedTo_totalAmount = usingOutsAmount.compare(totalAmountIncludingFees)
//		if (usingOutsAmount_comparedTo_totalAmount < 0) {
//			__trampolineFor_err_withStr(
//				"Not enough spendable outputs / balance too low (have: "
//					+ monero_utils.formatMoneyFull(usingOutsAmount)
//					+ " need: "
//					+ monero_utils.formatMoneyFull(totalAmountIncludingFees)
//					+ ")"
//			)
//			return
//		}
//		// Now we can put together the list of fund transfers we need to perform
//		let fundTransferDescriptions = [] // to build…
//		// I. the actual transaction the user is asking to do
//		fundTransferDescriptions.push({
//			address: moneroReady_targetDescription_address,
//			amount: totalAmountWithoutFee_JSBigInt
//		})
//		// II. the fee that the hosting provider charges
//		// NOTE: The fee has been removed for RCT until a later date
//		// fundTransferDescriptions.push({
//		//             address: hostedMoneroAPIClient.HostingServiceFeeDepositAddress(),
//		//             amount: hostingService_chargeAmount
//		// })
//		// III. some amount of the total outputs will likely need to be returned to the user as "change":
//		if (usingOutsAmount_comparedTo_totalAmount > 0) {
//			var changeAmount = usingOutsAmount.subtract(totalAmountIncludingFees)
//			NSLog("changeAmount" , changeAmount)
//			if (isRingCT) { // for RCT we don't presently care about dustiness so add entire change amount
//				NSLog("Sending change of " + monero_utils.formatMoneySymbol(changeAmount) + " to " + wallet__public_address)
//				fundTransferDescriptions.push({
//					address: wallet__public_address,
//					amount: changeAmount
//				})
//			} else { // pre-ringct
//				// do not give ourselves change < dust threshold
//				var changeAmountDivRem = changeAmount.divRem(monero_config.dustThreshold)
//				NSLog("💬  changeAmountDivRem", changeAmountDivRem)
//				if (changeAmountDivRem[1].toString() !== "0") {
//					// miners will add dusty change to fee
//					NSLog("💬  Miners will add change of " + monero_utils.formatMoneyFullSymbol(changeAmountDivRem[1]) + " to transaction fee (below dust threshold)")
//				}
//				if (changeAmountDivRem[0].toString() !== "0") {
//					// send non-dusty change to our address
//					var usableChange = changeAmountDivRem[0].multiply(monero_config.dustThreshold)
//					NSLog("💬  Sending change of " + monero_utils.formatMoneySymbol(usableChange) + " to " + wallet__public_address)
//					fundTransferDescriptions.push({
//						address: wallet__public_address,
//						amount: usableChange
//					})
//				}
//			}
//		} else if (usingOutsAmount_comparedTo_totalAmount == 0) {
//			if (isRingCT) { // then create random destination to keep 2 outputs always in case of 0 change
//				var fakeAddress = monero_utils.create_address(monero_utils.random_scalar()).public_addr
//				NSLog("Sending 0 XMR to a fake address to keep tx uniform (no change exists): " + fakeAddress)
//				fundTransferDescriptions.push({
//					address: fakeAddress,
//					amount: 0
//				})
//			}
//		}
//		NSLog("fundTransferDescriptions so far", fundTransferDescriptions)
//		if (mixin < 0 || isNaN(mixin)) {
//			__trampolineFor_err_withStr("Invalid mixin")
//			return
//		}
//		if (mixin > 0) { // first, grab RandomOuts, then enter __createTx
//			hostedMoneroAPIClient.RandomOuts(
//				usingOuts,
//				mixin,
//				{ (err, amount_outs) in
//					if (err) {
//						__trampolineFor_err_withErr(err)
//						return
//					}
//					__createTxAndAttemptToSend(amount_outs)
//				}
//			)
//			return
//		} else { // mixin === 0: -- PSNOTE: is that even allowed?
//			__createTxAndAttemptToSend()
//		}
//		func __createTxAndAttemptToSend(mix_outs)
//		{
//			var signedTx;
//			try {
//			NSLog('Destinations: ')
//			monero_utils.printDsts(fundTransferDescriptions)
//			//
//			var realDestViewKey // need to get viewkey for encrypting here, because of splitting and sorting
//			if (final__pid_encrypt) {
//			realDestViewKey = monero_utils.decode_address(moneroReady_targetDescription_address).view
//			NSLog("got realDestViewKey" , realDestViewKey)
//			}
//			var splitDestinations = monero_utils.decompose_tx_destinations(
//			fundTransferDescriptions,
//			isRingCT
//			)
//			NSLog('Decomposed destinations:')
//			monero_utils.printDsts(splitDestinations)
//			//
//			signedTx = monero_utils.create_transaction(
//			wallet__public_keys,
//			wallet__private_keys,
//			splitDestinations,
//			usingOuts,
//			mix_outs,
//			mixin,
//			attemptAt_network_minimumFee,
//			final__payment_id,
//			final__pid_encrypt,
//			realDestViewKey,
//			0,
//			isRingCT
//			)
//			} catch (e) {
//			var errStr;
//			if (e) {
//			errStr = typeof e == "string" ? e : e.toString()
//			} else {
//			errStr = "Failed to create transaction with unknown error."
//			}
//			__trampolineFor_err_withStr(errStr)
//			return
//			}
//			NSLog("signed tx: ", JSON.stringify(signedTx))
//			//
//			var serialized_signedTx;
//			var tx_hash;
//			if (signedTx.version === 1) {
//				serialized_signedTx = monero_utils.serialize_tx(signedTx)
//				tx_hash = monero_utils.cn_fast_hash(raw_tx)
//			} else {
//				let raw_tx_and_hash = monero_utils.serialize_rct_tx_with_hash(signedTx)
//				serialized_signedTx = raw_tx_and_hash.raw
//				tx_hash = raw_tx_and_hash.hash
//			}
//			NSLog("tx serialized: " + serialized_signedTx)
//			NSLog("Tx hash: " + tx_hash)
//			//
//			// work out per-kb fee for transaction and verify that it's enough
//			var txBlobBytes = serialized_signedTx.length / 2
//			var numKB = Math.floor(txBlobBytes / 1024)
//			if (txBlobBytes % 1024) {
//				numKB++
//			}
//			NSLog(txBlobBytes + " bytes <= " + numKB + " KB (current fee: " + monero_utils.formatMoneyFull(attemptAt_network_minimumFee) + ")")
//			let feeActuallyNeededByNetwork = monero_config.feePerKB_JSBigInt.multiply(numKB)
//			// if we need a higher fee
//			if (feeActuallyNeededByNetwork.compare(attemptAt_network_minimumFee) > 0) {
//				NSLog("💬  Need to reletruct the tx with enough of a network fee. Previous fee: " + monero_utils.formatMoneyFull(attemptAt_network_minimumFee) + " New fee: " + monero_utils.formatMoneyFull(feeActuallyNeededByNetwork))
//				__reenterable_letructFundTransferListAndSendFunds_findingLowestNetworkFee(
//					moneroReady_targetDescription_address,
//					totalAmountWithoutFee_JSBigInt,
//					final__payment_id,
//					final__pid_encrypt,
//					unusedOuts,
//					feeActuallyNeededByNetwork // we are re-entering this codepath after changing this feeActuallyNeededByNetwork
//				)
//				//
//				return
//			}
//			//
//			// generated with correct per-kb fee
//			let final_networkFee = attemptAt_network_minimumFee // just to make things clear
//			NSLog("💬  Successful tx generation, submitting tx. Going with final_networkFee of ", monero_utils.formatMoney(final_networkFee))
//			// status: submitting…
//			hostedMoneroAPIClient.SubmitSerializedSignedTransaction(
//				wallet__public_address,
//				wallet__private_keys.view,
//				serialized_signedTx,
//				{ (err) in
//					if (err) {
//						__trampolineFor_err_withStr("Something unexpected occurred when submitting your transaction:", err)
//						return
//					}
//					let tx_fee = final_networkFee/*.add(hostingService_chargeAmount) NOTE: Service charge removed to reduce bloat for now */
//					__trampolineFor_success(
//						moneroReady_targetDescription_address,
//						amount,
//						final__payment_id,
//						tx_hash,
//						tx_fee
//					) // 🎉
//				}
//			)
//		}
//	}
}
//
//func __randomIndex(_ list: [Any]) -> Int
//{
//	let randomIndex = Int(arc4random_uniform(UInt32(list.count)))
//	return randomIndex
//}
//func _popAndReturnRandomElementFromList(_ list: [Any]) -> Any
//{
//	var idx = __randomIndex(list)
//	var val = list[idx]
//	list.remove(at: idx)
//	//
//	return val
//}
//func _outputsAndAmountToUseForMixin(
//	target_amount,
//	unusedOuts
//	)
//{
//	NSLog("Selecting outputs to use. target: " + monero_utils.formatMoney(target_amount))
//	var toFinalize_usingOutsAmount = new JSBigInt(0)
//	let toFinalize_usingOuts = []
//	let remaining_unusedOuts = unusedOuts.slice() // take copy so as to prevent issue if we must re-enter tx building fn if fee too low after building
//	while (toFinalize_usingOutsAmount.compare(target_amount) < 0 && remaining_unusedOuts.length > 0) {
//		var out = _popAndReturnRandomElementFromList(remaining_unusedOuts)
//		let out_amount = out.amount
//		toFinalize_usingOuts.push(out)
//		toFinalize_usingOutsAmount = toFinalize_usingOutsAmount.add(out_amount)
//		NSLog("Using output: " + monero_utils.formatMoney(out_amount) + " - " + JSON.stringify(out))
//	}
//	return {
//		usingOuts: toFinalize_usingOuts,
//		usingOutsAmount: toFinalize_usingOutsAmount,
//		remaining_unusedOuts: remaining_unusedOuts
//	}
//}
