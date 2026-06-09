import 'package:flutter/material.dart';

import 'package:github_repository_list_app/navigation/main_screen.dart';

class GithubRepositoryListApp extends StatelessWidget {
  const GithubRepositoryListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Repository List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0969DA)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
