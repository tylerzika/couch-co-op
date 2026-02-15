#include "math_lib.h"

int32_t math_add(int32_t a, int32_t b) {
    return a + b;
}

int32_t math_subtract(int32_t a, int32_t b) {
    return a - b;
}

int32_t math_multiply(int32_t a, int32_t b) {
    return a * b;
}

int32_t math_divide(int32_t a, int32_t b) {
    if (b == 0) {
        return 0; // Division by zero protection
    }
    return a / b;
}

int32_t math_abs(int32_t x) {
    return (x < 0) ? -x : x;
}

int32_t math_max(int32_t a, int32_t b) {
    return (a > b) ? a : b;
}

int32_t math_min(int32_t a, int32_t b) {
    return (a < b) ? a : b;
}
