import 'dart:convert';
import 'package:flutter/services.dart';

/// Country entry: code (e.g. US), display name (e.g. United States).
class CountryEntry {
  CountryEntry(this.code, this.name);
  final String code;
  final String name;
}

/// State/province entry: code (e.g. AL), display name (e.g. Alabama).
class StateEntry {
  StateEntry(this.code, this.name);
  final String code;
  final String name;
}

/// Loads country and state data from bundled JSON assets.
class CheckoutData {
  static List<CountryEntry>? _countries;
  static Map<String, List<StateEntry>>? _usStates;
  static Map<String, List<StateEntry>>? _caStates;

  static Future<List<CountryEntry>> getCountries() async {
    if (_countries != null) return _countries!;
    final str = await rootBundle.loadString('assets/data/country.json');
    final map = jsonDecode(str) as Map<String, dynamic>;
    _countries = map.entries.map((e) {
      final v = e.value as Map<String, dynamic>;
      final name = v['country'] as String? ?? e.key;
      return CountryEntry(e.key, name);
    }).toList();
    _countries!.sort((a, b) => a.name.compareTo(b.name));
    return _countries!;
  }

  /// Returns countries filtered by product category rule.
  /// [countryFilter] 'usa_only' = US only; 'usa_canada' = US + Canada; null or 'all' = all countries.
  static Future<List<CountryEntry>> getCountriesFiltered(String? countryFilter) async {
    final all = await getCountries();
    if (countryFilter == 'usa_only') {
      return all.where((c) => c.code == 'US').toList();
    }
    if (countryFilter == 'usa_canada') {
      return all.where((c) => c.code == 'US' || c.code == 'CA').toList();
    }
    return all;
  }

  static Future<List<StateEntry>> getUsStates() async {
    if (_usStates != null) return _usStates!['']!;
    final str = await rootBundle.loadString('assets/data/usastates.json');
    final map = jsonDecode(str) as Map<String, dynamic>;
    final list = map.entries
        .map((e) => StateEntry(e.key, e.value as String))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    _usStates = {'': list};
    return list;
  }

  static Future<List<StateEntry>> getCaStates() async {
    if (_caStates != null) return _caStates!['']!;
    final str = await rootBundle.loadString('assets/data/castates.json');
    final map = jsonDecode(str) as Map<String, dynamic>;
    final list = map.entries
        .map((e) => StateEntry(e.key, e.value as String))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    _caStates = {'': list};
    return list;
  }

  static Future<List<StateEntry>> getStatesForCountry(String countryCode) async {
    final code = countryCode.toUpperCase();
    if (code == 'US') return getUsStates();
    if (code == 'CA') return getCaStates();
    return [];
  }
}
