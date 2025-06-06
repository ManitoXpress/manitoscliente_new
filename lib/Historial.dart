import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/constants/service_constants.dart';
import 'package:manitoscliente_new/controller/historialProvider.dart';
import 'package:manitoscliente_new/request/resquest.dart';
import 'package:provider/provider.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart';
import '../request/dataprofile.dart';

import '../widgets/serviceList.dart';

import 'Styles/stilo.dart';
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
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final HistorialProvider _historialProv;

  String _userId = '';
  String _token = '';
  String _deviceId = '';
  bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // 1) Creamos el provider UNA sola vez
    _historialProv = HistorialProvider();

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

      // 4) Carga inicial de TODO el historial
      await _historialProv.loadAll(
        userId: _userId,
        token: _token,
        deviceId: _deviceId,
      );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 5) Abrimos el provider UNA sola vez con .value
    return ChangeNotifierProvider.value(
      value: _historialProv,
      child: Consumer<HistorialProvider>(
        builder: (__, prov, _) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(12),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    labelStyle: MyTextStyles.tabTextStyle,
                    unselectedLabelStyle: MyTextStyles.unselectedTabTextStyle,
                    indicator: const UnderlineTabIndicator(
                      borderSide:
                          BorderSide(width: 3, color: Color(0xFF1A819A)),
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
                                    child: Icon(Icons.task_alt,
                                        color: Colors.black)),
                                if (prov.availableCount > 0)
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
                                        prov.availableCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
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
                                    child: Icon(Icons.local_offer,
                                        color: Colors.black)),
                                if (prov.offerServiceCount > 0)
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
                                        prov.offerServiceCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
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
                                    child: Icon(Icons.assignment_ind,
                                        color: Colors.black)),
                                if (prov.inProgressCount > 0)
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
                                        prov.inProgressCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
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
                                    child: Icon(Icons.check_circle,
                                        color: Colors.black)),
                                if (prov.completedCount > 0)
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
                                        prov.completedCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
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
                                    child: Icon(Icons.cancel,
                                        color: Colors.black)),
                                if (prov.cancelledCount > 0)
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
                                        prov.cancelledCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
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
            body: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Text('Historial', style: MyTextStyles.buttonTextStyle3),
                      const Spacer(),
                      IconButton(
                        icon:
                            const Icon(Icons.refresh, color: Color(0xFF1A819A)),
                        onPressed: () => prov.refresh(
                          userId: _userId,
                          token: _token,
                          deviceId: _deviceId,
                        ),
                      ),
                    ],
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
                      ),
                      _ServiceListTab(
                        status: 'offer',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                      _ServiceListTab(
                        status: 'in_progress',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                      _ServiceListTab(
                        status: 'completed',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                      _ServiceListTab(
                        status: 'cancelled',
                        userId: _userId,
                        userData: widget.userData,
                        apiService: ApiService(),
                        apiService2: ApiService2(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

  const _ServiceListTab({
    required this.status,
    required this.userId,
    required this.userData,
    required this.apiService,
    required this.apiService2,
    Key? key,
  }) : super(key: key);

  @override
  State<_ServiceListTab> createState() => _ServiceListTabState();
}

class _ServiceListTabState extends State<_ServiceListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final prov = context.watch<HistorialProvider>();
    final list = prov.list(widget.status);

    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.errorMessage != null) {
      return Center(child: Text('Error: ${prov.errorMessage}'));
    }
    if (list.isEmpty) {
      return const Center(child: Text('No hay servicios.'));
    }

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    switch (widget.status) {
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
      // 1) Expandir todas las ofertas de cada servicio, forzando el tipo a Offer
      final List<Offer> listOffer = list
        .expand((s) => (s.offers ?? <Offer>[]).cast<Offer>())
        .toList();

      // 2) FILTRAR sólo las que están realmente en "in_progress".
      //    Aquí comparamos offer.status.id (que es un String como "in_progress")
      //    con nuestro ServiceStatus.inProgress (también "in_progress").
      final List<Offer> ofertasEnProgreso = listOffer
        .where((offer) => offer.status.id == ServiceStatus.inProgress)
        .toList();

      // 3) Ahora sí, pasamos sólo esa sublista al builder
      return ServiceListBuilder.inProgressList(
        list,               // List<ServiceRequest>
        ofertasEnProgreso,  // List<Offer> filtrada
        w,                  // screenWidth
        h,                  // screenHeight
        widget.userId,
        widget.userData,
        widget.apiService,
      );


      case 'completed':
        final offers = list.expand((s) => s.offers).toList();
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
          list,        // tu lista de ServiceRequest (incluye offers internamente)
          w,           // ancho
          h,           // alto
          widget.userId,
          widget.userData,
          widget.apiService,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}