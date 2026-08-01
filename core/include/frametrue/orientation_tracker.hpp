#pragma once

#include <array>
#include <chrono>
#include <cstdint>
#include <optional>

namespace frametrue {

enum class Orientation : std::uint8_t {
    portrait = 0,
    portraitUpsideDown,
    landscapeLeft,
    landscapeRight,
    unknown
};

struct Result {
    Orientation orientation{Orientation::unknown};
    double portraitSeconds{0.0};
    double landscapeSeconds{0.0};
    double unknownSeconds{0.0};
    double confidence{0.0};
};

class OrientationTracker {
public:
    using Clock = std::chrono::steady_clock;
    using TimePoint = Clock::time_point;

    void reset();
    void start(Orientation initial, TimePoint now = Clock::now());
    void update(Orientation next, TimePoint now = Clock::now());
    Result finish(TimePoint now = Clock::now());

    // Deterministic API useful for tests and platform adapters.
    void addDuration(Orientation orientation, double seconds);
    Result result() const;

private:
    void accrue(TimePoint now);
    static std::size_t index(Orientation orientation);

    std::array<double, 5> seconds_{};
    std::optional<TimePoint> lastTime_{};
    Orientation current_{Orientation::unknown};
    bool running_{false};
};

} // namespace frametrue
