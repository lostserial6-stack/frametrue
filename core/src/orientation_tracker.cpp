#include "frametrue/orientation_tracker.hpp"
#include <algorithm>

namespace frametrue {

std::size_t OrientationTracker::index(Orientation orientation) {
    return static_cast<std::size_t>(orientation);
}

void OrientationTracker::reset() {
    seconds_.fill(0.0);
    lastTime_.reset();
    current_ = Orientation::unknown;
    running_ = false;
}

void OrientationTracker::start(Orientation initial, TimePoint now) {
    reset();
    current_ = initial;
    lastTime_ = now;
    running_ = true;
}

void OrientationTracker::accrue(TimePoint now) {
    if (!running_ || !lastTime_) return;
    const std::chrono::duration<double> dt = now - *lastTime_;
    if (dt.count() > 0.0) {
        seconds_[index(current_)] += dt.count();
    }
    lastTime_ = now;
}

void OrientationTracker::update(Orientation next, TimePoint now) {
    if (!running_) {
        start(next, now);
        return;
    }
    accrue(now);
    current_ = next;
}

Result OrientationTracker::finish(TimePoint now) {
    accrue(now);
    running_ = false;
    return result();
}

void OrientationTracker::addDuration(Orientation orientation, double seconds) {
    if (seconds > 0.0) seconds_[index(orientation)] += seconds;
}

Result OrientationTracker::result() const {
    const double portrait = seconds_[index(Orientation::portrait)] +
                            seconds_[index(Orientation::portraitUpsideDown)];
    const double landscape = seconds_[index(Orientation::landscapeLeft)] +
                             seconds_[index(Orientation::landscapeRight)];
    const double unknown = seconds_[index(Orientation::unknown)];
    const double classified = portrait + landscape;

    Result out;
    out.portraitSeconds = portrait;
    out.landscapeSeconds = landscape;
    out.unknownSeconds = unknown;

    if (classified <= 0.0) {
        out.orientation = Orientation::unknown;
        out.confidence = 0.0;
        return out;
    }

    const bool isLandscape = landscape >= portrait;
    out.orientation = isLandscape ? Orientation::landscapeLeft : Orientation::portrait;
    out.confidence = std::max(landscape, portrait) / classified;
    return out;
}

} // namespace frametrue
