import 'dart:math' as math;

import 'package:flutter/material.dart';

class DesktopPhoneFrame extends StatelessWidget {
  const DesktopPhoneFrame({required this.child, super.key});

  final Widget child;

  static const _desktopMinWidth = 760.0;
  static const _desktopMinHeight = 420.0;
  static const _frameAspectRatio = 0.6;
  static const _maximumFrameWidth = 430.0;
  static const _minimumFrameWidth = 240.0;
  static const _screenPadding = 40.0;
  static const _bezelWidth = 8.0;
  static const _cameraSafeAreaHeight = 34.0;
  static const _homeIndicatorAreaHeight = 18.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        if (maxWidth < _desktopMinWidth || maxHeight < _desktopMinHeight) {
          return child;
        }

        final widthBudget = math.max(0.0, maxWidth - _screenPadding * 2);
        final heightBudget = math.max(0.0, maxHeight - _screenPadding * 2);
        var frameWidth = math.min(_maximumFrameWidth, widthBudget);
        var frameHeight = frameWidth / _frameAspectRatio;

        if (frameHeight > heightBudget) {
          frameHeight = heightBudget;
          frameWidth = math.min(frameWidth, frameHeight * _frameAspectRatio);
        }

        if (frameWidth < _minimumFrameWidth) {
          return child;
        }

        final contentWidth = frameWidth - _bezelWidth * 2;
        final contentHeight =
            frameHeight -
            _bezelWidth * 2 -
            _cameraSafeAreaHeight -
            _homeIndicatorAreaHeight;

        final contentSize = Size(contentWidth, contentHeight);

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8EAE5), Color(0xFFD9DDD7)],
            ),
          ),
          child: Center(
            child: SizedBox(
              key: const ValueKey('desktop-phone-frame'),
              width: frameWidth,
              height: frameHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF171819),
                  borderRadius: BorderRadius.circular(42),
                  border: Border.all(color: const Color(0xFF333536)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330D1110),
                      blurRadius: 40,
                      offset: Offset(0, 22),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_bezelWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: ColoredBox(
                      color: const Color(0xFFF7F5F0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: _cameraSafeAreaHeight,
                            child: Center(
                              child: Container(
                                key: const ValueKey('desktop-camera-cutout'),
                                width: 72,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF171819),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SafeArea(
                              top: false,
                              bottom: false,
                              child: MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(size: contentSize),
                                child: child,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: _homeIndicatorAreaHeight,
                            child: Center(
                              child: Container(
                                width: 78,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22201E),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
