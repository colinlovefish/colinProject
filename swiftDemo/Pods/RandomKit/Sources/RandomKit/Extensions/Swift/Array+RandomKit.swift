//
//  Array+RandomKit.swift
//  RandomKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015-2017 Nikolai Vazquez
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

extension Array where Element: Random {

    /// Construct an Array of random elements.
    ///
    /// Although safety is not guaranteed, `init(unsafeRandomCount:)` is *significantly* faster than this.
    public init<R: RandomGenerator>(randomCount: Int, using randomGenerator: inout R) {
        self.init(Element.randoms(limitedBy: randomCount, using: &randomGenerator))
    }

}

extension Array where Element: UnsafeRandom {

    /// Construct an Array of random elements by randomizing the buffer directly.
    ///
    /// This is *significantly* faster than using `init(randomCount:using:)`.
    public init<R: RandomGenerator>(unsafeRandomCount: Int, using randomGenerator: inout R) {
        self.init(ContiguousArray(unsafeRandomCount: unsafeRandomCount, using: &randomGenerator))
    }

}

extension Array where Element: RandomToValue {

    /// Construct an Array of random elements to a value.
    public init<R: RandomGenerator>(randomCount: Int, to value: Element, using randomGenerator: inout R) {
        self.init(Element.randoms(to: value, using: &randomGenerator))
    }

}

extension Array where Element: RandomThroughValue {

    /// Construct an Array of random elements through a value.
    public init<R: RandomGenerator>(randomCount: Int, through value: Element, using randomGenerator: inout R) {
        self.init(Element.randoms(through: value, using: &randomGenerator))
    }

}

extension Array where Element: RandomWithinRange {

    /// Construct an Array of random elements from within the range.
    public init<R: RandomGenerator>(randomCount: Int, within range: Range<Element>, using randomGenerator: inout R) {
        self.init(Element.randoms(limitedBy: randomCount, within: range, using: &randomGenerator))
    }

}

extension Array where Element: RandomWithinClosedRange {

    /// Construct an Array of random elements from within the closed range.
    public init<R: RandomGenerator>(randomCount: Int, within closedRange: ClosedRange<Element>, using randomGenerator: inout R) {
        self.init(Element.randoms(limitedBy: randomCount, within: closedRange, using: &randomGenerator))
    }

}

extension ContiguousArray where Element: UnsafeRandom {

    /// Construct a ContiguousArray of random elements by randomizing the buffer directly.
    ///
    /// This is *significantly* faster than using `init(randomCount:using:)`.
    public init<R: RandomGenerator>(unsafeRandomCount: Int, using randomGenerator: inout R) {
        self.init(repeating: .randomizableValue, count: unsafeRandomCount)
        withUnsafeMutableBytes {
            randomGenerator.randomize(buffer: $0)
        }
    }

}

extension Array {

    /// Returns an array of randomly choosen elements.
    ///
    /// If `count` >= `self.count` a copy of this array is returned.
    ///
    /// - parameter count: The number of elements to return.
    /// - parameter randomGenerator: The random generator to use.
    public func randomSlice<R: RandomGenerator>(count: Int, using randomGenerator: inout R) -> Array {
        guard count > 0 else {
            return []
        }
        guard count < self.count else {
            return self
        }
        // Algorithm R
        // fill the reservoir array
        var result = Array(self.prefix(upTo: count))
        // replace elements with gradually decreasing probability
        for i in CountableRange(uncheckedBounds: (count, self.count)) {
            let j = Int.random(to: i, using: &randomGenerator)
            if j < count {
                result[j] = self[i]
            }
        }
        return result
    }

    /// Returns an array of `count` randomly choosen elements.
    ///
    /// If `count` >= `self.count` or `weights.count` < `self.count` a copy of this array is returned.
    ///
    /// - parameter count: The number of elements to return.
    /// - parameter weights: Apply weights on element.
    /// - parameter randomGenerator: The random generator to use.
    public func randomSlice<R: RandomGenerator>(count: Int, weights: [Double], using randomGenerator: inout R) -> Array {
        guard count > 0 else {
            return []
        }
        guard count < self.count && weights.count >= self.count else {
            return self
        }

        // Algorithm A-Chao
        var result = Array(self.prefix(upTo: count))
        var weightSum: Double = weights.prefix(upTo: count).reduce(0.0) { (total, value) in
            total + value
        }
        for i in CountableRange(uncheckedBounds: (count, self.count)) {
            let p = weights[i] / weightSum
            let j = Double.random(through: 1.0, using: &randomGenerator)
            if j <= p {
                let index = Int.random(to: count, using: &randomGenerator)
                result[index] = self[i]
            }
            weightSum += weights[i]
        }
        return result
    }

}
