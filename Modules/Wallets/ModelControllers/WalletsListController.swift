//
//  WalletsListController.swift
//  MyMonero
//
//  Created by Paul Shapiro on 5/19/17.
//  Copyright © 2017 MyMonero. All rights reserved.
//

import Foundation

class WalletsListController: PersistedObjectListController
{
	// initial
	var mymoneroCore: MyMoneroCore!
	var hostedMoneroAPIClient: HostedMoneroAPIClient!
	//
	static let shared = WalletsListController()
	//
	// Lifecycle - Init
	private init()
	{
		super.init(listedObjectType: Wallet.self)
	}
	//
	// Lifecycle - Overrides
	override func setup_startObserving()
	{
		super.setup_startObserving()
		//
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(SettingsController__NotificationNames_Changed__specificAPIAddressURLAuthority),
			name: SettingsController.NotificationNames_Changed.specificAPIAddressURLAuthority.notificationName,
			object: nil
		)
	}
	override func stopObserving()
	{
		super.stopObserving()
		//
		NotificationCenter.default.removeObserver(self, name: SettingsController.NotificationNames_Changed.specificAPIAddressURLAuthority.notificationName, object: nil)
	}
	//
	// Runtime - Imperatives - Overrides
	override func overridable_sortRecords()
	{
		self.records = self.records.sorted(by: { (l, r) -> Bool in
			if l.insertedAt_date == nil {
				return false
			}
			if r.insertedAt_date == nil {
				return true
			}
			return l.insertedAt_date! > r.insertedAt_date!
		})
	}
	//
	// Runtime - Accessors - Derived properties
	var givenBooted_swatchesInUse: [Wallet.SwatchColor]
	{
		if self.hasBooted != true {
			assert(false, "givenBooted_swatchesInUse called when \(self) not yet booted.")
			return [] // this may be for the first wallet creation - let's say nothing in use yet
		}
		var inUseSwatches: [Wallet.SwatchColor] = []
		for (_, record) in self.records.enumerated() {
			let wallet = record as! Wallet
			if let swatchColor = wallet.swatchColor {
				inUseSwatches.append(swatchColor)
			}
		}
		return inUseSwatches
	}
	//
	//
	// Booted - Imperatives - Public - Wallets list
	//
	func CreateNewWallet_NoBootNoListAdd(
		_ fn: @escaping (_ err: String?, _ walletInstance: Wallet?) -> Void
	) -> Void
	{ // call this first, then call WhenBooted_ObtainPW_AddNewlyGeneratedWallet
		MyMoneroCore.shared.NewlyCreatedWallet
		{ (err_str, walletDescription) in
			if err_str != nil {
				fn(err_str, nil)
				return
			}
			do {
				guard let wallet = try Wallet(ifGeneratingNewWallet_walletDescription: walletDescription!) else {
					fn("Unable to add wallet.", nil)
					return
				}
				fn(nil, wallet)
			} catch let e {
				fn(e.localizedDescription, nil)
				return
			}
		}
	}
	func OnceBooted_ObtainPW_AddNewlyGeneratedWallet(
		walletInstance: Wallet,
		walletLabel: String,
		swatchColor: Wallet.SwatchColor,
		_ fn: @escaping (
			_ err_str: String?,
			_ walletInstance: Wallet?
		) -> Void,
		userCanceledPasswordEntry_fn: (() -> Void)? = {}
	) -> Void
	{
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					walletInstance.Boot_byLoggingIn_givenNewlyCreatedWallet(
						walletLabel: walletLabel,
						swatchColor: swatchColor,
						{ [unowned self] (err_str) in
							if err_str != nil {
								fn(err_str, nil)
								return
							}
							self._atRuntime__record_wasSuccessfullySetUp(walletInstance)
							//
							fn(nil, walletInstance)
						}
					)
				},
				{ // user canceled
					(userCanceledPasswordEntry_fn ?? {})()
				}
			)
		})
	}
	func OnceBooted_ObtainPW_AddExtantWalletWith_MnemonicString(
		walletLabel: String,
		swatchColor: Wallet.SwatchColor,
		mnemonicString: MoneroSeedAsMnemonic,
		_ fn: @escaping (
			_ err_str: String?,
			_ walletInstance: Wallet?,
			_ wasWalletAlreadyInserted: Bool?
		) -> Void,
		userCanceledPasswordEntry_fn: (() -> Void)? = {}
	) -> Void
	{
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					do {
						for (_, record) in self.records.enumerated() {
							let wallet = record as! Wallet
							if wallet.mnemonicString == mnemonicString {
								fn(nil, wallet, true) // wasWalletAlreadyInserted: true
								return
							}
							// TODO: solve limitation of this code - check if wallet with same address (but no mnemonic) was already added
						}
					}
					do {
						guard let wallet = try Wallet(ifGeneratingNewWallet_walletDescription: nil) else {
							fn("Unknown error while adding wallet.", nil, nil)
							return
						}
						wallet.Boot_byLoggingIn_existingWallet_withMnemonic(
							walletLabel: walletLabel,
							swatchColor: swatchColor,
							mnemonicString: mnemonicString,
							persistEvenIfLoginFailed_forServerChange: false, // not forServerChange
							{ [unowned self] (err_str) in
								if err_str != nil {
									fn(err_str, nil, nil)
									return
								}
								self._atRuntime__record_wasSuccessfullySetUp(wallet)
								fn(nil, wallet, false) // wasWalletAlreadyInserted: false
							}
						)
					} catch let e {
						fn(e.localizedDescription, nil, nil)
						return
					}
				},
				{ // user canceled
					(userCanceledPasswordEntry_fn ?? {})()
				}
			)
		})
	}
	func OnceBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys(
		walletLabel: String,
		swatchColor: Wallet.SwatchColor,
		address: MoneroAddress,
		privateKeys: MoneroKeyDuo,
		_ fn: @escaping (
			_ err_str: String?,
			_ wallet: Wallet?,
			_ wasWalletAlreadyInserted: Bool?
		) -> Void,
		userCanceledPasswordEntry_fn: (() -> Void)? = {}
	)
	{
		self.onceBooted({ [unowned self] in
			PasswordController.shared.OnceBootedAndPasswordObtained( // this will 'block' until we have access to the pw
				{ [unowned self] (password, passwordType) in
					do {
						for (_, record) in self.records.enumerated() {
							let wallet = record as! Wallet
							if wallet.public_address == address {
								// simply return existing wallet; note: this wallet might have mnemonic and thus seed
								// so might not be exactly what consumer of GivenBooted_ObtainPW_AddExtantWalletWith_AddressAndKeys is expecting
								fn(nil, wallet, true) // wasWalletAlreadyInserted: true
								return
							}
						}
					}
					do {
						guard let wallet = try Wallet(ifGeneratingNewWallet_walletDescription: nil) else {
							fn("Unknown error while adding wallet.", nil, nil)
							return
						}
						wallet.Boot_byLoggingIn_existingWallet_withAddressAndKeys(
							walletLabel: walletLabel,
							swatchColor: swatchColor,
							address: address,
							privateKeys: privateKeys,
							persistEvenIfLoginFailed_forServerChange: false, // not forServerChange
							{ [unowned self] (err_str) in
								if err_str != nil {
									fn(err_str, nil, nil)
									return
								}
								self._atRuntime__record_wasSuccessfullySetUp(wallet)
								fn(nil, wallet, false) // wasWalletAlreadyInserted: false
							}
						)
					} catch let e {
						fn(e.localizedDescription, nil, nil)
						return
					}
				},
				{ // user canceled
					(userCanceledPasswordEntry_fn ?? {})()
				}
			)
		})
	}
	//
	// Delegation - Overrides - Booting reconstitution - Instance setup
	override func overridable_booting_didReconstitute(listedObjectInstance: PersistableObject)
	{
		let wallet = listedObjectInstance as! Wallet
		wallet.Boot_havingLoadedDecryptedExistingInitDoc(
			{ err_str in
				if let err_str = err_str {
					DDLog.Error("Wallets", "Error while booting wallet: \(err_str)")
				}
			}
		)
	}
	//
	// Delegation - Notifications
	struct WalletRebootReconstitutionDescription
	{
//		var currency: Currency!
		var walletLabel: String
		var swatchColor: Wallet.SwatchColor
		//
		var mnemonicString: MoneroSeedAsMnemonic?
		var account_seed: MoneroSeed?
		var private_keys: MoneroKeyDuo!
		var public_address: MoneroAddress!
		//
		static func new(fromWallet wallet: Wallet) -> WalletRebootReconstitutionDescription
		{
			return WalletRebootReconstitutionDescription(
				walletLabel: wallet.walletLabel,
				swatchColor: wallet.swatchColor,
				//
				mnemonicString: wallet.mnemonicString,
				account_seed: wallet.account_seed,
				private_keys: wallet.private_keys,
				public_address: wallet.public_address
			)
		}
	}
	@objc func SettingsController__NotificationNames_Changed__specificAPIAddressURLAuthority()
	{
		// 'log out' all wallets by grabbing their keys (info to reconstitute them), deleting them, then reconstituting and booting them
		// I opted to do this here rather than within the wallet itself b/c if a wallet is currently logging in then it has to manage cancelling that, etc. - was easier and possibly simpler to just use List CRUD apis instead.
		if self.hasBooted == false {
			assert(self.records.count == 0)
			return // nothing to do
		}
		assert(self.hasBooted, "code fault")
		if self.records.count == 0 {
			return // nothing to do
		}
		if PasswordController.shared.hasUserEnteredValidPasswordYet == false {
			assert(false, "App expected password to exist as wallets exist")
			return
		}
		var reconstitutionDescriptions: [WalletRebootReconstitutionDescription] = []
		let walletsToDelete = self.records
		for (_, object) in walletsToDelete.enumerated() {
			let wallet = object as! Wallet
			reconstitutionDescriptions.append(
				WalletRebootReconstitutionDescription.new(fromWallet: wallet)
			)
			let err_str = wallet.delete()
			// TODO if needed: add self.stopObserving(record: record) for each deleted record if added later…
			if err_str != nil { // remove / release
				assert(false) // at least it will be removed from the list for now. if it appears when the app boots again, at least it will attempt to log in. maybe dedupe wallets on launch? probably not a good idea.
			}
		}
		self.records = [] // free old wallets, now that we have deleted them after obtaining their reconstitutionDescriptions
		//
		for (_, reconstitutionDescription) in reconstitutionDescriptions.enumerated() {
			
			do {
				guard let wallet = try Wallet(
					ifGeneratingNewWallet_walletDescription: nil
				) else {
					assert(false, "Unknown error while adding wallet.")
					continue // skip - nothing to append
				}
				// TODO if necessary - add startObserving record - but shouldn't be at the moment - if implemented, be sure to add corresponding stopObserving where necessary
				self.records.append(wallet) // preserves ordering
				// ^- appending immediately so we don't have to wait for success before updating
				//
				// now boot (aka login)
				if let mnemonicString = reconstitutionDescription.mnemonicString {
					wallet.Boot_byLoggingIn_existingWallet_withMnemonic(
						walletLabel: reconstitutionDescription.walletLabel,
						swatchColor: reconstitutionDescription.swatchColor,
						mnemonicString: mnemonicString,
						persistEvenIfLoginFailed_forServerChange: true, // IS forServerChange
						{ (err_str) in
							if err_str != nil {
								// it's ok if we get an error here b/c it will be displayed as a failed-to-boot wallet in the table view
							}
						}
					)
				} else {
					wallet.Boot_byLoggingIn_existingWallet_withAddressAndKeys(
						walletLabel: reconstitutionDescription.walletLabel,
						swatchColor: reconstitutionDescription.swatchColor,
						address: reconstitutionDescription.public_address,
						privateKeys: reconstitutionDescription.private_keys,
						persistEvenIfLoginFailed_forServerChange: true, // IS forServerChange
						{ (err_str) in
							if err_str != nil {
								// it's ok if we get an error here b/c it will be displayed as a failed-to-boot wallet in the table view
							}
						}
					)
				}
			} catch let e {
				assert(false, "Error while addind wallet: \(e)")
				continue // skip - nothing to append
			}
		}
		self.overridable_sortRecords()
		self._dispatchAsync_listUpdated_records()
		// ^-- so control can be passed back before all observers of notification handle their work - which is done synchronously
	}
}
