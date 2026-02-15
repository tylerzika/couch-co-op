#include <stdio.h>
#include "math_lib.h"

int main(void) {
    printf("=== Math Library Examples ===\n\n");

    // Addition
    int32_t a = 10, b = 5;
    printf("Addition: %d + %d = %d\n", a, b, math_add(a, b));

    // Subtraction
    printf("Subtraction: %d - %d = %d\n", a, b, math_subtract(a, b));

    // Multiplication
    printf("Multiplication: %d * %d = %d\n", a, b, math_multiply(a, b));

    // Division
    printf("Division: %d / %d = %d\n", a, b, math_divide(a, b));

    // Absolute value
    int32_t c = -42;
    printf("Absolute value: |%d| = %d\n", c, math_abs(c));

    // Max and min
    printf("Max(%d, %d) = %d\n", a, b, math_max(a, b));
    printf("Min(%d, %d) = %d\n", a, b, math_min(a, b));

    printf("\nExample completed successfully!\n");
    return 0;
}
