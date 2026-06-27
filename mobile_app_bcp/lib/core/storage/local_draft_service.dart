import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class LocalDraftService {
  Future<void> saveDraft({
    required String idBorrador,
    required String nombreCliente,
    required int pasoAlcanzado,
    required double monto,
    required Map<String, dynamic> datos,
  }) async {
    final db = await LocalDatabase.database;
    final dataString = jsonEncode(datos);
    final fecha = DateTime.now().toIso8601String();

    await db.insert(
      'local_solicitudes_borrador',
      {
        'id_borrador': idBorrador,
        'nombre_cliente': nombreCliente,
        'paso_alcanzado': pasoAlcanzado,
        'fecha_edicion': fecha,
        'monto': monto,
        'datos_serializados': dataString,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDrafts() async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'local_solicitudes_borrador',
      orderBy: 'fecha_edicion DESC',
    );
    
    return maps.map((m) {
      return {
        'id_borrador': m['id_borrador'] as String,
        'nombre_cliente': m['nombre_cliente'] as String,
        'paso_alcanzado': m['paso_alcanzado'] as int,
        'fecha_edicion': m['fecha_edicion'] as String,
        'monto': (m['monto'] as num).toDouble(),
        'datos': jsonDecode(m['datos_serializados'] as String) as Map<String, dynamic>,
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getDraft(String idBorrador) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'local_solicitudes_borrador',
      where: 'id_borrador = ?',
      whereArgs: [idBorrador],
    );

    if (maps.isEmpty) return null;
    final m = maps.first;
    return {
      'id_borrador': m['id_borrador'] as String,
      'nombre_cliente': m['nombre_cliente'] as String,
      'paso_alcanzado': m['paso_alcanzado'] as int,
      'fecha_edicion': m['fecha_edicion'] as String,
      'monto': (m['monto'] as num).toDouble(),
      'datos': jsonDecode(m['datos_serializados'] as String) as Map<String, dynamic>,
    };
  }

  Future<void> deleteDraft(String idBorrador) async {
    final db = await LocalDatabase.database;
    await db.delete(
      'local_solicitudes_borrador',
      where: 'id_borrador = ?',
      whereArgs: [idBorrador],
    );
  }
}
