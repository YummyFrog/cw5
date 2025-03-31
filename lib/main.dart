import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AquariumApp());
}

class AquariumApp extends StatelessWidget {
  const AquariumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AquariumPage(),
    );
  }
}

class AquariumPage extends StatefulWidget {
  const AquariumPage({super.key});

  @override
  State<AquariumPage> createState() => _AquariumPageState();
}

class _AquariumPageState extends State<AquariumPage> with SingleTickerProviderStateMixin {
  final List<Fish> _fishes = [];
  late AnimationController _controller;
  double _speed = 1.0;
  Color _selectedColor = Colors.orange;
  final Random _random = Random();
  final double _aquariumWidth = 300;
  final double _aquariumHeight = 300;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speed = prefs.getDouble('speed') ?? 1.0;
      _selectedColor = Color(prefs.getInt('color') ?? Colors.orange.value);
      
      final fishCount = prefs.getInt('fishCount') ?? 0;
      for (int i = 0; i < fishCount; i++) {
        _addFish(loadFromPrefs: true);
      }
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speed', _speed);
    await prefs.setInt('color', _selectedColor.value);
    await prefs.setInt('fishCount', _fishes.length);
  }

  void _addFish({bool loadFromPrefs = false}) {
    final fish = Fish(
      color: loadFromPrefs ? _selectedColor : _selectedColor.withOpacity(0.7 + _random.nextDouble() * 0.3),
      size: 20 + _random.nextDouble() * 20,
      speed: _speed * (0.5 + _random.nextDouble()),
      aquariumWidth: _aquariumWidth,
      aquariumHeight: _aquariumHeight,
    );
    setState(() {
      _fishes.add(fish);
    });
  }

  void _removeFish() {
    if (_fishes.isNotEmpty) {
      setState(() {
        _fishes.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Aquarium'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquarium Container
            Container(
              width: _aquariumWidth,
              height: _aquariumHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.lightBlue[50],
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    children: _fishes.map((fish) => fish.build()).toList(),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _addFish,
                  child: const Text('Add Fish'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _removeFish,
                  child: const Text('Remove Fish'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Speed Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text('Fish Speed:'),
                  Slider(
                    value: _speed,
                    min: 0.1,
                    max: 3.0,
                    divisions: 10,
                    label: _speed.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _speed = value;
                        for (var fish in _fishes) {
                          fish.speed = value * (0.5 + _random.nextDouble());
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Color Picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text('Fish Color:'),
                  DropdownButton<Color>(
                    value: _selectedColor,
                    onChanged: (Color? newValue) {
                      setState(() {
                        _selectedColor = newValue!;
                      });
                    },
                    items: [
                      Colors.orange,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.purple,
                      Colors.yellow,
                    ].map<DropdownMenuItem<Color>>((Color value) {
                      return DropdownMenuItem<Color>(
                        value: value,
                        child: Container(
                          width: 20,
                          height: 20,
                          color: value,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Fish Count Display
            Text('Fish Count: ${_fishes.length}'),
          ],
        ),
      ),
    );
  }
}

class Fish {
  Color color;
  double size;
  double speed;
  double aquariumWidth;
  double aquariumHeight;
  
  double x;
  double y;
  double dx;
  double dy;
  double angle;
  
  Fish({
    required this.color,
    required this.size,
    required this.speed,
    required this.aquariumWidth,
    required this.aquariumHeight,
  }) : 
    x = Random().nextDouble() * aquariumWidth,
    y = Random().nextDouble() * aquariumHeight,
    dx = Random().nextDouble() * 2 - 1,
    dy = Random().nextDouble() * 2 - 1,
    angle = Random().nextDouble() * 2 * pi;
  
  void update() {
    // Update position
    x += dx * speed;
    y += dy * speed;
    
    // Bounce off walls
    if (x < 0 || x > aquariumWidth) {
      dx = -dx;
      angle = atan2(dy, dx);
    }
    if (y < 0 || y > aquariumHeight) {
      dy = -dy;
      angle = atan2(dy, dx);
    }
    
    // Random direction changes
    if (Random().nextDouble() < 0.01) {
      dx = Random().nextDouble() * 2 - 1;
      dy = Random().nextDouble() * 2 - 1;
      angle = atan2(dy, dx);
    }
    
    // Normalize direction
    final length = sqrt(dx * dx + dy * dy);
    dx /= length;
    dy /= length;
  }
  
  Widget build() {
    update();
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(
          size: Size(size, size),
          painter: FishPainter(color: color),
        ),
      ),
    );
  }
}

class FishPainter extends CustomPainter {
  final Color color;
  
  FishPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    
    // Draw fish body (ellipse)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height / 2,
    );
    canvas.drawOval(bodyRect, paint);
    
    // Draw fish tail (triangle)
    final tailPath = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width / 4, 0)
      ..lineTo(size.width / 4, size.height)
      ..close();
    canvas.drawPath(tailPath, paint);
    
    // Draw fish eye
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.width * 0.1,
      Paint()..color = Colors.black,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}