class AppConstants {
  static const String appName = 'Sha Collects';
  static const String companyName = 'Tiny Fab';
  static const String appTagline = 'Tiny Fab Kids Clothing • Route Recovery & Collections';
  static const String officeStartingHub = 'Tiny Fab Central Hub / Office';
  
  // Firestore Collection Names
  static const String shopsCollection = 'shops';
  static const String collectionsCollection = 'collections';
  static const String followUpsCollection = 'follow_ups';
  
  // Payment Modes
  static const String paymentModeCash = 'Cash';
  static const String paymentModeGPay = 'GPay';
  static const String paymentModeCompanyAccount = 'Company Account';
  
  static const List<String> paymentModes = [
    paymentModeCash,
    paymentModeGPay,
    paymentModeCompanyAccount,
  ];

  // Time Slots for follow ups
  static const List<String> defaultTimeSlots = [
    'Morning (9 AM - 12 PM)',
    'Afternoon (12 PM - 4 PM)',
    'Evening (4 PM - 8 PM)',
    'Anytime During Route',
  ];
  
  // Weekly Route Schedule for Tiny Fab field itinerary (Day and District only)
  static const String routeAll = 'All Routes';
  static const String routeMonMalappuram = 'Monday - Malappuram';
  static const String routeTueMalappuram = 'Tuesday - Malappuram';
  static const String routeWedKannur = 'Wednesday - Kannur';
  static const String routeThuKannur = 'Thursday - Kannur';
  static const String routeFriKozhikode = 'Friday - Kozhikode';
  static const String routeSatKozhikode = 'Saturday - Kozhikode';

  // Aliases for compatibility
  static const String routeMonMalappuramSouth = routeMonMalappuram;
  static const String routeTueMalappuramNorth = routeTueMalappuram;
  static const String routeWedKannurSouth = routeWedKannur;
  static const String routeThuKannurNorth = routeThuKannur;
  static const String routeFriKozhikodeCity = routeFriKozhikode;
  static const String routeSatKozhikodeOuter = routeSatKozhikode;

  static const List<String> defaultRoutes = [
    routeAll,
    routeMonMalappuram,
    routeTueMalappuram,
    routeWedKannur,
    routeThuKannur,
    routeFriKozhikode,
    routeSatKozhikode,
  ];

  /// Automatically resolves the designated route based on today's day of week
  static String getTodayDefaultRoute() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case DateTime.monday:
        return routeMonMalappuram;
      case DateTime.tuesday:
        return routeTueMalappuram;
      case DateTime.wednesday:
        return routeWedKannur;
      case DateTime.thursday:
        return routeThuKannur;
      case DateTime.friday:
        return routeFriKozhikode;
      case DateTime.saturday:
        return routeSatKozhikode;
      default:
        return routeAll;
    }
  }

  static String getDayNameForRoute(String route) {
    if (route.startsWith('Monday')) return 'Monday';
    if (route.startsWith('Tuesday')) return 'Tuesday';
    if (route.startsWith('Wednesday')) return 'Wednesday';
    if (route.startsWith('Thursday')) return 'Thursday';
    if (route.startsWith('Friday')) return 'Friday';
    if (route.startsWith('Saturday')) return 'Saturday';
    return 'All Days';
  }

  static String getDistrictForRoute(String route) {
    if (route.contains('Malappuram')) return 'Malappuram';
    if (route.contains('Kannur')) return 'Kannur';
    if (route.contains('Kozhikode')) return 'Kozhikode';
    return 'All Districts';
  }
}
