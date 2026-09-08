import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vbexbxxxagdfyvrxuyqp.supabase.co',
    publishableKey: 'sb_publishable_5WwmzrhIrx_T60sjaRgcJQ_zxUndOxt',
  );

  runApp(const BackloggdCloneApp());
}

class BackloggdCloneApp extends StatelessWidget {
  const BackloggdCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipaton Backlog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14181C),
        colorScheme: ColorScheme.dark(
          primary: Colors.greenAccent[400]!,
          surface: const Color(0xFF1C2228),
        ),
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
    try {
      final response = await http.post(
        url,
        headers: {
          'Client-ID': 'MY_CLIENT_ID',
          'Authorization': 'Bearer MY_ACCESS_TOKEN',
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
        setState(() {
          _isLoading = false;
        });
        debugPrint('Error de red: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

class DetailScreen extends StatelessWidget {
  final dynamic game;
  final String coverUrl;

  const DetailScreen({super.key, required this.game, required this.coverUrl});

  Future<void> _saveGame(BuildContext context, String status) async {
    final supabase = Supabase.instance.client;

    if (supabase.auth.currentUser == null) {
      try {
        await supabase.auth.signInWithPassword(
          email: 'test@test.com',
          password: '12345',
        );
      } catch (authError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de autenticación: $authError')),
          );
        }
        return;
      }
    }

    final currentUserId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('user_games').insert({
        'user_id': currentUserId,
        'game_id': game['id'],
        'game_name': game['name'],
        'cover_url': coverUrl,
        'status': status,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Juego guardado en tu biblioteca!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar en la base de datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game['name'] ?? 'Detalle'),
        backgroundColor: const Color(0xFF1C2228),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: game['id'].toString(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    coverUrl,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              game['name'] ?? 'Sin título',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _saveGame(context, 'plan_to_play'),
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Pendiente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _saveGame(context, 'completed'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Completado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              game['summary'] ??
                  'No hay descripción disponible para este título.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[300],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
