import MathLibSwift

print("=== MathLib Swift Wrapper Example ===\n")

let a: Int32 = 10
let b: Int32 = 5

print("Using Swift wrapper for C math library:")
print("a = \(a), b = \(b)\n")

print("Addition: \(a) + \(b) = \(MathLib.add(a, b))")
print("Subtraction: \(a) - \(b) = \(MathLib.subtract(a, b))")
print("Multiplication: \(a) * \(b) = \(MathLib.multiply(a, b))")
print("Division: \(a) / \(b) = \(MathLib.divide(a, b))")

let c: Int32 = -42
print("Absolute value: |\(c)| = \(MathLib.abs(c))")

print("Max(\(a), \(b)) = \(MathLib.max(a, b))")
print("Min(\(a), \(b)) = \(MathLib.min(a, b))")

print("\nSwift example completed successfully!")
