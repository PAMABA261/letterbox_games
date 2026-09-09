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
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('No se pudo autenticar el usuario.');

    final userId = client.auth.currentUser!.id;

    await client.from('user_games').insert({
      'user_id': userId,
      'game_id': gameId,
      'game_name': gameName,
      'cover_url': coverUrl,
      'status': status,
      ...?(rating != null ? {'rating': rating} : null),
      ...?(review != null ? {'review': review} : null),
    });
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
  }) async {
    final authenticated = await ensureAuthenticated();
    if (!authenticated) throw Exception('No se pudo autenticar el usuario.');

    final userId = client.auth.currentUser!.id;

    await client
        .from('user_games')
        .update({'status': status, 'rating': rating, 'review': review})
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
}
