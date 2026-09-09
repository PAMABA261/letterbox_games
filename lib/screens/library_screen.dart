import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _userGames = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    final games = await SupabaseService.fetchUserGames();
    setState(() {
      _userGames = games;
      _isLoading = false;
    });
  }

  List<dynamic> _getFilteredGames(String filter) {
    if (filter == 'completed') {
      return _userGames.where((game) => game['status'] == 'completed').toList();
    } else if (filter == 'plan_to_play') {
      return _userGames
          .where((game) => game['status'] == 'plan_to_play')
          .toList();
    }
    return _userGames;
  }

  void _showEditDeleteModal(Map<String, dynamic> item) {
    String currentStatus = item['status'] ?? 'plan_to_play';
    double currentRating = item['rating'] != null
        ? (item['rating'] as num).toDouble()
        : 0.0;
    final TextEditingController reviewController = TextEditingController(
      text: item['review'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['game_name'] ?? 'Editar juego',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Estado',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: currentStatus,
                      dropdownColor: const Color(0xFF2C3440),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF2C3440),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'plan_to_play',
                          child: Text('Pendiente'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completado'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => currentStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Puntuación',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < currentRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setModalState(
                              () => currentRating = (index + 1).toDouble(),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reseña',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Actualiza tu reseña...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: const Color(0xFF2C3440),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800],
                            ),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await SupabaseService.deleteGame(item['game_id']);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _loadLibrary();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Juego eliminado de la biblioteca',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              'Guardar',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await SupabaseService.updateGame(
                                gameId: item['game_id'],
                                status: currentStatus,
                                rating: currentRating > 0
                                    ? currentRating
                                    : null,
                                review: reviewController.text.isNotEmpty
                                    ? reviewController.text
                                    : null,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _loadLibrary();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Juego actualizado con éxito'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGameGrid(List<dynamic> gamesList) {
    if (gamesList.isEmpty) {
      return Center(
        child: Text(
          'No hay juegos en esta sección.',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: gamesList.length,
      itemBuilder: (context, index) {
        final item = gamesList[index];
        final coverUrl = item['cover_url'] ?? '';
        final gameName = item['game_name'] ?? 'Juego';
        final status = item['status'] == 'completed'
            ? 'Completado'
            : 'Pendiente';
        final statusColor = item['status'] == 'completed'
            ? Colors.green
            : Colors.blueGrey;
        final rating = item['rating'];
        final review = item['review'];

        return GestureDetector(
          onTap: () => _showEditDeleteModal(item),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C2228),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (rating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$rating',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (review != null && review.toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"$review"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Biblioteca',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C2228),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Completados'),
            Tab(text: 'Pendientes'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGameGrid(_getFilteredGames('all')),
                _buildGameGrid(_getFilteredGames('completed')),
                _buildGameGrid(_getFilteredGames('plan_to_play')),
              ],
            ),
    );
  }
}
