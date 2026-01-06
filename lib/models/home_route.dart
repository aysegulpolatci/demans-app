class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceText,
    required this.durationText,
    required this.maneuver,
  });

  final String instruction;
  final String distanceText;
  final String durationText;
  final RouteManeuver maneuver;
}

enum RouteManeuver {
  headNorth,
  turnLeft,
  turnRight,
  continueStraight,
  arrive,
}

class HomeGuideRoute {
  const HomeGuideRoute({
    required this.homeAddress,
    required this.distanceText,
    required this.durationText,
    required this.steps,
  });

  final String homeAddress;
  final String distanceText;
  final String durationText;
  final List<RouteStep> steps;
}

final mockHomeRoute = HomeGuideRoute(
  homeAddress: 'Gül Sokak No:12, Moda / İstanbul',
  distanceText: '2,4 km',
  durationText: '9 dk',
  steps: const [
    RouteStep(
      instruction: 'Bağdat Caddesi boyunca kuzeye ilerle',
      distanceText: '350 m',
      durationText: '1 dk',
      maneuver: RouteManeuver.headNorth,
    ),
    RouteStep(
      instruction: 'Moda Caddesi\'ne sağa dön',
      distanceText: '600 m',
      durationText: '2 dk',
      maneuver: RouteManeuver.turnRight,
    ),
    RouteStep(
      instruction: 'Süreyya Operası kavşağında sola dön',
      distanceText: '1,1 km',
      durationText: '4 dk',
      maneuver: RouteManeuver.turnLeft,
    ),
    RouteStep(
      instruction: 'Gül Sokak boyunca devam et',
      distanceText: '350 m',
      durationText: '1 dk',
      maneuver: RouteManeuver.continueStraight,
    ),
    RouteStep(
      instruction: 'Evine ulaştın',
      distanceText: '—',
      durationText: '—',
      maneuver: RouteManeuver.arrive,
    ),
  ],
);

