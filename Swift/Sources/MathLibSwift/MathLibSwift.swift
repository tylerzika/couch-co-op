import CMathLib

/// Swift wrapper for the C math library
public struct MathLib {
    /// Add two integers
    /// - Parameters:
    ///   - a: First integer
    ///   - b: Second integer
    /// - Returns: Sum of a and b
    public static func add(_ a: Int32, _ b: Int32) -> Int32 {
        return math_add(a, b)
    }

    /// Subtract two integers
    /// - Parameters:
    ///   - a: Minuend
    ///   - b: Subtrahend
    /// - Returns: Difference of a - b
    public static func subtract(_ a: Int32, _ b: Int32) -> Int32 {
        return math_subtract(a, b)
    }

    /// Multiply two integers
    /// - Parameters:
    ///   - a: First integer
    ///   - b: Second integer
    /// - Returns: Product of a * b
    public static func multiply(_ a: Int32, _ b: Int32) -> Int32 {
        return math_multiply(a, b)
    }

    /// Divide two integers (integer division)
    /// - Parameters:
    ///   - a: Dividend
    ///   - b: Divisor (must not be 0)
    /// - Returns: Integer quotient of a / b
    public static func divide(_ a: Int32, _ b: Int32) -> Int32 {
        return math_divide(a, b)
    }

    /// Get the absolute value
    /// - Parameter x: Integer to get absolute value of
    /// - Returns: Absolute value of x
    public static func abs(_ x: Int32) -> Int32 {
        return math_abs(x)
    }

    /// Get the maximum of two integers
    /// - Parameters:
    ///   - a: First integer
    ///   - b: Second integer
    /// - Returns: Maximum value
    public static func max(_ a: Int32, _ b: Int32) -> Int32 {
        return math_max(a, b)
    }

    /// Get the minimum of two integers
    /// - Parameters:
    ///   - a: First integer
    ///   - b: Second integer
    /// - Returns: Minimum value
    public static func min(_ a: Int32, _ b: Int32) -> Int32 {
        return math_min(a, b)
    }
}
