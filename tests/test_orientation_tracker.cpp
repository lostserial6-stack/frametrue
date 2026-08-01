#include "frametrue/orientation_tracker.hpp"
#include <cassert>
#include <cmath>
#include <iostream>

using namespace frametrue;

static bool near(double a, double b, double eps = 1e-9) {
    return std::fabs(a - b) < eps;
}

int main() {
    {
        OrientationTracker t;
        t.addDuration(Orientation::portrait, 3.0);
        t.addDuration(Orientation::landscapeLeft, 57.0);
        auto r = t.result();
        assert(r.orientation == Orientation::landscapeLeft);
        assert(near(r.landscapeSeconds, 57.0));
        assert(near(r.portraitSeconds, 3.0));
        assert(near(r.confidence, 0.95));
    }
    {
        OrientationTracker t;
        t.addDuration(Orientation::portrait, 40.0);
        t.addDuration(Orientation::landscapeRight, 20.0);
        auto r = t.result();
        assert(r.orientation == Orientation::portrait);
        assert(near(r.confidence, 2.0 / 3.0));
    }
    {
        OrientationTracker t;
        t.addDuration(Orientation::unknown, 10.0);
        auto r = t.result();
        assert(r.orientation == Orientation::unknown);
        assert(near(r.unknownSeconds, 10.0));
    }
    {
        OrientationTracker t;
        t.addDuration(Orientation::portraitUpsideDown, 5.0);
        t.addDuration(Orientation::landscapeLeft, 5.0);
        auto r = t.result();
        // Stable deterministic tie-break: landscape.
        assert(r.orientation == Orientation::landscapeLeft);
        assert(near(r.confidence, 0.5));
    }

    std::cout << "FrameTrue core tests passed\n";
    return 0;
}
