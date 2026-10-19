import '../../../core/network/api_failure.dart';

typedef Json = Map<String, Object?>;
Json object(Object? value) {
  if (value is! Map) throw const FormatException('Invalid discovery response');
  return Map<String, Object?>.from(value);
}

List<T> rows<T>(Object? value, T Function(Json) decode) {
  if (value is! List) throw const FormatException('Expected list');
  return value.map((item) => decode(object(item))).toList(growable: false);
}

String text(Json json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Missing $key');
  return value;
}

double? number(Json json, String key) {
  final value = json[key];
  return value is num && value.isFinite ? value.toDouble() : null;
}

int integer(Json json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Missing $key');
  return value;
}

class SearchQuery {
  SearchQuery(String input, {this.limit = 5})
    : keyword = input.trim().split(RegExp(r'\s+')).join(' ');
  final String keyword;
  final int limit;
  Map<String, List<String>> get errors => {
    if (keyword.length < 2 || keyword.length > 100)
      'Q': ['Nhập từ 2 đến 100 ký tự sau khi gộp khoảng trắng.'],
    if (limit < 1 || limit > 10) 'Limit': ['Mỗi nhóm có từ 1 đến 10 kết quả.'],
  };
  void validate() {
    if (errors.isNotEmpty) {
      throw ApiFailure(
        FailureKind.validation,
        status: 400,
        code: 'invalid_search_query',
        fields: errors,
      );
    }
  }
}

class Station {
  const Station(this.id, this.name, this.order, this.latitude, this.longitude);
  final String id, name;
  final int order;
  final double? latitude, longitude;
  factory Station.fromJson(Json json) => Station(
    text(json, 'id'),
    text(json, 'name'),
    integer(json, 'order'),
    number(json, 'latitude'),
    number(json, 'longitude'),
  );
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.costMin,
    this.costMax,
    this.rating,
    this.reviewCount,
    this.googlePlaceId,
    this.stationName,
    this.distanceMeters,
  });
  final String id, name, address, category;
  final String? description, imageUrl, googlePlaceId, stationName;
  final double? latitude, longitude, costMin, costMax, rating, distanceMeters;
  final int? reviewCount;
  factory Place.fromJson(Json j) {
    final station = j['nearestStation'] ?? j['station'];
    final ref = station is Map ? object(station) : <String, Object?>{};
    return Place(
      id: text(j, 'id'),
      name: text(j, 'name'),
      address: text(j, 'address'),
      category: text(j, 'category'),
      description: j['description'] as String?,
      imageUrl: j['imageUrl'] as String?,
      latitude: number(j, 'latitude'),
      longitude: number(j, 'longitude'),
      costMin: number(j, 'estimatedCostMin'),
      costMax: number(j, 'estimatedCostMax'),
      rating: number(j, 'averageRating'),
      reviewCount: j['reviewCount'] as int?,
      googlePlaceId: j['googlePlaceId'] as String?,
      stationName: (ref['stationName'] ?? ref['name']) as String?,
      distanceMeters: number(j, 'distanceFromStationMeters'),
    );
  }
}

class CuratedTrip {
  const CuratedTrip(
    this.id,
    this.title,
    this.description,
    this.stationName,
    this.durationMinutes,
    this.costMin,
    this.costMax,
    this.items,
  );
  final String id, title;
  final String? description, stationName;
  final int durationMinutes;
  final double? costMin, costMax;
  final List<CuratedStop> items;
  factory CuratedTrip.fromJson(Json j) => CuratedTrip(
    text(j, 'id'),
    text(j, 'title'),
    j['description'] as String?,
    j['stationName'] as String?,
    integer(j, 'estimatedDurationMinutes'),
    number(j, 'estimatedCostMin'),
    number(j, 'estimatedCostMax'),
    j['items'] == null ? [] : rows(j['items'], CuratedStop.fromJson),
  );
}

class CuratedStop {
  const CuratedStop(this.placeId, this.name, this.order);
  final String placeId, name;
  final int order;
  factory CuratedStop.fromJson(Json j) => CuratedStop(
    text(j, 'placeId'),
    text(j, 'placeName'),
    integer(j, 'orderIndex'),
  );
}

class SearchStation {
  const SearchStation(this.id, this.name, this.order, this.placeCount);
  final String id, name;
  final int order, placeCount;
  factory SearchStation.fromJson(Json j) => SearchStation(
    text(j, 'id'),
    text(j, 'name'),
    integer(j, 'order'),
    integer(j, 'placeCount'),
  );
}

class ResultGroup<T> {
  const ResultGroup(this.items, this.hasMore);
  final List<T> items;
  final bool hasMore;
  static ResultGroup<T> parse<T>(Object? raw, T Function(Json) decode) {
    final j = object(raw);
    if (j['hasMore'] is! bool) throw const FormatException('Missing hasMore');
    return ResultGroup(rows(j['items'], decode), j['hasMore'] as bool);
  }
}

class SearchResults {
  const SearchResults(this.query, this.stations, this.places, this.curated);
  final String query;
  final ResultGroup<SearchStation> stations;
  final ResultGroup<Place> places;
  final ResultGroup<CuratedTrip> curated;
  factory SearchResults.fromJson(Object? raw) {
    final j = object(raw);
    return SearchResults(
      text(j, 'query'),
      ResultGroup.parse(j['stations'], SearchStation.fromJson),
      ResultGroup.parse(j['places'], Place.fromJson),
      ResultGroup.parse(j['curatedItineraries'], CuratedTrip.fromJson),
    );
  }
}

class StationCluster {
  const StationCluster(this.stationId, this.places);
  final String stationId;
  final List<Place> places;
  factory StationCluster.fromJson(Json j) =>
      StationCluster(text(j, 'stationId'), rows(j['places'], Place.fromJson));
}

class Headway {
  const Headway(this.from, this.to, this.minutes);
  final String from, to;
  final int minutes;
  factory Headway.fromJson(Json j) =>
      Headway(text(j, 'from'), text(j, 'to'), integer(j, 'minutes'));
}

class MetroSchedule {
  const MetroSchedule({
    required this.date,
    required this.estimated,
    required this.precision,
    required this.withinPeriod,
    required this.effectiveFrom,
    this.effectiveTo,
    this.notice,
    required this.directions,
  });
  final String date, precision, effectiveFrom;
  final String? effectiveTo, notice;
  final bool estimated, withinPeriod;
  final List<MetroDirection> directions;
  bool get showExact => precision == 'Exact' && withinPeriod;
  factory MetroSchedule.fromJson(Object? raw) {
    final j = object(raw);
    return MetroSchedule(
      date: text(j, 'date'),
      estimated: j['isEstimated'] == true,
      precision: text(j, 'precision'),
      withinPeriod: j['isWithinEffectivePeriod'] == true,
      effectiveFrom: text(j, 'effectiveFrom'),
      effectiveTo: j['effectiveTo'] as String?,
      notice: j['notice'] as String?,
      directions: rows(j['directions'], MetroDirection.fromJson),
    );
  }
}

class MetroDirection {
  const MetroDirection(this.toward, this.headways, this.departures);
  final String toward;
  final List<Headway> headways;
  final List<String> departures;
  factory MetroDirection.fromJson(Json j) => MetroDirection(
    text(j, 'towardStationName'),
    rows(j['headways'], Headway.fromJson),
    (j['departures'] as List).cast<String>(),
  );
}

class MetroJourney {
  const MetroJourney(
    this.from,
    this.to,
    this.minutes,
    this.stopCount,
    this.schedule,
    this.trips,
    this.headways,
  );
  final String from, to;
  final int minutes, stopCount;
  final MetroSchedule schedule;
  final List<({String departure, String arrival})> trips;
  final List<Headway> headways;
  factory MetroJourney.fromJson(Object? raw) {
    final j = object(raw);
    return MetroJourney(
      text(object(j['from']), 'name'),
      text(object(j['to']), 'name'),
      integer(j, 'travelMinutes'),
      integer(j, 'stopCount'),
      MetroSchedule.fromJson({...j, 'directions': <Object?>[]}),
      rows(
        j['trips'],
        (t) => (departure: text(t, 'departure'), arrival: text(t, 'arrival')),
      ),
      rows(j['headways'], Headway.fromJson),
    );
  }
}

abstract final class MapsUrlBuilder {
  static Uri? directions(
    double? latitude,
    double? longitude, {
    String? placeId,
  }) {
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return null;
    }
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      if (placeId != null && placeId.trim().isNotEmpty)
        'destination_place_id': placeId,
      'travelmode': 'walking',
    });
  }
}
