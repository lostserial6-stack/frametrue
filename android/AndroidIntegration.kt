package dev.frametrue

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaMuxer
import java.nio.ByteBuffer

/**
 * Post-capture MP4 remux reference.
 *
 * FrameTrue decides orientation only after recording stops. MediaMuxer requires
 * setOrientationHint() before start(), so the reference flow records a temporary
 * MP4, then remuxes encoded samples into a final MP4 with the chosen composition
 * matrix. The samples are copied; they are not decoded/re-encoded here.
 */
object FrameTrueAndroidIntegration {
    fun remuxWithOrientationHint(
        inputPath: String,
        outputPath: String,
        degrees: Int
    ) {
        require(degrees == 0 || degrees == 90 || degrees == 180 || degrees == 270)

        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        muxer.setOrientationHint(degrees)

        val trackMap = mutableMapOf<Int, Int>()
        var maxBufferSize = 1 * 1024 * 1024

        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val muxerTrack = muxer.addTrack(format)
            trackMap[i] = muxerTrack
            extractor.selectTrack(i)
            if (format.containsKey(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)) {
                maxBufferSize = maxOf(
                    maxBufferSize,
                    format.getInteger(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)
                )
            }
        }

        val buffer = ByteBuffer.allocateDirect(maxBufferSize)
        val info = MediaCodec.BufferInfo()

        muxer.start()
        try {
            while (true) {
                buffer.clear()
                val size = extractor.readSampleData(buffer, 0)
                if (size < 0) break

                val sourceTrack = extractor.sampleTrackIndex
                val targetTrack = trackMap[sourceTrack] ?: error("Unmapped source track")

                info.offset = 0
                info.size = size
                info.presentationTimeUs = extractor.sampleTime
                info.flags = extractor.sampleFlags

                muxer.writeSampleData(targetTrack, buffer, info)
                extractor.advance()
            }
        } finally {
            muxer.stop()
            muxer.release()
            extractor.release()
        }
    }
}
