import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/operator_screen.dart';
import 'screens/supervisor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TangerMedApp());
}

class TangerMedApp extends StatelessWidget {
  const TangerMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tanger Med',
        theme: ThemeData.dark(),
        home: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (appState.user == null)                  return LoginScreen();
            if (appState.user!.role == 'operator')      return OperatorScreen();
            if (appState.user!.role == 'supervisor')    return SupervisorScreen();
            return LoginScreen();
          },
        ),
      ),
    );
  }
}