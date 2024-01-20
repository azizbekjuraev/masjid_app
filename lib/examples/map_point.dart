import 'package:equatable/equatable.dart';

/// Модель точки на карте
class MapPoint extends Equatable {
  MapPoint({
    required this.documentId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Название населенного пункта
  final String documentId;

  String name;

  /// Широта
  final double latitude;

  /// Долгота
  final double longitude;

  @override
  List<Object?> get props => [name, latitude, longitude];
}
