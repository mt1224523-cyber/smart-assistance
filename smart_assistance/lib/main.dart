import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/consent_repository.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/screens/consent_screen.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  if (AppConstants.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConstants.sentryDsn;
        options.environment = AppConstants.sentryEnvironment;
        options.release = AppConstants.appVersion;
        options.tracesSampleRate = kReleaseMode ? 0.1 : 0.0;
        options.sendDefaultPii = false;
        options.attachStacktrace = true;
      },
      appRunner: () => runApp(const SmartAssistanceApp()),
    );
  } else {
    runApp(const SmartAssistanceApp());
  }
}

class SmartAssistanceApp extends StatelessWidget {
  const SmartAssistanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider()..initialize(),
      child: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Assistant Intelligent',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
            home: const _RootGate(),
          );
        },
      ),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  final ConsentRepository _consentRepository = ConsentRepository();
  bool? _accepted;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final accepted = await _consentRepository.hasAccepted();
    if (mounted) {
      setState(() => _accepted = accepted);
    }
  }

  Future<void> _handleAccept() async {
    await _consentRepository.accept();
    if (mounted) {
      setState(() => _accepted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _accepted;
    if (accepted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!accepted) {
      return ConsentScreen(onAccept: _handleAccept);
    }
    return const HomeScreen();
  }
}
