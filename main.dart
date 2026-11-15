import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'field_mapping_screen.dart';
import 'nasa_weather_screen.dart';
import 'weather_rain_alerts_screen.dart';
import 'add_crop_screen.dart';
import 'your_crops_screen.dart';
import 'crop_overall_data_screen.dart';
import 'marketplace_screen.dart';
import 'government_login_screen.dart';
Future<void> setupDIFMSNotifications() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    final token = await messaging.getToken();

    if (token != null) {
      debugPrint('DIFMS FCM Token: $token');
    }
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupDIFMSNotifications();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DIFMS - Smart Farming',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF49D98A),
          brightness: Brightness.dark,
          primary: const Color(0xFF49D98A),
          secondary: const Color(0xFF39C7F4),
          surface: const Color(0xFF102236),
        ),
        scaffoldBackgroundColor: const Color(0xFF071321),
        // Explicit high-contrast typography for the dark space palette.
        // This prevents Material defaults or inherited themes from rendering
        // ordinary text in black on navy surfaces.
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          displayMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          displaySmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFF0F6FC),
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: Color(0xFFE1EAF2),
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: Color(0xFFF0F6FC)),
          bodyMedium: TextStyle(color: Color(0xFFE1EAF2)),
          bodySmall: TextStyle(color: Color(0xFFB7C8D8)),
          labelLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: TextStyle(
            color: Color(0xFFE1EAF2),
            fontWeight: FontWeight.w600,
          ),
          labelSmall: TextStyle(color: Color(0xFFB7C8D8)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE1EAF2)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF091827),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF102236),
          floatingLabelStyle: const TextStyle(color: Color(0xFF49D98A)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          labelStyle: const TextStyle(color: Color(0xFF9EB3C7)),
          hintStyle: const TextStyle(color: Color(0xFF71869B)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF294158)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF294158)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF49D98A), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF7373)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF49D98A),
            foregroundColor: const Color(0xFF062116),
            elevation: 0,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFBDEFD2),
            minimumSize: const Size(0, 50),
            side: const BorderSide(color: Color(0xFF35546A)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF102236),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF243D52)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF183247),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerColor: const Color(0xFF243D52),
      ),
      home: const WelcomeScreen(),
    ),
  );
}

// ---------------- FARMER MODEL ----------------

class Farmer {
  final String name;
  final String mobile;
  final String email;
  final bool emailReminderConsent;
  final String state;
  final String district;
  final String village;
  final String surveyNumber;
  final String landArea;
  final String latitude;
  final String longitude;
  final String soilPH;
  final String flin;
  final String password;
  final List<Map<String, double>> fieldBoundary;
  final double fieldAreaAcres;

  Farmer({
    required this.name,
    required this.mobile,
    required this.email,
    this.emailReminderConsent = false,
    required this.state,
    required this.district,
    required this.village,
    required this.surveyNumber,
    required this.landArea,
    required this.latitude,
    required this.longitude,
    required this.soilPH,
    required this.flin,
    required this.password,
    this.fieldBoundary = const [],
    this.fieldAreaAcres = 0,
  });
}

// Local cache for farmers used during the current app session.
final List<Farmer> registeredFarmers = [];

final Map<String, List<String>> stateDistricts = {
  'Andhra Pradesh': [
    'Alluri Sitharama Raju',
    'Anakapalli',
    'Ananthapuramu',
    'Annamayya',
    'Bapatla',
    'Chittoor',
    'Dr. B. R. Ambedkar Konaseema',
    'East Godavari',
    'Eluru',
    'Guntur',
    'Kakinada',
    'Krishna',
    'Kurnool',
    'Nandyal',
    'NTR',
    'Palnadu',
    'Parvathipuram Manyam',
    'Prakasam',
    'Sri Potti Sriramulu Nellore',
    'Sri Sathya Sai',
    'Srikakulam',
    'Tirupati',
    'Visakhapatnam',
    'Vizianagaram',
    'West Godavari',
    'YSR Kadapa',
  ],
  'Telangana': [
    'Adilabad',
    'Bhadradri Kothagudem',
    'Hanumakonda',
    'Hyderabad',
    'Jagtial',
    'Jangaon',
    'Jayashankar Bhupalpally',
    'Jogulamba Gadwal',
    'Kamareddy',
    'Karimnagar',
    'Khammam',
    'Kumuram Bheem Asifabad',
    'Mahabubabad',
    'Mahabubnagar',
    'Mancherial',
    'Medak',
    'Medchal-Malkajgiri',
    'Mulugu',
    'Nagarkurnool',
    'Nalgonda',
    'Narayanpet',
    'Nirmal',
    'Nizamabad',
    'Peddapalli',
    'Rajanna Sircilla',
    'Rangareddy',
    'Sangareddy',
    'Siddipet',
    'Suryapet',
    'Vikarabad',
    'Wanaparthy',
    'Warangal',
    'Yadadri Bhuvanagiri',
  ],
};

// ---------------- WELCOME SCREEN ----------------

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SpaceBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: width < 380 ? 18 : 24,
                  vertical: 10,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide)
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF49D98A),
                                    Color(0xFFB5F17B),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Color(0xFF082318),
                                size: 29,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DIFMS',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'DIGITAL FARMING INTELLIGENCE',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF9CB5C8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const _LiveBadge(),
                          ],
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF49D98A),
                                        Color(0xFFB5F17B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    color: Color(0xFF082318),
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'DIFMS',
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'DIGITAL FARMING INTELLIGENCE',
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.5,
                                color: Color(0xFF9CB5C8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const _LiveBadge(),
                          ],
                        ),
                      SizedBox(height: wide ? 24 : 5),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 11, child: _HeroCopy()),
                            const SizedBox(width: 24),
                            const Expanded(flex: 9, child: _EarthVisual()),
                          ],
                        )
                      else ...[
                        const _EarthVisual(compact: true),
                        const SizedBox(height: 2),
                        const _HeroCopy(centered: true),
                      ],
                      SizedBox(height: wide ? 24 : 8),
                      const Text(
                        'CHOOSE YOUR WORKSPACE',
                        style: TextStyle(
                          color: Color(0xFF8FA8BD),
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _RoleCard(
                                icon: Icons.agriculture_rounded,
                                title: 'Farmer',
                                subtitle:
                                'Manage your land, crops and field insights.',
                                tag: 'FARM WORKSPACE',
                                accent: const Color(0xFF49D98A),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const FarmerRegistrationScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleCard(
                                icon: Icons.policy_rounded,
                                title: 'Government officer',
                                subtitle:
                                'Review farmer records and crop monitoring.',
                                tag: 'AUTHORIZED ACCESS',
                                accent: const Color(0xFF43C8F4),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const GovernmentLoginScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _RoleCard(
                          icon: Icons.agriculture_rounded,
                          title: 'Farmer workspace',
                          subtitle: 'Manage crops, weather and field insights.',
                          tag: 'CROP • WEATHER • MARKET',
                          accent: const Color(0xFF49D98A),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FarmerRegistrationScreen(),
                            ),
                          ),
                        ),
                        _RoleCard(
                          icon: Icons.policy_rounded,
                          title: 'Government officer',
                          subtitle:
                          'Review farmer records and crop monitoring.',
                          tag: 'AUTHORIZED ACCESS',
                          accent: const Color(0xFF43C8F4),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GovernmentLoginScreen(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FarmerLoginScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text(
                          'Already registered? Sign in as farmer',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: const Color(0xFFD6E8F5),
                          side: const BorderSide(color: Color(0xFF29465D)),
                          backgroundColor: const Color(
                            0xFF0C1C2C,
                          ).withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          _FooterSignal(
                            icon: Icons.satellite_alt_rounded,
                            label: 'Earth observation',
                          ),
                          _FooterSignal(
                            icon: Icons.grass_rounded,
                            label: 'Precision agriculture',
                          ),
                          _FooterSignal(
                            icon: Icons.insights_rounded,
                            label: 'Evidence-led insights',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'NASA and other data sources are identified within relevant features. '
                            'Availability depends on the selected dataset and location.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF637D91),
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Divider(color: Color(0xFF29465D)),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _WelcomeLegalLink(
                            label: 'About DIFMS',
                            icon: Icons.info_outline_rounded,
                            page: _WelcomeInfoPage.about(),
                          ),
                          _WelcomeLegalLink(
                            label: 'Terms & Conditions',
                            icon: Icons.description_outlined,
                            page: _WelcomeInfoPage.terms(),
                          ),
                          _WelcomeLegalLink(
                            label: 'Privacy Policy',
                            icon: Icons.privacy_tip_outlined,
                            page: _WelcomeInfoPage.privacy(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'DIFMS • Digital farming insights for informed decisions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9CB5C8),
                          fontSize: 10,
                          height: 1.25,
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

class _WelcomeLegalLink extends StatelessWidget {
  const _WelcomeLegalLink({
    required this.label,
    required this.icon,
    required this.page,
  });
  final String label;
  final IconData icon;
  final _WelcomeInfoPage page;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page)),
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFFFD166),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
  );
}

class _WelcomeInfoPage extends StatelessWidget {
  const _WelcomeInfoPage({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
  final String title;
  final String subtitle;
  final List<_InfoSection> sections;

  factory _WelcomeInfoPage.about() => const _WelcomeInfoPage(
    title: 'About DIFMS',
    subtitle: 'From space-based observations to field-level decisions.',
    sections: [
      _InfoSection(
        'Our mission',
        'DIFMS (Digital Integrated Farming Monitoring System) is designed to bring crop records, environmental information, field observations and agricultural services together in one place.',
      ),
      _InfoSection(
        'What you can do',
        'Farmers can register and manage crop records, review available weather and environmental information, submit periodic crop photos where supported, and explore marketplace features. Authorized government officers can review permitted farmer and crop records.',
      ),
      _InfoSection(
        'Earth observation',
        'Some features use NASA or other external datasets. Data availability, update frequency, spatial resolution and suitability vary by source and location. A satellite-derived estimate is not the same as a direct field measurement.',
      ),
      _InfoSection(
        'Responsible use',
        'DIFMS is a decision-support tool. Confirm important agricultural, financial or compliance decisions with qualified local experts and official sources.',
      ),
    ],
  );

  factory _WelcomeInfoPage.terms() => const _WelcomeInfoPage(
    title: 'Terms & Conditions',
    subtitle: 'Please use DIFMS responsibly.',
    sections: [
      _InfoSection(
        '1. Account responsibility',
        'Provide accurate information, keep your sign-in credentials confidential, and notify the project administrator if you believe your account has been misused.',
      ),
      _InfoSection(
        '2. Permitted use',
        'Use the app only for lawful agricultural, monitoring, marketplace or authorized administrative purposes. Do not attempt to access another person’s records or bypass role-based access controls.',
      ),
      _InfoSection(
        '3. Data and recommendations',
        'Environmental data, forecasts, satellite estimates and recommendations may be delayed, incomplete or unavailable. They are provided for informational support and are not a guarantee of crop yield, weather conditions, eligibility or government approval.',
      ),
      _InfoSection(
        '4. Marketplace and submissions',
        'Verify counterparties, prices and transaction terms independently. Upload only photos and information you are permitted to share. A record or reminder in DIFMS does not itself mean an official government submission, approval or notification has occurred.',
      ),
      _InfoSection(
        '5. Availability and changes',
        'Features may change as the project is developed. Do not rely on DIFMS as the only place to store critical records. Applicable law and any official service terms remain in effect.',
      ),
    ],
  );

  factory _WelcomeInfoPage.privacy() => const _WelcomeInfoPage(
    title: 'Privacy Policy',
    subtitle: 'Understand what information DIFMS may handle.',
    sections: [
      _InfoSection(
        'Information you provide',
        'Depending on the features you use, DIFMS may store farmer profile and contact details, FLIN or other identifiers, land and crop information, uploaded crop photographs, marketplace records, and messages or reminders.',
      ),
      _InfoSection(
        'How information is used',
        'Information is used to provide account access, display crop and field records, support monitoring workflows, enable marketplace features, and support authorized government review where enabled.',
      ),
      _InfoSection(
        'Service providers and data sources',
        'The app may use Firebase services for authentication and data storage, Cloudinary for image uploads, and NASA or other external data providers for environmental information. Those providers process data under their own terms and privacy practices.',
      ),
      _InfoSection(
        'Access and security',
        'Access should be limited by account role and configured backend security rules. No internet-connected system can be guaranteed completely secure. Do not submit passwords, bank credentials or unrelated sensitive information in crop notes or photos.',
      ),
      _InfoSection(
        'Your choices and contact',
        'Keep your profile accurate and contact the DIFMS project administrator to request help with account or data questions. The project team should publish a verified contact address and retention/deletion procedure before public launch.',
      ),
      _InfoSection(
        'Important project note',
        'This policy describes intended app behavior and must be reviewed against the actual deployed configuration before public release. Data retention, deletion, legal basis and official contact details must be finalized by the project owner.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071321),
    appBar: AppBar(
      title: Text(title),
      backgroundColor: const Color(0xFF0D2031),
      foregroundColor: Colors.white,
    ),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1D2D), Color(0xFF071321)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF29465D)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF123047), Color(0xFF0C2234)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.public_rounded,
                    color: Color(0xFF49D98A),
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final section in sections) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10263A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF203D53)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.heading,
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: const TextStyle(
                        color: Color(0xFFE5EDF5),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _InfoSection {
  const _InfoSection(this.heading, this.body);
  final String heading;
  final String body;
}

class _SpaceBackdrop extends StatelessWidget {
  const _SpaceBackdrop();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF071321), Color(0xFF091C2B), Color(0xFF06111E)],
      ),
    ),
    child: CustomPaint(painter: _StarPainter(), child: const SizedBox.expand()),
  );
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8DB8D3).withValues(alpha: 0.42);
    // Deterministic star positions keep the background stable between rebuilds.
    for (var i = 0; i < 85; i++) {
      final x = ((i * 73 + 19) % 997) / 997 * size.width;
      final y = ((i * 137 + 41) % 991) / 991 * size.height;
      final radius = i % 9 == 0 ? 1.25 : 0.55;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF102A32),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFF2C6856)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: Color(0xFF49D98A), size: 7),
        SizedBox(width: 7),
        Text(
          'FIELD INTELLIGENCE',
          style: TextStyle(
            color: Color(0xFFBDEFD2),
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _HeroCopy extends StatelessWidget {
  final bool centered;
  const _HeroCopy({this.centered = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF14342F),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF2A6953)),
        ),
        child: const Text(
          'FROM SPACE TO SOIL',
          style: TextStyle(
            color: Color(0xFF8DE8B4),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ),
      SizedBox(height: centered ? 6 : 16),
      Text(
        centered
            ? 'See your farm from a new perspective.'
            : 'See your farm\nfrom a new\nperspective.',
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: Colors.white,
          fontSize: centered ? 23 : 37,
          height: centered ? 1.08 : 1.03,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
      ),
      SizedBox(height: centered ? 4 : 13),
      Text(
        centered
            ? 'Satellite insights and field monitoring for smarter farming.'
            : 'Connect crop records, Earth-observation data and practical field monitoring in one farming workspace.',
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: const Color(0xFFB0C2D1),
          fontSize: centered ? 11 : 14,
          height: centered ? 1.25 : 1.55,
        ),
      ),
    ],
  );
}

class _EarthVisual extends StatelessWidget {
  final bool compact;
  const _EarthVisual({this.compact = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 112 : 250,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: compact ? 108 : 230,
          height: compact ? 108 : 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1FBA8C).withValues(alpha: 0.13),
                blurRadius: 44,
                spreadRadius: 12,
              ),
            ],
            border: Border.all(
              color: const Color(0xFF3A8A9A).withValues(alpha: 0.45),
            ),
          ),
        ),
        Container(
          width: compact ? 92 : 195,
          height: compact ? 92 : 195,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.35, -0.45),
              radius: 0.95,
              colors: [Color(0xFF2D8C94), Color(0xFF15526C), Color(0xFF071A35)],
              stops: [0, 0.48, 1],
            ),
          ),
          child: ClipOval(
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 24,
                  child: Transform.rotate(
                    angle: -0.48,
                    child: Container(
                      width: compact ? 48 : 105,
                      height: compact ? 30 : 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF65D68D).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 25,
                  child: Transform.rotate(
                    angle: 0.55,
                    child: Container(
                      width: compact ? 40 : 80,
                      height: compact ? 24 : 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6E878).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.satellite_alt_rounded,
                    size: compact ? 30 : 55,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: compact ? 4 : 20,
          right: compact ? 12 : 35,
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Color(0xFFB5F17B),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0xFFB5F17B), blurRadius: 13)],
            ),
          ),
        ),
        Positioned(
          bottom: compact ? 2 : 26,
          left: compact ? 2 : 30,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 10,
              vertical: compact ? 5 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF102638).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2B5366)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.public_rounded,
                  color: Color(0xFF49D98A),
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'EARTH • FARM • FUTURE',
                  style: TextStyle(
                    color: Color(0xFFD4E6EF),
                    fontSize: compact ? 6 : 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final Color accent;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF0D2030),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.38)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.10),
              const Color(0xFF0D2030),
              const Color(0xFF0A1928),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accent, size: 27),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      color: accent,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFA7BBCB),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: accent, size: 22),
          ],
        ),
      ),
    ),
  );
}

class _FooterSignal extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FooterSignal({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xFF49D98A)),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8FA8BD),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _WelcomeTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WelcomeTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD5E2C7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF39764A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF385440),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- REGISTRATION SCREEN ----------------

class FarmerRegistrationScreen extends StatefulWidget {
  const FarmerRegistrationScreen({super.key});

  @override
  State<FarmerRegistrationScreen> createState() =>
      _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState extends State<FarmerRegistrationScreen> {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final village = TextEditingController();
  final survey = TextEditingController();
  final area = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final ph = TextEditingController();
  final password = TextEditingController();

  String? state;
  String? district;
  bool gettingGPS = false;
  bool hidePassword = true;
  bool emailReminderConsent = false;
  List<Map<String, double>> fieldBoundary = [];
  double fieldAreaAcres = 0;

  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    email.dispose();
    village.dispose();
    survey.dispose();
    area.dispose();
    latitude.dispose();
    longitude.dispose();
    ph.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> getGPS() async {
    setState(() => gettingGPS = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please enable Location on your phone.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Please grant location permission in Settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        latitude.text = position.latitude.toStringAsFixed(6);
        longitude.text = position.longitude.toStringAsFixed(6);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('GPS location captured.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => gettingGPS = false);
      }
    }
  }

  Widget field(
      String label,
      TextEditingController controller, {
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
        bool obscure = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
        validator ??
                (value) => value == null || value.trim().isEmpty
                ? 'Please enter $label'
                : null,
      ),
    );
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    if (state == null || district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select state and district.')),
      );
      return;
    }

    if (latitude.text.isEmpty || longitude.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Get the GPS location first.')),
      );
      return;
    }

    String flin;

    do {
      flin = (10000 + Random.secure().nextInt(90000)).toString();
    } while (registeredFarmers.any((f) => f.flin == flin));

    final farmer = Farmer(
      name: name.text.trim(),
      mobile: mobile.text.trim(),
      email: email.text.trim().toLowerCase(),
      emailReminderConsent: emailReminderConsent,
      state: state!,
      district: district!,
      village: village.text.trim(),
      surveyNumber: survey.text.trim(),
      landArea: area.text.trim(),
      latitude: latitude.text.trim(),
      longitude: longitude.text.trim(),
      soilPH: ph.text.trim(),
      flin: flin,
      password: password.text,
      fieldBoundary: List<Map<String, double>>.from(fieldBoundary),
      fieldAreaAcres: fieldAreaAcres,
    );

    try {
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmer.flin)
          .set({
        'name': farmer.name,
        'mobile': farmer.mobile,
        'email': farmer.email,
        'emailReminderConsent': farmer.emailReminderConsent,
        'emailConsentUpdatedAt': farmer.emailReminderConsent
            ? FieldValue.serverTimestamp()
            : null,
        'state': farmer.state,
        'district': farmer.district,
        'village': farmer.village,
        'surveyNumber': farmer.surveyNumber,
        'landArea': farmer.landArea,
        'latitude': farmer.latitude,
        'longitude': farmer.longitude,
        'soilPH': farmer.soilPH,
        'flin': farmer.flin,

        // Demo only. Use Firebase Authentication in production.
        // Never store plaintext passwords in Firestore.
        'password': farmer.password,

        'fieldBoundary': farmer.fieldBoundary,
        'fieldAreaAcres': farmer.fieldAreaAcres,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save farmer details: $e')),
      );
      return;
    }

    registeredFarmers.add(farmer);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your demo FLIN:'),
            SelectableText(
              flin,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Remember your FLIN for login.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Registration')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            field('Farmer Name', name),
            field(
              'Mobile Number',
              mobile,
              keyboard: TextInputType.phone,
              validator: (v) => v != null && RegExp(r'^[0-9]{10}$').hasMatch(v)
                  ? null
                  : 'Enter a valid 10-digit mobile number',
            ),
            field(
              'Email Address',
              email,
              keyboard: TextInputType.emailAddress,
              validator: (value) {
                final valueTrimmed = value?.trim() ?? '';
                return RegExp(
                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                ).hasMatch(valueTrimmed)
                    ? null
                    : 'Enter a valid email address';
              },
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF102236),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF294158)),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: emailReminderConsent,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Receive government reminders by email',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Optional. You can change this preference later.',
                  style: TextStyle(color: Color(0xFFB7C8D8), fontSize: 12),
                ),
                onChanged: (value) =>
                    setState(() => emailReminderConsent = value ?? false),
              ),
            ),
            DropdownButtonFormField<String>(
              value: state,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
              items: stateDistricts.keys
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() {
                state = v;
                district = null;
              }),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: district,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
              items: (state == null ? <String>[] : stateDistricts[state]!)
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: state == null
                  ? null
                  : (v) => setState(() => district = v),
            ),
            const SizedBox(height: 15),
            field('Village / Town', village),
            field('Survey Number', survey),
            field(
              'Land Area (acres)',
              area,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return n != null && n > 0 ? null : 'Enter a valid area';
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: Text(
                fieldBoundary.length >= 3
                    ? 'Edit Field Boundary (${fieldBoundary.length} corners)'
                    : 'Mark Field Boundary on Map',
              ),
              onPressed: () async {
                final result = await Navigator.push<FieldMappingResult>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FieldMappingScreen(
                      initialLatitude: double.tryParse(latitude.text),
                      initialLongitude: double.tryParse(longitude.text),
                    ),
                  ),
                );

                if (result == null || !mounted) return;

                setState(() {
                  fieldBoundary = result.corners
                      .map(
                        (p) => <String, double>{
                      'latitude': p.latitude,
                      'longitude': p.longitude,
                    },
                  )
                      .toList();

                  fieldAreaAcres = result.areaAcres;
                  area.text = result.areaAcres.toStringAsFixed(3);

                  if (result.corners.isNotEmpty) {
                    latitude.text = result.corners.first.latitude
                        .toStringAsFixed(6);
                    longitude.text = result.corners.first.longitude
                        .toStringAsFixed(6);
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Field boundary added: '
                          '${result.areaAcres.toStringAsFixed(3)} acres (approx.)',
                    ),
                  ),
                );
              },
            ),
            if (fieldBoundary.length >= 3) ...[
              const SizedBox(height: 6),
              Text(
                'Mapped field area: '
                    '${fieldAreaAcres.toStringAsFixed(3)} acres (approx.)',
                style: const TextStyle(
                  color: Color(0xFF246B3B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 5),
            const Text(
              'Farm GPS Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF246B3B),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: gettingGPS ? null : getGPS,
              icon: const Icon(Icons.my_location),
              label: Text(
                gettingGPS ? 'Getting GPS...' : 'Get Current GPS Location',
              ),
            ),
            const SizedBox(height: 15),
            field(
              'Latitude',
              latitude,
              keyboard: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            field(
              'Longitude',
              longitude,
              keyboard: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            field(
              'Soil pH (optional)',
              ph,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v);
                return n != null && n >= 0 && n <= 14
                    ? null
                    : 'Enter a pH value from 0 to 14';
              },
            ),
            TextFormField(
              controller: password,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Create Password (minimum 8 characters)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
              ),
              validator: (v) => v != null && v.length >= 8
                  ? null
                  : 'Password must contain at least 8 characters',
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: register,
                icon: const Icon(Icons.person_add),
                label: const Text('Register Farmer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- LOGIN SCREEN ----------------

class FarmerLoginScreen extends StatefulWidget {
  const FarmerLoginScreen({super.key});

  @override
  State<FarmerLoginScreen> createState() => _FarmerLoginScreenState();
}

class _FarmerLoginScreenState extends State<FarmerLoginScreen> {
  final flin = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;

  @override
  void dispose() {
    flin.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final enteredFlin = flin.text.trim();
    final enteredPassword = password.text;

    if (enteredFlin.isEmpty || enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your FLIN and password.')),
      );
      return;
    }

    try {
      final document = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(enteredFlin)
          .get();

      if (!mounted) return;

      if (!document.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farmer record not found. Check your FLIN.'),
          ),
        );
        return;
      }

      final data = document.data()!;

      if (data['password'] != enteredPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Incorrect password.')));
        return;
      }

      final farmer = Farmer(
        name: (data['name'] ?? '').toString(),
        mobile: (data['mobile'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        emailReminderConsent: data['emailReminderConsent'] == true,
        state: (data['state'] ?? '').toString(),
        district: (data['district'] ?? '').toString(),
        village: (data['village'] ?? '').toString(),
        surveyNumber: (data['surveyNumber'] ?? '').toString(),
        landArea: (data['landArea'] ?? '').toString(),
        latitude: (data['latitude'] ?? '').toString(),
        longitude: (data['longitude'] ?? '').toString(),
        soilPH: (data['soilPH'] ?? '').toString(),
        flin: (data['flin'] ?? enteredFlin).toString(),
        password: (data['password'] ?? '').toString(),
        fieldBoundary: (data['fieldBoundary'] as List<dynamic>? ?? [])
            .map(
              (point) => <String, double>{
            'latitude': ((point as Map)['latitude'] as num).toDouble(),
            'longitude': (point['longitude'] as num).toDouble(),
          },
        )
            .toList(),
        fieldAreaAcres: ((data['fieldAreaAcres'] ?? 0) as num).toDouble(),
      );

      if (!registeredFarmers.any((f) => f.flin == farmer.flin)) {
        registeredFarmers.add(farmer);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FarmerDashboardScreen(farmer: farmer),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                const Icon(Icons.account_circle, size: 85, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  'Welcome, Farmer!',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: flin,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: '5-digit FLIN',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: login,
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- DASHBOARD ----------------



/// Dashboard summary. NASA values are fetched from NASA POWER; ground readings
/// are read from Firestore and visibly marked simulated when applicable.
class _DashboardCropInsights extends StatefulWidget {
  final Farmer farmer;
  const _DashboardCropInsights({required this.farmer});

  @override
  State<_DashboardCropInsights> createState() => _DashboardCropInsightsState();
}

class _DashboardCropInsightsState extends State<_DashboardCropInsights> {
  bool _loading = true;
  String? _error;
  DateTime? _date;
  double? _temp, _humidity, _rain;
  Map<String, dynamic>? _ground;
  Map<String, dynamic>? _crop;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cropDocs = await FirebaseFirestore.instance
          .collection('farmerCrops')
          .where('farmerFlin', isEqualTo: widget.farmer.flin)
          .get();
      final groundDocs = await FirebaseFirestore.instance
          .collection('farmerGroundReadings')
          .where('farmerFlin', isEqualTo: widget.farmer.flin)
          .get();

      Map<String, dynamic>? latestGround;
      final sortedGround = groundDocs.docs.toList()
        ..sort((a, b) {
          final av = a.data()['createdAt'];
          final bv = b.data()['createdAt'];
          final ad = av is Timestamp ? av.toDate() : DateTime(2000);
          final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);
          return bd.compareTo(ad);
        });
      if (sortedGround.isNotEmpty) latestGround = sortedGround.first.data();

      final lat = double.tryParse(widget.farmer.latitude);
      final lon = double.tryParse(widget.farmer.longitude);
      double? temp, humidity, rain;
      DateTime? date;
      if (lat != null && lon != null) {
        final now = DateTime.now().toUtc();
        final uri = Uri.https('power.larc.nasa.gov', '/api/temporal/daily/point', {
          'parameters': 'T2M,RH2M,PRECTOTCORR',
          'community': 'AG',
          'longitude': lon.toStringAsFixed(4),
          'latitude': lat.toStringAsFixed(4),
          'start': _dateKey(now.subtract(const Duration(days: 14))),
          'end': _dateKey(now),
          'format': 'JSON',
          'time-standard': 'UTC',
        });
        final response = await http.get(uri).timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) throw Exception('NASA POWER HTTP ${response.statusCode}');
        final root = jsonDecode(response.body) as Map<String, dynamic>;
        final params = (root['properties'] as Map?)?['parameter'] as Map?;
        double? latest(String key) {
          final values = params?[key];
          if (values is! Map) return null;
          final entries = values.entries.where((e) {
            final n = double.tryParse(e.value.toString());
            return n != null && n > -900;
          }).toList()..sort((a, b) => b.key.toString().compareTo(a.key.toString()));
          if (entries.isEmpty) return null;
          final keyDate = entries.first.key.toString();
          date ??= DateTime.tryParse('${keyDate.substring(0,4)}-${keyDate.substring(4,6)}-${keyDate.substring(6,8)}');
          return double.tryParse(entries.first.value.toString());
        }
        temp = latest('T2M');
        humidity = latest('RH2M');
        rain = latest('PRECTOTCORR');
      }
      if (!mounted) return;
      setState(() {
        _crop = cropDocs.docs.isEmpty ? null : cropDocs.docs.first.data();
        _ground = latestGround;
        _temp = temp; _humidity = humidity; _rain = rain; _date = date;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Some monitoring data could not be loaded.'; });
    }
  }

  String _v(num? n, String unit) => n == null ? 'Unavailable' : '${n.toStringAsFixed(1)} $unit';

  Widget _panel({required String title, required IconData icon, required Color color, required List<Widget> children}) =>
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color), const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)))]),
        const Divider(height: 20),
        ...children,
      ],
      )));

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      const SizedBox(width: 6),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final g = _ground;
    final groundTemp = (g?['airTemperatureC'] as num?)?.toDouble();
    final groundHumidity = (g?['relativeHumidityPercent'] as num?)?.toDouble();
    final moisture = (g?['soilMoisturePercent'] as num?)?.toDouble();
    final ph = (g?['soilPH'] as num?)?.toDouble();
    final simulated = g != null && (g['isSimulated'] == true || g['dataType'] == 'simulated_demo');

    final cropName = (_crop?['cropName'] ?? _crop?['name'] ?? _crop?['crop'] ?? '').toString();
    final suggestions = <String>[];
    if (moisture == null) {
      suggestions.add('Ground soil-moisture data is unavailable; check the sensor connection before making irrigation decisions.');
    } else if (moisture < 30) {
      suggestions.add('Recorded soil moisture is low. Check the field and crop needs before irrigating.');
    } else if (moisture > 75) {
      suggestions.add('Recorded soil moisture is high. Check drainage and avoid unnecessary watering.');
    } else {
      suggestions.add('Review soil moisture alongside the crop growth stage before scheduling irrigation.');
    }
    if (_rain != null && _rain! >= 5) suggestions.add('NASA POWER indicates recent daily precipitation; check field conditions before adding irrigation.');
    if (ph == null) suggestions.add('Add a verified soil pH measurement for more crop-specific guidance.');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Current Crop & Field Insights', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        const Icon(Icons.grass, color: Color(0xFF49D98A), size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CURRENT CROP', style: TextStyle(fontSize: 11, color: Color(0xFFFFD166), fontWeight: FontWeight.bold)),
          Text(cropName.isEmpty ? 'No saved crop record found' : cropName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('FLIN ${widget.farmer.flin} • ${widget.farmer.village}', style: const TextStyle(fontSize: 12)),
          if (_crop != null) Text('Season: ${_crop!['season'] ?? 'Not recorded'} • Area: ${_crop!['areaAcres'] ?? _crop!['area'] ?? 'Not recorded'} acres', style: const TextStyle(fontSize: 12)),
          if (cropName.isEmpty) const Text('Save crop details first to show the current crop here.', style: TextStyle(fontSize: 11, color: Color(0xFFFFD166))),
        ])),
      ]))),
      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())),
      if (_error != null) Card(child: ListTile(leading: const Icon(Icons.info_outline), title: Text(_error!), trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)))),
      if (!_loading) ...[
        if (_date != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('NASA latest available date: ${_date!.day}/${_date!.month}/${_date!.year}', style: const TextStyle(fontSize: 11, color: Color(0xFFFFD166)))),
        _panel(title: 'NASA vs GROUND-LEVEL DATA', icon: Icons.compare_arrows, color: const Color(0xFF43C8F4), children: [
          if (simulated)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('GROUND DATA IS SIMULATED — NOT LIVE ARDUINO DATA',
                  style: TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(const Color(0xFF203A50)),
              dataRowMinHeight: 44,
              dataRowMaxHeight: 58,
              columns: const [
                DataColumn(label: Text('Parameter', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF43C8F4)))),
                DataColumn(label: Text('NASA data', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF43C8F4)))),
                DataColumn(label: Text('Ground-level', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF49D98A)))),
              ],
              rows: [
                DataRow(cells: [const DataCell(Text('Air temperature')), DataCell(Text(_v(_temp, '°C'))), DataCell(Text(_v(groundTemp, '°C')))]),
                DataRow(cells: [const DataCell(Text('Relative humidity')), DataCell(Text(_v(_humidity, '%'))), DataCell(Text(_v(groundHumidity, '%')))]),
                DataRow(cells: [const DataCell(Text('Precipitation')), DataCell(Text(_v(_rain, 'mm/day'))), const DataCell(Text('Not measured'))]),
                DataRow(cells: [const DataCell(Text('Soil moisture')), const DataCell(Text('Not provided')), DataCell(Text(_v(moisture, '%')))]),
                DataRow(cells: [const DataCell(Text('Soil pH')), const DataCell(Text('Not provided')), DataCell(Text(_v(ph, 'pH')))]),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('NASA values are gridded estimates. Ground values are simulated until connected sensors provide real readings.',
              style: TextStyle(fontSize: 10, color: Color(0xFFFFD166))),
        ]),
        _panel(title: 'FARMING SUGGESTIONS', icon: Icons.lightbulb_outline, color: const Color(0xFFFFD166), children: [
          for (final suggestion in suggestions)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_outline, size: 17, color: Color(0xFF49D98A)),
              const SizedBox(width: 8), Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 12, height: 1.4))),
            ])),
          const Text('Suggestions are rule-based prompts, not a crop diagnosis. NASA rainfall is not a substitute for local field inspection.', style: TextStyle(fontSize: 10, color: Color(0xFFFFD166))),
        ]),
      ],
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Refresh field insights'))),
    ]);
  }
}


class FarmerDashboardScreen extends StatelessWidget {
  final Farmer farmer;

  const FarmerDashboardScreen({super.key, required this.farmer});

  // Selected crop production estimates in million tonnes.
  static const Map<String, double> production = {
    'Rice': 154.024,
    'Wheat': 120.657,
    'Maize': 55.093,
    'Millets': 17.584,
    'Gram': 12.514,
    'Tur': 3.592,
    'Lentil': 1.762,
  };

  Future<void> _addDashboardSampleReadings(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('farmerGroundReadings').add({
        'farmerFlin': farmer.flin,
        'farmerName': farmer.name,
        'controller': 'Arduino (planned)',
        'dataType': 'simulated_demo',
        'isSimulated': true,
        'soilMoisturePercent': 42.0,
        'airTemperatureC': 30.2,
        'relativeHumidityPercent': 68.0,
        'soilPH': 6.2,
        'createdAt': FieldValue.serverTimestamp(),
        'note': 'SIMULATED DEMO DATA — not collected from connected sensors.',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demo ground readings saved. These are not live sensor readings.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save sample readings. Check Firestore rules. $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = production.values.fold<double>(
      0,
          (sum, value) => sum + value,
    );

    final maxProduction = production.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Farmer Profile',
          icon: const CircleAvatar(
            backgroundColor: Color(0xFFE5F2E2),
            child: Icon(Icons.person, color: Color(0xFF247A38)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FarmerProfileScreen(farmer: farmer),
              ),
            );
          },
        ),
        title: const Text('DIFMS Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome, ${farmer.name}!',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF247A38),
            ),
          ),
          const SizedBox(height: 8),
          Text('FLIN: ${farmer.flin}'),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF102B48),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF49D98A), width: 1.2),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1D5B49),
                child: Icon(Icons.health_and_safety_outlined, color: Color(0xFF72F0A7)),
              ),
              title: const Text(
                'Crop Disease & Suggestions',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Open crop disease detection and guidance',
                style: TextStyle(color: Color(0xFFB8C9D8)),
              ),
              trailing: const Icon(Icons.open_in_new, color: Color(0xFF72F0A7)),
              onTap: () async {
                final uri = Uri.parse(
                  'https://script.google.com/macros/s/AKfycbyz-EmMGj5GK_IQL-9DGBIG-bDMGjSopZQfv7jugxJoKK9X7Z4QcHiWq2FAIFdh5CI56w/exec',
                );
                try {
                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open Crop Disease & Suggestions link.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open link: $e')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Crop and environmental monitoring sits immediately above the
          // existing national crop-production chart.
          _DashboardCropInsights(farmer: farmer),
          const SizedBox(height: 18),

          const Text(
            'India Crop Statistics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            '2025–26 estimated production of selected crops',
            style: TextStyle(color: Color(0xFFFFD166)),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crop Production Bar Chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),

                  ...production.entries.map((entry) {
                    final share = entry.value / total * 100;
                    final barWidth = entry.value / maxProduction;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${share.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF247A38),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: barWidth,
                              minHeight: 18,
                              backgroundColor: const Color(0xFFE2E9DF),
                              color: const Color(0xFF247A38),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.value.toStringAsFixed(3)} '
                                'million tonnes',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFD166),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(),
                  Text(
                    'Total of displayed crops: '
                        '${total.toStringAsFixed(3)} million tonnes',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Percentages represent the share of combined '
                        'production for these seven selected crops. '
                        'They do not measure demand or shortages.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFFD166)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Farm Management',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.grass, color: Colors.green, size: 32),
              title: const Text('Add Crop'),
              subtitle: const Text('Register your crop details'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddCropScreen(
                      farmerFlin: farmer.flin,
                      farmerName: farmer.name,
                      latitude: farmer.latitude,
                      longitude: farmer.longitude,
                      soilPH: farmer.soilPH,
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.inventory_2,
                color: Colors.teal,
                size: 32,
              ),
              title: const Text('Your Crops'),
              subtitle: const Text('View saved crops and update growth stages'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => YourCropsScreen(farmerFlin: farmer.flin),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.satellite_alt,
                color: Colors.blue,
                size: 32,
              ),
              title: const Text('NASA Satellite Data'),
              subtitle: const Text(
                'View NASA POWER weather data for your farm',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NasaWeatherScreen(
                      latitude: farmer.latitude,
                      longitude: farmer.longitude,
                      farmName: farmer.name,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.storefront,
                color: Color(0xFF246B3B),
                size: 32,
              ),
              title: const Text('Market'),
              subtitle: const Text(
                'Sell your crops or buy crops directly from farmers',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarketplaceScreen(
                      farmerName: farmer.name,
                      flin: farmer.flin,
                      latitude: farmer.latitude,
                      longitude: farmer.longitude,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.compare_arrows,
                color: Colors.indigo,
                size: 32,
              ),
              title: const Text('Crop Overall Data'),
              subtitle: const Text(
                'Compare NASA POWER weather estimates with ground-level IoT readings',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CropOverallDataScreen(
                      farmerFlin: farmer.flin,
                      farmerName: farmer.name,
                      latitude: farmer.latitude,
                      longitude: farmer.longitude,
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.sensors,
                      color: Colors.orange,
                      size: 32,
                    ),
                    title: const Text('Ground Level Data'),
                    subtitle: const Text(
                      'Arduino sensors planned: soil moisture, temperature/humidity and soil pH',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CropOverallDataScreen(
                            farmerFlin: farmer.flin,
                            farmerName: farmer.name,
                            latitude: farmer.latitude,
                            longitude: farmer.longitude,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Presentation-only values; no ground sensors are connected yet.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFFD166)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _addDashboardSampleReadings(context),
                    icon: const Icon(Icons.add_chart),
                    label: const Text('Add Sample Readings'),
                  ),
                ],
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.cloud,
                color: Colors.blueGrey,
                size: 32,
              ),
              title: const Text('Weather and Rain Alerts'),
              subtitle: const Text(
                'Check farm weather, rainfall readings and rain-risk guidance',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeatherRainAlertsScreen(
                      latitude: farmer.latitude,
                      longitude: farmer.longitude,
                      farmName: farmer.name,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- FARMER PROFILE ----------------

class FarmerProfileScreen extends StatelessWidget {
  final Farmer farmer;

  const FarmerProfileScreen({super.key, required this.farmer});

  Widget detail(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Color(0xFFFFD166))),
        subtitle: Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFE5F2E2),
            child: Icon(Icons.person, size: 48, color: Color(0xFF247A38)),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              farmer.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'FLIN: ${farmer.flin}',
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Personal and Land Details',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          detail('Farmer Name', farmer.name),
          detail('Mobile Number', farmer.mobile),
          detail('State', farmer.state),
          detail('District', farmer.district),
          detail('Village / Town', farmer.village),
          detail('Survey Number', farmer.surveyNumber),
          detail('Land Area (acres)', farmer.landArea),
          detail('Latitude', farmer.latitude),
          detail('Longitude', farmer.longitude),
          detail('Soil pH', farmer.soilPH),
          detail(
            'Mapped Field Corners',
            farmer.fieldBoundary.length.toString(),
          ),
          detail(
            'Mapped Field Area (acres)',
            farmer.fieldAreaAcres > 0
                ? farmer.fieldAreaAcres.toStringAsFixed(3)
                : 'No field boundary saved',
          ),
          if (farmer.fieldBoundary.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Field Boundary Coordinates',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            ...farmer.fieldBoundary.asMap().entries.map(
                  (entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${entry.key + 1}')),
                  title: Text(
                    'Latitude: '
                        '${entry.value['latitude']!.toStringAsFixed(6)}',
                  ),
                  subtitle: Text(
                    'Longitude: '
                        '${entry.value['longitude']!.toStringAsFixed(6)}',
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Field Registration Certificate'),
              onPressed: () => generateFarmerCertificate(context, farmer),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- PDF CERTIFICATE ----------------

Future<void> generateFarmerCertificate(
    BuildContext context,
    Farmer farmer,
    ) async {
  final document = pw.Document();
  final certificateNumber = 'DIFMS-${farmer.flin}-${DateTime.now().year}';

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) => pw.Container(
        padding: const pw.EdgeInsets.all(24),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.green800, width: 3),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'DIFMS',
              style: pw.TextStyle(
                fontSize: 30,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'DIGITAL INDIAN FARMING MONITORING SYSTEM',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'FIELD REGISTRATION CERTIFICATE',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Certificate No: $certificateNumber'),
            pw.SizedBox(height: 20),
            pw.Text(
              'This certificate records the farm details submitted '
                  'to the DIFMS application.',
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 22),
            _certificateRow('Farmer Name', farmer.name),
            _certificateRow('Farmer Identification Number (FLIN)', farmer.flin),
            _certificateRow('Mobile Number', farmer.mobile),
            _certificateRow('State', farmer.state),
            _certificateRow('District', farmer.district),
            _certificateRow('Village / Town', farmer.village),
            _certificateRow('Survey Number', farmer.surveyNumber),
            _certificateRow('Recorded Land Area', '${farmer.landArea} acres'),
            _certificateRow(
              'Mapped Area (approx.)',
              farmer.fieldAreaAcres > 0
                  ? '${farmer.fieldAreaAcres.toStringAsFixed(3)} acres'
                  : 'Not mapped',
            ),
            _certificateRow(
              'Boundary Corners',
              '${farmer.fieldBoundary.length}',
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'IMPORTANT: This is an application-generated record '
                  'only. It is not proof of land ownership or a '
                  'government-issued land title.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated: '
                  '${DateTime.now().toLocal().toString().split('.').first}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => document.save(),
    name: 'DIFMS_Certificate_${farmer.flin}.pdf',
  );
}

pw.Widget _certificateRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 190,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(child: pw.Text(value.isEmpty ? 'Not provided' : value)),
      ],
    ),
  );
}

// ---------------- CROP REGISTRATION + CROP RECOMMENDATIONS ----------------

class CropRegistrationScreen extends StatefulWidget {
  final Farmer farmer;

  const CropRegistrationScreen({super.key, required this.farmer});

  @override
  State<CropRegistrationScreen> createState() => _CropRegistrationScreenState();
}

class _CropRegistrationScreenState extends State<CropRegistrationScreen> {
  final cropName = TextEditingController();
  final cropArea = TextEditingController();
  final soilPH = TextEditingController();

  String season = 'Kharif';
  String? selectedCrop;

  // General reference pH ranges. Local conditions can vary.
  static const Map<String, _CropRecommendationData> cropData = {
    'Rice': _CropRecommendationData(
      5.5,
      6.5,
      90,
      'MSP-supported cereal; procurement depends on state and season.',
    ),
    'Wheat': _CropRecommendationData(
      6.0,
      7.5,
      88,
      'MSP-supported rabi cereal; local procurement access matters.',
    ),
    'Maize': _CropRecommendationData(
      5.8,
      7.0,
      72,
      'MSP crop; actual government procurement varies by location.',
    ),
    'Bajra': _CropRecommendationData(
      5.5,
      7.5,
      70,
      'Check local buyers and millet procurement access.',
    ),
    'Jowar': _CropRecommendationData(
      5.5,
      7.5,
      62,
      'Demand and procurement vary by region.',
    ),
    'Ragi': _CropRecommendationData(
      5.0,
      7.0,
      60,
      'Check local market demand and procurement access.',
    ),
    'Gram (Chickpea)': _CropRecommendationData(
      6.0,
      8.0,
      78,
      'Pulse procurement depends on scheme and season.',
    ),
    'Lentil': _CropRecommendationData(
      6.0,
      8.0,
      66,
      'Confirm local suitability and buyer access.',
    ),
    'Red gram (Tur)': _CropRecommendationData(
      5.5,
      7.0,
      78,
      'Procurement depends on state and season.',
    ),
    'Groundnut': _CropRecommendationData(
      6.0,
      6.5,
      70,
      'Oilseed procurement is not guaranteed locally.',
    ),
    'Mustard': _CropRecommendationData(
      5.5,
      7.5,
      74,
      'Mostly a rabi-season option.',
    ),
    'Soybean': _CropRecommendationData(
      6.0,
      7.0,
      72,
      'Verify local marketing arrangements.',
    ),
    'Cotton': _CropRecommendationData(
      5.8,
      8.0,
      70,
      'Suitability depends strongly on local conditions.',
    ),
    'Chilli': _CropRecommendationData(
      6.0,
      7.0,
      45,
      'Local market demand is important.',
    ),
    'Tomato': _CropRecommendationData(
      5.5,
      7.0,
      45,
      'Prices can fluctuate sharply.',
    ),
  };

  @override
  void initState() {
    super.initState();
    soilPH.text = widget.farmer.soilPH;
  }

  @override
  void dispose() {
    cropName.dispose();
    cropArea.dispose();
    soilPH.dispose();
    super.dispose();
  }

  double? get effectivePH => double.tryParse(soilPH.text.trim());

  double soilScore(_CropRecommendationData crop, double? ph) {
    if (ph == null || ph < 0 || ph > 14) {
      return 50;
    }

    if (ph >= crop.phMin && ph <= crop.phMax) {
      return 100;
    }

    final distance = ph < crop.phMin ? crop.phMin - ph : ph - crop.phMax;

    return (100 - distance * 25).clamp(0, 100).toDouble();
  }

  double totalScore(_CropRecommendationData crop, double? ph) {
    return (soilScore(crop, ph) + crop.demandIndex) / 2;
  }

  List<MapEntry<String, _CropRecommendationData>> rankedCrops(double? ph) {
    final entries = cropData.entries.toList();

    entries.sort(
          (a, b) => totalScore(b.value, ph).compareTo(totalScore(a.value, ph)),
    );

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final ph = effectivePH;
    final recommendations = rankedCrops(ph).take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Crop & Suggestions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.recommend, color: Color(0xFF246B3B), size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recommended crops for your farm',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Farmer FLIN: ${widget.farmer.flin}'),
                  Text(
                    'Saved soil pH: '
                        '${widget.farmer.soilPH.isEmpty ? "Not recorded" : widget.farmer.soilPH}',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ranking = 50% soil pH suitability + '
                        '50% government-demand indicator.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter a recent soil-test pH below to update '
                        'the ranking. If pH is unavailable, soil '
                        'suitability is treated as neutral (50/100).',
                    style: TextStyle(color: Color(0xFFFFD166)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: soilPH,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Soil pH (saved value prefilled; editable)',
              helperText: 'Valid range: 0–14',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.science_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),

          if (soilPH.text.trim().isNotEmpty &&
              (ph == null || ph < 0 || ph > 14))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Enter a valid pH between 0 and 14.',
                style: TextStyle(color: Colors.red),
              ),
            ),

          const SizedBox(height: 10),

          ...recommendations.asMap().entries.map((ranked) {
            final rank = ranked.key + 1;
            final entry = ranked.value;
            final sScore = soilScore(entry.value, ph);
            final dScore = entry.value.demandIndex.toDouble();
            final combined = totalScore(entry.value, ph);

            final suitable =
                ph != null &&
                    ph >= entry.value.phMin &&
                    ph <= entry.value.phMax;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE4F2DF),
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF246B3B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Suitable pH: '
                                    '${entry.value.phMin.toStringAsFixed(1)}–'
                                    '${entry.value.phMax.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD166),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${combined.toStringAsFixed(0)}/100',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF246B3B),
                              ),
                            ),
                            const Text(
                              'combined score',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFFD166),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _scoreBar('Soil suitability · 50%', sScore),
                    _scoreBar('Government indicator · 50%', dScore),
                    const SizedBox(height: 8),
                    Text(
                      entry.value.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFFD166),
                      ),
                    ),
                    if (suitable)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Your entered pH is within this crop’s '
                              'general range.',
                          style: TextStyle(
                            color: Color(0xFF246B3B),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Choose this crop'),
                        onPressed: () {
                          setState(() {
                            selectedCrop = entry.key;
                            cropName.text = entry.key;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Data transparency: The government indicator is a '
                    'prototype ranking value, not live procurement '
                    'data or a verified local demand forecast. MSP '
                    'does not guarantee procurement. Confirm the '
                    'current season, local procurement access, '
                    'irrigation, soil test and market before planting.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFFD166),
                  height: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
          const Text(
            'Government references',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Official MSP and crop statistics (DA&FW)'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Open https://desagri.gov.in/ for the latest '
                        'MSP and crop production releases.',
                  ),
                ),
              );
            },
          ),

          const Divider(height: 28),
          const Text(
            'Register a crop',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: selectedCrop,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select recommended or other crop',
              border: OutlineInputBorder(),
            ),
            items: [
              ...cropData.keys.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
              ),
              const DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (v) {
              setState(() {
                selectedCrop = v;
                cropName.text = v == 'Other' ? '' : (v ?? '');
              });
            },
          ),

          const SizedBox(height: 14),
          TextField(
            controller: cropName,
            decoration: const InputDecoration(
              labelText: 'Crop Name',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),
          TextField(
            controller: cropArea,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Area for this crop (acres)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: season,
            decoration: const InputDecoration(
              labelText: 'Growing Season',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Kharif', child: Text('Kharif')),
              DropdownMenuItem(value: 'Rabi', child: Text('Rabi')),
              DropdownMenuItem(value: 'Summer', child: Text('Summer')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => season = v);
            },
          ),

          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Crop Details'),
              onPressed: () {
                final nameValue = cropName.text.trim();
                final areaValue = double.tryParse(cropArea.text.trim());
                final phText = soilPH.text.trim();
                final phValue = phText.isEmpty ? null : double.tryParse(phText);

                if (nameValue.isEmpty ||
                    areaValue == null ||
                    areaValue <= 0 ||
                    (phText.isNotEmpty &&
                        (phValue == null || phValue < 0 || phValue > 14))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a crop name, valid area and pH.'),
                    ),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Crop Details'),
                    content: Text(
                      'Crop: $nameValue\n'
                          'Area: $areaValue acres\n'
                          'Season: $season\n'
                          'Soil pH: ${phText.isEmpty ? "Not entered" : phText}'
                          '\n\nThese details are not yet saved permanently.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _scoreBar(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFE5EAE2),
              color: const Color(0xFF43844E),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropRecommendationData {
  final double phMin;
  final double phMax;
  final int demandIndex;
  final String note;

  const _CropRecommendationData(
      this.phMin,
      this.phMax,
      this.demandIndex,
      this.note,
      );
}