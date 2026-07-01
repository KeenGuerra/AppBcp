# supabase_session.py
# Adaptador robusto que emula SQLAlchemy Session usando Supabase REST API (supabase-py)
# Versión 2.0 — Corrige bugs de UUID, order_by, fechas, y raw SQL

import uuid
import logging
import datetime
from typing import Any, List, Optional, Type
from supabase import create_client, Client
from app.core.config import settings

logger = logging.getLogger(__name__)

# Lazy loading injection moved to SupabaseSession class initialization to prevent circular imports



def _get_supabase() -> Client:
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)


def _to_str(val):
    """Convierte valores Python a strings compatibles con Supabase REST"""
    if isinstance(val, uuid.UUID):
        return str(val)
    if isinstance(val, datetime.datetime):
        return val.isoformat()
    if isinstance(val, datetime.date):
        return val.isoformat()
    from decimal import Decimal
    if isinstance(val, Decimal):
        return float(val)
    if isinstance(val, list):
        return [_to_str(v) for v in val]
    return val


def _obj_to_dict(obj) -> dict:
    """Convierte un modelo SQLAlchemy a dict para insertar en Supabase"""
    result = {}
    try:
        for col in obj.__table__.columns:
            val = getattr(obj, col.name, None)
            if val is None:
                continue
            result[col.name] = _to_str(val)
    except Exception as e:
        logger.error(f"Error convirtiendo objeto a dict: {e}")
    return result


def _dict_to_obj(model_class, data: dict, session=None):
    """Convierte dict de Supabase a instancia del modelo SQLAlchemy"""
    # Intentar obtener la clave primaria para verificar el mapa de identidad
    pk_cols = []
    try:
        pk_cols = [c.name for c in model_class.__table__.columns if c.primary_key]
    except Exception:
        pass

    if len(pk_cols) == 1 and session is not None:
        pk_val = data.get(pk_cols[0])
        if pk_val:
            pk_val_str = str(pk_val)
            cached = session._identity_map.get((model_class, pk_val_str))
            if cached:
                return cached

    obj = model_class()
    if session is not None:
        obj._session = session
        if len(pk_cols) == 1:
            pk_val = data.get(pk_cols[0])
            if pk_val:
                session._identity_map[(model_class, str(pk_val))] = obj

    for k, v in data.items():
        setattr(obj, k, v)
    # Intentar convertir UUIDs a objetos UUID donde corresponda
    try:
        for col in model_class.__table__.columns:
            if hasattr(col.type, 'as_uuid') and col.type.as_uuid:
                val = getattr(obj, col.name, None)
                if isinstance(val, str) and val:
                    try:
                        setattr(obj, col.name, uuid.UUID(val))
                    except (ValueError, AttributeError):
                        pass
    except Exception:
        pass
    obj._original_dict = data.copy()
    return obj


def _are_values_equal(val1, val2) -> bool:
    if val1 == val2:
        return True
    if val1 is None or val2 is None:
        return val1 == val2
    try:
        from decimal import Decimal
        d1 = Decimal(str(val1))
        d2 = Decimal(str(val2))
        return d1 == d2
    except (ValueError, TypeError, ArithmeticError):
        pass
    return str(val1) == str(val2)


def _is_object_dirty(obj) -> bool:
    original = getattr(obj, '_original_dict', None)
    if original is None:
        return False
    try:
        for col in obj.__table__.columns:
            orig_val = original.get(col.name)
            curr_val = getattr(obj, col.name, None)
            curr_val_str = _to_str(curr_val)
            if not _are_values_equal(orig_val, curr_val_str):
                return True
    except Exception as e:
        logger.warning(f"Error checking if object is dirty: {e}")
    return False


def _extract_filter_value(cond):
    """Extrae el valor de una expresión binaria SQLAlchemy de forma robusta"""
    right = getattr(cond, 'right', None)
    if right is None:
        return None
    # BindParameter
    if hasattr(right, 'value') and right.value is not None:
        return right.value
    if hasattr(right, 'effective_value') and right.effective_value is not None:
        return right.effective_value
    # ClauseList para IN
    if hasattr(right, 'clauses'):
        vals = []
        for c in right.clauses:
            if hasattr(c, 'value'):
                vals.append(c.value)
        return vals if vals else None
    return None


def _extract_col_key(cond):
    """Extrae el nombre de columna de una expresión binaria SQLAlchemy"""
    left = getattr(cond, 'left', None)
    if left is None:
        return None
    if hasattr(left, 'key'):
        return left.key
    if hasattr(left, 'element') and hasattr(left.element, 'key'):
        return left.element.key
    if hasattr(left, 'name'):
        return left.name
    return None


class SupabaseQuery:
    """Emula sqlalchemy.orm.Query para Supabase REST API v2"""

    def __init__(self, sb: Client, model_class, session=None):
        self._sb = sb
        self._model = model_class
        self._session = session
        self._table = model_class.__tablename__
        self._eq_filters = []       # [(col, val)]
        self._neq_filters = []      # [(col, val)]
        self._in_filters = []       # [(col, [vals])]
        self._gte_filters = []      # [(col, val)]
        self._lte_filters = []      # [(col, val)]
        self._gt_filters = []       # [(col, val)]
        self._lt_filters = []       # [(col, val)]
        self._limit_val = None
        self._offset_val = None
        self._order_col = None
        self._order_desc = False

    def filter(self, *conditions):
        """
        Soporta condiciones del tipo BinaryExpression de SQLAlchemy:
          Model.campo == valor
          Model.campo != valor
          Model.campo.in_([...])
          Model.campo >= valor
          Model.campo <= valor
        """
        for cond in conditions:
            try:
                if hasattr(cond, 'clauses'):
                    # AND clause (multiple conditions)
                    for sub in cond.clauses:
                        self.filter(sub)
                    continue

                col_key = _extract_col_key(cond)
                if not col_key:
                    continue

                val = _extract_filter_value(cond)

                # Convert to string-compatible format
                if isinstance(val, list):
                    val = [_to_str(v) for v in val]
                elif val is not None:
                    val = _to_str(val)

                # Detect operator
                op = ''
                if hasattr(cond, 'operator'):
                    try:
                        op = cond.operator.__name__ if callable(cond.operator) else str(cond.operator)
                    except Exception:
                        op = str(getattr(cond, 'operator', ''))

                if 'ne' in op or 'not' in op:
                    self._neq_filters.append((col_key, val))
                elif isinstance(val, list):
                    self._in_filters.append((col_key, val))
                elif 'ge' in op or '>=' in op:
                    self._gte_filters.append((col_key, val))
                elif 'le' in op or '<=' in op:
                    self._lte_filters.append((col_key, val))
                elif 'gt' in op or ('>' in op and '=' not in op):
                    self._gt_filters.append((col_key, val))
                elif 'lt' in op or ('<' in op and '=' not in op):
                    self._lt_filters.append((col_key, val))
                else:
                    if val is not None:
                        self._eq_filters.append((col_key, val))

            except Exception as e:
                logger.warning(f"No se pudo parsear condición de filtro: {e}")
        return self

    def filter_by(self, **kwargs):
        for k, v in kwargs.items():
            self._eq_filters.append((k, _to_str(v)))
        return self

    def _build_query(self, limit=None):
        q = self._sb.table(self._table).select('*')
        for col, val in self._eq_filters:
            if val is not None:
                q = q.eq(col, val)
        for col, val in self._neq_filters:
            q = q.neq(col, val)
        for col, vals in self._in_filters:
            q = q.in_(col, vals)
        for col, val in self._gte_filters:
            q = q.gte(col, val)
        for col, val in self._lte_filters:
            q = q.lte(col, val)
        for col, val in self._gt_filters:
            q = q.gt(col, val)
        for col, val in self._lt_filters:
            q = q.lt(col, val)

        if self._order_col:
            q = q.order(self._order_col, desc=self._order_desc)

        lim = limit or self._limit_val
        if lim:
            q = q.limit(lim)
        if self._offset_val:
            off = self._offset_val
            end = off + (lim or 1000) - 1
            q = q.range(off, end)
        return q

    def first(self):
        try:
            # Intentar buscar en el mapa de identidad si es una consulta simple por clave primaria
            if self._session and len(self._eq_filters) == 1:
                col, val = self._eq_filters[0]
                try:
                    pk_cols = [c.name for c in self._model.__table__.columns if c.primary_key]
                    if len(pk_cols) == 1 and col == pk_cols[0]:
                        cached = self._session._identity_map.get((self._model, str(val)))
                        if cached:
                            return cached
                except Exception:
                    pass

            r = self._build_query(limit=1).execute()
            if r.data:
                return _dict_to_obj(self._model, r.data[0], session=self._session)
        except Exception as e:
            logger.error(f"Error en query.first() [{self._table}]: {e}")
        return None

    def all(self) -> List:
        try:
            r = self._build_query().execute()
            return [_dict_to_obj(self._model, d, session=self._session) for d in (r.data or [])]
        except Exception as e:
            logger.error(f"Error en query.all() [{self._table}]: {e}")
            return []

    def count(self) -> int:
        try:
            q = self._sb.table(self._table).select('*', count='exact')
            for col, val in self._eq_filters:
                if val is not None:
                    q = q.eq(col, val)
            r = q.execute()
            return r.count or 0
        except Exception:
            return 0

    def limit(self, n: int):
        self._limit_val = n
        return self

    def offset(self, n: int):
        self._offset_val = n
        return self

    def order_by(self, *args):
        for arg in args:
            try:
                # Handle desc() wrapped columns
                if hasattr(arg, 'modifier') or hasattr(arg, 'element'):
                    # UnaryExpression with desc modifier
                    elem = getattr(arg, 'element', arg)
                    col_name = getattr(elem, 'key', None) or getattr(elem, 'name', None)
                    if col_name:
                        self._order_col = col_name
                        # Check if descending
                        mod = str(getattr(arg, 'modifier', '')).lower()
                        op = str(getattr(arg, 'operator', '')).lower()
                        self._order_desc = 'desc' in mod or 'desc' in op
                elif hasattr(arg, 'key'):
                    self._order_col = arg.key
                    self._order_desc = False
                elif hasattr(arg, 'name'):
                    self._order_col = arg.name
                    self._order_desc = False
            except Exception as e:
                logger.warning(f"order_by parse warning: {e}")
        return self

    def with_entities(self, *args):
        return self

    def scalar(self):
        return self.first()

    def one_or_none(self):
        return self.first()

    def delete(self):
        try:
            q = self._sb.table(self._table).delete()
            for col, val in self._eq_filters:
                if val is not None:
                    q = q.eq(col, val)
            q.execute()
        except Exception as e:
            logger.error(f"Error en query.delete() [{self._table}]: {e}")
        return self


class RawResultProxy:
    """Proxy para resultados de raw SQL"""
    def __init__(self, data):
        self._data = data or []

    def fetchone(self):
        if self._data:
            row = self._data[0]
            if isinstance(row, dict):
                return tuple(row.values())
            return row
        return None

    def fetchall(self):
        result = []
        for row in self._data:
            if isinstance(row, dict):
                result.append(tuple(row.values()))
            else:
                result.append(row)
        return result

    def __iter__(self):
        return iter(self.fetchall())


class SupabaseSession:
    """
    Emula SQLAlchemy Session usando Supabase REST API v2.
    Compatible con: db.query(Model).filter(...).first()
                    db.add(), db.commit(), db.refresh()
                    db.execute(text(...))
    """

    _lazy_loading_injected = False

    @classmethod
    def _inject_lazy_loading(cls):
        try:
            from app.database.session import Base
            orig_getattribute = Base.__getattribute__

            def my_getattribute(self, name):
                try:
                    if not name.startswith('_'):
                        clazz = object.__getattribute__(self, '__class__')
                        mapper = getattr(clazz, '__mapper__', None)
                        if mapper and name in mapper.relationships:
                            instance_dict = object.__getattribute__(self, '__dict__')
                            if name not in instance_dict:
                                loading_key = f"_loading_{name}"
                                if loading_key not in instance_dict:
                                    instance_dict[loading_key] = True
                                    try:
                                        prop = mapper.relationships[name]
                                        target_class = prop.mapper.class_
                                        session = instance_dict.get('_session')
                                        if session:
                                            if prop.direction.name == "MANYTOONE":
                                                local_col = prop.local_remote_pairs[0][0]
                                                val = instance_dict.get(local_col.key)
                                                if val:
                                                    remote_key = prop.local_remote_pairs[0][1].key
                                                    related_obj = session.query(target_class).filter_by(**{remote_key: val}).first()
                                                    if related_obj:
                                                        instance_dict[name] = related_obj
                                            elif prop.direction.name == "ONETOMANY":
                                                local_col = prop.local_remote_pairs[0][1]
                                                val = instance_dict.get(local_col.key)
                                                if val:
                                                    remote_key = prop.local_remote_pairs[0][0].key
                                                    related_list = session.query(target_class).filter_by(**{remote_key: val}).all()
                                                    instance_dict[name] = related_list
                                    finally:
                                        if loading_key in instance_dict:
                                            del instance_dict[loading_key]
                except Exception as e:
                    logger.warning(f"Error loading relationship {name}: {e}")
                return orig_getattribute(self, name)

            Base.__getattribute__ = my_getattribute
            cls._lazy_loading_injected = True
            logger.info("Lazy loading inyectado exitosamente en Base")
        except Exception as e:
            logger.warning(f"No se pudo inyectar lazy loading en Base: {e}")

    def __init__(self):
        if not SupabaseSession._lazy_loading_injected:
            SupabaseSession._inject_lazy_loading()
        self._sb = _get_supabase()
        self._dirty_objects = []
        self._new_objects = []
        self._deleted_objects = []
        self._identity_map = {}

    @property
    def sb(self) -> Client:
        return self._sb

    def query(self, model_class, *entities) -> SupabaseQuery:
        return SupabaseQuery(self._sb, model_class, session=self)

    def add(self, obj):
        """Agrega un objeto nuevo o marca uno existente como modificado"""
        if not hasattr(obj, '_session'):
            obj._session = self
        self._new_objects.append(obj)
        return obj

    def add_all(self, objs):
        for obj in objs:
            self.add(obj)

    def commit(self):
        """Ejecuta todas las operaciones pendientes en Supabase"""
        errors = []

        # Autodetect modified objects in identity map
        for obj in list(self._identity_map.values()):
            if obj not in self._new_objects and obj not in self._dirty_objects and obj not in self._deleted_objects:
                if _is_object_dirty(obj):
                    self._dirty_objects.append(obj)

        # Insertar nuevos objetos
        for obj in self._new_objects:
            try:
                table = obj.__tablename__
                data = _obj_to_dict(obj)
                if data:
                    pk_cols = [c.name for c in obj.__table__.primary_key.columns]
                    pk_vals = {k: data.get(k) for k in pk_cols if data.get(k)}
                    if pk_vals:
                        self._sb.table(table).upsert(data).execute()
                    else:
                        self._sb.table(table).insert(data).execute()
                    # Cache the inserted values as original
                    obj._original_dict = data.copy()
                    # Also register it in the session's identity map!
                    if len(pk_cols) == 1:
                        pk_val = data.get(pk_cols[0])
                        if pk_val:
                            self._identity_map[(obj.__class__, str(pk_val))] = obj
            except Exception as e:
                logger.error(f"Error en insert/upsert [{obj.__tablename__}]: {e}")
                errors.append(str(e))

        # Actualizar objetos modificados
        for obj in self._dirty_objects:
            try:
                table = obj.__tablename__
                data = _obj_to_dict(obj)
                pk_cols = [c.name for c in obj.__table__.primary_key.columns]
                update_data = {k: v for k, v in data.items() if k not in pk_cols}
                if update_data:
                    q = self._sb.table(table).update(update_data)
                    for pk in pk_cols:
                        if data.get(pk):
                            q = q.eq(pk, data[pk])
                    q.execute()
                # Update the original dict to reflect current state
                obj._original_dict = data.copy()
            except Exception as e:
                logger.error(f"Error en update [{obj.__tablename__}]: {e}")
                errors.append(str(e))

        # Eliminar objetos
        for obj in self._deleted_objects:
            try:
                table = obj.__tablename__
                data = _obj_to_dict(obj)
                pk_cols = [c.name for c in obj.__table__.primary_key.columns]
                q = self._sb.table(table).delete()
                for pk in pk_cols:
                    if data.get(pk):
                        q = q.eq(pk, data[pk])
                q.execute()
            except Exception as e:
                logger.error(f"Error en delete [{obj.__tablename__}]: {e}")
                errors.append(str(e))

        self._new_objects.clear()
        self._dirty_objects.clear()
        self._deleted_objects.clear()

        if errors:
            logger.error(f"Errores en commit: {errors}")
            raise Exception(f"Error en base de datos: {'; '.join(errors)}")

    def refresh(self, obj):
        """Recarga un objeto desde Supabase"""
        try:
            table = obj.__tablename__
            pk_cols = [c.name for c in obj.__table__.primary_key.columns]
            data = _obj_to_dict(obj)
            q = self._sb.table(table).select('*')
            for pk in pk_cols:
                if data.get(pk):
                    q = q.eq(pk, data[pk])
            r = q.limit(1).execute()
            if r.data:
                if not hasattr(obj, '_session'):
                    obj._session = self
                for k, v in r.data[0].items():
                    setattr(obj, k, v)
                # Convert UUIDs
                try:
                    for col in obj.__table__.columns:
                        if hasattr(col.type, 'as_uuid') and col.type.as_uuid:
                            val = getattr(obj, col.name, None)
                            if isinstance(val, str) and val:
                                try:
                                    setattr(obj, col.name, uuid.UUID(val))
                                except (ValueError, AttributeError):
                                    pass
                except Exception:
                    pass
        except Exception as e:
            logger.warning(f"Error en refresh [{obj.__tablename__}]: {e}")

    def delete(self, obj):
        self._deleted_objects.append(obj)

    def expunge(self, obj):
        pass

    def rollback(self):
        self._new_objects.clear()
        self._dirty_objects.clear()
        self._deleted_objects.clear()

    def close(self):
        self.rollback()

    def flush(self):
        pass

    def merge(self, obj):
        self._dirty_objects.append(obj)
        return obj

    def execute(self, stmt, params=None):
        """
        Intenta ejecutar raw SQL via Supabase.
        Para SELECT simples de tablas conocidas, usa el cliente REST.
        Para raw SQL complejo, retorna un resultado vacío con log de advertencia.
        """
        try:
            stmt_str = str(stmt)
            logger.debug(f"execute() SQL: {stmt_str[:200]}")

            # Parsear SELECT simples: SELECT col FROM tabla WHERE col = :param
            import re
            m = re.search(r'FROM\s+(\w+)', stmt_str, re.IGNORECASE)
            if m and params:
                table = m.group(1)
                # Build basic query
                q = self._sb.table(table).select('*')
                # Apply WHERE conditions from params
                where_m = re.findall(r'(\w+)\s*=\s*:(\w+)', stmt_str, re.IGNORECASE)
                for col, param_name in where_m:
                    val = params.get(param_name)
                    if val is not None:
                        q = q.eq(col, str(val) if isinstance(val, uuid.UUID) else val)
                # AND estado conditions
                estado_m = re.search(r"estado\s*=\s*'(\w+)'", stmt_str, re.IGNORECASE)
                if estado_m:
                    q = q.eq('estado', estado_m.group(1))
                r = q.execute()
                return RawResultProxy(r.data)

        except Exception as e:
            logger.warning(f"execute() falló gracefully: {e}")

        return RawResultProxy([])

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        else:
            self.commit()
        self.close()
        return False
