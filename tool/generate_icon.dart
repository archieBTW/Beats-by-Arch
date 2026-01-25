// ignore_for_file: depend_on_referenced_packages
// Run with: dart run tool/generate_icon.dart

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() async {
  print('🎨 Generating app icons from SVG design...\n');
  
  Directory('assets').createSync(recursive: true);
  
  // Generate 1024x1024 master icons
  final icon = generateIcon(1024);
  final foreground = generateForeground(1024);
  
  File('assets/icon.png').writeAsBytesSync(img.encodePng(icon));
  print('✓ Created assets/icon.png (1024x1024)');
  
  File('assets/icon_foreground.png').writeAsBytesSync(img.encodePng(foreground));
  print('✓ Created assets/icon_foreground.png (1024x1024)');
  
  print('\n🚀 Now run: dart run flutter_launcher_icons\n');
}

img.Image generateIcon(int size) {
  final image = img.Image(width: size, height: size);
  final scale = size / 512.0;
  
  // Fill background #121212
  img.fill(image, color: img.ColorRgba8(0x12, 0x12, 0x12, 255));
  
  // Draw all elements
  drawOuterWaves(image, scale, 0.3, 0x00, 0xE5, 0xFF); // Cyan outer waves
  drawOuterWaves2(image, scale, 0.2, 0x7B, 0x2C, 0xBF); // Purple outer waves
  drawHeadphoneBand(image, scale);
  drawBrainIcon(image, scale);
  drawEarCups(image, scale);
  
  // Round corners
  roundCorners(image, (100 * scale).round());
  
  return image;
}

img.Image generateForeground(int size) {
  final image = img.Image(width: size, height: size);
  final scale = size / 512.0;
  
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  
  drawOuterWaves(image, scale, 0.3, 0x00, 0xE5, 0xFF);
  drawOuterWaves2(image, scale, 0.2, 0x7B, 0x2C, 0xBF);
  drawHeadphoneBand(image, scale);
  drawBrainIcon(image, scale);
  drawEarCups(image, scale);
  
  return image;
}

void drawOuterWaves(img.Image image, double scale, double opacity, int r, int g, int b) {
  final strokeWidth = (4 * scale).round();
  final alpha = (255 * opacity).round();
  final color = img.ColorRgba8(r, g, b, alpha);
  
  // Left wave: M60 256 C 60 160, 100 100, 150 256
  drawBezierCurve(image, 
    60 * scale, 256 * scale,
    60 * scale, 160 * scale,
    100 * scale, 100 * scale,
    150 * scale, 256 * scale,
    strokeWidth, color);
  
  // Right wave: M452 256 C 452 160, 412 100, 362 256
  drawBezierCurve(image,
    452 * scale, 256 * scale,
    452 * scale, 160 * scale,
    412 * scale, 100 * scale,
    362 * scale, 256 * scale,
    strokeWidth, color);
}

void drawOuterWaves2(img.Image image, double scale, double opacity, int r, int g, int b) {
  final strokeWidth = (4 * scale).round();
  final alpha = (255 * opacity).round();
  final color = img.ColorRgba8(r, g, b, alpha);
  
  // Left wave: M40 256 C 40 120, 90 60, 130 256
  drawBezierCurve(image,
    40 * scale, 256 * scale,
    40 * scale, 120 * scale,
    90 * scale, 60 * scale,
    130 * scale, 256 * scale,
    strokeWidth, color);
  
  // Right wave: M472 256 C 472 120, 422 60, 382 256
  drawBezierCurve(image,
    472 * scale, 256 * scale,
    472 * scale, 120 * scale,
    422 * scale, 60 * scale,
    382 * scale, 256 * scale,
    strokeWidth, color);
}

void drawHeadphoneBand(img.Image image, double scale) {
  final strokeWidth = (24 * scale).round();
  
  // The band path: M120 280 V 220 C 120 130, 130 90, 256 90 C 382 90, 392 130, 392 220 V 280
  // This is: vertical line from (120,280) to (120,220), then curve to (256,90), then curve to (392,220), then to (392,280)
  
  // Left vertical segment
  for (double y = 220 * scale; y <= 280 * scale; y++) {
    final t = (y - 220 * scale) / (60 * scale);
    final color = gradientColor(0.0 + t * 0.1);
    drawThickPoint(image, (120 * scale).round(), y.round(), strokeWidth ~/ 2, color);
  }
  
  // Left curve up to center
  for (double t = 0; t <= 1; t += 0.002) {
    final x = cubicBezier(120 * scale, 120 * scale, 130 * scale, 256 * scale, t);
    final y = cubicBezier(220 * scale, 130 * scale, 90 * scale, 90 * scale, t);
    final colorT = t * 0.5;
    drawThickPoint(image, x.round(), y.round(), strokeWidth ~/ 2, gradientColor(colorT));
  }
  
  // Right curve from center
  for (double t = 0; t <= 1; t += 0.002) {
    final x = cubicBezier(256 * scale, 382 * scale, 392 * scale, 392 * scale, t);
    final y = cubicBezier(90 * scale, 90 * scale, 130 * scale, 220 * scale, t);
    final colorT = 0.5 + t * 0.5;
    drawThickPoint(image, x.round(), y.round(), strokeWidth ~/ 2, gradientColor(colorT));
  }
  
  // Right vertical segment
  for (double y = 220 * scale; y <= 280 * scale; y++) {
    final t = (y - 220 * scale) / (60 * scale);
    final color = gradientColor(0.9 + t * 0.1);
    drawThickPoint(image, (392 * scale).round(), y.round(), strokeWidth ~/ 2, color);
  }
}

void drawBrainIcon(img.Image image, double scale) {
  final strokeWidth = (8 * scale).round();
  final offsetX = 166 * scale;
  final offsetY = 150 * scale;
  
  // Left brain lobe: M 88 10 C 50 10, 10 40, 10 90 C 10 140, 30 170, 88 170
  for (double t = 0; t <= 1; t += 0.005) {
    final x = cubicBezier(88, 50, 10, 10, t);
    final y = cubicBezier(10, 10, 40, 90, t);
    final colorT = ((offsetX + x * scale) - 166 * scale) / (180 * scale);
    drawThickPoint(image, (offsetX + x * scale).round(), (offsetY + y * scale).round(), 
        strokeWidth ~/ 2, gradientColor(colorT.clamp(0, 1)));
  }
  for (double t = 0; t <= 1; t += 0.005) {
    final x = cubicBezier(10, 10, 30, 88, t);
    final y = cubicBezier(90, 140, 170, 170, t);
    final colorT = ((offsetX + x * scale) - 166 * scale) / (180 * scale);
    drawThickPoint(image, (offsetX + x * scale).round(), (offsetY + y * scale).round(),
        strokeWidth ~/ 2, gradientColor(colorT.clamp(0, 1)));
  }
  
  // Right brain lobe: M 92 10 C 130 10, 170 40, 170 90 C 170 140, 150 170, 92 170
  for (double t = 0; t <= 1; t += 0.005) {
    final x = cubicBezier(92, 130, 170, 170, t);
    final y = cubicBezier(10, 10, 40, 90, t);
    final colorT = ((offsetX + x * scale) - 166 * scale) / (180 * scale);
    drawThickPoint(image, (offsetX + x * scale).round(), (offsetY + y * scale).round(),
        strokeWidth ~/ 2, gradientColor(colorT.clamp(0, 1)));
  }
  for (double t = 0; t <= 1; t += 0.005) {
    final x = cubicBezier(170, 170, 150, 92, t);
    final y = cubicBezier(90, 140, 170, 170, t);
    final colorT = ((offsetX + x * scale) - 166 * scale) / (180 * scale);
    drawThickPoint(image, (offsetX + x * scale).round(), (offsetY + y * scale).round(),
        strokeWidth ~/ 2, gradientColor(colorT.clamp(0, 1)));
  }
  
  // Inner wave details
  final innerStroke = (6 * scale).round();
  
  // Left inner waves
  drawSmallCurve(image, offsetX + 45 * scale, offsetY + 60 * scale, 
      offsetX + 65 * scale, offsetY + 80 * scale,
      offsetX + 45 * scale, offsetY + 100 * scale, innerStroke, scale);
  drawSmallCurve(image, offsetX + 60 * scale, offsetY + 130 * scale,
      offsetX + 80 * scale, offsetY + 140 * scale,
      offsetX + 60 * scale, offsetY + 150 * scale, innerStroke, scale);
      
  // Right inner waves  
  drawSmallCurve(image, offsetX + 135 * scale, offsetY + 60 * scale,
      offsetX + 115 * scale, offsetY + 80 * scale,
      offsetX + 135 * scale, offsetY + 100 * scale, innerStroke, scale);
  drawSmallCurve(image, offsetX + 120 * scale, offsetY + 130 * scale,
      offsetX + 100 * scale, offsetY + 140 * scale,
      offsetX + 120 * scale, offsetY + 150 * scale, innerStroke, scale);
}

void drawSmallCurve(img.Image image, double x1, double y1, double cx, double cy, double x2, double y2, int strokeWidth, double scale) {
  for (double t = 0; t <= 1; t += 0.01) {
    final x = quadBezier(x1, cx, x2, t);
    final y = quadBezier(y1, cy, y2, t);
    final colorT = ((x) - 166 * scale) / (180 * scale);
    drawThickPoint(image, x.round(), y.round(), strokeWidth ~/ 2, gradientColor(colorT.clamp(0, 1)));
  }
}

void drawEarCups(img.Image image, double scale) {
  // Left ear cup: rect x="90" y="240" width="60" height="100" rx="20"
  drawRoundedRect(image, 90 * scale, 240 * scale, 60 * scale, 100 * scale, 20 * scale, 6 * scale, true);
  
  // Right ear cup: rect x="362" y="240" width="60" height="100" rx="20"
  drawRoundedRect(image, 362 * scale, 240 * scale, 60 * scale, 100 * scale, 20 * scale, 6 * scale, false);
  
  // Center lines
  final lineColor = img.ColorRgba8(0x33, 0x33, 0x33, 255);
  for (double y = 250 * scale; y <= 330 * scale; y++) {
    drawThickPoint(image, (100 * scale).round(), y.round(), (2 * scale).round(), lineColor);
    drawThickPoint(image, (372 * scale).round(), y.round(), (2 * scale).round(), lineColor);
  }
}

void drawRoundedRect(img.Image image, double x, double y, double w, double h, double r, double strokeWidth, bool isLeft) {
  final fill = img.ColorRgba8(0x1A, 0x1A, 0x24, 255);
  
  // Fill inside
  for (int py = y.round(); py <= (y + h).round(); py++) {
    for (int px = x.round(); px <= (x + w).round(); px++) {
      if (isInsideRoundedRect(px - x, py - y, 0, 0, w, h, r)) {
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, fill);
        }
      }
    }
  }
  
  // Draw border
  final sw = strokeWidth.round();
  for (int py = (y - sw).round(); py <= (y + h + sw).round(); py++) {
    for (int px = (x - sw).round(); px <= (x + w + sw).round(); px++) {
      final inOuter = isInsideRoundedRect(px - x + sw, py - y + sw, -sw.toDouble(), -sw.toDouble(), w + sw * 2, h + sw * 2, r + sw);
      final inInner = isInsideRoundedRect(px - x, py - y, 0, 0, w, h, r);
      
      if (inOuter && !inInner) {
        final t = isLeft ? (py - y) / h : (py - y) / h;
        final colorT = isLeft ? t * 0.3 : 0.7 + t * 0.3;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, gradientColor(colorT.clamp(0, 1)));
        }
      }
    }
  }
}

void drawBezierCurve(img.Image image, double x1, double y1, double cx1, double cy1, double cx2, double cy2, double x2, double y2, int strokeWidth, img.Color color) {
  for (double t = 0; t <= 1; t += 0.002) {
    final x = cubicBezier(x1, cx1, cx2, x2, t);
    final y = cubicBezier(y1, cy1, cy2, y2, t);
    drawThickPoint(image, x.round(), y.round(), strokeWidth ~/ 2, color);
  }
}

double cubicBezier(double p0, double p1, double p2, double p3, double t) {
  final mt = 1 - t;
  return mt * mt * mt * p0 + 3 * mt * mt * t * p1 + 3 * mt * t * t * p2 + t * t * t * p3;
}

double quadBezier(double p0, double p1, double p2, double t) {
  final mt = 1 - t;
  return mt * mt * p0 + 2 * mt * t * p1 + t * t * p2;
}

void drawThickPoint(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (int dy = -radius; dy <= radius; dy++) {
    for (int dx = -radius; dx <= radius; dx++) {
      if (dx * dx + dy * dy <= radius * radius) {
        final px = cx + dx;
        final py = cy + dy;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          // Alpha blend
          final existing = image.getPixel(px, py);
          final newColor = blendColors(existing, color);
          image.setPixel(px, py, newColor);
        }
      }
    }
  }
}

img.Color blendColors(img.Color bg, img.Color fg) {
  final fgA = fg.a / 255.0;
  final bgA = bg.a / 255.0;
  
  if (fgA >= 1.0) return fg;
  if (fgA <= 0.0) return bg;
  
  final outA = fgA + bgA * (1 - fgA);
  if (outA <= 0) return img.ColorRgba8(0, 0, 0, 0);
  
  final r = ((fg.r * fgA + bg.r * bgA * (1 - fgA)) / outA).round();
  final g = ((fg.g * fgA + bg.g * bgA * (1 - fgA)) / outA).round();
  final b = ((fg.b * fgA + bg.b * bgA * (1 - fgA)) / outA).round();
  
  return img.ColorRgba8(r, g, b, (outA * 255).round());
}

bool isInsideRoundedRect(double px, double py, double rx, double ry, double rw, double rh, double radius) {
  radius = min(radius, min(rw / 2, rh / 2));
  if (radius < 0) radius = 0;
  
  if (px >= rx + radius && px <= rx + rw - radius && py >= ry && py <= ry + rh) return true;
  if (px >= rx && px <= rx + rw && py >= ry + radius && py <= ry + rh - radius) return true;
  
  if (isInsideCircle(px, py, rx + radius, ry + radius, radius)) return true;
  if (isInsideCircle(px, py, rx + rw - radius, ry + radius, radius)) return true;
  if (isInsideCircle(px, py, rx + radius, ry + rh - radius, radius)) return true;
  if (isInsideCircle(px, py, rx + rw - radius, ry + rh - radius, radius)) return true;
  
  return false;
}

bool isInsideCircle(double px, double py, double cx, double cy, double r) {
  return (px - cx) * (px - cx) + (py - cy) * (py - cy) <= r * r;
}

img.Color gradientColor(double t) {
  t = t.clamp(0.0, 1.0);
  // #00E5FF (cyan) to #7B2CBF (purple)
  final r = (0x00 + (0x7B - 0x00) * t).round();
  final g = (0xE5 + (0x2C - 0xE5) * t).round();
  final b = (0xFF + (0xBF - 0xFF) * t).round();
  return img.ColorRgba8(r, g, b, 255);
}

void roundCorners(img.Image image, int radius) {
  final width = image.width;
  final height = image.height;
  
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      bool inCorner = false;
      double dist = 0;
      
      if (x < radius && y < radius) {
        dist = sqrt(pow(x - radius, 2) + pow(y - radius, 2));
        inCorner = true;
      } else if (x >= width - radius && y < radius) {
        dist = sqrt(pow(x - (width - radius - 1), 2) + pow(y - radius, 2));
        inCorner = true;
      } else if (x < radius && y >= height - radius) {
        dist = sqrt(pow(x - radius, 2) + pow(y - (height - radius - 1), 2));
        inCorner = true;
      } else if (x >= width - radius && y >= height - radius) {
        dist = sqrt(pow(x - (width - radius - 1), 2) + pow(y - (height - radius - 1), 2));
        inCorner = true;
      }
      
      if (inCorner && dist > radius) {
        image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
      }
    }
  }
}
