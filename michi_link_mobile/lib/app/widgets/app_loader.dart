import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:michi_link_mobile/app/app.dart';

class AppLoader {
  AppLoader(this.context);

  final BuildContext context;

  late double _size;
  bool _isLoading = false;
  int _loadingSessionId = 0;

  Future<void> showLoading({double size = 120}) async {
    _size = size;
    _isLoading = true;
    final sessionId = ++_loadingSessionId;

    await showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) => PopScope(
        canPop: false,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: _size,
                  height: _size,
                  child: CircularLoadingAnimation(
                    outerCircleColor: const Color(0xFF2D6E44),
                    innerCircleColor: const Color(0xFF96C38C),
                    backgroundColor: Colors.white,
                    centerWidget: Image.asset(
                      'assets/images/logo-no-bg-light.png',
                      width: _size / 3,
                      height: _size / 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (_loadingSessionId == sessionId) {
        _isLoading = false;
      }
    });
  }

  void hideLoading() {
    if (Navigator.of(context).canPop() && _isLoading) {
      Navigator.of(context).pop();
      _isLoading = false;
    }
  }

  bool get isLoading => _isLoading;
}
