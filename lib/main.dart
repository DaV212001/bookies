import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:bookies/core/network/api_client.dart';
import 'package:bookies/core/network/socket_service.dart';
import 'package:bookies/core/services/incoming_file_service.dart';
import 'package:bookies/core/theme/app_theme.dart';
import 'package:bookies/core/routing/app_router.dart';
import 'package:bookies/core/theme/theme_cubit.dart';

import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/repositories/discussion_repository.dart';
import 'package:bookies/data/repositories/api_discussion_repository.dart';
import 'package:bookies/data/repositories/api_community_repository.dart';
import 'package:bookies/data/repositories/local_book_repository.dart';
import 'package:bookies/data/repositories/api_auth_repository.dart';
import 'package:bookies/data/repositories/api_catalog_repository.dart';

import 'package:bookies/domain/repositories/auth_repository.dart';
import 'package:bookies/domain/repositories/book_repository.dart';
import 'package:bookies/domain/repositories/catalog_repository.dart';
import 'package:bookies/domain/repositories/community_repository.dart';

import 'package:bookies/features/library/bloc/library_bloc.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/features/discussion/bloc/discussion_bloc.dart';
import 'package:bookies/features/community/bloc/community_bloc.dart';
import 'package:bookies/features/discover/bloc/catalog_bloc.dart';
import 'package:bookies/features/auth/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localDataService = LocalDataService();
  await localDataService.init();

  const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://bookies-backend-1r9d.onrender.com',
  );
  final apiClient = ApiClient(baseUrl: '$backendUrl/api/v1');
  final socketService = SocketService(
    serverUrl: backendUrl,
    tokenProvider: () => apiClient.cachedToken,
  );
  socketService.connect();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalDataService>.value(
          value: localDataService,
        ),
        Provider<ApiClient>.value(value: apiClient),
        Provider<SocketService>.value(value: socketService),
        Provider<IncomingFileService>(
          create: (_) => IncomingFileService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<AuthRepository>(
          create: (context) => ApiAuthRepository(
            context.read<ApiClient>(),
          ),
        ),
        Provider<BookRepository>(
          create: (context) => LocalBookRepository(
            context.read<LocalDataService>(),
          ),
        ),
        Provider<CommunityRepository>(
          create: (context) => ApiCommunityRepository(
            apiClient: context.read<ApiClient>(),
            localDataService: context.read<LocalDataService>(),
          ),
        ),
        Provider<DiscussionRepository>(
          create: (context) => ApiDiscussionRepository(
            apiClient: context.read<ApiClient>(),
            socketService: context.read<SocketService>(),
            localDataService: context.read<LocalDataService>(),
          ),
        ),
        Provider<CatalogRepository>(
          create: (context) => ApiCatalogRepository(
            apiClient: context.read<ApiClient>(),
            bookRepository: context.read<BookRepository>(),
          ),
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
        BlocProvider(
          create: (context) => ThemeCubit(context.read<LocalDataService>()),
        ),
        BlocProvider(
          create: (context) {
            final bloc = LibraryBloc(context.read<LocalDataService>())..add(LoadLibrary());
            context.read<IncomingFileService>().initialize(
              onFileOpened: (filePath) => bloc.add(ImportBook(filePath)),
            );
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) => ReaderBloc(context.read<LocalDataService>()),
        ),
        BlocProvider(
          create: (context) => DiscussionBloc(context.read<LocalDataService>()),
        ),
        BlocProvider(
          create: (context) => CommunityBloc(
            communityRepository: context.read<CommunityRepository>(),
            bookRepository: context.read<BookRepository>(),
          )..add(const LoadCommunities()),
        ),
        BlocProvider(
          create: (context) => CatalogBloc(
            catalogRepository: context.read<CatalogRepository>(),
          )..add(const FetchCatalogEvent()),
        ),
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: context.read<AuthRepository>(),
          )..add(const CheckAuthStatusEvent()),
        ),
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
