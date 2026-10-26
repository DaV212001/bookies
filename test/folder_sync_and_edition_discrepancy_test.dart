import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/repositories/local_book_repository.dart';
import 'package:bookies/domain/entities/community_entity.dart';
import 'package:bookies/features/library/bloc/library_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDataService localDataService;
  late LocalBookRepository bookRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localDataService = LocalDataService();
    await localDataService.init();
    bookRepository = LocalBookRepository(localDataService);
  });

  group('Folder Auto-Sync & Fingerprinting Architecture Tests', () {
    test('localDataService persists and retrieves auto-sync folder path', () async {
      expect(localDataService.getAutoSyncFolder(), isNull);

      await localDataService.setAutoSyncFolder('/storage/emulated/0/Download/Books');
      expect(localDataService.getAutoSyncFolder(), '/storage/emulated/0/Download/Books');

      await localDataService.setAutoSyncFolder(null);
      expect(localDataService.getAutoSyncFolder(), isNull);
    });

    test('addBook deduplicates books based on identical cryptographic fingerprints', () async {
      final book1 = Book(
        id: 'book-1',
        title: 'The Secret History',
        author: 'Donna Tartt',
        fingerprint: 'sha256_mock_hash_12345',
        localPath: '/data/book1.epub',
      );

      final duplicateBook = Book(
        id: 'book-2-duplicate',
        title: 'The Secret History (Copy)',
        author: 'Donna Tartt',
        fingerprint: 'sha256_mock_hash_12345',
        localPath: '/data/copy/book1.epub',
      );

      await localDataService.addBook(book1);
      expect(localDataService.getBooks().length, 1);

      // Adding duplicate book with same fingerprint updates rather than appends duplicate
      await localDataService.addBook(duplicateBook);
      expect(localDataService.getBooks().length, 1);
      expect(localDataService.getBooks().first.title, 'The Secret History (Copy)');
    });

    test('LibraryBloc handles SetAutoSyncFolder and persists state', () async {
      final bloc = LibraryBloc(localDataService, bookRepository: bookRepository);

      bloc.add(const SetAutoSyncFolder('/my/books/folder'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<LibraryLoaded>().having(
            (s) => s.autoSyncFolder,
            'autoSyncFolder',
            '/my/books/folder',
          ),
        ),
      );

      await bloc.close();
    });
  });

  group('Community Edition Discrepancy & Fingerprint Alignment Tests', () {
    test('CommunityEntity preserves canonical edition fingerprint and metadata', () {
      const community = CommunityEntity(
        id: 'comm-10',
        name: 'Dune Discussion Circle',
        description: 'Reading Frank Herbert together',
        bookId: 'dune-cat-1',
        memberCount: 5,
        creatorId: 'user-1',
        canonicalFingerprint: 'sha256_dune_definitive_edition',
        editionTitle: 'Dune (40th Anniversary Illustrated Edition)',
        downloadUrl: '/catalog/dune-cat-1/download',
      );

      expect(community.canonicalFingerprint, 'sha256_dune_definitive_edition');
      expect(community.editionTitle, contains('40th Anniversary'));
      expect(community.downloadUrl, '/catalog/dune-cat-1/download');
    });

    test('LocalDataService createCommunity binds canonical fingerprint from selected book', () async {
      final duneBook = Book(
        id: 'dune-book-id',
        title: 'Dune',
        author: 'Frank Herbert',
        fingerprint: 'sha256_canonical_dune_hash_999',
      );
      await localDataService.addBook(duneBook);

      final newComm = await localDataService.createCommunity(
        name: 'Arrakis Readers',
        description: 'Spice must flow',
        bookId: 'dune-book-id',
      );


      expect(newComm.canonicalFingerprint, 'sha256_canonical_dune_hash_999');
      expect(newComm.editionTitle, 'Dune (Frank Herbert)');
    });
  });
}
