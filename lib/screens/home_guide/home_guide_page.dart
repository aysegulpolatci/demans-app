import 'package:flutter/material.dart';

import '../../models/home_route.dart';
import '../../services/tts_service.dart';

class HomeGuidePage extends StatefulWidget {
  const HomeGuidePage({super.key});

  @override
  State<HomeGuidePage> createState() => _HomeGuidePageState();
}

class _HomeGuidePageState extends State<HomeGuidePage> {
  final _ttsService = TtsService();

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _speakRoute(HomeGuideRoute route) async {
    final buffer = StringBuffer()
      ..writeln('Eve dönüş rehberi.')
      ..writeln('Adres: ${route.homeAddress}.')
      ..writeln('Mesafe: ${route.distanceText}, süre: ${route.durationText}.')
      ..writeln('Adımlar:');

    for (int i = 0; i < route.steps.length; i++) {
      final step = route.steps[i];
      buffer.writeln(
          '${i + 1}. ${step.instruction}. Mesafe ${step.distanceText}, süre ${step.durationText}.');
    }

    try {
      await _ttsService.speak(buffer.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sesli tarif hatası: $e'),
          backgroundColor: const Color(0xFFFB7C7C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = mockHomeRoute;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _ModernHeader(route: route),
            
            // Map Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModernMapCard(route: route),
                    const SizedBox(height: 24),
                    _RouteInfoCard(route: route),
                    const SizedBox(height: 28),
                    _StepsSection(
                      steps: route.steps,
                      onSpeak: () => _speakRoute(route),
                    ),
                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _ModernActionButton(
        onNavigate: () => _speakRoute(route),
        onSpeak: () => _speakRoute(route),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ModernHeader extends StatelessWidget {
  const _ModernHeader({required this.route});

  final HomeGuideRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eve Dön',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.home_rounded,
                size: 18,
                color: Color(0xFF4BBE9E),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.homeAddress,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernMapCard extends StatelessWidget {
  const _ModernMapCard({required this.route});

  final HomeGuideRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4BBE9E),
            Color(0xFF3A9B7D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4BBE9E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Map placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.map_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          
          // Route info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(
                    icon: Icons.access_time_rounded,
                    label: route.durationText,
                    color: Colors.white,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _InfoItem(
                    icon: Icons.straighten_rounded,
                    label: route.distanceText,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  const _RouteInfoCard({required this.route});

  final HomeGuideRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFF6C6EF5),
              label: 'Süre',
              value: route.durationText,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: const Color(0xFFE5E5E5),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.straighten_rounded,
              iconColor: const Color(0xFF4BBE9E),
              label: 'Mesafe',
              value: route.distanceText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF999999),
                    fontSize: 13,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
        ),
      ],
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection({
    required this.steps,
    required this.onSpeak,
  });

  final List<RouteStep> steps;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yol Tarifi',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          steps.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < steps.length - 1 ? 12 : 0,
            ),
            child: _ModernStepTile(
              step: steps[index],
              index: index,
              isLast: index == steps.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernStepTile extends StatelessWidget {
  const _ModernStepTile({
    required this.step,
    required this.index,
    required this.isLast,
  });

  final RouteStep step;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number and line
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStepColor(step.maneuver),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Step content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: isLast ? 0 : 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF0F0F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconForManeuver(step.maneuver),
                        size: 20,
                        color: _getStepColor(step.maneuver),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.instruction,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (step.distanceText != '—' && step.durationText != '—')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${step.distanceText} • ${step.durationText}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF999999),
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStepColor(RouteManeuver maneuver) {
    switch (maneuver) {
      case RouteManeuver.arrive:
        return const Color(0xFF4BBE9E);
      case RouteManeuver.turnLeft:
      case RouteManeuver.turnRight:
        return const Color(0xFF6C6EF5);
      default:
        return const Color(0xFF999999);
    }
  }

  IconData _iconForManeuver(RouteManeuver maneuver) {
    switch (maneuver) {
      case RouteManeuver.headNorth:
        return Icons.north_rounded;
      case RouteManeuver.turnLeft:
        return Icons.turn_left_rounded;
      case RouteManeuver.turnRight:
        return Icons.turn_right_rounded;
      case RouteManeuver.continueStraight:
        return Icons.straighten_rounded;
      case RouteManeuver.arrive:
        return Icons.home_rounded;
    }
  }
}

class _ModernActionButton extends StatelessWidget {
  const _ModernActionButton({
    required this.onNavigate,
    required this.onSpeak,
  });

  final VoidCallback onNavigate;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_rounded, size: 22),
              label: const Text(
                'Başlat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4BBE9E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSpeak,
            icon: const Icon(Icons.volume_up_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF8F9FA),
              foregroundColor: const Color(0xFF4BBE9E),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Sesli okut',
          ),
        ],
      ),
    );
  }
}

