/// An extension that adds fractional getters to the [Duration] class.
///
/// This extension provides methods to retrieve the duration in seconds and
/// milliseconds, including the fractional parts.
extension FractionalGetters on Duration {
  /// The number of fractional seconds spanned by this [Duration].
  ///
  /// The returned value can be greater than or equal to 60.

  // This method was ported from Chromium and we are preserving the original
  // name to maintain consistency.
  // ignore: non_constant_identifier_names
  double InSecondsF() => inMicroseconds / Duration.microsecondsPerSecond;

  /// The number of fractional milliseconds spanned by this [Duration].
  ///
  /// The returned value can be greater than or equal to 1000.

  // This method was ported from Chromium and we are preserving the original
  // name to maintain consistency.
  // ignore: non_constant_identifier_names
  double InMillisecondsF() =>
      inMicroseconds / Duration.microsecondsPerMillisecond;
}

/// Creates a [Duration] object from fractional [seconds].
///
/// This function creates a [Duration] object by multiplying the fractional
/// [seconds] by [Duration.microsecondsPerSecond] and discarding any leftover
/// fractional part of the resulting microseconds.
Duration durationFromSeconds(final double seconds) => Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).truncate(),
    );

/// Creates a [Duration] object from fractional [milliseconds].
///
/// This function creates a [Duration] object by multiplying the fractional
/// [milliseconds] by [Duration.microsecondsPerMillisecond] and discarding any
/// leftover fractional part of the resulting microseconds.
Duration durationFromMilliseconds(final double milliseconds) => Duration(
      microseconds:
          (milliseconds * Duration.microsecondsPerMillisecond).truncate(),
    );

/// Returns the lesser of two [Duration] objects, treating `null` as infinity.
///
/// If [b] is `null`, this function returns [a] as the smaller value. Otherwise,
/// it compares the two durations and returns the one with the smaller value.
Duration minDuration(final Duration a, final Duration? b) =>
    (b == null) ? a : (a < b ? a : b);

/// Returns the greater of two [Duration] objects, treating `null` as negative
/// infinity.
///
/// If [b] is `null`, this function returns [a] as the greater value. Otherwise,
/// it compares the two durations and returns the one with the larger value.
Duration maxDuration(final Duration a, final Duration? b) =>
    (b == null) ? a : (a > b ? a : b);
