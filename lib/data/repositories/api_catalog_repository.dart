import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:bookies/core/network/api_client.dart';
import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/entities/catalog_book_entity.dart';
import 'package:bookies/domain/repositories/book_repository.dart';
import 'package:bookies/domain/repositories/catalog_repository.dart';

class ApiCatalogRepository implements CatalogRepository {
  final ApiClient _apiClient;
  final BookRepository _bookRepository;

  static const String _tag = 'ApiCatalogRepository';

  // Fallback curated books when backend is disconnected or offline
  static const List<CatalogBookEntity> fallbackBooks = [
    CatalogBookEntity(
      id: 'fallback-secret-history',
      title: 'The Secret History',
      author: 'Donna Tartt',
      coverUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC7cpL27jzawVwPw3wJxDpwBU3uGQMUNJgC_jwFsuKEm3c6S6pxXrO15bNkcjfvyam6YqaZEbIouXlUJwUmWPuaq2TowE295nAdd7eU5DHIJPOJIYzaIscj8WU_yqRRI8fNo6ZqE1YhbRF7ZHVx1ZuabhhDAqjN6IAbfYmG14Ocs8kpM-nTrPsBahyWyrfgNpGpbHry9ufCxtIvl6oJ5b_CcKT5yRgJCqhZLGi3Bsz0U4c-2wgw607D',
      description:
          'Under the influence of their charismatic classics professor, a group of clever, eccentric misfits at an elite New England college discover a way of thinking and living that is a world away from the humdrum existence of their contemporaries.',
      activeReadersCount: 1420,
      genres: ['DarkAcademia', 'ClassicPoetry', 'PhilosophicalFiction'],
      rating: 4.8,
    ),
    CatalogBookEntity(
      id: 'fallback-klara',
      title: 'Klara and the Sun',
      author: 'Kazuo Ishiguro',
      coverUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCVHL-GpK6FZbXybZZ24zzA3UPoMxNO9gTYUyfdtxGPvUb6z4maALR0u5sVAHgwso5_fXX4UvwGOT2KQEcrkK-UGNQEdhVImabTzk23jN4ze8220aMLxFAHaBEV5-ioHrASPvuyfgiD-SFNIjaPvWV9UAnPAhZs15cjIiouRu2N2URgc4Sn0NmNQsxW6leFu6NEZOpKDf4C8uqvqTGCwpR9zVRWA9o8rgMxm98EdUXhYdxFz4kMdJb9',
      description:
          'Klara, an Artificial Friend with outstanding observational qualities, watches carefully the behavior of those who come in to browse, and of those who pass on the street outside.',
      activeReadersCount: 842,
      genres: ['SciFiEpics', 'PhilosophicalFiction'],
      rating: 4.6,
    ),
    CatalogBookEntity(
      id: 'fallback-circe',
      title: 'Circe',
      author: 'Madeline Miller',
      coverUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBsdAVPP4bjoOSwMwUVX1AiRluOsFyCp7gW1Ae_9Jb6uIVQCBmsAbRRvVOUSMG_a52kMaElQjSR82ecn5oMnKalrJdMuYxvgXZE_KTUaQdML9cewnmZJ6B3lTyssGW_Yj4plmgS8AYsQlaNheGFjydKY1c-sj6YwUke28kwiuyGr9eTKfFooVkSrvgJO-QoN92vwlbRBfNTQEgiNy9BY37Z90Ll0Rbmy_Vl8LOyJBkFLje-xXra-Czp',
      description:
          'In the house of Helios, god of the sun and mightiest of the Titans, a daughter is born. But Circe is a strange child—not powerful, like her father, nor viciously alluring like her mother.',
      activeReadersCount: 654,
      genres: ['ModernClassics', 'ClassicPoetry'],
      rating: 4.7,
    ),
    CatalogBookEntity(
      id: 'fallback-overstory',
      title: 'The Overstory',
      author: 'Richard Powers',
      coverUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDONIiNGZtWPM3D1H0s_q3PMePPezRfnsJ_JTMymFNm2BL4xJoO-FuzYbNuPtrO14m7_knZHS1beum7110ZWcAgwXH1_lgs-IiPSZXZdTo--D-xenwgywzJm3f7yxL_z2dK_zxQrSZSNPE9JPq8jcphNKg2KCPp6DUxAQknqZMpcMwlJfjOKYQEfPYUJfuuw06qcT-1GhUyN5SU7XWbqMbXtCXcuwgwV-pTc0Rek5OqqOoYBOeoOLhQ',
      description:
          'The Overstory is a sweeping, impassioned work of activism and resistance that is also a stunning evocation of the natural world.',
      activeReadersCount: 389,
      genres: ['ModernClassics', 'EssayCollections'],
      rating: 4.5,
    ),
  ];

  ApiCatalogRepository({
    required ApiClient apiClient,
    required BookRepository bookRepository,
  })  : _apiClient = apiClient,
        _bookRepository = bookRepository;

  @override
  Future<List<CatalogBookEntity>> getDiscoverCatalog({
    String? genre,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/catalog/search',
        queryParameters: {
          if (genre != null && genre.isNotEmpty && genre != '#AllCuration')
            'q': genre.replaceAll('#', ''),
          if (query != null && query.isNotEmpty) 'q': query,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => _mapJsonToCatalogBook(item))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to fetch catalog from backend, using fallback: $e');
    }

    // Filter fallback list if genre specified
    if (genre != null && genre.isNotEmpty && genre != '#AllCuration') {
      final cleanGenre = genre.replaceAll('#', '').toLowerCase();
      final filtered = fallbackBooks.where((b) {
        return b.genres.any((g) => g.toLowerCase().contains(cleanGenre));
      }).toList();
      return filtered.isNotEmpty ? filtered : fallbackBooks;
    }

    return fallbackBooks;
  }

  @override
  Future<List<CatalogBookEntity>> searchCatalog(String query) async {
    if (query.trim().isEmpty) {
      return getDiscoverCatalog();
    }

    try {
      final response = await _apiClient.dio.get(
        '/catalog/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => _mapJsonToCatalogBook(item))
            .toList();
      }
    } catch (e) {
      AppLogger.w(_tag, 'Search request failed: $e');
    }

    // Local fallback search
    final q = query.toLowerCase();
    return fallbackBooks.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          (b.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<BookEntity> downloadAndImportBook({
    required CatalogBookEntity catalogBook,
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'catalog_${catalogBook.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.epub';
    final targetPath = '${tempDir.path}/$fileName';

    String downloadUrl = catalogBook.downloadUrl ??
        '${_apiClient.baseUrl}/catalog/${catalogBook.id}/download';

    if (downloadUrl.startsWith('/')) {
      downloadUrl = '${_apiClient.baseUrl}$downloadUrl';
    } else if (downloadUrl.contains('localhost:3000') && _apiClient.baseUrl.contains('10.0.2.2:3000')) {
      downloadUrl = downloadUrl.replaceAll('localhost:3000', '10.0.2.2:3000');
    }

    AppLogger.i(_tag, 'Downloading catalog book: ${catalogBook.title} from $downloadUrl');

    try {
      await _apiClient.dio.download(
        downloadUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final downloadedFile = File(targetPath);
      if (!await downloadedFile.exists() || await downloadedFile.length() == 0) {
        throw Exception('Downloaded file is empty or missing');
      }

      // Ingest directly via BookRepository into the local Readium reader library
      final importedBook = await _bookRepository.importBook(downloadedFile.path);
      AppLogger.i(_tag, 'Book imported into local library: ${importedBook.title} (${importedBook.id})');
      return importedBook;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to download/import catalog book', e);
      rethrow;
    }
  }

  CatalogBookEntity _mapJsonToCatalogBook(dynamic json) {
    return CatalogBookEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      author: json['author']?.toString() ?? 'Unknown Author',
      coverUrl: json['coverUrl']?.toString(),
      description: json['description']?.toString(),
      downloadUrl: json['downloadUrl']?.toString(),
      activeReadersCount: json['activeReadersCount'] as int? ?? 0,
      genres: json['genres'] is List
          ? List<String>.from(json['genres'])
          : json['genre'] != null
              ? [json['genre'].toString()]
              : const [],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}
