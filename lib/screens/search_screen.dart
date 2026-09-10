import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'detail_screen.dart';
import 'library_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _games = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isNotEmpty) {
        _searchGames(trimmedQuery);
      } else {
        setState(() {
          _games = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _searchGames(String query) async {
    setState(() => _isLoading = true);

    final url = Uri.parse('https://api.igdb.com/v4/games');
    try {
      final response = await http.post(
        url,
        headers: {
          'Client-ID': 'MY_CLIENT_ID',
          'Authorization': 'Bearer MY_ACCESS_TOKEN',
          'Accept': 'application/json',
        },
        body:
            'search "$query"; fields name, cover.url, summary, first_release_date, genres.name, category, involved_companies.company.name; where cover != null; limit 300;',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);

        final forbiddenKeywords = [
          'rom hack',
          'romhack',
          'hack',
          'fangame',
          'fan-game',
          'fan game',
          'mod',
          'demake',
          'remake',
          'kaizo',
          'randomizer',
          'unofficial',
          'no oficial',
          'clone',
          'port',
          'homebrew',
          'bootleg',
        ];

        final mainGames = decoded.where((game) {
          final cat = game['category'];
          if (cat != null && cat != 0) return false;

          final name = (game['name'] ?? '').toLowerCase();
          final summary = (game['summary'] ?? '').toLowerCase();

          if (summary.trim().isEmpty) return false;

          final companies = game['involved_companies'];
          if (companies == null || companies is! List || companies.isEmpty) {
            return false;
          }

          final fullText = '$name $summary';
          for (var word in forbiddenKeywords) {
            if (fullText.contains(word)) return false;
          }

          return true;
        }).toList();

        setState(() {
          _games = mainGames;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint('Error de red: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Excepción: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catálogo de Juegos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.greenAccent),
            tooltip: 'Mi Biblioteca',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LibraryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe para buscar juegos...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C3440),
                prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _games = []);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            )
          else
            Expanded(
              child: _games.isEmpty
                  ? Center(
                      child: Text(
                        'Escribe el nombre de un juego para empezar',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        final game = _games[index];
                        final rawUrl = game['cover'] != null
                            ? game['cover']['url']
                            : '';
                        final coverUrl = rawUrl.isNotEmpty
                            ? 'https:${rawUrl.replaceFirst('t_thumb', 't_cover_big')}'
                            : 'https://via.placeholder.com/264x352';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                  game: game,
                                  coverUrl: coverUrl,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: game['id'].toString(),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[850],
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                              ),
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
