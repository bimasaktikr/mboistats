import 'package:flutter_test/flutter_test.dart';
import 'package:mboistats/services/bps_api_service.dart';

void main() {
  test('BpsApiService fetches and parses LPE data correctly', () async {
    final data = await BpsApiService.fetchData(varId: 434, maxYears: 5);
    expect(data.title, contains('Laju Pertumbuhan Ekonomi'));
    expect(data.unit, equals('Persen'));
    expect(data.years.length, equals(5));
    expect(data.series.length, equals(3));
    expect(data.series[0].values.length, equals(5));
    expect(data.series[0].values.every((v) => v != null), isTrue);
  });
}
