//
//  IntOperators.swift
//  Atem
//
//  Created by Damiaan on 11-11-16.
//
//

import Foundation

extension UInt8 {
	var firstBit: Bool {return self & 1 == 1}
}

extension FixedWidthInteger {
    init(from slice: ArraySlice<UInt8>) {
        precondition(slice.count == MemoryLayout<Self>.size,
                     "slice must be exactly \(MemoryLayout<Self>.size) bytes")
        var value: Self = 0
        for byte in slice {
            value = (value << 8) | Self(byte)
        }
        self = value
    }

    var bytes: [UInt8] {
        var value = self.bigEndian
        var result = [UInt8](repeating: 0, count: MemoryLayout<Self>.size)
        for i in 0..<result.count {
            result[result.count - 1 - i] = UInt8((value >> (i * 8)) & 0xFF)
        }
        return result
    }
}

extension ArraySlice {
	subscript(relative index: Index) -> Element {
		return self[startIndex + index]
	}
	
	subscript<R: AdvancableRange>(relative range: R) -> SubSequence where R.Bound == Index {
		return self[range.advanced(by: startIndex)]
	}
}

protocol AdvancableRange: RangeExpression where Bound: Strideable {
	func advanced(by stride: Bound.Stride) -> Self
}

extension CountableRange: AdvancableRange {
	func advanced(by stride: Bound.Stride) -> CountableRange<Bound> {
		return CountableRange(uncheckedBounds: (lower: lowerBound.advanced(by: stride), upper: upperBound.advanced(by: stride)))
	}
}

extension CountablePartialRangeFrom: AdvancableRange {
	func advanced(by stride: Bound.Stride) -> CountablePartialRangeFrom<Bound> {
		return CountablePartialRangeFrom(lowerBound.advanced(by: stride))
	}
}

let truncationDots = "...".data(using: .ascii)!
extension UnsafeMutableBufferPointer where Element == UInt8 {
	static let errorText = "Error".data(using: .ascii)!

	func write<I: FixedWidthInteger>(_ number: I, at offset: Int) {
        UnsafeMutableRawPointer(baseAddress!.advanced(by: offset)).bindMemory(to: I.self, capacity: 1).pointee = number
	}

	func write<S: StringProtocol>(_ text: S, to range: Range<Int>) {
		if let data = text.data(using: .ascii) {
			write(data: data, to: range)
		} else {
			write(data: Self.errorText, to: range)
			print("Warning: unable to encode to utf8: ", text)
		}
	}

	func write(data: Data, to range: Range<Int>) {
		let destination = baseAddress!
			.advanced(by: range.lowerBound)
			.withMemoryRebound(to: UInt8.self, capacity: range.count) { $0 }

		if data.count > range.count {
			let shortenedCount = range.count - truncationDots.count
			data.copyBytes(to: destination, count: shortenedCount)
			truncationDots.copyBytes(to: destination + shortenedCount, count: truncationDots.count)
		} else {
			data.copyBytes(to: destination, count: data.count)
			if data.count < range.count {
				destination[data.count] = 0
			}
		}
	}
}
