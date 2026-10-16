import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:bookies/core/theme/app_theme.dart';
import 'package:bookies/core/routing/app_router.dart';
import 'package:bookies/features/library/bloc/library_bloc.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/features/discussion/bloc/discussion_bloc.dart';
import 'package:bookies/data/providers/local_data_service.dart';

import 'package:bookies/core/theme/theme_cubit.dart';

import 'package:bookies/data/repositories/discussion_repository.dart';
import 'package:bookies/data/repositories/local_discussion_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final localDataService = LocalDataService();
  await localDataService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalDataService>.value(
          value: localDataService,
        ),
        Provider<DiscussionRepository>(
          create: (context) => LocalDiscussionRepository(context.read<LocalDataService>()),
        ),
      ],
      child: const BookiesApp(),
    ),
  );
}

class BookiesApp extends StatelessWidget {
  const BookiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit(context.read<LocalDataService>())),
        BlocProvider(create: (context) => LibraryBloc(context.read<LocalDataService>())..add(LoadLibrary())),
        BlocProvider(create: (context) => ReaderBloc(context.read<LocalDataService>())),
        BlocProvider(create: (context) => DiscussionBloc(context.read<LocalDataService>())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Bookies',
            theme: themeState.themeData,
            darkTheme: AppTheme.charcoalNight,
            themeMode: themeState.mode == AppThemeMode.system ? ThemeMode.system : ThemeMode.light,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
