#include "math/math.hpp"
#include <iostream>

int main() {
  int x = 3, y = 5;
  std::cout << "Sum: " << math::add(x, y) << "\n";
  std::cout << "Product: " << math::multiply(x, y) << "\n";
  return 0;
}
