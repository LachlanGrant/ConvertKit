//
//  CKCurrency.swift
//  ConvertKit
//
//  Created by Lachlan Grant on 19/12/16.
//  Copyright © 2016 Lachlan Grant. All rights reserved.
//

import Foundation

/// Class for Storing Currency Detail
public class CKCurrency {
	
	/// Currency Code eg. AUD
	public var code: String!
	
	/// Symbol used for the currency eg. $
	public var symbol: String?
	
	/// Display Name eg. Australian Dollar
	public var name: String!
	
	/// Conversion Rate
	public var rate: Double!
	
	/// Depricated
	public var enabled: Bool!

	
	/// Create Currency Object with parameters
	///
	/// - Parameters:
	///   - code: Currency Code
	///   - symbol: Currency Symbol
	///   - name: Currency Display Name
	///   - rate: Conversion Rate
	///   - enabled: Depricated
	public init(code: String, symbol: String?, name: String, rate: Double, enabled: Bool?) {
		self.code = code
		self.name = name
		self.rate = rate

		if (enabled != true) {
			self.enabled = false
		} else {
			self.enabled = true
		}

		if (symbol != nil) {
			self.symbol = symbol!
		} else {
			self.symbol = self.code
		}
	}
	
	
	/// Convert into AUD
	///
	/// - Parameter value: Amount to Convert
	/// - Returns: Converted Amount
	public func valueInAUD(_ value: Double) -> Double {
		return value * rate
	}
	
	
	/// Convert from AUD
	///
	/// - Parameter audValue: Value in AUD
	/// - Returns: Converted Value
	public func valueFromAUD(_ audValue: Double) -> Double {
		return audValue / self.rate
	}

	
	/// Convert between two Currencies
	///
	/// - Parameters:
	///   - value: Amoun to Convert
	///   - toCourrency: Currency to convert to
	/// - Returns: Amount in 'toCurrency'
	public func valueConvertedFromCurrency(_ value: Double, toCourrency: CKCurrency) -> Double {
		let aud = self.valueInAUD(value)

		let value = toCourrency.valueFromAUD(aud)

		return value
	}
}
