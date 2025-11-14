#include <cassert>
#include "math/math.hpp"

int main() {
    assert(math::add(2, 3) == 5);
    assert(math::multiply(4, 5) == 20);
    assert(math::add(-1, 1) == 0);
    assert(math::multiply(0, 10) == 0);
    return 0;
}
