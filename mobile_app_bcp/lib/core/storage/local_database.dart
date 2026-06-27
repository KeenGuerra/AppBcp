// local_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class LocalDatabase {
  static dynamic _database;

  static Future<dynamic> get database async {
    if (kIsWeb) {
      _database ??= MockWebDatabase();
      return _database;
    }
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bcp_local_db.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Create local_cartera
        await db.execute('''
          CREATE TABLE local_cartera (
            id_cartera TEXT PRIMARY KEY,
            id_asesor TEXT,
            id_cliente TEXT,
            id_solicitud TEXT,
            fecha_asignacion TEXT,
            tipo_gestion TEXT,
            prioridad TEXT,
            score_prioridad INTEGER,
            estado_visita TEXT,
            resultado_visita TEXT,
            observacion_visita TEXT,
            lat_visita REAL,
            lng_visita REAL,
            timestamp_visita TEXT,
            pendiente_sync INTEGER DEFAULT 0
          )
        ''');

        // Create local_clientes
        await db.execute('''
          CREATE TABLE local_clientes (
            id_cliente TEXT PRIMARY KEY,
            documento TEXT,
            nombres TEXT,
            apellidos TEXT,
            telefono TEXT,
            correo TEXT,
            direccion TEXT,
            distrito TEXT,
            provincia TEXT,
            departamento TEXT,
            fecha_nacimiento TEXT,
            estado_civil TEXT,
            ocupacion TEXT,
            tipo_cliente TEXT
          )
        ''');

        // Create local_solicitudes_pendientes
        await db.execute('''
          CREATE TABLE local_solicitudes_pendientes (
            id_solicitud TEXT PRIMARY KEY,
            id_cliente TEXT,
            id_negocio TEXT,
            id_producto_credito TEXT,
            monto_solicitado REAL,
            plazo_meses INTEGER,
            con_seguro_desgravamen INTEGER,
            garantia TEXT,
            destino_credito TEXT,
            cuota_estimada REAL,
            estado TEXT,
            lat_captura REAL,
            lng_captura REAL,
            pendiente_sync INTEGER DEFAULT 1
          )
        ''');

        // Create local_visitas_pendientes
        await db.execute('''
          CREATE TABLE local_visitas_pendientes (
            id_visita TEXT PRIMARY KEY,
            id_cartera TEXT,
            id_asesor TEXT,
            id_cliente TEXT,
            resultado TEXT,
            observacion TEXT,
            lat REAL,
            lng REAL,
            fecha_hora TEXT,
            pendiente_sync INTEGER DEFAULT 1
          )
        ''');

        // Create local_documentos_pendientes
        await db.execute('''
          CREATE TABLE local_documentos_pendientes (
            id_documento TEXT PRIMARY KEY,
            id_solicitud TEXT,
            tipo_documento TEXT,
            nombre_archivo TEXT,
            storage_path TEXT,
            base64_content TEXT,
            pendiente_sync INTEGER DEFAULT 1
          )
        ''');

        // Create local_sync_queue
        await db.execute('''
          CREATE TABLE local_sync_queue (
            id_sync TEXT PRIMARY KEY,
            action TEXT,
            url TEXT,
            method TEXT,
            body TEXT,
            timestamp TEXT
          )
        ''');

        // Create local_solicitudes_borrador
        await db.execute('''
          CREATE TABLE local_solicitudes_borrador (
            id_borrador TEXT PRIMARY KEY,
            nombre_cliente TEXT,
            paso_alcanzado INTEGER,
            fecha_edicion TEXT,
            monto REAL,
            datos_serializados TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_solicitudes_borrador (
              id_borrador TEXT PRIMARY KEY,
              nombre_cliente TEXT,
              paso_alcanzado INTEGER,
              fecha_edicion TEXT,
              monto REAL,
              datos_serializados TEXT
            )
          ''');
        }
      },
    );
  }
}

class MockWebDatabase {
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'local_cartera': [],
    'local_clientes': [],
    'local_solicitudes_pendientes': [],
    'local_visitas_pendientes': [],
    'local_documentos_pendientes': [],
    'local_sync_queue': [],
    'local_solicitudes_borrador': [],
  };

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final list = _tables[table] ?? [];
    if (where == null) return list;
    
    if (where.contains('pendiente_sync = 1')) {
      return list.where((row) => row['pendiente_sync'] == 1).toList();
    }
    if (where.contains('id_cliente = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      return list.where((row) => row['id_cliente'] == id).toList();
    }
    if (where.contains('id_solicitud = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      return list.where((row) => row['id_solicitud'] == id).toList();
    }
    if (where.contains('id_borrador = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      return list.where((row) => row['id_borrador'] == id).toList();
    }
    
    return list;
  }

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String? nullColumnHack,
    dynamic conflictAlgorithm,
  }) async {
    final list = _tables[table] ??= [];
    final pkKeys = ['id_cartera', 'id_cliente', 'id_solicitud', 'id_visita', 'id_documento', 'id_sync', 'id_borrador'];
    String? pkKey;
    for (var k in pkKeys) {
      if (values.containsKey(k)) {
        pkKey = k;
        break;
      }
    }
    
    if (pkKey != null) {
      final pkVal = values[pkKey];
      list.removeWhere((row) => row[pkKey] == pkVal);
    }
    
    list.add(Map<String, dynamic>.from(values));
    return 1;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
    dynamic conflictAlgorithm,
  }) async {
    final list = _tables[table] ?? [];
    if (where != null && where.contains('id_cliente = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      for (var row in list) {
        if (row['id_cliente'] == id) {
          values.forEach((k, v) => row[k] = v);
        }
      }
    } else if (where != null && where.contains('id_solicitud = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      for (var row in list) {
        if (row['id_solicitud'] == id) {
          values.forEach((k, v) => row[k] = v);
        }
      }
    }
    return 1;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final list = _tables[table] ?? [];
    if (where == null) {
      list.clear();
      return 1;
    }
    if (where.contains('id_visita = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      list.removeWhere((row) => row['id_visita'] == id);
    }
    if (where.contains('id_solicitud = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      list.removeWhere((row) => row['id_solicitud'] == id);
    }
    if (where.contains('id_borrador = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs.first;
      list.removeWhere((row) => row['id_borrador'] == id);
    }
    return 1;
  }

  Future<void> execute(String sql) async {}
}

