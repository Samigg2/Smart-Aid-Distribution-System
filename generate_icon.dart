import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  // Create icon directory if it doesn't exist
  final iconDir = Directory('assets/icon');
  if (!iconDir.existsSync()) {
    iconDir.createSync(recursive: true);
  }

  // Create 1024x1024 icon
  const size = 1024;
  final icon = img.Image(width: size, height: size);

  // Fill with blue background
  img.fill(icon, color: img.ColorRgb8(33, 150, 243)); // #2196F3

  // Draw a white circle in the center
  final center = size ~/ 2;
  final radius = size ~/ 3;
  img.drawCircle(
    icon,
    centerX: center,
    centerY: center,
    radius: radius,
    color: img.ColorRgb8(255, 255, 255),
  );

  // Draw "SA" text in the center (using simple shapes to represent letters)
  // Draw "S" shape
  final sWidth = size ~/ 4;
  final sHeight = size ~/ 3;
  final sX = center - sWidth ~/ 2;
  final sY = center - sHeight ~/ 2;
  
  // Top curve of S
  img.drawCircle(
    icon,
    centerX: sX + sWidth ~/ 2,
    centerY: sY + sHeight ~/ 4,
    radius: sWidth ~/ 4,
    color: img.ColorRgb8(33, 150, 243),
    thickness: 20,
  );
  
  // Middle line of S
  img.drawLine(
    icon,
    x1: sX,
    y1: sY + sHeight ~/ 2,
    x2: sX + sWidth,
    y2: sY + sHeight ~/ 2,
    color: img.ColorRgb8(33, 150, 243),
    thickness: 20,
  );
  
  // Bottom curve of S
  img.drawCircle(
    icon,
    centerX: sX + sWidth ~/ 2,
    centerY: sY + 3 * sHeight ~/ 4,
    radius: sWidth ~/ 4,
    color: img.ColorRgb8(33, 150, 243),
    thickness: 20,
  );

  // Draw "A" shape
  final aX = center + sWidth ~/ 4;
  final aY = center - sHeight ~/ 2;
  
  // Left side of A
  img.drawLine(
    icon,
    x1: aX,
    y1: aY + sHeight,
    x2: aX + sWidth ~/ 4,
    y2: aY,
    color: img.ColorRgb8(33, 150, 243),
    thickness: 20,
  );
  
  // Right side of A
  img.drawLine(
    icon,
    x1: aX + sWidth ~/ 2,
    y1: aY,
    x2: aX + 3 * sWidth ~/ 4,
    y2: aY + sHeight,
    color: img.ColorRgb8(33, 150, 243),
    thickness: 20,
  );
  
  // Crossbar of A
  img.drawLine(
    icon,
    x1: aX + sWidth ~/ 6,
    y1: aY + sHeight ~/ 2,
    x2: aX + 5 * sWidth ~/ 6,
    y2: aY + sHeight ~/ 2,
    color: img.ColorRgb8(33, 150, 243),
    thickness: 20,
  );

  // Save the icon
  final pngBytes = img.encodePng(icon);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);
  print('Icon generated: assets/icon/app_icon.png');

  // Create foreground icon (same as main icon for adaptive icon)
  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(pngBytes);
  print('Foreground icon generated: assets/icon/app_icon_foreground.png');
}

