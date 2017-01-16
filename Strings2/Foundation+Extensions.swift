import Foundation

public extension Dictionary {
	init<S: Sequence>
		(keyValues seq: S)
		where S.Iterator.Element == Element {
        self.init()
        self.merge(seq: seq)
    }
 
	mutating func merge<S: Sequence>
		(seq: S)
		where S.Iterator.Element == Element {
        var gen = seq.makeIterator()
        while let (k,v) = gen.next() {
            self[k] = v
        }
    }
}

public extension Array {
	func find(predicate: (Element) -> Bool) -> Element? {
		if let index = index(where: predicate) {
			return self[index]
		}
		return nil
	}

	func truncate(count: Int) -> Array {
		// return copy with 1st n items only
//		return Array(self[0..<min(self.count, count)] )
		return Array( self.dropLast(count) )
	}
}

public protocol Configurable {
}

public extension Configurable where Self: Any {
    public func configure( block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}

public extension Configurable where Self: AnyObject {
    public func configure( block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

public extension NSObjectProtocol {
	func configure( block: (Self)->Void) -> Self {
		block(self)
		return self
	}
}

public func configure<V>( object:inout V, block: (V) -> Void) -> V {
	block(object)
    return object
}


public class WrapAny<T>: NSObject {
	public var value: T!
	
	public init(_ value: T) {
		super.init()
		self.value = value
	}
}

public func clamp<T: Comparable>(value: T, min mn: T, max mx: T) -> T
{
	return min(max(value,mn),mx)
}
