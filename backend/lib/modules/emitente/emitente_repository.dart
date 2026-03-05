import '../../config/database.dart';

class EmitenteRepository {
  Future<Map<String, String?>?> findFirst() async {
    final results = await Database.instance.query(
      'SELECT * FROM emitente LIMIT 1',
      {},
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> upsert(Map<String, String> data) async {
    final existing = await findFirst();

    if (existing == null) {
      // INSERT
      final cols = data.keys.join(', ');
      final placeholders = data.keys.map((k) => ':$k').join(', ');
      await Database.instance.execute(
        'INSERT INTO emitente ($cols) VALUES ($placeholders)',
        data,
      );
    } else {
      // UPDATE
      final sets = data.keys.map((k) => '$k = :$k').join(', ');
      await Database.instance.execute(
        'UPDATE emitente SET $sets WHERE id = :id',
        {...data, 'id': existing['id']!},
      );
    }
  }
}
