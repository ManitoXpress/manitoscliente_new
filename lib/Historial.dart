import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:manitoscliente_new/constants/service_constants.dart';

import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/request/resquest.dart';
import 'package:manitoscliente_new/widgets/serviceList.dart';
import 'package:provider/provider.dart';

import 'Styles/stilo.dart';
import 'provider/providerService.dart';

class HistorialScreen extends StatefulWidget {
  final UserData userData;
  final VoidCallback onTabTapped;
  const HistorialScreen({
    Key? key,
    required this.userData,
    required this.onTabTapped,
  }) : super(key: key);

  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen>
    with SingleTickerProviderStateMixin, RestorationMixin {
  final RestorableInt _tabIndex = RestorableInt(0);
  late TabController _tabController;

  String _userId = '';
  String _token = '';
  String _deviceId = '';
  Timer? _autoRefreshTimer;

  @override
  String? get restorationId => 'historial_screen';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabIndex.value = _tabController.index;
        });
      }
    });

    // 2) Obtenemos credenciales y disparamos la carga
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      final deviceId = await _fetchDeviceId();

      if (!mounted) return;
      setState(() {
        _userId = user.uid;
        _token = token ?? '';
        _deviceId = deviceId;
      });

      // Usar el provider del contexto
      final historialProv =
          Provider.of<HistorialProvider>(context, listen: false);
      await historialProv.loadAll(
        userId: _userId,
        token: _token,
        deviceId: _deviceId,
      );

      // Iniciar polling automático
      historialProv.startAutoRefresh(
        userId: _userId,
        token: _token,
        deviceId: _deviceId,
      );

      // Iniciar temporizador de cancelación automática de servicios vencidos
      historialProv.iniciarTemporizadorCancelacion(_userId, _token);

      // Iniciar refresco automático cada 1 minuto
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted &&
            _userId.isNotEmpty &&
            _token.isNotEmpty &&
            _deviceId.isNotEmpty) {
          Provider.of<HistorialProvider>(context, listen: false).refresh(
            userId: _userId,
            token: _token,
            deviceId: _deviceId,
          );
        }
      });
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tabIndex, 'tab_index');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tabController.index = _tabIndex.value;
      }
    });
  }

  Future<String> _fetchDeviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return a.id ?? 'unknown';
    } else if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? 'unknown';
    }
    return 'unsupported';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabIndex.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: MyTextStyles.tabTextStyle,
              unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: Color(0xFF1A819A)),
                insets: EdgeInsets.symmetric(horizontal: 20),
              ),
              tabs: [
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.task_alt, color: Colors.black),
                          ),
                          if (Provider.of<HistorialProvider>(context)
                                  .availableCount >
                              0)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A819A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  Provider.of<HistorialProvider>(context)
                                      .availableCount
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Disponibles'),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.local_offer, color: Colors.black),
                          ),
                          if (Provider.of<HistorialProvider>(context)
                                  .offerServiceCount >
                              0)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A819A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  Provider.of<HistorialProvider>(context)
                                      .offerServiceCount
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Cotizaciones'),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child:
                                Icon(Icons.assignment_ind, color: Colors.black),
                          ),
                          if (Provider.of<HistorialProvider>(context)
                                  .inProgressCount >
                              0)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A819A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  Provider.of<HistorialProvider>(context)
                                      .inProgressCount
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Asignados'),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child:
                                Icon(Icons.check_circle, color: Colors.black),
                          ),
                          if (Provider.of<HistorialProvider>(context)
                                  .completedCount >
                              0)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A819A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  Provider.of<HistorialProvider>(context)
                                      .completedCount
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Completados'),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.cancel, color: Colors.black),
                          ),
                          if (Provider.of<HistorialProvider>(context)
                                  .cancelledCount >
                              0)
                            Positioned(
                              top: -10,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A819A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  Provider.of<HistorialProvider>(context)
                                      .cancelledCount
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Cancelados'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Center(
                  child:
                      Text('Historial', style: MyTextStyles.buttonTextStyle3),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ServiceListTab(
                      status: 'available',
                      userId: _userId,
                      userData: widget.userData,
                      apiService: ApiService(),
                      apiService2: ApiService2(),
                      onRefresh: () =>
                          Provider.of<HistorialProvider>(context, listen: false)
                              .refresh(
                                  userId: _userId,
                                  token: _token,
                                  deviceId: _deviceId),
                      isLoading:
                          Provider.of<HistorialProvider>(context).isLoading,
                    ),
                    _ServiceListTab(
                      status: 'offer',
                      userId: _userId,
                      userData: widget.userData,
                      apiService: ApiService(),
                      apiService2: ApiService2(),
                      onRefresh: () =>
                          Provider.of<HistorialProvider>(context, listen: false)
                              .refresh(
                                  userId: _userId,
                                  token: _token,
                                  deviceId: _deviceId),
                      isLoading:
                          Provider.of<HistorialProvider>(context).isLoading,
                    ),
                    _ServiceListTab(
                      status: 'in_progress',
                      userId: _userId,
                      userData: widget.userData,
                      apiService: ApiService(),
                      apiService2: ApiService2(),
                      onRefresh: () =>
                          Provider.of<HistorialProvider>(context, listen: false)
                              .refresh(
                                  userId: _userId,
                                  token: _token,
                                  deviceId: _deviceId),
                      isLoading:
                          Provider.of<HistorialProvider>(context).isLoading,
                    ),
                    _ServiceListTab(
                      status: 'completed',
                      userId: _userId,
                      userData: widget.userData,
                      apiService: ApiService(),
                      apiService2: ApiService2(),
                      onRefresh: () =>
                          Provider.of<HistorialProvider>(context, listen: false)
                              .refresh(
                                  userId: _userId,
                                  token: _token,
                                  deviceId: _deviceId),
                      isLoading:
                          Provider.of<HistorialProvider>(context).isLoading,
                    ),
                    _ServiceListTab(
                      status: 'cancelled',
                      userId: _userId,
                      userData: widget.userData,
                      apiService: ApiService(),
                      apiService2: ApiService2(),
                      onRefresh: () =>
                          Provider.of<HistorialProvider>(context, listen: false)
                              .refresh(
                                  userId: _userId,
                                  token: _token,
                                  deviceId: _deviceId),
                      isLoading:
                          Provider.of<HistorialProvider>(context).isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Loader mejorado: cubre toda la pantalla, incluyendo tabs y FAB
          if (Provider.of<HistorialProvider>(context).isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF1A819A)),
                          strokeWidth: 6,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Cargando servicios...',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: Provider.of<HistorialProvider>(context).isLoading ||
                _userId.isEmpty ||
                _token.isEmpty ||
                _deviceId.isEmpty
            ? null
            : () {
                print(
                    'Botón actualizar presionado: userId=[32m$_userId[0m, token=[32m$_token[0m, deviceId=[32m$_deviceId[0m');
                Provider.of<HistorialProvider>(context, listen: false).refresh(
                  userId: _userId,
                  token: _token,
                  deviceId: _deviceId,
                );
              },
        label: const Text('Actualizar'),
        icon: const Icon(Icons.refresh),
        backgroundColor: const Color(0xFF1A819A),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Un widget por pestaña, que conserva scroll y no se rebuild innecesariamente
class _ServiceListTab extends StatefulWidget {
  final String status;
  final String userId;
  final UserData userData;
  final ApiService apiService;
  final ApiService2 apiService2;
  final VoidCallback onRefresh;
  final bool isLoading;

  const _ServiceListTab({
    required this.status,
    required this.userId,
    required this.userData,
    required this.apiService,
    required this.apiService2,
    required this.onRefresh,
    required this.isLoading,
    Key? key,
  }) : super(key: key);

  @override
  State<_ServiceListTab> createState() => _ServiceListTabState();
}

class _ServiceListTabState extends State<_ServiceListTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final prov = Provider.of<HistorialProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (prov.hasMore(widget.status) && !prov.isLoadingMore(widget.status)) {
        prov.loadMore(
          status: widget.status,
          userId: widget.userId,
          token: '', // Puedes pasar el token real si lo necesitas
          deviceId: '', // Puedes pasar el deviceId real si lo necesitas
        );
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  /// Método helper para construir la lista de servicios
  Widget _buildServiceList(
      String status, List<ServiceRequest> list, double w, double h) {
    switch (status) {
      case 'available':
        final offers = list.expand((s) => s.offers).toList();
        return ServiceListBuilder.buildServiceListAvailable(
          list,
          w,
          h,
          widget.userId,
          widget.userData,
          widget.apiService,
        );
      case 'offer':
        final offers = list.expand((s) => s.offers).toList();
        return ServiceListBuilder.buildOfferList(
          list,
          offers,
          w,
          h,
          widget.userId,
          widget.userData,
          widget.apiService,
        );
      case 'in_progress':
        final offers = list.expand((s) => s.offers).toList();
        return ServiceListBuilder.inProgressList(
          list,
          offers,
          w,
          h,
          widget.userId,
          widget.userData,
          widget.apiService,
        );
      case 'completed':
        final offers = list
            .expand((s) => s.offers)
            .where((offer) => offer.status.id == ServiceStatus.completed)
            .toList();
        return ServiceListBuilder.buildServiceListComplete(
          list,
          offers,
          w,
          h,
          widget.userId,
          widget.userData,
          widget.apiService,
        );
      case 'cancelled':
        return ServiceListBuilder.buildServiceListCancelled(
          list,
          w,
          h,
          widget.userId,
          widget.userData,
          widget.apiService,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<HistorialProvider>(context);
    final list = prov.list(widget.status);
    final isLoadingMore = prov.isLoadingMore(widget.status);
    final hasMore = prov.hasMore(widget.status);

    // Declarar las variables de tamaño al inicio
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: Builder(
        builder: (context) {
          if (prov.errorMessage != null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFF1A819A),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error al cargar historial',
                        style: TextStyle(
                          color: Color(0xFF1A819A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          prov.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => widget.onRefresh(),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Reintentar',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A819A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (list.isEmpty && !widget.isLoading) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        color: Color(0xFF1A819A),
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay servicios en esta categoría',
                        style: TextStyle(
                          color: Color(0xFF1A819A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Usa el botón de refresh para actualizar',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Skeleton loader para carga inicial
          if (widget.isLoading && list.isEmpty) {
            return ListView.builder(
              controller: _scrollController,
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 80,
                                height: 12,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 60,
                                height: 12,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Skeleton loader para actualización (cuando hay datos pero se está actualizando)
          if (prov.isRefreshing && list.isNotEmpty) {
            return Stack(
              children: [
                // Mostrar los datos actuales con opacidad reducida
                Opacity(
                  opacity: 0.3,
                  child: _buildServiceList(widget.status, list, w, h),
                ),
                // Overlay con skeleton loader
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: 3,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 14,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 80,
                                      height: 12,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 60,
                                      height: 12,
                                      color: Colors.grey[300],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          Widget listWidget;
          switch (widget.status) {
            case 'available':
              final offers = list.expand((s) => s.offers).toList();
              listWidget = ServiceListBuilder.buildServiceListAvailable(
                list,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
              );
              break;
            case 'offer':
              final offers = list.expand((s) => s.offers).toList();
              listWidget = ServiceListBuilder.buildOfferList(
                list,
                offers,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
              );
              break;
            case 'in_progress':
              // Debug: Imprimir información de la lista
              print('🔍 Debug - Lista de servicios recibida: ${list.length}');
              for (int i = 0; i < list.length; i++) {
                print(
                    '🔍 Debug - Servicio $i: ID=${list[i].id}, Status=${list[i].status.id}, Offers=${list[i].offers.length}');
              }

              // 1) Expandir todas las ofertas de cada servicio, forzando el tipo a Offer
              final List<Offer> listOffer = list
                  .expand((s) => (s.offers ?? <Offer>[]).cast<Offer>())
                  .toList();

              print(
                  '🔍 Debug - Total de ofertas expandidas: ${listOffer.length}');
              for (int i = 0; i < listOffer.length; i++) {
                print(
                    '🔍 Debug - Oferta $i: ID=${listOffer[i].id}, Status=${listOffer[i].status.id}, ServiceId=${listOffer[i].serviceId}');
              }

              // 2) FILTRAR sólo las que están realmente en "in_progress".
              //    Aquí comparamos offer.status.id (que es un String como "in_progress")
              //    con nuestro ServiceStatus.inProgress (también "in_progress").
              final List<Offer> ofertasEnProgreso = listOffer
                  .where((offer) => offer.status.id == ServiceStatus.inProgress)
                  .toList();

              print(
                  '🔍 Debug - Ofertas filtradas por in_progress: ${ofertasEnProgreso.length}');
              print(
                  '🔍 Debug - ServiceStatus.inProgress = ${ServiceStatus.inProgress}');

              // Si no hay ofertas en progreso, también mostrar servicios que tengan status in_progress directamente
              if (ofertasEnProgreso.isEmpty) {
                print(
                    '🔍 Debug - No se encontraron ofertas en progreso, revisando servicios directamente...');
                final serviciosEnProgreso = list
                    .where((s) => s.status.id == ServiceStatus.inProgress)
                    .toList();
                print(
                    '🔍 Debug - Servicios con status in_progress: ${serviciosEnProgreso.length}');

                if (serviciosEnProgreso.isNotEmpty) {
                  // Si hay servicios en progreso pero sin ofertas, crear ofertas dummy
                  final ofertasDummy = serviciosEnProgreso.map((service) {
                    return Offer(
                      id: service.id,
                      workerId: service.workerId.isNotEmpty
                          ? service.workerId
                          : 'unknown',
                      offeredPrice: service.offeredPrice,
                      hasOffer: true,
                      serviceId: service.id,
                      extraCosts: 0.0,
                      totalPrice: service.offeredPrice,
                      status: service.status,
                      userToken: '',
                      createdAt: DateTime.now(),
                      expertises: service.expertises,
                      subcategoryName: service.subcategoryName,
                    );
                  }).toList();

                  print(
                      '🔍 Debug - Creando ofertas dummy para servicios en progreso: ${ofertasDummy.length}');
                  listWidget = ServiceListBuilder.inProgressList(
                    list,
                    ofertasDummy,
                    w,
                    h,
                    widget.userId,
                    widget.userData,
                    widget.apiService,
                  );
                } else {
                  listWidget = const Center(
                    child: Text(
                      'No hay servicios en progreso',
                      style: TextStyle(
                        color: Color(0xFF1A819A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
              } else {
                // 3) Ahora sí, pasamos sólo esa sublista al builder
                listWidget = ServiceListBuilder.inProgressList(
                  list, // List<ServiceRequest>
                  ofertasEnProgreso, // List<Offer> filtrada
                  w, // screenWidth
                  h, // screenHeight
                  widget.userId,
                  widget.userData,
                  widget.apiService,
                );
              }
              break;
            case 'completed':
              final offers = list
                  .expand((s) => s.offers)
                  .where((offer) => offer.status.id == ServiceStatus.completed)
                  .toList();
              listWidget = ServiceListBuilder.buildServiceListComplete(
                list,
                offers,
                w,
                h,
                widget.userId,
                widget.userData,
                widget.apiService,
              );
              break;
            case 'cancelled':
              listWidget = ServiceListBuilder.buildServiceListCancelled(
                list, // tu lista de ServiceRequest (incluye offers internamente)
                w, // ancho
                h, // alto
                widget.userId,
                widget.userData,
                widget.apiService,
              );
              break;
            default:
              listWidget = const SizedBox.shrink();
          }

          return Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200 &&
                      hasMore &&
                      !isLoadingMore) {
                    prov.loadMore(
                      status: widget.status,
                      userId: widget.userId,
                      token: '', // Puedes pasar el token real si lo necesitas
                      deviceId:
                          '', // Puedes pasar el deviceId real si lo necesitas
                    );
                  }
                  return false;
                },
                child: listWidget,
              ),
              if (isLoadingMore)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1A819A)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Cargando más...',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF1A819A))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
