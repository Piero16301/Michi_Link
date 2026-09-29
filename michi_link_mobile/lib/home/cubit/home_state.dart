part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({this.zoom = 10});

  final double zoom;

  HomeState copyWith({double? zoom}) {
    return HomeState(zoom: zoom ?? this.zoom);
  }

  @override
  List<Object?> get props => [zoom];
}
