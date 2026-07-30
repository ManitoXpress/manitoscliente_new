import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/worker_detailsModels.dart';

/// Widget que carga y muestra la información del trabajador de forma profesional.
/// Se puede usar tanto en la pestaña "En espera" (dentro de una oferta)
/// como en "En proceso" (trabajador ya asignado).
class WorkerInfoCard extends StatefulWidget {
  final String workerId;

  /// Si ya tenemos los detalles del trabajador, los pasamos directamente
  /// para evitar una carga adicional de Firestore.
  final WorkerDetailsModel? preloadedWorker;

  const WorkerInfoCard({
    Key? key,
    required this.workerId,
    this.preloadedWorker,
  }) : super(key: key);

  @override
  State<WorkerInfoCard> createState() => _WorkerInfoCardState();
}

class _WorkerInfoCardState extends State<WorkerInfoCard>
    with SingleTickerProviderStateMixin {
  WorkerDetailsModel? _worker;
  bool _isLoading = false;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    if (widget.preloadedWorker != null) {
      _worker = widget.preloadedWorker;
      _animController.forward();
    } else if (widget.workerId.isNotEmpty) {
      _loadWorker();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadWorker() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.workerId)
          .get();
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        setState(() {
          _worker =
              WorkerDetailsModel.fromMap(Map<String, dynamic>.from(doc.data()!));
          _isLoading = false;
        });
        _animController.forward();
      } else {
        setState(() {
          _error = 'Trabajador no encontrado';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar datos';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }
    if (_error != null) {
      return _buildError();
    }
    if (_worker == null) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildWorkerContent(_worker!),
    );
  }

  Widget _buildWorkerContent(WorkerDetailsModel worker) {
    final primaryColor = const Color(0xFF1A819A);
    final bgGradient = LinearGradient(
      colors: [
        primaryColor.withOpacity(0.06),
        primaryColor.withOpacity(0.02),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.18), width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado con avatar y datos básicos ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _buildAvatar(worker, primaryColor),
              const SizedBox(width: 14),
              // Nombre + verificación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            worker.displayName.isNotEmpty
                                ? worker.displayName
                                : 'Trabajador',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2F35),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildVerificationBadge(worker.verificationStatus ?? ''),
                      ],
                    ),
                    if (worker.expertises.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        worker.expertises.map((e) => e.name).join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFE0EFF2)),
          const SizedBox(height: 12),

          // ── Fila de chips de información ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (worker.phoneNumber.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.phone_outlined,
                  label: worker.phoneNumber,
                  color: primaryColor,
                ),
              if (worker.email.isNotEmpty)
                _buildInfoChip(
                  icon: Icons.email_outlined,
                  label: worker.email,
                  color: primaryColor,
                ),
              if (worker.expLevel != null)
                _buildInfoChip(
                  icon: Icons.star_outline_rounded,
                  label: _expLevelLabel(worker.expLevel!),
                  color: const Color(0xFFE6A817),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(WorkerDetailsModel worker, Color primaryColor) {
    final hasImage = worker.imagePath.isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withOpacity(0.35), width: 2),
        color: primaryColor.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                worker.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar(primaryColor),
              )
            : _defaultAvatar(primaryColor),
      ),
    );
  }

  Widget _defaultAvatar(Color primaryColor) {
    return Container(
      color: primaryColor.withOpacity(0.1),
      child: Icon(Icons.person_outline_rounded, color: primaryColor, size: 28),
    );
  }

  Widget _buildVerificationBadge(String status) {
    if (status == 'verified' || status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0F9D58).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_rounded, color: Color(0xFF0F9D58), size: 11),
            SizedBox(width: 3),
            Text(
              'Verificado',
              style: TextStyle(
                color: Color(0xFF0F9D58),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  String _expLevelLabel(int level) {
    switch (level) {
      case 1:
        return 'Junior';
      case 2:
        return 'Intermedio';
      case 3:
        return 'Senior';
      default:
        return 'Nivel $level';
    }
  }

  Widget _buildSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 120, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(height: 11, width: 80, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        children: const [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          SizedBox(width: 8),
          Text(
            'No se pudo cargar la info del trabajador',
            style: TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Versión expandible del WorkerInfoCard — muestra un header colapsable
/// que al tocarlo revela la información completa del trabajador.
// ─────────────────────────────────────────────────────────────────────────────
class WorkerInfoExpansionTile extends StatefulWidget {
  final String workerId;
  final WorkerDetailsModel? preloadedWorker;
  final String title;
  final bool initiallyExpanded;

  const WorkerInfoExpansionTile({
    Key? key,
    required this.workerId,
    this.preloadedWorker,
    this.title = 'Detalles del Trabajador',
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<WorkerInfoExpansionTile> createState() =>
      _WorkerInfoExpansionTileState();
}

class _WorkerInfoExpansionTileState extends State<WorkerInfoExpansionTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _rotateCtrl;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _rotateCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
    if (_expanded) {
      _rotateCtrl.forward();
    } else {
      _rotateCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A819A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header clicable ──
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _expanded
                              ? 'Toca para ocultar'
                              : 'Información del profesional asignado',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnim,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido expandible ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: WorkerInfoCard(
                workerId: widget.workerId,
                preloadedWorker: widget.preloadedWorker,
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
