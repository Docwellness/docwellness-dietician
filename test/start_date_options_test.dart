import 'package:docwellnesdoc/app/models/start_date_options_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartDateOptions.fromResponse', () {
    test('parses a first-time plan', () {
      final options = StartDateOptions.fromResponse(200, {
        'success': true,
        'data': {
          'required': true,
          'defaultDate': '2026-11-19',
          'minDate': '2026-11-19',
          'isRenewal': false,
          'runningCycleEndDate': null,
        },
      });

      expect(options, isNotNull);
      expect(options!.required, isTrue);
      expect(options.defaultDate, '2026-11-19');
      expect(options.minDate, '2026-11-19');
      expect(options.isRenewal, isFalse);
      expect(options.runningCycleEndDate, isNull);
      expect(options.minDay, DateTime(2026, 11, 19));
    });

    test('parses a renewal with the running plan end', () {
      final options = StartDateOptions.fromResponse(200, {
        'success': true,
        'data': {
          'required': true,
          'defaultDate': '2026-11-19',
          'minDate': '2026-11-26',
          'isRenewal': true,
          'runningCycleEndDate': '2026-11-25',
        },
      });

      expect(options!.isRenewal, isTrue);
      expect(options.minDay, DateTime(2026, 11, 26));
      expect(options.runningCycleEndDay, DateTime(2026, 11, 25));
    });

    test('an old-flow plan is not required', () {
      final options = StartDateOptions.fromResponse(200, {
        'success': true,
        'data': {'required': false},
      });

      expect(options!.required, isFalse);
    });

    test('a 404 means an old backend: no row, not an error', () {
      final options = StartDateOptions.fromResponse(404, {'success': false});

      expect(options, same(StartDateOptions.notRequired));
      expect(options!.required, isFalse);
    });

    test('any other failure is null so the caller shows an error', () {
      expect(StartDateOptions.fromResponse(500, {'success': false}), isNull);
      expect(StartDateOptions.fromResponse(null, null), isNull);
      expect(StartDateOptions.fromResponse(200, {'success': false}), isNull);
      expect(StartDateOptions.fromResponse(200, {'success': true}), isNull);
    });
  });

  group('start day format', () {
    test('formats a calendar day as yyyy-MM-dd with no time or zone', () {
      expect(formatStartDay(DateTime(2026, 11, 9)), '2026-11-09');
      expect(formatStartDay(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
    });

    test('parses only a strict yyyy-MM-dd', () {
      expect(parseStartDay('2026-11-19'), DateTime(2026, 11, 19));
      expect(parseStartDay('2026-11-19T00:00:00.000Z'), isNull);
      expect(parseStartDay('19-11-2026'), isNull);
      expect(parseStartDay(null), isNull);
    });
  });

  group('buildActivateBody', () {
    test('sends the picked day as yyyy-MM-dd, never an ISO timestamp', () {
      final body = buildActivateBody(
        proofId: 'p1',
        amountReceived: 5000,
        amountPending: 0,
        startDay: DateTime(2026, 11, 19),
      );

      expect(body['startDate'], '2026-11-19');
      expect(body['proofId'], 'p1');
      expect(body['amountReceived'], 5000);
      expect(body['amountPending'], 0);
    });

    test('leaves startDate out when the plan needs none', () {
      final body = buildActivateBody(proofId: 'p1', amountReceived: 5000);

      expect(body.containsKey('startDate'), isFalse);
      expect(body.containsKey('amountPending'), isFalse);
    });
  });
}
