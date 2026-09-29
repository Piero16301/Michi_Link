import 'package:firebase_performance/firebase_performance.dart';
import 'package:michi_link_mobile/app/app.dart';

class PerformanceService {
  PerformanceService({required this._performanceRepository});

  final PerformanceRepository _performanceRepository;

  Trace startTrace(String name) {
    return _performanceRepository.startTrace(name);
  }

  void stopTrace(Trace trace) {
    _performanceRepository.stopTrace(trace);
  }
}
