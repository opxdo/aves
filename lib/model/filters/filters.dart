import 'dart:convert';

import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/album.dart';
import 'package:aves/model/filters/favourite.dart';
import 'package:aves/model/filters/location.dart';
import 'package:aves/model/filters/mime.dart';
import 'package:aves/model/filters/query.dart';
import 'package:aves/model/filters/tag.dart';
import 'package:aves/model/filters/type.dart';
import 'package:aves/utils/color_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class CollectionFilter implements Comparable<CollectionFilter> {
  static const List<String> collectionFilterOrder = [
    QueryFilter.type,
    FavouriteFilter.type,
    MimeFilter.type,
    TypeFilter.type,
    AlbumFilter.type,
    LocationFilter.type,
    TagFilter.type,
  ];

  static CollectionFilter fromJson(String jsonString) {
    final jsonMap = jsonDecode(jsonString);
    final type = jsonMap['type'];
    switch (type) {
      case AlbumFilter.type:
        return AlbumFilter.fromMap(jsonMap);
      case FavouriteFilter.type:
        return FavouriteFilter();
      case LocationFilter.type:
        return LocationFilter.fromMap(jsonMap);
      case TypeFilter.type:
        return TypeFilter.fromMap(jsonMap);
      case MimeFilter.type:
        return MimeFilter.fromMap(jsonMap);
      case QueryFilter.type:
        return QueryFilter.fromMap(jsonMap);
      case TagFilter.type:
        return TagFilter.fromMap(jsonMap);
    }
    debugPrint('failed to parse filter from json=$jsonString');
    return null;
  }

  const CollectionFilter();

  Map<String, dynamic> toMap();

  String toJson() => jsonEncode(toMap());

  EntryFilter get test;

  bool get isUnique => true;

  String get label;

  String get tooltip => label;

  Widget iconBuilder(BuildContext context, double size, {bool showGenericIcon = true, bool embossed = false});

  Future<Color> color(BuildContext context) => SynchronousFuture(stringToColor(label));

  String get typeKey;

  int get displayPriority => collectionFilterOrder.indexOf(typeKey);

  // to be used as widget key
  String get key => '$typeKey-$label';

  @override
  int compareTo(CollectionFilter other) {
    final c = displayPriority.compareTo(other.displayPriority);
    return c != 0 ? c : compareAsciiUpperCase(label, other.label);
  }
}

class FilterGridItem<T extends CollectionFilter> {
  final T filter;
  final AvesEntry entry;

  const FilterGridItem(this.filter, this.entry);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is FilterGridItem && other.filter == filter && other.entry == entry;
  }

  @override
  int get hashCode => hashValues(filter, entry);
}

typedef EntryFilter = bool Function(AvesEntry);
