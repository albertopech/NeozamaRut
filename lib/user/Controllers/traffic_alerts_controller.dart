import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/supabase_service.dart';

/// Controlador para gestionar las ALERTAS DE TRÁFICO
///
/// Este controlador maneja los streams de alertas de la tabla 'traffic_alerts'.
class TrafficAlertsController {
  // Obtener el cliente de Supabase
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Obtiene una lista de alertas activas (solo una vez)
  /// Se usa para verificar el estado inicial de la ruta al cargar la vista.
  Future<List<Map<String, dynamic>>> fetchActiveAlertsByRoute(String routeId) async {
    try {
      final response = await _supabase
          .from('traffic_alerts')
          .select()
          .eq('route_id', routeId)
          .eq('is_active', true)
          .eq('alert_type', 'route_start') // Solo queremos las de inicio de ruta
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching active alerts: $e');
      return [];
    }
  }

  /// Stream de alertas activas para una ruta específica (tiempo real)
  ///
  /// [routeId] ID de la ruta
  Stream<List<Map<String, dynamic>>> watchActiveAlertsByRoute(String routeId) {
    return _supabase
        .from('traffic_alerts')
        .stream(primaryKey: ['id'])
        .map((data) {
      // Aplicar filtros y ordenamiento localmente (client-side)
      final filteredData = data
          .where((item) =>
      item['route_id'] == routeId &&
          item['is_active'] == true
      )
          .toList();

      // Aplicar ordenamiento por fecha de creación (más reciente primero)
      filteredData.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA); // Comparación descendente
      });

      return filteredData.map((e) => e as Map<String, dynamic>).toList();
    });
  }
}