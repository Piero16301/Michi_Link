part of 'collars_cubit.dart';

class CollarsState extends Equatable {
  const CollarsState({this.collars = const <String>[]});

  final List<String> collars;

  CollarsState copyWith({List<String>? collars}) {
    return CollarsState(collars: collars ?? this.collars);
  }

  @override
  List<Object?> get props => [collars];
}
