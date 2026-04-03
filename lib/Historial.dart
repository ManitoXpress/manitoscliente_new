import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:manitoscliente_new/provider/providerService.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/request/resquest.dart';

import 'package:manitoscliente_new/widgets/serviceList.dart';
import 'package:provider/provider.dart';

import 'Styles/stilo.dart';
import 'constant/serviceConstants.dart';
import 'HistorialTabWidgets.dart';
import 'services/historial_preload_service.dart';


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
  bool _isInitialized = false;

  @override
  String? get restorationId => 'historial_screen';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabIndex.value = _tabController.index;
        });
      }
    });

    // Inicialización optimizada con delay mínimo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeHistorial();
    });
  }

  /// 🚀 OPTIMIZADO: Inicialización ultra-rápida del historial con precarga
  Future<void> _initializeHistorial() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      null;
      final startTime = DateTime.now();

      setState(() {
        _userId = user.uid;
      });

      // 🚀 OPTIMIZACIÓN: Verificar si ya se precargó
      final preloadService = HistorialPreloadService();
      if (preloadService.isPreloadedForUser(_userId)) {
        null;
        _isInitialized = true;
        return;
      }

      // Si no está precargado, cargar normalmente
      final futures = await Future.wait([
        user.getIdToken(),
        _fetchDeviceId(),
      ]).timeout(const Duration(seconds: 5));

      final token = futures[0] as String?;
      final deviceId = futures[1] as String;

      if (!mounted) return;
      
      setState(() {
        _token = token ?? '';
        _deviceId = deviceId;
      });

      // Usar el provider del contexto con optimizaciones
      final historialProv = Provider.of<HistorialProvider>(context, listen: false);
      
      // 🚀 OPTIMIZACIÓN: Cargar datos de forma asíncrona sin bloquear la UI
      Future.microtask(() async {
        await historialProv.loadAll(
          userId: _userId,
          token: _token,
          deviceId: _deviceId,
        );

        // Iniciar actualización automática inteligente
        historialProv.startAutoRefresh(
          userId: _userId,
          token: _token,
          deviceId: _deviceId,
        );

        // Iniciar temporizador de cancelación automática
        historialProv.iniciarTemporizadorCancelacion(_userId, _token);

        _isInitialized = true;
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        null;
      });

    } catch (e) {
      null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return a.id ?? 'unknown';
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        return i.identifierForVendor ?? 'unknown';
      }
      return 'unsupported';
    } catch (e) {
      null;
      return 'error';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabIndex.dispose();
    _autoRefreshTimer?.cancel();
    
    // Detener actualización automática al salir
    if (_userId.isNotEmpty) {
      final historialProv = Provider.of<HistorialProvider>(context, listen: false);
      historialProv.stopAutoRefresh();
    }
    
    super.dispose();
  }

  /// Refrescar historial de forma optimizada
  Future<void> _refreshHistorial() async {
    if (_userId.isEmpty || _token.isEmpty || _deviceId.isEmpty) return;
    
    try {
      final historialProv = Provider.of<HistorialProvider>(context, listen: false);
      await historialProv.refresh(
        userId: _userId,
        token: _token,
        deviceId: _deviceId,
      );
    } catch (e) {
      null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // TabBar optimizado con indicadores de estado
          Container(
            color: Colors.white,
            child: Consumer<HistorialProvider>(
              builder: (context, provider, child) {
                return ModernTabBar(
                  controller: _tabController,
                  availableCount: provider.availableCount,
                  offerServiceCount: provider.offerServiceCount,
                  inProgressCount: provider.inProgressCount,
                  completedCount: provider.completedCount,
                );
              },
            ),
          ),
          
          // Header con información de estado
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Text('Historial', style: MyTextStyles.buttonTextStyle3),
                  ),
                ),
                // 🚀 MEJORADO: Indicador de estado de caché más informativo
                Consumer<HistorialProvider>(
                  builder: (context, provider, child) {
                    if (provider.isRefreshing) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A819A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Actualizando...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A819A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Contenido principal optimizado
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
                  onRefresh: _refreshHistorial,
                  isLoading: Provider.of<HistorialProvider>(context).isLoading,
                ),
                _ServiceListTab(
                  status: 'offer',
                  userId: _userId,
                  userData: widget.userData,
                  apiService: ApiService(),
                  apiService2: ApiService2(),
                  onRefresh: _refreshHistorial,
                  isLoading: Provider.of<HistorialProvider>(context).isLoading,
                ),
                _ServiceListTab(
                  status: 'in_progress',
                  userId: _userId,
                  userData: widget.userData,
                  apiService: ApiService(),
                  apiService2: ApiService2(),
                  onRefresh: _refreshHistorial,
                  isLoading: Provider.of<HistorialProvider>(context).isLoading,
                ),
                _ServiceListTab(
                  status: 'completed',
                  userId: _userId,
                  userData: widget.userData,
                  apiService: ApiService(),
                  apiService2: ApiService2(),
                  onRefresh: _refreshHistorial,
                  isLoading: Provider.of<HistorialProvider>(context).isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Botón flotante optimizado
      floatingActionButton: Consumer<HistorialProvider>(
        builder: (context, provider, child) {
          final canRefresh = _isInitialized && 
                           _userId.isNotEmpty && 
                           _token.isNotEmpty && 
                           _deviceId.isNotEmpty &&
                           !provider.isRefreshing;
          
          return FloatingActionButton.extended(
            onPressed: canRefresh ? _refreshHistorial : null,
            label: Text(provider.isRefreshing ? 'Actualizando...' : 'Actualizar'),
            icon: provider.isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            backgroundColor: canRefresh ? const Color(0xFF1A819A) : Colors.grey,
            foregroundColor: Colors.white,
          );
        },
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
  bool _isLoadingMore = false;

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
        _loadMoreData(prov);
      }
    }
  }

  /// Carga más datos de forma optimizada
  Future<void> _loadMoreData(HistorialProvider provider) async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      await provider.loadMore(
        status: widget.status,
        userId: widget.userId,
        token: '', // Se obtendrá del provider
        deviceId: '', // Se obtendrá del provider
      );
    } catch (e) {
      null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  /// Método helper para construir la lista de servicios optimizado
  Widget _buildServiceList(
      String status, List<ServiceRequest> list, double w, double h) {
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (status) {
      case 'available':
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<HistorialProvider>(
      builder: (context, provider, child) {
        final list = provider.list(widget.status);
        final isLoadingMore = provider.isLoadingMore(widget.status);
        final hasMore = provider.hasMore(widget.status);
        final errorMessage = provider.errorMessage;

        // Declarar las variables de tamaño al inicio
        final w = MediaQuery.of(context).size.width;
        final h = MediaQuery.of(context).size.height;

        return RefreshIndicator(
          onRefresh: () async => widget.onRefresh(),
          child: Builder(
            builder: (context) {
              // Manejo de errores optimizado
              if (errorMessage != null) {
                return _buildErrorView(errorMessage, widget.onRefresh);
              }

              // Vista vacía optimizada
              if (list.isEmpty && !widget.isLoading) {
                return _buildEmptyView();
              }

              // Skeleton loader para carga inicial
              if (widget.isLoading && list.isEmpty) {
                return _buildSkeletonLoader();
              }

              // Skeleton loader para actualización
              if (provider.isRefreshing && list.isNotEmpty) {
                return _buildRefreshSkeleton(list, w, h);
              }

              // Lista principal optimizada
              return _buildMainList(list, w, h, hasMore, isLoadingMore, provider);
            },
          ),
        );
      },
    );
  }

  /// Vista de error optimizada
  Widget _buildErrorView(String errorMessage, VoidCallback onRefresh) {
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
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRefresh,
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

  /// Vista vacía optimizada
  Widget _buildEmptyView() {
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

  /// Skeleton loader optimizado
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonItem(),
    );
  }

  /// Skeleton loader para actualización
  Widget _buildRefreshSkeleton(List<ServiceRequest> list, double w, double h) {
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
            itemBuilder: (context, index) => _buildSkeletonItem(),
          ),
        ),
      ],
    );
  }

  /// Item de skeleton reutilizable
  Widget _buildSkeletonItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  /// Lista principal optimizada
  Widget _buildMainList(
    List<ServiceRequest> list,
    double w,
    double h,
    bool hasMore,
    bool isLoadingMore,
    HistorialProvider provider,
  ) {
    Widget listWidget;
    
    // Construir la lista según el estado
    switch (widget.status) {
      case 'available':
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
        final offers = list.expand((s) => s.offers).toList();
        listWidget = ServiceListBuilder.inProgressList(
          list,
          offers,
          w,
          h,
          widget.userId,
          widget.userData,
          widget.apiService,
        );
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
          list,
          w,
          h,
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
        // Lista principal con scroll listener optimizado
        NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200 &&
                hasMore &&
                !isLoadingMore) {
              _loadMoreData(provider);
            }
            return false;
          },
          child: listWidget,
        ),
        
        // Indicador de carga más datos
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
  }
}
