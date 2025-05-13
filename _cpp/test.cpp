#include <iostream>
#include <optional>

int main() {
    std::optional<int> opt = 10;
    if (opt) {
        std::cout << "Value: " << *opt << std::endl;
    }
    return 0;
}
