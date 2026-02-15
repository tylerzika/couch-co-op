#ifndef MATH_LIB_H
#define MATH_LIB_H

#include <stdint.h>

/**
 * Add two integers
 * @param a First integer
 * @param b Second integer
 * @return Sum of a and b
 */
int32_t math_add(int32_t a, int32_t b);

/**
 * Subtract two integers
 * @param a First integer (minuend)
 * @param b Second integer (subtrahend)
 * @return Difference of a - b
 */
int32_t math_subtract(int32_t a, int32_t b);

/**
 * Multiply two integers
 * @param a First integer
 * @param b Second integer
 * @return Product of a * b
 */
int32_t math_multiply(int32_t a, int32_t b);

/**
 * Divide two integers (integer division)
 * @param a Dividend
 * @param b Divisor (must not be 0)
 * @return Integer quotient of a / b
 */
int32_t math_divide(int32_t a, int32_t b);

/**
 * Get the absolute value of an integer
 * @param x Integer value
 * @return Absolute value of x
 */
int32_t math_abs(int32_t x);

/**
 * Get the maximum of two integers
 * @param a First integer
 * @param b Second integer
 * @return Maximum value
 */
int32_t math_max(int32_t a, int32_t b);

/**
 * Get the minimum of two integers
 * @param a First integer
 * @param b Second integer
 * @return Minimum value
 */
int32_t math_min(int32_t a, int32_t b);

#endif // MATH_LIB_H
