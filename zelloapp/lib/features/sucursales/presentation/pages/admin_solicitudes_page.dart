import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/sesion_usuario.dart';
import 'package:zelloapp/features/sucursales/data/datasources/sucursales_remote_data_source.dart';

class AdminSolicitudesPage extends StatefulWidget {
  const AdminSolicitudesPage({super.key});

  @override
  State<AdminSolicitudesPage> createState() => _AdminSolicitudesPageState();
}

class _AdminSolicitudesPageState extends State<AdminSolicitudesPage> {
  final _dataSource = SucursalesRemoteDataSource();

  List<SolicitudModel> _solicitudes = [];
  bool _isLoading = false;
  String? _error;
  String _filtroEstado = 'TODOS'; // TODOS, PENDIENTE, APROBADA, RECHAZADA
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _dataSource.getSolicitudes(
        estado: _filtroEstado == 'TODOS' ? null : _filtroEstado,
      );
      if (mounted) {
        setState(() => _solicitudes = list);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<SolicitudModel> get _solicitudesFiltradas {
    if (_busqueda.trim().isEmpty) return _solicitudes;
    final q = _busqueda.trim().toLowerCase();
    return _solicitudes.where((s) {
      final matchNombre = s.nombreNegocio.toLowerCase().contains(q);
      final matchSolicitante = (s.nombreSolicitante ?? '').toLowerCase().contains(q);
      final matchEmail = (s.usuarioEmail ?? '').toLowerCase().contains(q);
      final matchDireccion = (s.direccion ?? '').toLowerCase().contains(q);
      return matchNombre || matchSolicitante || matchEmail || matchDireccion;
    }).toList();
  }

  Color _colorEstado(String estado) {
    final est = estado.toUpperCase();
    if (est.contains('APROBAD')) return Colors.green.shade700;
    if (est.contains('RECHAZAD')) return Colors.red.shade700;
    return Colors.orange.shade800;
  }

  Color _bgEstado(String estado) {
    final est = estado.toUpperCase();
    if (est.contains('APROBAD')) return Colors.green.shade50;
    if (est.contains('RECHAZAD')) return Colors.red.shade50;
    return Colors.orange.shade50;
  }

  IconData _iconoEstado(String estado) {
    final est = estado.toUpperCase();
    if (est.contains('APROBAD')) return Icons.verified_rounded;
    if (est.contains('RECHAZAD')) return Icons.cancel_rounded;
    return Icons.hourglass_top_rounded;
  }

  Future<void> _cerrarSesionAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SesionUsuario().usuarioId = null;
    SesionUsuario().rol = null;
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final pendientesCount = _solicitudes
        .where((s) => s.estado.toUpperCase().contains('PENDIENTE'))
        .length;
    final aprobadasCount = _solicitudes
        .where((s) => s.estado.toUpperCase().contains('APROBAD'))
        .length;
    final rechazadasCount = _solicitudes
        .where((s) => s.estado.toUpperCase().contains('RECHAZAD'))
        .length;

    final listaVisible = _solicitudesFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Panel Administrador — Solicitudes de Alta',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
            onPressed: _cargarSolicitudes,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar sesión de administrador',
            onPressed: _cerrarSesionAdmin,
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen superior y filtros
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.blueGrey.shade100),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contadores rápidos
                Row(
                  children: [
                    _buildCounterChip(
                      label: 'Pendientes',
                      count: pendientesCount,
                      color: Colors.orange.shade800,
                      bgColor: Colors.orange.shade100,
                    ),
                    const SizedBox(width: 8),
                    _buildCounterChip(
                      label: 'Aprobadas',
                      count: aprobadasCount,
                      color: Colors.green.shade800,
                      bgColor: Colors.green.shade100,
                    ),
                    const SizedBox(width: 8),
                    _buildCounterChip(
                      label: 'Rechazadas',
                      count: rechazadasCount,
                      color: Colors.red.shade800,
                      bgColor: Colors.red.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Buscador
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _busqueda = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre del local, dueño, correo o dirección...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _busqueda = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filtro por estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('TODOS', 'Todas'),
                      const SizedBox(width: 8),
                      _buildFilterChip('PENDIENTE', 'Pendientes de Revisión'),
                      const SizedBox(width: 8),
                      _buildFilterChip('APROBADA', 'Aprobadas'),
                      const SizedBox(width: 8),
                      _buildFilterChip('RECHAZADA', 'Rechazadas'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cuerpo: Lista de solicitudes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _cargarSolicitudes,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : listaVisible.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No se encontraron solicitudes de alta con este filtro.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarSolicitudes,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: listaVisible.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final sol = listaVisible[index];
                                final docsCount = sol.listaDocumentos.length;
                                final fechaStr =
                                    '${sol.fechaSolicitud.day.toString().padLeft(2, '0')}/${sol.fechaSolicitud.month.toString().padLeft(2, '0')}/${sol.fechaSolicitud.year}';

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: _colorEstado(sol.estado).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      final actualizado = await context.push<bool>(
                                        '/admin/solicitudes/detalle',
                                        extra: sol,
                                      );
                                      if (actualizado == true) {
                                        _cargarSolicitudes();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: _bgEstado(sol.estado),
                                                child: Icon(
                                                  _iconoEstado(sol.estado),
                                                  color: _colorEstado(sol.estado),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: sol.esCambioNombre
                                                                ? Colors.purple.shade50
                                                                : Colors.blue.shade50,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            sol.esCambioNombre
                                                                ? 'CAMBIO DE NOMBRE'
                                                                : 'NUEVA SUCURSAL',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              color: sol.esCambioNombre
                                                                  ? Colors.purple.shade800
                                                                  : Colors.blue.shade800,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      sol.nombreNegocio,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 17,
                                                      ),
                                                    ),
                                                    if (sol.esCambioNombre &&
                                                        sol.nombreAnterior != null &&
                                                        sol.nombreAnterior!.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2),
                                                        child: Text(
                                                          'Nombre anterior: ${sol.nombreAnterior}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.purple.shade700,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    if (sol.nombreSolicitante != null &&
                                                        sol.nombreSolicitante!.isNotEmpty)
                                                      Text(
                                                        'Solicitante: ${sol.nombreSolicitante}',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    if (sol.usuarioEmail != null &&
                                                        sol.usuarioEmail!.isNotEmpty)
                                                      Text(
                                                        'Correo: ${sol.usuarioEmail}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    if (sol.direccion != null &&
                                                        sol.direccion!.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2),
                                                        child: Text(
                                                          'Dirección: ${sol.direccion}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.black54,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _bgEstado(sol.estado),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _colorEstado(sol.estado),
                                                  ),
                                                ),
                                                child: Text(
                                                  sol.estado,
                                                  style: TextStyle(
                                                    color: _colorEstado(sol.estado),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.folder_shared_outlined,
                                                    size: 16,
                                                    color: Colors.blueGrey.shade700,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '$docsCount documento(s) adjunto(s)',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blueGrey.shade800,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Icon(
                                                    Icons.calendar_today_outlined,
                                                    size: 14,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    fechaStr,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Evaluar solicitud',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 13,
                                                    color: Theme.of(context).primaryColor,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (sol.comentariosEvaluacion != null &&
                                              sol.comentariosEvaluacion!.trim().isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.amber.shade300),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.comment_outlined,
                                                    size: 16,
                                                    color: Colors.amber.shade900,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Observación enviada: ${sol.comentariosEvaluacion}',
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.amber.shade900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterChip({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String valor, String etiqueta) {
    final seleccionado = _filtroEstado == valor;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (sel) {
        if (sel) {
          setState(() => _filtroEstado = valor);
          _cargarSolicitudes();
        }
      },
    );
  }
}
