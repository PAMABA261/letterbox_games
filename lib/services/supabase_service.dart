import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://vbexbxxxagdfyvrxuyqp.supabase.co',
      publishableKey: 'sb_publishable_5WwmzrhIrx_T60sjaRgcJQ_zxUndOxt',
    );
  }

  static Future<bool> ensureAuthenticated() async {
    if (client.auth.currentUser != null) return true;

    try {
      await client.auth.signInWithPassword(
        email: 'test@test.com',
        password: '12345',
      );
      return true;
    } catch (e) {
      debugPrint('Error de autenticación: $e');
      return false;
    }
  }

  static Future<void> saveGame({
    required int gameId,
    required String gameName,
    required String coverUrl,
    required String status,
    double? rating,
    String? review,
    String? platform,
    List<String>? availablePlatforms,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('No se pudo autenticar el usuario.');

    final userId = client.auth.currentUser!.id;

    await client.from('user_games').upsert({
      'user_id': userId,
      'game_id': gameId,
      'game_name': gameName,
      'cover_url': coverUrl,
      'status': status,
      'platform': platform,
      'available_platforms': availablePlatforms,
      ...?(rating != null ? {'rating': rating} : null),
      ...?(review != null ? {'review': review} : null),
    }, onConflict: 'user_id, game_id');
  }

  static Future<List<dynamic>> fetchUserGames() async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final userId = client.auth.currentUser!.id;

    final response = await client
        .from('user_games')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response;
  }

  static Future<void> updateGame({
    required int gameId,
    required String status,
    double? rating,
    String? review,
    String? platform,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('No se pudo autenticar el usuario.');

    final userId = client.auth.currentUser!.id;

    await client
        .from('user_games')
        .update({
          'status': status,
          'rating': rating,
          'review': review,
          'platform': platform,
        })
        .eq('user_id', userId)
        .eq('game_id', gameId);
  }

  static Future<void> deleteGame(int gameId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('No se pudo autenticar el usuario.');

    final userId = client.auth.currentUser!.id;

    await client
        .from('user_games')
        .delete()
        .eq('user_id', userId)
        .eq('game_id', gameId);
  }

  static Future<List<dynamic>> fetchUserLists() async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final userId = client.auth.currentUser!.id;
    final response = await client
        .from('custom_lists')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<void> createList(String title, String description) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('No se pudo autenticar el usuario.');

    final userId = client.auth.currentUser!.id;
    await client.from('custom_lists').insert({
      'user_id': userId,
      'title': title,
      'description': description,
    });
  }

  static Future<void> addGameToList({
    required String listId,
    required int gameId,
    required String gameName,
    required String coverUrl,
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('No autenticado.');

    try {
      await client.from('list_games').insert({
        'list_id': listId,
        'game_id': gameId,
        'game_name': gameName,
        'cover_url': coverUrl,
      });
    } catch (e) {
      throw Exception('El juego ya está en esta lista o hubo un error.');
    }
  }

  static Future<List<dynamic>> fetchGamesForList(String listId) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) return [];

    final response = await client
        .from('list_games')
        .select()
        .eq('list_id', listId)
        .order('added_at', ascending: false);

    return response;
  }
}
