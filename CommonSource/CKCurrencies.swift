//
//  CKCurrencies.swift
//  ConvertKit
//
//  Created by Lachlan Grant on 19/12/16.
//  Copyright © 2016 Lachlan Grant. All rights reserved.
//

import Foundation
import MKUtilityKit
import MKKit


/// Currency Manager
public class CKCurrencies {
    
    public static let shared = CKCurrencies()
	
	/// Array of CKCurrency Objects
	public var currencies: [CKCurrency] = []
	
	/// Array of CKCurrency Objects for CryptoCurrencies
	public var cryptoCurrencies: [CKCurrency] = []
	
	/// Time/Date String of Last Updated
	public var lastUpdated: String?
	private var base: String?
    
    #if os(macOS)
        private let fileLocation = FileManager.SearchPathDirectory.applicationSupportDirectory
    #else
        private let fileLocation = FileManager.SearchPathDirectory.documentDirectory
    #endif

	
	/// Blank Init
	public init() {}

	
	/// Get Currency using Currency Code
	///
	/// - Parameter code: Currency Code
	/// - Returns: CKCurrency Object
	public func getCurrency(_ code: String) -> CKCurrency? {

		for item in currencies {
			if item.code == code {
				return item
			}
		}

		for item in cryptoCurrencies {
			if item.code == code {
				return item
			}
		}

		return nil
	}
	
	
	/// List Currency Codes
	///
	/// - Returns: Array of Codes
	public func listCurrencies() -> [String] {
		var names: [String] = []
		for item in currencies {
			names.append(item.name)
		}

		for item in cryptoCurrencies {
			names.append(item.name)
		}

		return names
	}

	
	/// Get 'Active' Currencies ~~ MKAppGroups.ConvertNowSettings app group required
	///
	/// - Returns: Array of CKCurrency Objects
	public func getActiveCurrencies() -> [CKCurrency] {
		var active = MKUDefaults(suiteName: MKAppGroups.ConvertNowSettings).defaults.array(forKey: "active")

		if (active == nil) {
			active = ["AUD", "USD", "EUR"]
			setActiveCurrencies(active!)
		}
		var final: [CKCurrency] = []

		for item in active! {
			let temp = getCurrency(item as! String)

			if (temp != nil) {
				final.append(temp!)
			}
		}

		return final
	}
    
    public func addCurrencyToActive(_ currency: CKCurrency) {
        var active = MKUDefaults.init(suiteName: MKAppGroups.ConvertNowSettings).defaults.array(forKey: "active")
        
        active?.append(currency.code)
        
        MKUDefaults.init(suiteName: MKAppGroups.ConvertNowSettings).defaults.set(active, forKey: "active")
    }
    
    public func removeCurrencyFromActive(_ currency: CKCurrency) {
        let active = MKUDefaults.init(suiteName: MKAppGroups.ConvertNowSettings).defaults.array(forKey: "active") as! [String]
        
        let newActive = active.filter { $0 != currency.code }
        
        MKUDefaults.init(suiteName: MKAppGroups.ConvertNowSettings).defaults.set(newActive, forKey: "active")
    }

	
	/// Get 'Active' Currencies when a currency is selected.
	///
	/// - Parameter selectedCurrency: Selected Currency
	/// - Returns: Array of CKCurrency Objects
	public func getActiveWhen(selectedCurrency: CKCurrency?) -> [CKCurrency] {
		if selectedCurrency != nil && selectedCurrency?.code != "" && selectedCurrency?.code != nil {
			let active = getActiveCurrencies()
			var approved: [CKCurrency] = []

			for item in active {
				if item.code != selectedCurrency?.code {
					approved.append(item)
				}
			}

			return approved
		} else {
			return getActiveCurrencies()
		}
	}

	
	/// Set 'Active' Currencies
	///
	/// - Parameter array: Array of Currency Codes
	public func setActiveCurrencies(_ array: [Any]) {
		MKUDefaults(suiteName: MKAppGroups.ConvertNowSettings).defaults.set(array, forKey: "active")
	}

	
	/// Get Currency using the Currency Name
	///
	/// - Parameter name: Currency Name
	/// - Returns: CKCurrency
	public func getCurrencyFromName(_ name: String) -> CKCurrency? {
		for item in currencies {
			if item.name == name {
				return item
			}
		}

		for item in cryptoCurrencies {
			if item.name == name {
				return item
			}
		}
		return nil
	}

	
	/// Download new currency data from the Internet
	///
	/// - Parameter callback: Callback when data has been parsed and cached, with a success bool return
	public func updateWithNewData(callback: @escaping (Bool, Data, Data) -> Void) {
		if (MKUReachability().isConnectedToNetwork) {
			try! downloadNewData(callback: { (data, crypto) in
                callback(true, data, crypto)
			})
        } else {
            callback(false, Data(), Data())
        }
	}

	
	/// Get Cached Data then Update with updated Data
	///
	/// - Parameters:
	///   - cachedData: Callback for when the cached data has been loaded
	///   - updatedData: Callback for when the updated data has been loaded
    public func getCachedThenUpdate(updatedData: @escaping (Data, Data) -> Void) {
        self.updateWithNewData { (success, data, crypto) in
            if success {
                updatedData(data, crypto)
            } else {
                self.loadCacheData(completion: { (data, crypto) in
                    updatedData(data, crypto)
                })
            }
        }
	}

	
	/// Download New Data
	///
	/// - Parameter callback: Returns two data objects
	private func downloadNewData(callback: @escaping (Data, Data) -> Void) throws {
        do {
            let url = URL(string: "https://api.fixer.io/latest?base=AUD")!
            
            let contents = try String(contentsOf: url)
            let data = contents.data(using: String.Encoding.utf8)
            
            var limit = 0
            
            if (MKUAppSettings.shared.bundleID == MKBundleID.ConvertNow) {
                limit = 64
            } else {
                limit = 32
            }
            
            let cryptoURL = URL(string: "https://api.coinmarketcap.com/v1/ticker/" + (limit != 0 ? "?limit=\(limit)": ""))!
            let cryptoContents = try! String(contentsOf: cryptoURL)
            let cryptoData = cryptoContents.data(using: String.Encoding.utf8)
            
            callback(data!, cryptoData!)
        } catch {
            let strError = String(describing: error)
            
            MKULog.shared.error("[ConvertKit] \(strError)")
            throw error
        }
	}

	
	/// Write Data to File
	///
	/// - Parameters:
	///   - data: Currency Data
	///   - crypto: Crypto Data
	private func writeToFile(data: Data, crypto: Data) {
		let file = "currency.txt"
		let cryptoFile = "crypto.txt"

        let dir = NSSearchPathForDirectoriesInDomains(fileLocation, .userDomainMask, true)
		let path = URL(fileURLWithPath: "\(dir[0])/\(file)")
		let cryptoPath = URL(fileURLWithPath: "\(dir[0])/\(cryptoFile)")

		do {
			try data.write(to: path)
			try crypto.write(to: cryptoPath)
		} catch {
			let er = MKUJSON.toJson(error)
			MKULog.shared.error(er as AnyObject)
		}
	}

	
	/// Load Data from Cache
	///
	/// - Parameter completion: Callback, success bool
	public func loadCacheData(completion: @escaping (Data, Data) -> Void) {
		var tmpCurrency = Data()
		var tmpCrypto = Data()

		getCachedCurrencyData { (data, success) in
			if success {
				tmpCurrency = data
			}
		}

		getCachedCryptoData { (data, success) in
			if success {
				tmpCrypto = data
			}
		}

//        var success = false
//        if (tmpCurrency != Data() && tmpCrypto != Data()) {
//            success = true
//        }

		completion(tmpCurrency, tmpCrypto)
	}

	
	/// Get Currency Data from File
	///
	/// - Parameter callback: Data and Success returned
	private func getCachedCurrencyData(callback: @escaping (Data, Bool) -> Void) {
		getFileContents(fileName: "currency.txt") { (data, success) in
			if !success {
				callback(Data(), false)
			} else {
				callback(data, true)
			}
		}
	}

	
	/// Get Crypto Data from File
	///
	/// - Parameter callback: Data and Success Returned
	private func getCachedCryptoData(callback: @escaping (Data, Bool) -> Void) {
		getFileContents(fileName: "crypto.txt") { (data, success) in
			if !success {
				callback(Data(), false)
			} else {
				callback(data, true)
			}
		}
	}
	
	
	/// Get Contents of File
	///
	/// - Parameters:
	///   - fileName: File Name
	///   - callback: Data and success return
	private func getFileContents(fileName: String, callback: @escaping (Data, Bool) -> Void) {

        let dir = NSSearchPathForDirectoriesInDomains(fileLocation, .userDomainMask, true)
		let path = URL(fileURLWithPath: "\(dir[0])/\(MKUAppSettings.shared.bundleID)/\(fileName)")

		do {
			let data = try Data(contentsOf: path)
			callback(data, true)
		} catch {
			callback(Data(), false)
		}
	}

	
	/// Parse New Data
	///
	/// - Parameters:
	///   - data: Currency Data
	///   - crypto: Crypto Data
	///   - saveToDefaults: Should this data be saved to UserDefaults (watchOS Support)
	public func handleUpdate(_ data: Data, crypto: Data, saveToDefaults: Bool) {
		do {
			var saved = getSavedData()
			let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]

			base = (json["base"] as! String)
			lastUpdated = (json["date"] as! String)

			let aud = CKCurrency(code: "AUD", symbol: "$", name: "Australian Dollar", rate: 1, enabled: true)
			currencies.append(aud)

			if let rates = json["rates"] as? [String: Double] {
				for rate in rates {
					var savedData = saved?[rate.key] as! [String: String]

					var tempSymbol = ""

					if (savedData["Symbol"] != nil) {
						tempSymbol = savedData["Symbol"]!
					} else {
						tempSymbol = savedData["Code"]!
					}
					let name = savedData["Name"]!

					let tempCurr = CKCurrency(code: rate.key,
											  symbol: tempSymbol,
											  name: name,
											  rate: rate.value,
											  enabled: false)

					currencies.append(tempCurr)
				}
			}

			let cryptoJSON = try JSONSerialization.jsonObject(with: crypto, options: []) as! [[String: Any]]

			for item in cryptoJSON {
				let code = item["symbol"] as! String
				let name = item["name"] as! String
				let valInUSD = Double((item["price_usd"] as! String))

				let usd = getCurrency("USD")
				let rate = usd?.valueInAUD(1 / valInUSD!)


				let tempCurr = CKCurrency(code: code, symbol: name, name: name, rate: rate!, enabled: false)
				cryptoCurrencies.append(tempCurr)
			}


			if saveToDefaults {
				saveDataToDefaults()
			}
		} catch {
			MKULog.shared.error(MKUJSON.toJson(error) as AnyObject)
		}
	}

	
	/// Save Data to Defaults
	private func saveDataToDefaults() {
		let curr = currencies
		let crypto = cryptoCurrencies
//        let defaults = MKUDefaults.init(suiteName: MKAppGroups.ConvertNowData).defaults
        let defaultss = MKUDefaults(suiteName: MKAppGroups.ConvertNowData).defaults

		var codes: [String] = []
		var name: [String] = []
		var rate: [Double] = []

		for item in curr {
			codes.append(item.code)
			name.append(item.name)
			rate.append(item.rate)
		}

		for item in crypto {
			codes.append(item.code)
			name.append(item.code)
			rate.append(item.rate)
		}

		defaultss.set(codes, forKey: "codes")
		defaultss.set(name, forKey: "names")
		defaultss.set(rate, forKey: "rates")
	}

	
	/// Get PLIST Data
	///
	/// - Returns: Array of Plist Data
	private func getSavedData() -> [String: AnyObject]? {
        var plistData: [String: AnyObject] = [:]
        
        let fileCont = MKUFileController()
        let path = try! fileCont.getPath(withName: "currency", ofType: "plist", fromBundleWithID: MKBundleID.ConvertKit)
        let content = try! fileCont.readFile(atPath: path)
        
        do {
            plistData = try PropertyListSerialization.propertyList(from: content,
                                                                   options: PropertyListSerialization.ReadOptions.mutableContainersAndLeaves,
                                                                   format: nil) as! [String: AnyObject]
            return plistData
        } catch {
            MKULog.shared.error(MKUJSON.toJson(error) as AnyObject)
            return nil
        }

	}
}

enum CKError: Error {
    case noData
}
