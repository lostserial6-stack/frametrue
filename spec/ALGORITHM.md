# FrameTrue algorithm

FrameTrue chooses one presentation orientation for a recorded video using the accumulated time the device spends in portrait versus landscape during the recording session.

## Inputs

A platform adapter provides a stream of classified device states:

- `portrait`
- `portraitUpsideDown`
- `landscapeLeft`
- `landscapeRight`
- `unknown`

`unknown` covers ambiguous states such as face-up / face-down or periods where the platform cannot provide a reliable classification.

## Accumulation

FrameTrue accumulates elapsed duration (`dt`) rather than callback counts. This prevents sampling frequency from biasing the result.

```text
portrait = portrait + portraitUpsideDown
landscape = landscapeLeft + landscapeRight
```

`unknown` does not vote.

## Decision

- If `landscape > portrait`, choose landscape.
- If `portrait > landscape`, choose portrait.
- v0.1 uses landscape as the deterministic tie break.
- If no classified time exists, return `unknown`.

The confidence value is the winning classified duration divided by all classified duration.

## Important non-goals

FrameTrue does **not** crop, trim, rotate individual frames, infer scene content, or change orientation during playback. It chooses the single presentation orientation that best reflects the dominant physical recording orientation.

The initial seconds remain part of the recording even when they differ from the final orientation.
