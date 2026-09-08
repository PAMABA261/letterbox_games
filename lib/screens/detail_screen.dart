import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DetailScreen extends StatelessWidget {
  final dynamic game;
  final String coverUrl;

  const DetailScreen({super.key, required this.game, required this.coverUrl});

  Future<void> _saveGame(BuildContext context, String status) async {
    try {
      await SupabaseService.saveGame(
        gameId: game['id'],
        gameName: game['name'],
        coverUrl: coverUrl,
        status: status,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Juego guardado en tu biblioteca!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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
