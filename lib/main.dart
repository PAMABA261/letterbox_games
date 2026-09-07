import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const BackloggdCloneApp());
}

class BackloggdCloneApp extends StatelessWidget {
  const BackloggdCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipaton Backlog',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const SearchScreen(),
    );
  }
}

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

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://api.igdb.com/v4/games');
    final response = await http.post(
      url,
      headers: {
        'Client-ID': 'TU_CLIENT_ID',
        'Authorization': 'Bearer TU_TOKEN',
        'Accept': 'application/json',
      },
      body:
          'search "$query"; fields name, cover.url; where cover != null; limit 15;',
    );

    if (response.statusCode == 200) {
      setState(() {
        _games = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Juegos'),
        backgroundColor: Colors.black45,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ej: Zelda, Doom, Halo...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchGames(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _searchGames,
            ),
          ),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _games.length,
                itemBuilder: (context, index) {
                  final game = _games[index];
                  final coverUrl = game['cover'] != null
                      ? 'https:${game['cover']['url']}'
                      : 'https://via.placeholder.com/90x120';

                  return ListTile(
                    contentPadding: const EdgeInsets.all(8.0),
                    leading: Image.network(
                      coverUrl.replaceAll('t_thumb', 't_cover_small'),
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      game['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
