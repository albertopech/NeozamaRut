import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase_service.dart';

/// Controlador para gestionar los horarios de las rutas
///
/// Maneja consultas, creación y actualización de horarios
/// de operación de las rutas de transporte.
class SchedulesController {
  // Obtener el cliente de Supabase
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Obtener todos los horarios de una ruta
  ///
  /// [routeId] ID de la ruta
  Future<List<Map<String, dynamic>>> getRouteSchedules(String routeId) async {
    try {
      final response = await _supabase
          .from('schedules')
          .select('''
            *,
            routes (
              route_number,
              route_name
            )
          ''')
          .eq('route_id', routeId)
          .order('day_of_week')
          .order('start_time');

      print('✅ Se obtuvieron ${response.length} horarios');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener horarios: $e');
      return [];
    }
  }

  /// Obtener horarios de una ruta para un día específico
  ///
  /// [routeId] ID de la ruta
  /// [dayOfWeek] Día de la semana (0=Domingo, 1=Lunes, ..., 6=Sábado)
  Future<List<Map<String, dynamic>>> getSchedulesByDay(
      String routeId,
      int dayOfWeek,
      ) async {
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('route_id', routeId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      print('✅ Se obtuvieron ${response.length} horarios para el día $dayOfWeek');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error al obtener horarios del día: $e');
      return [];
    }
  }

  /// Obtener horarios actuales (del día de hoy)
  ///
  /// [routeId] ID de la ruta
  Future<List<Map<String, dynamic>>> getTodaySchedules(String routeId) async {
    try {
      // Obtener el día actual (0=Domingo, 1=Lunes, etc.)
      final today = DateTime.now().weekday % 7; // weekday va de 1-7, lo convertimos a 0-6

      return await getSchedulesByDay(routeId, today);
    } catch (e) {
      print('❌ Error al obtener horarios de hoy: $e');
      return [];
    }
  }

  /// Verificar si una ruta está operando en este momento
  ///
  /// [routeId] ID de la ruta
  Future<bool> isRouteOperatingNow(String routeId) async {
    try {
      final now = DateTime.now();
      final currentDay = now.weekday % 7;
      final currentTime = TimeOfDay.fromDateTime(now);

      final schedules = await getSchedulesByDay(routeId, currentDay);

      for (final schedule in schedules) {
        final startTime = _parseTime(schedule['start_time']);
        final endTime = _parseTime(schedule['end_time']);

        if (_isTimeBetween(currentTime, startTime, endTime)) {
          print('✅ La ruta está operando ahora');
          return true;
        }
      }

      print('ℹ️ La ruta no está operando en este momento');
      return false;
    } catch (e) {
      print('❌ Error al verificar operación: $e');
      return false;
    }
  }

  /// Obtener el próximo horario de salida
  ///
  /// [routeId] ID de la ruta
  Future<Map<String, dynamic>?> getNextDeparture(String routeId) async {
    try {
      final schedules = await getTodaySchedules(routeId);

      if (schedules.isEmpty) {
        return null;
      }

      final now = TimeOfDay.fromDateTime(DateTime.now());

      for (final schedule in schedules) {
        final startTime = _parseTime(schedule['start_time']);
        final endTime = _parseTime(schedule['end_time']);
        final frequencyMinutes = schedule['frequency_minutes'] as int;

        // Si estamos dentro del rango de operación
        if (_isTimeBetween(now, startTime, endTime)) {
          // Calcular el próximo horario basado en la frecuencia
          final minutesSinceStart = _minutesBetween(startTime, now);
          final minutesToNext = frequencyMinutes - (minutesSinceStart % frequencyMinutes);

          return {
            'schedule': schedule,
            'minutes_to_next': minutesToNext,
            'next_departure_time': _addMinutes(now, minutesToNext),
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener próximo horario: $e');
      return null;
    }
  }

  /// Obtener todos los horarios de operación de la semana
  ///
  /// [routeId] ID de la ruta
  /// Retorna un Map con los horarios organizados por día
  Future<Map<int, List<Map<String, dynamic>>>> getWeekSchedules(
      String routeId,
      ) async {
    try {
      final allSchedules = await getRouteSchedules(routeId);

      // Organizar por día
      final weekSchedules = <int, List<Map<String, dynamic>>>{};

      for (final schedule in allSchedules) {
        final day = schedule['day_of_week'] as int;

        if (!weekSchedules.containsKey(day)) {
          weekSchedules[day] = [];
        }

        weekSchedules[day]!.add(schedule);
      }

      print('✅ Horarios de la semana organizados');
      return weekSchedules;
    } catch (e) {
      print('❌ Error al obtener horarios de la semana: $e');
      return {};
    }
  }

  /// Crear un nuevo horario
  ///
  /// [scheduleData] Datos del horario (route_id, day_of_week, start_time, end_time, frequency_minutes)
  Future<Map<String, dynamic>?> createSchedule(
      Map<String, dynamic> scheduleData,
      ) async {
    try {
      final response = await _supabase
          .from('schedules')
          .insert(scheduleData)
          .select()
          .single();

      print('✅ Horario creado');
      return response;
    } catch (e) {
      print('❌ Error al crear horario: $e');
      return null;
    }
  }

  /// Actualizar un horario existente
  ///
  /// [scheduleId] ID del horario
  /// [updates] Datos a actualizar
  Future<bool> updateSchedule(
      String scheduleId,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _supabase
          .from('schedules')
          .update(updates)
          .eq('id', scheduleId);

      print('✅ Horario actualizado');
      return true;
    } catch (e) {
      print('❌ Error al actualizar horario: $e');
      return false;
    }
  }

  /// Eliminar un horario
  ///
  /// [scheduleId] ID del horario
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _supabase
          .from('schedules')
          .delete()
          .eq('id', scheduleId);

      print('✅ Horario eliminado');
      return true;
    } catch (e) {
      print('❌ Error al eliminar horario: $e');
      return false;
    }
  }

  /// Obtener el nombre del día en español
  ///
  /// [dayOfWeek] Día de la semana (0-6)
  String getDayName(int dayOfWeek) {
    const days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];

    return dayOfWeek >= 0 && dayOfWeek < 7 ? days[dayOfWeek] : 'Desconocido';
  }

  /// Formatear hora para mostrar (HH:mm)
  ///
  /// [timeString] String de tiempo en formato ISO o "HH:mm:ss"
  String formatTime(String timeString) {
    try {
      final time = _parseTime(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  /// Formatear duración en minutos a texto legible
  ///
  /// [minutes] Duración en minutos
  String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours h';
    }

    return '$hours h $remainingMinutes min';
  }

  // ========== Métodos auxiliares privados ==========

  /// Parsear string de tiempo a TimeOfDay
  TimeOfDay _parseTime(String timeString) {
    // Manejar formato "HH:mm:ss" o "HH:mm"
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Verificar si una hora está entre dos horas
  bool _isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Si el horario cruza medianoche
    if (endMinutes < startMinutes) {
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// Calcular minutos entre dos horas
  int _minutesBetween(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return endMinutes - startMinutes;
  }

  /// Agregar minutos a una hora
  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final hours = (totalMinutes ~/ 60) % 24;
    final mins = totalMinutes % 60;

    return TimeOfDay(hour: hours, minute: mins);
  }
}