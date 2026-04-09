import 'package:flutter/material.dart';

class RingSettings {
  final int ringCount;
  final List<Color> ringColors;
  final double ringThickness;
  final double ringSpacing;
  final double animationSpeed;
  final double waveIntensity;

  RingSettings({
    this.ringCount = 3,
    this.ringColors = const [Colors.cyan, Colors.purple, Colors.pink],
    this.ringThickness = 3.0,
    this.ringSpacing = 20.0,
    this.animationSpeed = 1.0,
    this.waveIntensity = 1.0,
  });

  RingSettings copyWith({
    int? ringCount,
    List<Color>? ringColors,
    double? ringThickness,
    double? ringSpacing,
    double? animationSpeed,
    double? waveIntensity,
  }) {
    return RingSettings(
      ringCount: ringCount ?? this.ringCount,
      ringColors: ringColors ?? this.ringColors,
      ringThickness: ringThickness ?? this.ringThickness,
      ringSpacing: ringSpacing ?? this.ringSpacing,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      waveIntensity: waveIntensity ?? this.waveIntensity,
    );
  }
}