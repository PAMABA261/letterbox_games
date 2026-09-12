import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DetailScreen extends StatefulWidget {
  final dynamic game;
  final String coverUrl;

  const DetailScreen({super.key, required this.game, required this.coverUrl});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  double _rating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  String? _selectedPlatform;

  List<String> _platforms = [];

  @override
  void initState() {
    super.initState();
    _platforms = _extractPlatforms();
  }

  List<String> _extractPlatforms() {
    final platformsList = widget.game['platforms'];
    List<String> extracted = [];

    if (platformsList != null && platformsList is List) {
      extracted = platformsList.map((p) => p['name'] as String).toList();
    }

    extracted.addAll(['Emulador']);

    return extracted.toSet().toList();
  }

  Future<void> _saveGame(String status) async {
    try {
      await SupabaseService.saveGame(
        gameId: widget.game['id'],
        gameName: widget.game['name'],
        coverUrl: widget.coverUrl,
        status: status,
        rating: _rating > 0 ? _rating : null,
        review: _reviewController.text.isNotEmpty
            ? _reviewController.text
            : null,
        platform: _selectedPlatform,
        availablePlatforms: _platforms,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Guardado en tu biblioteca con éxito!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  String _getReleaseYear() {
    final timestamp = widget.game['first_release_date'];
    if (timestamp == null) return 'Desconocido';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return date.year.toString();
  }

  String _getGenres() {
    final genresList = widget.game['genres'];
    if (genresList == null || genresList is! List || genresList.isEmpty) {
      return 'No especificado';
    }
    return genresList.map((g) => g['name'] as String).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game['name'] ?? 'Detalle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF1C2228),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: widget.game['id'].toString(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.coverUrl,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.game['name'] ?? 'Sin título',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lanzamiento: ${_getReleaseYear()}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.category,
                      size: 14,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Géneros: ${_getGenres()}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30, color: Colors.grey),

            const Text(
              'Tu Puntuación',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = (index + 1).toDouble();
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escribe tu reseña sobre el juego...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C3440),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedPlatform,
              decoration: InputDecoration(
                labelText: 'Plataforma / Emulador',
                labelStyle: const TextStyle(color: Colors.greenAccent),
                filled: true,
                fillColor: const Color(0xFF2C3440),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: const Color(0xFF2C3440),
              style: const TextStyle(color: Colors.white),
              items: _platforms.map((String platform) {
                return DropdownMenuItem<String>(
                  value: platform,
                  child: Text(platform),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPlatform = newValue;
                });
              },
            ),
            const SizedBox(height: 24),

            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('playing'),
                    icon: const Icon(Icons.videogame_asset),
                    label: const Text('Jugando'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('plan_to_play'),
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Pendiente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('completed'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Completado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveGame('dropped'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Abandonado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sinopsis',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.game['summary'] ??
                  'No hay descripción disponible para este título.',
              style: TextStyle(
                fontSize: 14,
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
