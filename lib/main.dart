import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/publish_screen.dart';
import 'services/image_storage_service.dart';
import 'services/data_migration_service.dart';
import 'services/in_app_purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 初始化内购服务
  await InAppPurchaseService.initialize();
  
  // 清理无效的图片文件和数据
  try {
    await ImageStorageService.cleanupOrphanedImages();
    await DataMigrationService.cleanupInvalidData();
  } catch (e) {
    print('清理数据失败: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '音乐搭子',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文简体
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'CN'),
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        primaryColor: const Color(0xFFFCF15D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFCF15D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFCF15D),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFFCF15D),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/publish': (context) => const PublishScreen(),
      },
    );
  }
}
