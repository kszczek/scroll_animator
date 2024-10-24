import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_animator/src/utils/duration.dart';

const nanosecondsPerMicrosecond = 1000;
const nanosecondsPerMillisecond =
    nanosecondsPerMicrosecond * Duration.microsecondsPerMillisecond;
const nanosecondsPerSecond =
    nanosecondsPerMillisecond * Duration.millisecondsPerSecond;

const smallerPositiveDuration = Duration(
  minutes: 50,
  seconds: 23,
  milliseconds: 145,
  microseconds: 394,
);
const positiveDuration = Duration(
  minutes: 50,
  seconds: 23,
  milliseconds: 145,
  microseconds: 395,
);
const positiveDurationSeconds = 3023.145395;
const positiveDurationMilliseconds = 3023145.395;

const smallerNegativeDuration = Duration(
  minutes: -50,
  seconds: -23,
  milliseconds: -145,
  microseconds: -396,
);
const negativeDuration = Duration(
  minutes: -50,
  seconds: -23,
  milliseconds: -145,
  microseconds: -395,
);
const negativeDurationSeconds = -3023.145395;
const negativeDurationMilliseconds = -3023145.395;

void main() {
  test(
    'Duration.InSecondsF() returns the duration in fractional seconds',
    () {
      expect(positiveDuration.InSecondsF(), equals(positiveDurationSeconds));
      expect(Duration.zero.InSecondsF(), equals(0.0));
      expect(negativeDuration.InSecondsF(), equals(negativeDurationSeconds));
    },
  );

  test(
    'Duration.InMillisecondsF() returns the duration in fractional '
    'milliseconds',
    () {
      expect(
        positiveDuration.InMillisecondsF(),
        equals(positiveDurationMilliseconds),
      );
      expect(Duration.zero.InSecondsF(), equals(0.0));
      expect(
        negativeDuration.InMillisecondsF(),
        equals(negativeDurationMilliseconds),
      );
    },
  );

  test(
    'durationFromSeconds() converts fractional seconds to a Duration object',
    () {
      expect(
        durationFromSeconds(positiveDurationSeconds),
        equals(positiveDuration),
      );
      expect(durationFromSeconds(0.0), equals(Duration.zero));
      expect(
        durationFromSeconds(negativeDurationSeconds),
        equals(negativeDuration),
      );

      // The fractional part smaller than one microsecond should be discarded.
      expect(
        durationFromSeconds(
          positiveDurationSeconds + (999 / nanosecondsPerSecond),
        ),
        equals(positiveDuration),
      );
      expect(
        durationFromSeconds(
          negativeDurationSeconds - (999 / nanosecondsPerSecond),
        ),
        equals(negativeDuration),
      );

      expect(
        () => durationFromSeconds(double.infinity),
        throwsUnsupportedError,
      );
      expect(
        () => durationFromSeconds(double.negativeInfinity),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'durationFromMilliseconds() converts fractional milliseconds to a Duration '
    'object',
    () {
      expect(
        durationFromMilliseconds(positiveDurationMilliseconds),
        equals(positiveDuration),
      );
      expect(durationFromMilliseconds(0.0), equals(Duration.zero));
      expect(
        durationFromMilliseconds(negativeDurationMilliseconds),
        equals(negativeDuration),
      );

      // The fractional part smaller than one microsecond should be discarded.
      expect(
        durationFromMilliseconds(
          positiveDurationMilliseconds + (999 / nanosecondsPerMillisecond),
        ),
        equals(positiveDuration),
      );
      expect(
        durationFromMilliseconds(
          negativeDurationMilliseconds - (999 / nanosecondsPerMillisecond),
        ),
        equals(negativeDuration),
      );

      expect(
        () => durationFromMilliseconds(double.infinity),
        throwsUnsupportedError,
      );
      expect(
        () => durationFromMilliseconds(double.negativeInfinity),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'minDuration() returns the lesser of two durations, or the first one if '
    'the second one is null',
    () {
      expect(
        minDuration(smallerPositiveDuration, positiveDuration),
        equals(smallerPositiveDuration),
      );
      expect(
        minDuration(smallerNegativeDuration, negativeDuration),
        equals(smallerNegativeDuration),
      );
      expect(
        minDuration(positiveDuration, positiveDuration),
        equals(positiveDuration),
      );
      expect(
        minDuration(negativeDuration, negativeDuration),
        equals(negativeDuration),
      );
      expect(minDuration(positiveDuration, null), equals(positiveDuration));
      expect(minDuration(negativeDuration, null), equals(negativeDuration));
    },
  );

  test(
    'maxDuration() returns the greater of two durations, or the first one if '
    'the second one is null',
    () {
      expect(
        maxDuration(smallerPositiveDuration, positiveDuration),
        equals(positiveDuration),
      );
      expect(
        maxDuration(smallerNegativeDuration, negativeDuration),
        equals(negativeDuration),
      );
      expect(
        maxDuration(positiveDuration, positiveDuration),
        equals(positiveDuration),
      );
      expect(
        maxDuration(negativeDuration, negativeDuration),
        equals(negativeDuration),
      );
      expect(maxDuration(positiveDuration, null), equals(positiveDuration));
      expect(maxDuration(negativeDuration, null), equals(negativeDuration));
    },
  );
}
