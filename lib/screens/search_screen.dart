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
  List<dynamic> _games = [];
  bool _isLoading = false;

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('https://api.igdb.com/v4/games');
    try {
      final response = await http.post(
        url,
        headers: {
          'Client-ID': 'lcgl4fyetyqozygtae145slsb7hup8',
          'Authorization': 'Bearer yhkdljdry753rq5alsul6bahe2c41v',
          'Accept': 'application/json',
        },
        body:
            'search "$query"; fields name, cover.url, summary, first_release_date; where cover != null; limit 18;',
      );

      if (response.statusCode == 200) {
        setState(() {
          _games = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint('Error de red: ${response.statusCode}');
      }
    } catch (e) {
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Busca un juego (ej. Metroid, Zelda...)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C3440),
                prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _searchGames,
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
                        'Busca tu próximo juego favorito',
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
