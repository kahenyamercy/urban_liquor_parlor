import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  late AnimationController _artCtrl;
  late AnimationController _textCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

    _artCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _artCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _artCtrl.forward(from: 0);
    _textCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Page view
          PageView(
            controller: _pageCtrl,
            onPageChanged: _onPageChanged,
            children: [
              _Slide1(artCtrl: _artCtrl, textCtrl: _textCtrl),
              _Slide2(artCtrl: _artCtrl, textCtrl: _textCtrl),
              _Slide3(artCtrl: _artCtrl, textCtrl: _textCtrl),
            ],
          ),

          // Bottom controls — overlaid on all slides
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final colors = [
      const Color(0xFFD4A853),
      const Color(0xFF52A882),
      const Color(0xFF5299E0),
    ];
    final color = colors[_currentPage];

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? color : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Next / Get Started button
          GestureDetector(
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentPage == 0
                      ? [const Color(0xFFAA7E30), const Color(0xFFD4A853),
                          const Color(0xFFE8C47A)]
                      : _currentPage == 1
                          ? [const Color(0xFF1B6B45), const Color(0xFF52A882),
                              const Color(0xFF7BC8A4)]
                          : [const Color(0xFF1B406B), const Color(0xFF5299E0),
                              const Color(0xFF7AB8F5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentPage == 2 ? 'Get Started →' : 'Next',
                  style: const TextStyle(
                    color: Color(0xFF0D0D0D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // Skip
          if (_currentPage < 2) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _goToLogin,
              child: Text('Skip',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                  )),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 1 — Product catalogue
// ─────────────────────────────────────────────────────────────────────────────
class _Slide1 extends StatelessWidget {
  final AnimationController artCtrl;
  final AnimationController textCtrl;

  const _Slide1({required this.artCtrl, required this.textCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a0800), Color(0xFF0D0D0D), Color(0xFF0D0D0D)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Column(
        children: [
          // Art area
          Expanded(
            flex: 55,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background glow
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 300,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4A853).withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Animated bottles
                Positioned(
                  bottom: 20,
                  child: FadeTransition(
                    opacity: artCtrl,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: artCtrl,
                              curve: Curves.easeOutBack)),
                      child: _BottleRow(),
                    ),
                  ),
                ),

                // Floating category chips
                Positioned(
                  top: 60,
                  left: 20,
                  child: FadeTransition(
                    opacity: artCtrl,
                    child: _CategoryChip('🍺 Beer', const Color(0xFFD4A853)),
                  ),
                ),
                Positioned(
                  top: 100,
                  right: 16,
                  child: FadeTransition(
                    opacity: artCtrl,
                    child: _CategoryChip(
                        '🍷 Wine', const Color(0xFF722F37)),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: 40,
                  child: FadeTransition(
                    opacity: artCtrl,
                    child: _CategoryChip(
                        '🥃 Whiskey', const Color(0xFF8B4513)),
                  ),
                ),
              ],
            ),
          ),

          // Text area with space for bottom controls
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 160),
              child: FadeTransition(
                opacity: textCtrl,
                child: SlideTransition(
                  position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: textCtrl,
                          curve: Curves.easeOut)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SlideNumber('01 / 03', const Color(0xFFD4A853)),
                      const SizedBox(height: 12),
                      RichText(
                        text: const TextSpan(children: [
                          TextSpan(
                            text: "Nairobi's finest\n",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'at your fingertips',
                            style: TextStyle(
                              color: Color(0xFFD4A853),
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Browse our full catalogue of beers, wines, whiskeys and spirits. Live stock updates — always know what\'s available.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 2 — Real-time tracking
// ─────────────────────────────────────────────────────────────────────────────
class _Slide2 extends StatefulWidget {
  final AnimationController artCtrl;
  final AnimationController textCtrl;

  const _Slide2({required this.artCtrl, required this.textCtrl});

  @override
  State<_Slide2> createState() => _Slide2State();
}

class _Slide2State extends State<_Slide2>
    with SingleTickerProviderStateMixin {
  late AnimationController _pingCtrl;

  @override
  void initState() {
    super.initState();
    _pingCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() { _pingCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001a0d), Color(0xFF0D0D0D), Color(0xFF0D0D0D)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 55,
            child: FadeTransition(
              opacity: widget.artCtrl,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ping rings
                  AnimatedBuilder(
                    animation: _pingCtrl,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        _PingRing(
                          progress: _pingCtrl.value,
                          color: const Color(0xFF52A882),
                          maxRadius: 120,
                        ),
                        _PingRing(
                          progress: (_pingCtrl.value + 0.4) % 1.0,
                          color: const Color(0xFF52A882),
                          maxRadius: 120,
                        ),
                      ],
                    ),
                  ),

                  // Center pin
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF52A882).withValues(alpha: 0.15),
                      border: Border.all(
                          color: const Color(0xFF52A882), width: 1.5),
                    ),
                    child: const Center(
                        child: Text('📍', style: TextStyle(fontSize: 28))),
                  ),

                  // Status card
                  Positioned(
                    top: 40,
                    right: 32,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52A882).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF52A882)
                                .withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _LiveDot(),
                            SizedBox(width: 6),
                            Text('LIVE',
                                style: TextStyle(
                                    color: Color(0xFF52A882),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                          ]),
                          SizedBox(height: 4),
                          Text('Out for delivery',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text('ETA: 12 min',
                              style: TextStyle(
                                  color: Color(0xFF52A882),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 160),
              child: FadeTransition(
                opacity: widget.textCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SlideNumber('02 / 03', const Color(0xFF52A882)),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                          text: 'Order and track\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: 'in real time',
                          style: TextStyle(
                            color: Color(0xFF52A882),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Watch your order move from confirmed to your door — live updates, no refreshing needed.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 3 — Fast delivery
// ─────────────────────────────────────────────────────────────────────────────
class _Slide3 extends StatefulWidget {
  final AnimationController artCtrl;
  final AnimationController textCtrl;

  const _Slide3({required this.artCtrl, required this.textCtrl});

  @override
  State<_Slide3> createState() => _Slide3State();
}

class _Slide3State extends State<_Slide3>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _progressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00071a), Color(0xFF0D0D0D), Color(0xFF0D0D0D)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 55,
            child: FadeTransition(
              opacity: widget.artCtrl,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rider icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF5299E0).withValues(alpha: 0.1),
                        border: Border.all(
                            color: const Color(0xFF5299E0).withValues(alpha: 0.3),
                            width: 1.5),
                      ),
                      child: const Center(
                          child: Text('🛵',
                              style: TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 28),

                    // Progress steps
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StepItem('Received', true,
                                const Color(0xFF52A882)),
                            _StepLine(true, const Color(0xFF52A882)),
                            _StepItem('Confirmed', true,
                                const Color(0xFF52A882)),
                            _StepLine(true, const Color(0xFFD4A853)),
                            _StepItem('On way', true,
                                const Color(0xFFD4A853)),
                            _StepLine(false, Colors.white12),
                            _StepItem('Delivered', false, Colors.white24),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Progress bar
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressCtrl,
                            builder: (_, __) => FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.6 + _progressCtrl.value * 0.15,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF52A882),
                                      Color(0xFFD4A853)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Est. 15–25 min · Kayole area',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                              letterSpacing: 0.3,
                            )),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 160),
              child: FadeTransition(
                opacity: widget.textCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SlideNumber('03 / 03', const Color(0xFF5299E0)),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                          text: 'Fast delivery\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: 'across Kayole',
                          style: TextStyle(
                            color: Color(0xFF5299E0),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Our riders know every street in Kayole. Order now and get your drinks delivered in under 30 minutes.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _BottleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottles = [
      {'h': 140.0, 'w': 32.0, 'c1': const Color(0xFFD4A853),
          'c2': const Color(0xFF8B6420)},
      {'h': 110.0, 'w': 28.0, 'c1': const Color(0xFF722F37),
          'c2': const Color(0xFF3D1520)},
      {'h': 160.0, 'w': 36.0, 'c1': const Color(0xFF1B4D6E),
          'c2': const Color(0xFF0a2030)},
      {'h': 100.0, 'w': 30.0, 'c1': const Color(0xFF4A7C3F),
          'c2': const Color(0xFF1a3015)},
      {'h': 130.0, 'w': 26.0, 'c1': const Color(0xFF8B4513),
          'c2': const Color(0xFF3d1f08)},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bottles.map((b) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Bottle neck
              Container(
                width: (b['w'] as double) * 0.4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [b['c1'] as Color, b['c2'] as Color],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ),
              // Bottle body
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: b['w'] as double,
                  height: b['h'] as double,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [b['c1'] as Color,
                          (b['c2'] as Color).withValues(alpha: 0.8)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                        bottom: Radius.circular(2)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _SlideNumber extends StatelessWidget {
  final String text;
  final Color color;
  const _SlideNumber(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w500));
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(
            color: Color(0xFF52A882), shape: BoxShape.circle),
      ),
    );
  }
}

class _PingRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double maxRadius;
  const _PingRing(
      {required this.progress,
      required this.color,
      required this.maxRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxRadius * 2 * progress,
      height: maxRadius * 2 * progress,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: (1 - progress) * 0.4),
          width: 1.5,
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool done;
  final Color color;
  const _StepItem(this.label, this.done, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color : Colors.white12),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
            color: done ? color : Colors.white24,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          )),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  final Color color;
  const _StepLine(this.done, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
          height: 1.5,
          margin: const EdgeInsets.only(bottom: 14),
          color: color),
    );
  }
}