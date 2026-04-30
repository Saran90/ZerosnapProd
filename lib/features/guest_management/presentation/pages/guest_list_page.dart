import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../frro/domain/entities/guest.dart';
import '../../../frro/presentation/bloc/guest_list_bloc.dart';
import '../../../frro/presentation/bloc/guest_list_event.dart';
import '../../../frro/presentation/bloc/guest_list_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class GuestListPage extends StatelessWidget {
  const GuestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GuestListPageContent();
  }
}

class _GuestListPageContent extends StatefulWidget {
  const _GuestListPageContent();

  @override
  State<_GuestListPageContent> createState() => _GuestListPageState();
}

class _GuestListPageState extends State<_GuestListPageContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';

  /// null = not yet loaded (show nothing to avoid layout flash)
  /// true  = show both Check-in and Check-out tabs
  /// false = show Check-in tab only (no blank space)
  bool? _showCheckOut;

  static const int _branchId = 5;

  /// Maps tab index to the API's btnStatusOfCheckINOUT value.
  /// Tab 0 (Check-in)  → 1
  /// Tab 1 (Check-out) → 2  (only when _showCheckOut is true)
  int get _apiStatus => _tabController.index + 1;

  @override
  void initState() {
    super.initState();
    // Initialise with length 1 as a safe placeholder — will be rebuilt
    // immediately once _loadCheckOutVisibility completes.
    _tabController = TabController(length: 1, vsync: this);
    _loadCheckOutVisibility();
  }

  Future<void> _loadCheckOutVisibility() async {
    final session = await SharedPreferencesProvider().getLoginSession();
    if (!mounted) return;
    final show = session?.showFrroCheckOutInExt ?? true;

    // Rebuild tab controller with the correct length
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _tabController = TabController(length: show ? 2 : 1, vsync: this);
    _tabController.addListener(_onTabChanged);

    setState(() => _showCheckOut = show);

    // Trigger initial guest list load now that we know the correct tab count
    if (mounted) {
      context.read<GuestListBloc>().add(
        const LoadGuestList(branchId: _branchId, btnStatusOfCheckINOUT: 1),
      );
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _searchCtrl.clear();
    setState(() => _query = '');
    context.read<GuestListBloc>().add(
      LoadGuestList(branchId: _branchId, btnStatusOfCheckINOUT: _apiStatus),
    );
  }

  void _refresh() {
    context.read<GuestListBloc>().add(
      RefreshGuestList(branchId: _branchId, btnStatusOfCheckINOUT: _apiStatus),
    );
  }

  List<Guest> _filter(List<Guest> guests) {
    if (_query.isEmpty) return guests;
    final q = _query.toLowerCase();
    return guests
        .where(
          (g) =>
              g.fullName.toLowerCase().contains(q) ||
              g.nationalityText.toLowerCase().contains(q) ||
              g.documentNo.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing until the checkout visibility flag is loaded from prefs.
    // This prevents any blank-space flash before the correct layout is known.
    if (_showCheckOut == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFDEEFF8),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text(
          'Guest List',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
        bottom: _showCheckOut!
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.login_outlined, size: 18),
                    text: 'Check-in',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.logout_outlined, size: 18),
                    text: 'Check-out',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // â”€â”€ Search bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search guest',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // â”€â”€ Guest list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: BlocBuilder<GuestListBloc, GuestListState>(
              builder: (context, state) {
                if (state is GuestListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is GuestListError) {
                  return _ErrorView(message: state.message, onRetry: _refresh);
                }

                if (state is GuestListLoaded) {
                  final guests = _filter(state.guests);
                  final isCheckOut = state.btnStatusOfCheckINOUT == 2;

                  if (guests.isEmpty) {
                    return _EmptyView(
                      isCheckOut: isCheckOut,
                      hasQuery: _query.isNotEmpty,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: guests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _GuestCard(guest: guests[i], isCheckOutTab: isCheckOut),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // â”€â”€ Bottom buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            color: const Color(0xFFDEEFF8),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.frroList),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Launch FRRO',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C3E50),
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'version 1.0',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guest card ────────────────────────────────────────────────────────────────
class _GuestCard extends StatefulWidget {
  final Guest guest;
  final bool isCheckOutTab;

  const _GuestCard({required this.guest, required this.isCheckOutTab});

  @override
  State<_GuestCard> createState() => _GuestCardState();
}

class _GuestCardState extends State<_GuestCard> {
  bool _expanded = false;
  final _appIdCtrl = TextEditingController();
  bool _isCheckingIn = false;
  bool _isCheckingOut = false;

  static const int _branchId = 5;

  @override
  void dispose() {
    _appIdCtrl.dispose();
    super.dispose();
  }

  void _onCheckIn() {
    final appId = _appIdCtrl.text.trim();
    if (appId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the Application ID'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isCheckingIn = true);
    context.read<GuestListBloc>().add(
      CheckInGuest(
        guestdataId: widget.guest.guestdataId,
        branchId: _branchId,
        applicationId: appId,
      ),
    );
  }

  void _onCheckOut() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Check-Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to check out ${widget.guest.fullName}?',
          style: const TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() => _isCheckingOut = true);
                    context.read<GuestListBloc>().add(
                      CheckOutGuest(
                        guestdataId: widget.guest.guestdataId,
                        branchId: _branchId,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Check Out',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GuestListBloc, GuestListState>(
      listener: (context, state) {
        // Check-in success
        if (state is GuestCheckInSuccess &&
            state.guestdataId == widget.guest.guestdataId) {
          setState(() {
            _isCheckingIn = false;
            _expanded = false;
          });
          _appIdCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.guest.fullName} checked in successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
          context.read<GuestListBloc>().add(
            const RefreshGuestList(
              branchId: _branchId,
              btnStatusOfCheckINOUT: 1,
            ),
          );
        }
        // Check-in failure
        else if (state is GuestCheckInFailure &&
            state.guestdataId == widget.guest.guestdataId) {
          setState(() => _isCheckingIn = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
        // Check-out success
        else if (state is GuestCheckOutSuccess &&
            state.guestdataId == widget.guest.guestdataId) {
          setState(() {
            _isCheckingOut = false;
            _expanded = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.guest.fullName} checked out successfully',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
          context.read<GuestListBloc>().add(
            const RefreshGuestList(
              branchId: _branchId,
              btnStatusOfCheckINOUT: 2,
            ),
          );
        }
        // Check-out failure
        else if (state is GuestCheckOutFailure &&
            state.guestdataId == widget.guest.guestdataId) {
          setState(() => _isCheckingOut = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: _expanded
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header row ──────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCDE8F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF29ABE2),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.guest.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.guest.nationalityText.isNotEmpty
                                ? widget.guest.nationalityText
                                : widget.guest.nationality,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.guest.documentNo.isNotEmpty)
                            Text(
                              'Doc: ${widget.guest.documentNo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusBadge(
                          isCheckOutTab: widget.isCheckOutTab,
                          guest: widget.guest,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isCheckOutTab
                              ? widget.guest.checkOutDate
                              : widget.guest.arrivalDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable check-in section ─────────────────────────
            if (!widget.isCheckOutTab && _expanded)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 4),
                    Text(
                      'APPLICATION ID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _appIdCtrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onCheckIn(),
                      decoration: InputDecoration(
                        hintText: 'Enter FRRO Application ID',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingIn ? null : _onCheckIn,
                        icon: _isCheckingIn
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_outlined, size: 18),
                        label: Text(
                          _isCheckingIn ? 'Checking in...' : 'Check In',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Expandable check-out section ────────────────────────
            if (widget.isCheckOutTab && _expanded)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingOut ? null : _onCheckOut,
                        icon: _isCheckingOut
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.logout_outlined, size: 18),
                        label: Text(
                          _isCheckingOut ? 'Checking out...' : 'Check Out',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Status badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatusBadge extends StatelessWidget {
  final bool isCheckOutTab;
  final Guest guest;

  const _StatusBadge({required this.isCheckOutTab, required this.guest});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (guest.frroStatus) {
      FrroStatus.newGuest => (
        'Pending',
        const Color(0xFFFFF3E0),
        const Color(0xFFF57C00),
      ),
      FrroStatus.submittedToFrro => (
        'FRRO Submitted',
        const Color(0xFFE3F2FD),
        const Color(0xFF1976D2),
      ),
      FrroStatus.checkInCompleted => (
        'Checked In',
        const Color(0xFFE8F5E9),
        const Color(0xFF27AE60),
      ),
      FrroStatus.checkoutCompleted => (
        'Checked Out',
        const Color(0xFFF3E5F5),
        const Color(0xFF7B1FA2),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// â”€â”€ Empty view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EmptyView extends StatelessWidget {
  final bool isCheckOut;
  final bool hasQuery;

  const _EmptyView({required this.isCheckOut, required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final icon = hasQuery
        ? Icons.search_off_rounded
        : isCheckOut
        ? Icons.logout_rounded
        : Icons.login_rounded;

    final title = hasQuery
        ? 'No results found'
        : isCheckOut
        ? 'No guests to check out'
        : 'No guests to check in';

    final subtitle = hasQuery
        ? 'Try a different name, nationality or document number'
        : isCheckOut
        ? 'All checked-in guests have been checked out'
        : 'New arrivals will appear here once they check in';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Error view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading guests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
