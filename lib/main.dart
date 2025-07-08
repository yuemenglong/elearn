import 'package:flutter/material.dart';
import 'package:record_example/db/db.dart';
import 'package:record_example/page/reading_quiz_page.dart';
import 'package:record_example/util/pack/refresh_token.dart';
import 'package:record_example/util/util.dart';
import 'context/context.dart';
import 'page/home_page.dart';
import 'page/reading_page.dart';
import 'page/quiz_page.dart';
import 'page/star_page.dart';
import 'const/const.dart';

void main() async {
  await Db.init();
  AppContext.init();
  Util.refreshToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Record Example',
      initialRoute: '/',
      theme: ThemeData(
        scaffoldBackgroundColor: Const.backgroundColor,
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/reading': (context) => const ReadingPage(),
        '/quizEn2Cn': (context) => const QuizPage(
              isCn2En: false,
            ),
        '/quizCn2En': (context) => const QuizPage(
              isCn2En: true,
            ),
        '/readingQuiz': (context) => const ReadingQuizPage(),
        '/star': (context) => const StarPage(),
      },
    );
  }
}
