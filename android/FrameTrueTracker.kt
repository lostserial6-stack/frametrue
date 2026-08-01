package dev.frametrue

enum class FrameTrueOrientation {
    PORTRAIT,
    PORTRAIT_UPSIDE_DOWN,
    LANDSCAPE_LEFT,
    LANDSCAPE_RIGHT,
    UNKNOWN
}

data class FrameTrueResult(
    val orientation: FrameTrueOrientation,
    val portraitSeconds: Double,
    val landscapeSeconds: Double,
    val unknownSeconds: Double,
    val confidence: Double
)

class FrameTrueTracker {
    private val durations = mutableMapOf<FrameTrueOrientation, Double>()
    private var current = FrameTrueOrientation.UNKNOWN
    private var lastNs: Long? = null

    fun reset() {
        durations.clear()
        current = FrameTrueOrientation.UNKNOWN
        lastNs = null
    }

    fun start(orientation: FrameTrueOrientation, nowNs: Long = System.nanoTime()) {
        reset()
        current = orientation
        lastNs = nowNs
    }

    fun update(orientation: FrameTrueOrientation, nowNs: Long = System.nanoTime()) {
        accrue(nowNs)
        current = orientation
    }

    fun finish(nowNs: Long = System.nanoTime()): FrameTrueResult {
        accrue(nowNs)
        lastNs = null
        return result()
    }

    private fun accrue(nowNs: Long) {
        val last = lastNs ?: run {
            lastNs = nowNs
            return
        }
        val dt = (nowNs - last).coerceAtLeast(0L) / 1_000_000_000.0
        durations[current] = (durations[current] ?: 0.0) + dt
        lastNs = nowNs
    }

    fun result(): FrameTrueResult {
        val portrait = (durations[FrameTrueOrientation.PORTRAIT] ?: 0.0) +
            (durations[FrameTrueOrientation.PORTRAIT_UPSIDE_DOWN] ?: 0.0)
        val landscape = (durations[FrameTrueOrientation.LANDSCAPE_LEFT] ?: 0.0) +
            (durations[FrameTrueOrientation.LANDSCAPE_RIGHT] ?: 0.0)
        val unknown = durations[FrameTrueOrientation.UNKNOWN] ?: 0.0
        val classified = portrait + landscape
        if (classified <= 0.0) {
            return FrameTrueResult(FrameTrueOrientation.UNKNOWN, portrait, landscape, unknown, 0.0)
        }
        val final = if (landscape >= portrait) FrameTrueOrientation.LANDSCAPE_LEFT
                    else FrameTrueOrientation.PORTRAIT
        return FrameTrueResult(
            final,
            portrait,
            landscape,
            unknown,
            maxOf(portrait, landscape) / classified
        )
    }
}
