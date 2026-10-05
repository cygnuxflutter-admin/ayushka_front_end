import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/utils/file_download_helper.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../data/models/cow_model.dart';
import '../../../data/models/shed_transfer_history_model.dart';
import '../../../data/services/api_service.dart';

enum HistoryViewMode { table, timeline }

/// Executive Modal Dialog for viewing Shed Transfer History.
/// Supports both Gaushala-wide audit history and single Cattle relocation timeline.
class ShedTransferHistoryDialog extends StatefulWidget {
  final String? gaushalaId;
  final String? gaushalaName;
  final String? cowId;
  final CowModel? cow;

  const ShedTransferHistoryDialog({
    super.key,
    this.gaushalaId,
    this.gaushalaName,
    this.cowId,
    this.cow,
  });

  /// Displays the Shed Transfer History Modal Dialog.
  static Future<void> show({
    required BuildContext context,
    String? gaushalaId,
    String? gaushalaName,
    String? cowId,
    CowModel? cow,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ShedTransferHistoryDialog(
        gaushalaId: gaushalaId,
        gaushalaName: gaushalaName,
        cowId: cowId,
        cow: cow,
      ),
    );
  }

  @override
  State<ShedTransferHistoryDialog> createState() => _ShedTransferHistoryDialogState();
}

class _ShedTransferHistoryDialogState extends State<ShedTransferHistoryDialog> {
  final ApiService _apiService = Get.find<ApiService>();

  bool _isLoading = true;
  String? _errorMessage;

  List<ShedTransferRecord> _allRecords = [];
  TransferGaushalaSummary? _gaushalaSummary;
  TransferCowHeader? _cowHeader;

  HistoryViewMode _viewMode = HistoryViewMode.table;
  late final TextEditingController _searchController;
  late final ScrollController _tableVerticalScrollController;
  late final ScrollController _tableHorizontalScrollController;
  late final ScrollController _timelineScrollController;
  String _searchQuery = '';
  String _selectedShedFilter = 'all';

  // Advance filter state
  bool _showAdvancedFilters = false;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _selectedDatePreset = 'All Time';
  String _selectedFromShed = 'all';
  String _selectedToShed = 'all';
  String _selectedReason = 'all';
  String _selectedStaff = 'all';
  String _selectedGender = 'all'; // 'all', 'female', 'male'
  bool _isExporting = false;
  int _sortColumnIndex = 1;
  bool _sortAscending = false;

  // Pagination states
  int _currentPage = 1;
  int _rowsPerPage = 5;
  int _totalRecords = 0;
  int _totalPages = 1;

  bool get _isCowSpecific => (widget.cowId != null && widget.cowId!.isNotEmpty) || widget.cow != null;

  String get _effectiveCowId => widget.cow?.id ?? widget.cowId ?? '';

  String get _effectiveGaushalaId =>
      widget.gaushalaId ?? widget.cow?.gaushala?.id ?? '';

  String get _effectiveGaushalaName =>
      widget.gaushalaName ?? widget.cow?.gaushala?.gaushalaName ?? _gaushalaSummary?.gaushalaName ?? '';

  int get _activeAdvancedFilterCount {
    int count = 0;
    if (_filterStartDate != null || _filterEndDate != null) count++;
    if (_selectedFromShed != 'all') count++;
    if (_selectedToShed != 'all') count++;
    if (_selectedReason != 'all') count++;
    if (_selectedStaff != 'all') count++;
    if (_selectedGender != 'all') count++;
    return count;
  }

  bool get _hasActiveFilters =>
      _activeAdvancedFilterCount > 0 || _searchQuery.isNotEmpty || _selectedShedFilter != 'all';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tableVerticalScrollController = ScrollController();
    _tableHorizontalScrollController = ScrollController();
    _timelineScrollController = ScrollController();
    // Default to timeline if single cow, table if gaushala wide
    _viewMode = _isCowSpecific ? HistoryViewMode.timeline : HistoryViewMode.table;
    _fetchHistory(page: 1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableVerticalScrollController.dispose();
    _tableHorizontalScrollController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory({int? page, int? limit}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetPage = page ?? _currentPage;
    final targetLimit = limit ?? _rowsPerPage;

    try {
      final response = await _apiService.getShedTransferHistory(
        gaushalaId: _effectiveGaushalaId.isNotEmpty ? _effectiveGaushalaId : null,
        cowId: _effectiveCowId.isNotEmpty ? _effectiveCowId : null,
        page: targetPage,
        limit: targetLimit,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final data = response.data!;
          setState(() {
            _allRecords = data.records;
            _gaushalaSummary = data.gaushala;
            _cowHeader = data.cow;
            _totalRecords = data.total;
            _currentPage = data.page;
            _rowsPerPage = data.limit;
            _totalPages = data.totalPages;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Failed to retrieve shed transfer history.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<ShedTransferRecord> get _filteredRecords {
    final query = _searchQuery.trim().toLowerCase();
    final list = _allRecords.where((record) {
      // 1. Quick Shed Filter
      if (_selectedShedFilter != 'all') {
        final matchesFrom = record.fromShed?.id == _selectedShedFilter;
        final matchesTo = record.toShed?.id == _selectedShedFilter;
        if (!matchesFrom && !matchesTo) return false;
      }

      // 2. Specific Origin Shed Filter
      if (_selectedFromShed != 'all') {
        if (record.fromShed?.id != _selectedFromShed) return false;
      }

      // 3. Specific Destination Shed Filter
      if (_selectedToShed != 'all') {
        if (record.toShed?.id != _selectedToShed) return false;
      }

      // 4. Date Range Filter
      if (record.transferDate != null) {
        if (_filterStartDate != null && record.transferDate!.isBefore(_filterStartDate!)) {
          return false;
        }
        if (_filterEndDate != null && record.transferDate!.isAfter(_filterEndDate!)) {
          return false;
        }
      }

      // 5. Transfer Reason Filter
      if (_selectedReason != 'all') {
        if (!record.reason.toLowerCase().contains(_selectedReason.toLowerCase())) {
          return false;
        }
      }

      // 6. Transferred By (Staff) Filter
      if (_selectedStaff != 'all') {
        final staffMatch = record.transferredBy?.id == _selectedStaff ||
            record.transferredBy?.name.toLowerCase() == _selectedStaff.toLowerCase();
        if (!staffMatch) return false;
      }

      // 7. Gender Filter (for Gaushala-wide audit)
      if (_selectedGender != 'all' && record.cow != null) {
        if (_selectedGender == 'female' && !record.cow!.isFemale) return false;
        if (_selectedGender == 'male' && record.cow!.isFemale) return false;
      }

      // 8. Search query filter
      if (query.isNotEmpty) {
        final tagMatches = record.cow?.tagId.toLowerCase().contains(query) ?? false;
        final calfNameMatches = record.cow?.calfName?.toLowerCase().contains(query) ?? false;
        final breedMatches = record.cow?.breedName?.toLowerCase().contains(query) ?? false;
        final fromShedMatches = record.fromShed?.shedName.toLowerCase().contains(query) ?? false;
        final toShedMatches = record.toShed?.shedName.toLowerCase().contains(query) ?? false;
        final reasonMatches = record.reason.toLowerCase().contains(query);
        final staffMatches = record.transferredBy?.name.toLowerCase().contains(query) ?? false;

        if (!(tagMatches ||
            calfNameMatches ||
            breedMatches ||
            fromShedMatches ||
            toShedMatches ||
            reasonMatches ||
            staffMatches)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort according to active column
    list.sort((a, b) {
      int cmp = 0;
      if (_sortColumnIndex == 1) {
        final da = a.transferDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.transferDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        cmp = da.compareTo(db);
      } else if (_sortColumnIndex == 2 && !_isCowSpecific) {
        final ta = a.cow?.tagId ?? '';
        final tb = b.cow?.tagId ?? '';
        cmp = ta.compareTo(tb);
      } else if (_sortColumnIndex == (_isCowSpecific ? 5 : 6)) {
        cmp = a.reason.compareTo(b.reason);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  // Set of all distinct sheds involved for filter dropdown
  List<TransferShedSummary> get _uniqueSheds {
    final Map<String, TransferShedSummary> map = {};
    for (final r in _allRecords) {
      if (r.fromShed != null && r.fromShed!.id.isNotEmpty) {
        map[r.fromShed!.id] = r.fromShed!;
      }
      if (r.toShed != null && r.toShed!.id.isNotEmpty) {
        map[r.toShed!.id] = r.toShed!;
      }
    }
    return map.values.toList();
  }

  List<TransferShedSummary> get _uniqueFromSheds {
    final Map<String, TransferShedSummary> map = {};
    for (final r in _allRecords) {
      if (r.fromShed != null && r.fromShed!.id.isNotEmpty) {
        map[r.fromShed!.id] = r.fromShed!;
      }
    }
    return map.values.toList();
  }

  List<TransferShedSummary> get _uniqueToSheds {
    final Map<String, TransferShedSummary> map = {};
    for (final r in _allRecords) {
      if (r.toShed != null && r.toShed!.id.isNotEmpty) {
        map[r.toShed!.id] = r.toShed!;
      }
    }
    return map.values.toList();
  }

  List<String> get _uniqueReasons {
    final Set<String> reasons = {
      'Moved to milking shed',
      'Dry period segregation',
      'Medical quarantine',
      'Calving pen',
      'Routine relocation',
      'Post-treatment recovery',
    };
    for (final r in _allRecords) {
      if (r.reason.trim().isNotEmpty) {
        reasons.add(r.reason.trim());
      }
    }
    return reasons.toList();
  }

  List<TransferUserSummary> get _uniqueStaff {
    final Map<String, TransferUserSummary> map = {};
    for (final r in _allRecords) {
      if (r.transferredBy != null && r.transferredBy!.id.isNotEmpty) {
        map[r.transferredBy!.id] = r.transferredBy!;
      }
    }
    return map.values.toList();
  }

  String get _selectedShedDisplayName {
    if (_selectedShedFilter == 'all') return 'All Sheds';
    final match = _uniqueSheds.firstWhereOrNull((s) => s.id == _selectedShedFilter);
    return match?.display ?? 'All Sheds';
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _selectedDatePreset = preset;
      _currentPage = 1;
      if (preset == 'All Time') {
        _filterStartDate = null;
        _filterEndDate = null;
      } else if (preset == 'Today') {
        _filterStartDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'Yesterday') {
        final y = now.subtract(const Duration(days: 1));
        _filterStartDate = DateTime(y.year, y.month, y.day, 0, 0, 0);
        _filterEndDate = DateTime(y.year, y.month, y.day, 23, 59, 59);
      } else if (preset == 'Last 7 Days') {
        final past = now.subtract(const Duration(days: 7));
        _filterStartDate = DateTime(past.year, past.month, past.day, 0, 0, 0);
        _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'This Month') {
        _filterStartDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
    });
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _filterStartDate ?? now.subtract(const Duration(days: 7)),
      end: _filterEndDate ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final isCompact = mediaQuery.size.width < 500;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isCompact ? mediaQuery.size.width * 0.95 : 460,
              maxHeight: isCompact ? mediaQuery.size.height * 0.88 : 600,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                      ),
                ),
                child: child!,
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
        _filterEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _selectedDatePreset = 'Custom';
        _currentPage = 1;
      });
    }
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedShedFilter = 'all';
      _filterStartDate = null;
      _filterEndDate = null;
      _selectedDatePreset = 'All Time';
      _selectedFromShed = 'all';
      _selectedToShed = 'all';
      _selectedReason = 'all';
      _selectedStaff = 'all';
      _selectedGender = 'all';
      _currentPage = 1;
    });
  }

  Future<void> _exportToCsv() async {
    final records = _filteredRecords;
    if (records.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'No Data to Export',
        message: 'There are no transfer records matching your current criteria.',
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final buffer = StringBuffer();
      // CSV Header
      buffer.writeln(
        '#,Date & Time,Tag ID,Calf Name,Gender,Breed,From Shed,From Shed Number,To Shed,To Shed Number,Reason,Transferred By,Staff Email,Gaushala',
      );

      String escapeCsv(String val) {
        if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
          return '"${val.replaceAll('"', '""')}"';
        }
        return val;
      }

      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        final dateStr = r.transferDate != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(r.transferDate!)
            : 'N/A';
        final tagId = r.cow?.tagId ?? 'N/A';
        final calfName = r.cow?.calfName ?? '';
        final gender = r.cow == null ? '' : (r.cow!.isFemale ? 'Female' : 'Male');
        final breed = r.cow?.breedName ?? '';
        final fromShedName = r.fromShed?.shedName ?? 'Initial Shed';
        final fromShedNum = r.fromShed?.shedNumber ?? '';
        final toShedName = r.toShed?.shedName ?? 'Target Shed';
        final toShedNum = r.toShed?.shedNumber ?? '';
        final reason = r.reason.isNotEmpty ? r.reason : 'Relocation';
        final staffName = r.transferredBy?.name ?? 'Admin';
        final staffEmail = r.transferredBy?.emailId ?? '';
        final gaushalaName = _effectiveGaushalaName;

        buffer.writeln([
          '${i + 1}',
          escapeCsv(dateStr),
          escapeCsv(tagId),
          escapeCsv(calfName),
          escapeCsv(gender),
          escapeCsv(breed),
          escapeCsv(fromShedName),
          escapeCsv(fromShedNum),
          escapeCsv(toShedName),
          escapeCsv(toShedNum),
          escapeCsv(reason),
          escapeCsv(staffName),
          escapeCsv(staffEmail),
          escapeCsv(gaushalaName),
        ].join(','));
      }

      final dateStamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'shed_transfer_history_$dateStamp.csv';
      final bytes = utf8.encode(buffer.toString());

      await FileDownloadHelper.download(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'text/csv;charset=utf-8',
      );

      CustomSnackbar.showSuccess(
        title: 'Export Successful',
        message: 'Exported ${records.length} shed transfer records to $fileName',
      );
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Export Failed',
        message: 'Could not export records: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 700;

    final dialogWidth = isMobile ? screenWidth * 0.96 : 1040.0;
    final dialogHeight = screenHeight * 0.90;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------------------------------------------------
            // HEADER BAR
            // ---------------------------------------------------------
            _buildHeader(context, isDark, isMobile),
            const Divider(height: 1),

            // ---------------------------------------------------------
            // SUMMARY STATS STRIP
            // ---------------------------------------------------------
            _buildStatsStrip(isDark, isMobile),
            const Divider(height: 1),

            // ---------------------------------------------------------
            // SEARCH & FILTER BAR
            // ---------------------------------------------------------
            _buildFilterBar(isDark, isMobile),

            // ---------------------------------------------------------
            // ADVANCE FILTER PANEL (COLLAPSIBLE)
            // ---------------------------------------------------------
            if (_showAdvancedFilters) ...[
              const Divider(height: 1),
              _buildAdvancedFilterPanel(context, isDark, isMobile),
            ],

            // ---------------------------------------------------------
            // ACTIVE FILTER CHIPS STRIP
            // ---------------------------------------------------------
            if (_hasActiveFilters) ...[
              const Divider(height: 1),
              _buildActiveFilterChips(isDark),
            ],
            const Divider(height: 1),

            // ---------------------------------------------------------
            // BODY (TABLE OR TIMELINE VIEW)
            // ---------------------------------------------------------
            Expanded(
              child: _buildBody(context, isDark, isMobile),
            ),

            // ---------------------------------------------------------
            // FOOTER & PAGINATION BAR
            // ---------------------------------------------------------
            const Divider(height: 1),
            _buildFooter(context, isDark, isMobile),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 1. DIALOG HEADER
  // -------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isDark, bool isMobile) {
    final cowTag = widget.cow?.tagId ?? _cowHeader?.tagId ?? 'Cattle';
    final cowAlias = widget.cow?.calfName ?? _cowHeader?.calfName;
    final gaushalaName = _effectiveGaushalaName.isNotEmpty
        ? _effectiveGaushalaName
        : (_gaushalaSummary?.gaushalaName ?? 'Gaushala');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              PhosphorIconsRegular.clockCounterClockwise,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Titles & Subtitles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _isCowSpecific
                            ? 'Shed History: $cowTag${(cowAlias != null && cowAlias.isNotEmpty) ? " ($cowAlias)" : ""}'
                            : 'Shed Transfer History',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isCowSpecific ? 'CATTLE AUDIT' : 'GAUSHALA AUDIT',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isCowSpecific
                      ? 'Complete housing shed relocation history & lineage for this cattle'
                      : 'Relocation audit log for $gaushalaName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // View Switcher (Table vs Timeline)
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF0F4F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE0E8E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewTab(
                    icon: PhosphorIconsRegular.table,
                    label: 'Table',
                    isSelected: _viewMode == HistoryViewMode.table,
                    isDark: isDark,
                    onTap: () => setState(() => _viewMode = HistoryViewMode.table),
                  ),
                  _buildViewTab(
                    icon: PhosphorIconsRegular.gitCommit,
                    label: 'Timeline',
                    isSelected: _viewMode == HistoryViewMode.timeline,
                    isDark: isDark,
                    onTap: () => setState(() => _viewMode = HistoryViewMode.timeline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Export CSV Button
          IconButton(
            icon: _isExporting
                ? const CustomInlineLoader(size: 16, strokeWidth: 2)
                : const Icon(
                    PhosphorIconsRegular.fileCsv,
                    size: 20,
                    color: Color(0xFF1D6F42),
                  ),
            tooltip: 'Export to CSV',
            onPressed: (_isLoading || _isExporting) ? null : _exportToCsv,
          ),
          const SizedBox(width: 4),

          // Refresh Button
          IconButton(
            icon: _isLoading
                ? const CustomInlineLoader(size: 16, strokeWidth: 2)
                : const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh History',
            onPressed: _isLoading ? null : () => _fetchHistory(page: _currentPage),
          ),

          // Close Button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cardDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 2. SUMMARY STATS STRIP
  // -------------------------------------------------------------------
  Widget _buildStatsStrip(bool isDark, bool isMobile) {
    final filtered = _filteredRecords;
    final recentRecord = filtered.isNotEmpty ? filtered.first : (_allRecords.isNotEmpty ? _allRecords.first : null);
    final lastTransferDate = recentRecord?.transferDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(recentRecord!.transferDate!)
        : 'None recorded';

    final currentShed = recentRecord?.toShed?.display ??
        (widget.cow?.shed?.display ?? 'Not Assigned');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 10,
      ),
      color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : const Color(0xFFF8FAF9),
      child: Row(
        children: [
          // Stat 1: Total Transfers or Filtered Transfers
          _buildStatPill(
            icon: PhosphorIconsRegular.arrowsLeftRight,
            label: _hasActiveFilters ? 'Matching Transfers' : 'Total Transfers',
            value: _hasActiveFilters ? '${filtered.length} of $_totalRecords' : '$_totalRecords',
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(width: 14),

          // Stat 2: Current Shed (if single cow) or Most Active
          if (_isCowSpecific) ...[
            _buildStatPill(
              icon: PhosphorIconsRegular.warehouse,
              label: 'Current Housing Shed',
              value: currentShed,
              color: AppColors.secondary,
              isDark: isDark,
            ),
            const SizedBox(width: 14),
          ],

          // Stat 3: Last Movement
          if (!isMobile) ...[
            Expanded(
              child: _buildStatPill(
                icon: PhosphorIconsRegular.calendarBlank,
                label: _hasActiveFilters ? 'Latest in Filtered' : 'Latest Relocation',
                value: lastTransferDate,
                color: Colors.blueGrey,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // 3. FILTER & SEARCH BAR
  // -------------------------------------------------------------------
  // -------------------------------------------------------------------
  // 3. FILTER & SEARCH BAR
  // -------------------------------------------------------------------
  Widget _buildFilterBar(bool isDark, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                },
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: _isCowSpecific
                      ? 'Search by Shed, Reason, or Staff member...'
                      : 'Search by Tag ID, Alias, Shed, Reason, or Staff...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          tooltip: 'Clear Search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF7FAF8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Advance Filter Toggle Button
          _buildAdvanceFilterToggleButton(isDark, isMobile),

          // Quick Shed filter dropdown (if multiple sheds available)
          if (_uniqueSheds.isNotEmpty && !isMobile) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 195,
              child: DropdownSearch<String>(
                items: (filter, infiniteScrollProps) {
                  final allItems = ['All Sheds', ..._uniqueSheds.map((s) => s.display)];
                  if (filter.isEmpty) return allItems;
                  return allItems
                      .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                      .toList();
                },
                selectedItem: _selectedShedDisplayName,
                compareFn: (i1, i2) => i1 == i2,
                onSelected: (selected) {
                  if (selected != null) {
                    setState(() {
                      if (selected == 'All Sheds') {
                        _selectedShedFilter = 'all';
                      } else {
                        final match = _uniqueSheds.firstWhereOrNull((s) => s.display == selected);
                        _selectedShedFilter = match?.id ?? 'all';
                      }
                      _currentPage = 1;
                    });
                  }
                },
                popupProps: PopupProps.menu(
                  showSearchBox: _uniqueSheds.length > 5,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search shed...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  menuProps: MenuProps(
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    elevation: 8,
                  ),
                  itemBuilder: (ctx, item, isDisabled, isSelected) {
                    final isCurrent = item == _selectedShedDisplayName;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: isCurrent
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Icon(
                            item == 'All Sheds'
                                ? PhosphorIconsRegular.circlesFour
                                : PhosphorIconsRegular.warehouse,
                            size: 15,
                            color: isCurrent
                                ? AppColors.primary
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isCurrent
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                          if (isCurrent)
                            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    );
                  },
                ),
                dropdownBuilder: (context, selectedItem) {
                  return Text(
                    selectedItem ?? 'All Sheds',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  );
                },
                suffixProps: DropdownSuffixProps(
                  dropdownButtonProps: DropdownButtonProps(
                    iconClosed: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                decoratorProps: DropDownDecoratorProps(
                  baseStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.warehouse,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Export Button on desktop
          if (!isMobile) ...[
            const SizedBox(width: 10),
            _buildExportButton(isDark),
          ],

          // View toggle and Export for mobile
          if (isMobile) ...[
            const SizedBox(width: 6),
            _buildExportButton(isDark, compact: true),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                _viewMode == HistoryViewMode.table
                    ? PhosphorIconsRegular.gitCommit
                    : PhosphorIconsRegular.table,
                size: 20,
              ),
              tooltip: _viewMode == HistoryViewMode.table ? 'Timeline View' : 'Table View',
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == HistoryViewMode.table
                      ? HistoryViewMode.timeline
                      : HistoryViewMode.table;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // 3A. ADVANCE FILTER TOGGLE BUTTON
  // -------------------------------------------------------------------
  Widget _buildAdvanceFilterToggleButton(bool isDark, bool isMobile) {
    final isActive = _showAdvancedFilters || _activeAdvancedFilterCount > 0;
    return InkWell(
      onTap: () {
        setState(() {
          _showAdvancedFilters = !_showAdvancedFilters;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 13),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.surfaceDark : const Color(0xFFF7FAF8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.faders,
              size: 17,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 7),
              Text(
                'Advance Filter',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ],
            if (_activeAdvancedFilterCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_activeAdvancedFilterCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 3B. EXPORT BUTTON
  // -------------------------------------------------------------------
  Widget _buildExportButton(bool isDark, {bool compact = false}) {
    return InkWell(
      onTap: (_isLoading || _isExporting || _filteredRecords.isEmpty) ? null : _exportToCsv,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExporting)
              const CustomInlineLoader(size: 14, strokeWidth: 2)
            else
              const Icon(
                PhosphorIconsRegular.fileCsv,
                size: 17,
                color: Color(0xFF1D6F42),
              ),
            if (!compact) ...[
              const SizedBox(width: 6),
              const Text(
                'Export CSV',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D6F42),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 3C. ADVANCE FILTER PANEL (COLLAPSIBLE PANEL)
  // -------------------------------------------------------------------
  Widget _buildAdvancedFilterPanel(BuildContext context, bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B231D) : const Color(0xFFF3F7F4),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFDEE7E0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of Advance Filters
          Row(
            children: [
              const Icon(PhosphorIconsRegular.faders, size: 16, color: AppColors.primary),
              const SizedBox(width: 7),
              const Text(
                'Advance Filter Options',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters) ...[
                InkWell(
                  onTap: _resetAllFilters,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 14,
                          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reset All Filters',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              InkWell(
                onTap: () => setState(() => _showAdvancedFilters = false),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Date Range Section
          _buildDateRangeFilterRow(context, isDark, isMobile),
          const SizedBox(height: 14),

          // 2. Dropdown Filters
          _buildDropdownFiltersRow(isDark, isMobile),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // 3D. DATE RANGE FILTER SECTION
  // -------------------------------------------------------------------
  Widget _buildDateRangeFilterRow(BuildContext context, bool isDark, bool isMobile) {
    final presets = ['All Time', 'Today', 'Yesterday', 'Last 7 Days', 'This Month'];
    final isCustomActive = _selectedDatePreset == 'Custom' && _filterStartDate != null && _filterEndDate != null;

    final dateDisplay = isCustomActive
        ? '${DateFormat("dd MMM yyyy").format(_filterStartDate!)} - ${DateFormat("dd MMM yyyy").format(_filterEndDate!)}'
        : (_filterStartDate != null && _filterEndDate != null
            ? '${DateFormat("dd MMM").format(_filterStartDate!)} - ${DateFormat("dd MMM yyyy").format(_filterEndDate!)}'
            : 'Select Custom Range');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(PhosphorIconsRegular.calendarBlank, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              'Relocation Date Range',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            if (_filterStartDate != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateDisplay,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...presets.map((preset) {
              final isSelected = _selectedDatePreset == preset;
              return InkWell(
                onTap: () => _setDatePreset(preset),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : const Color(0xFFD6E0D8)),
                    ),
                  ),
                  child: Text(
                    preset,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
              );
            }),

            // Custom Range Button
            InkWell(
              onTap: () => _pickDateRange(context),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCustomActive
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCustomActive
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : const Color(0xFFD6E0D8)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 13,
                      color: isCustomActive
                          ? Colors.white
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCustomActive ? dateDisplay : 'Custom Range...',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isCustomActive ? FontWeight.bold : FontWeight.w500,
                        color: isCustomActive
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // 3E. DROPDOWN FILTERS ROW (ORIGIN, DESTINATION, REASON, STAFF, GENDER)
  // -------------------------------------------------------------------
  Widget _buildDropdownFiltersRow(bool isDark, bool isMobile) {
    // 1. From Shed items
    final fromShedItems = ['All Origin Sheds', ..._uniqueFromSheds.map((s) => s.display)];
    final selectedFromShedDisplay = _selectedFromShed == 'all'
        ? 'All Origin Sheds'
        : (_uniqueFromSheds.firstWhereOrNull((s) => s.id == _selectedFromShed)?.display ?? 'All Origin Sheds');

    // 2. To Shed items
    final toShedItems = ['All Destination Sheds', ..._uniqueToSheds.map((s) => s.display)];
    final selectedToShedDisplay = _selectedToShed == 'all'
        ? 'All Destination Sheds'
        : (_uniqueToSheds.firstWhereOrNull((s) => s.id == _selectedToShed)?.display ?? 'All Destination Sheds');

    // 3. Reason items
    final reasonItems = ['All Reasons', ..._uniqueReasons];
    final selectedReasonDisplay = _selectedReason == 'all' ? 'All Reasons' : _selectedReason;

    // 4. Staff items
    final staffItems = ['All Staff', ..._uniqueStaff.map((u) => u.name)];
    final selectedStaffDisplay = _selectedStaff == 'all' ? 'All Staff' : _selectedStaff;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final count = _isCowSpecific ? 4 : 5;
        final itemWidth = isMobile
            ? (availableWidth - 9) / 2
            : (availableWidth - (count - 1) * 9) / count;

        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            // From Shed
            _buildFilterDropdown(
              label: 'From Shed (Origin)',
              selectedValue: selectedFromShedDisplay,
              items: fromShedItems,
              width: itemWidth,
              prefixIcon: PhosphorIconsRegular.warehouse,
              searchHint: 'Search origin shed...',
              showSearchBox: fromShedItems.length > 2,
              isDark: isDark,
              onChanged: (val) {
                setState(() {
                  if (val == null || val == 'All Origin Sheds') {
                    _selectedFromShed = 'all';
                  } else {
                    final match = _uniqueFromSheds.firstWhereOrNull((s) => s.display == val);
                    _selectedFromShed = match?.id ?? 'all';
                  }
                  _currentPage = 1;
                });
              },
            ),

            // To Shed
            _buildFilterDropdown(
              label: 'To Shed (Destination)',
              selectedValue: selectedToShedDisplay,
              items: toShedItems,
              width: itemWidth,
              prefixIcon: PhosphorIconsRegular.warehouse,
              searchHint: 'Search destination shed...',
              showSearchBox: toShedItems.length > 2,
              isDark: isDark,
              onChanged: (val) {
                setState(() {
                  if (val == null || val == 'All Destination Sheds') {
                    _selectedToShed = 'all';
                  } else {
                    final match = _uniqueToSheds.firstWhereOrNull((s) => s.display == val);
                    _selectedToShed = match?.id ?? 'all';
                  }
                  _currentPage = 1;
                });
              },
            ),

            // Reason
            _buildFilterDropdown(
              label: 'Transfer Reason',
              selectedValue: selectedReasonDisplay,
              items: reasonItems,
              width: itemWidth,
              prefixIcon: PhosphorIconsRegular.tag,
              searchHint: 'Search reason...',
              showSearchBox: reasonItems.length > 2,
              isDark: isDark,
              onChanged: (val) {
                setState(() {
                  if (val == null || val == 'All Reasons') {
                    _selectedReason = 'all';
                  } else {
                    _selectedReason = val;
                  }
                  _currentPage = 1;
                });
              },
            ),

            // Staff
            _buildFilterDropdown(
              label: 'Transferred By (Staff)',
              selectedValue: selectedStaffDisplay,
              items: staffItems,
              width: itemWidth,
              prefixIcon: PhosphorIconsRegular.user,
              searchHint: 'Search staff...',
              showSearchBox: staffItems.length > 2,
              isDark: isDark,
              onChanged: (val) {
                setState(() {
                  if (val == null || val == 'All Staff') {
                    _selectedStaff = 'all';
                  } else {
                    _selectedStaff = val;
                  }
                  _currentPage = 1;
                });
              },
            ),

            // Gender (if Gaushala wide)
            if (!_isCowSpecific)
              _buildFilterDropdown(
                label: 'Gender',
                selectedValue: _selectedGender == 'all'
                    ? 'All Genders'
                    : (_selectedGender == 'female' ? 'Female (♀)' : 'Male (♂)'),
                items: const ['All Genders', 'Female (♀)', 'Male (♂)'],
                width: itemWidth,
                prefixIcon: PhosphorIconsRegular.genderIntersex,
                showSearchBox: false,
                isDark: isDark,
                onChanged: (val) {
                  setState(() {
                    if (val == null || val == 'All Genders') {
                      _selectedGender = 'all';
                    } else if (val.startsWith('Female')) {
                      _selectedGender = 'female';
                    } else {
                      _selectedGender = 'male';
                    }
                    _currentPage = 1;
                  });
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String selectedValue,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
    IconData? prefixIcon,
    double? width,
    String? searchHint,
    bool? showSearchBox,
  }) {
    final isSelected = selectedValue != 'all' &&
        selectedValue.isNotEmpty &&
        !selectedValue.startsWith('All');
    final currentDisplay = items.contains(selectedValue)
        ? selectedValue
        : (items.isNotEmpty ? items.first : '');

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 5),
          DropdownSearch<String>(
            items: (filter, infiniteScrollProps) {
              if (filter.isEmpty) return items;
              return items
                  .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                  .toList();
            },
            selectedItem: currentDisplay,
            compareFn: (i1, i2) => i1 == i2,
            onSelected: (val) {
              if (val != null) {
                onChanged(val);
              }
            },
            popupProps: PopupProps.menu(
              fit: FlexFit.loose,
              constraints: const BoxConstraints(maxHeight: 280),
              showSearchBox: showSearchBox ?? (items.length > 2),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: searchHint ?? 'Search...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                elevation: 8,
              ),
              itemBuilder: (ctx, item, isDisabled, isSelectedInMenu) {
                final isCurrent = item == selectedValue;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      if (prefixIcon != null) ...[
                        Icon(
                          prefixIcon,
                          size: 15,
                          color: isCurrent
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent
                                ? AppColors.primary
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ),
                      if (isCurrent)
                        const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                );
              },
            ),
            dropdownBuilder: (context, selectedItem) {
              return Text(
                selectedItem ?? currentDisplay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              );
            },
            suffixProps: DropdownSuffixProps(
              dropdownButtonProps: DropdownButtonProps(
                iconClosed: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                iconOpened: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            decoratorProps: DropDownDecoratorProps(
              baseStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                prefixIcon: prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8, right: 6),
                        child: Icon(
                          prefixIcon,
                          size: 15,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // 3F. ACTIVE FILTER CHIPS STRIP
  // -------------------------------------------------------------------
  Widget _buildActiveFilterChips(bool isDark) {
    final chips = <Widget>[];

    // 1. Date Range
    if (_filterStartDate != null && _filterEndDate != null) {
      final text = '${DateFormat("dd MMM").format(_filterStartDate!)} - ${DateFormat("dd MMM yyyy").format(_filterEndDate!)}';
      chips.add(
        _buildChipItem(
          label: 'Date: $text',
          icon: PhosphorIconsRegular.calendarBlank,
          onRemove: () => _setDatePreset('All Time'),
          isDark: isDark,
        ),
      );
    }

    // 2. From Shed
    if (_selectedFromShed != 'all') {
      final name = _uniqueFromSheds.firstWhereOrNull((s) => s.id == _selectedFromShed)?.display ?? _selectedFromShed;
      chips.add(
        _buildChipItem(
          label: 'From: $name',
          icon: PhosphorIconsRegular.warehouse,
          onRemove: () => setState(() {
            _selectedFromShed = 'all';
            _currentPage = 1;
          }),
          isDark: isDark,
        ),
      );
    }

    // 3. To Shed
    if (_selectedToShed != 'all') {
      final name = _uniqueToSheds.firstWhereOrNull((s) => s.id == _selectedToShed)?.display ?? _selectedToShed;
      chips.add(
        _buildChipItem(
          label: 'To: $name',
          icon: PhosphorIconsRegular.warehouse,
          onRemove: () => setState(() {
            _selectedToShed = 'all';
            _currentPage = 1;
          }),
          isDark: isDark,
        ),
      );
    }

    // 4. Reason
    if (_selectedReason != 'all') {
      chips.add(
        _buildChipItem(
          label: 'Reason: $_selectedReason',
          icon: PhosphorIconsRegular.tag,
          onRemove: () => setState(() {
            _selectedReason = 'all';
            _currentPage = 1;
          }),
          isDark: isDark,
        ),
      );
    }

    // 5. Staff
    if (_selectedStaff != 'all') {
      chips.add(
        _buildChipItem(
          label: 'Staff: $_selectedStaff',
          icon: PhosphorIconsRegular.user,
          onRemove: () => setState(() {
            _selectedStaff = 'all';
            _currentPage = 1;
          }),
          isDark: isDark,
        ),
      );
    }

    // 6. Gender
    if (_selectedGender != 'all') {
      chips.add(
        _buildChipItem(
          label: 'Gender: ${_selectedGender == "female" ? "Female" : "Male"}',
          icon: PhosphorIconsRegular.genderIntersex,
          onRemove: () => setState(() {
            _selectedGender = 'all';
            _currentPage = 1;
          }),
          isDark: isDark,
        ),
      );
    }

    // 7. Quick Shed
    if (_selectedShedFilter != 'all') {
      chips.add(
        _buildChipItem(
          label: 'Shed: $_selectedShedDisplayName',
          icon: PhosphorIconsRegular.warehouse,
          onRemove: () => setState(() {
            _selectedShedFilter = 'all';
            _currentPage = 1;
          }),
          isDark: isDark,
        ),
      );
    }

    // 8. Search query
    if (_searchQuery.isNotEmpty) {
      chips.add(
        _buildChipItem(
          label: 'Search: "$_searchQuery"',
          icon: Icons.search_rounded,
          onRemove: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _currentPage = 1;
            });
          },
          isDark: isDark,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.3) : const Color(0xFFF9FBFA),
      child: Row(
        children: [
          Text(
            'Active Filters:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...chips,
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _resetAllFilters,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipItem({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // 4. BODY CONTENT
  // -------------------------------------------------------------------
  Widget _buildBody(BuildContext context, bool isDark, bool isMobile) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomInlineLoader(size: 28),
            SizedBox(height: 14),
            Text(
              'Fetching shed transfer logs...',
              style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                'Failed to load transfer history',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                width: 110,
                height: 36,
                onPressed: () => _fetchHistory(page: _currentPage),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredRecords;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.arrowsLeftRight,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matching transfer records found'
                    : 'No shed transfers recorded yet',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search query or clear the shed filter.'
                    : 'Relocations made via "Transfer Shed" will appear here automatically with full audit trail.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewMode == HistoryViewMode.timeline) {
      return _buildTimelineView(filtered, isDark, isMobile);
    }

    return _buildTableView(filtered, isDark, isMobile);
  }

  // -------------------------------------------------------------------
  // 4A. TABLE VIEW (EXECUTIVE DATA TABLE)
  // -------------------------------------------------------------------
  Widget _buildTableView(
    List<ShedTransferRecord> records,
    bool isDark,
    bool isMobile,
  ) {
    return Scrollbar(
      controller: _tableVerticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _tableVerticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _tableHorizontalScrollController,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            controller: _tableHorizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 880),
              child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 58,
              horizontalMargin: 16,
              columnSpacing: 18,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.surfaceDark : const Color(0xFFF4F7F4),
              ),
              columns: [
                const DataColumn(
                  label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                DataColumn(
                  label: const Text('DATE & TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onSort: (colIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = colIndex;
                      _sortAscending = ascending;
                    });
                  },
                ),
                if (!_isCowSpecific)
                  DataColumn(
                    label: const Text('CATTLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onSort: (colIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = colIndex;
                        _sortAscending = ascending;
                      });
                    },
                  ),
                const DataColumn(
                  label: Text('FROM SHED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const DataColumn(
                  label: Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const DataColumn(
                  label: Text('TO SHED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                DataColumn(
                  label: const Text('REASON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onSort: (colIndex, ascending) {
                    setState(() {
                      _sortColumnIndex = colIndex;
                      _sortAscending = ascending;
                    });
                  },
                ),
                const DataColumn(
                  label: Text('TRANSFERRED BY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
              rows: records.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final r = entry.value;

                final dateStr = r.transferDate != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(r.transferDate!)
                    : 'N/A';

                return DataRow(
                  cells: [
                    // 1. #
                    DataCell(
                      Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),

                    // 2. Date & Time
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.calendarBlank, size: 14, color: AppColors.textMutedLight),
                          const SizedBox(width: 6),
                          Text(dateStr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    // 3. Cattle Info (if Gaushala-wide)
                    if (!_isCowSpecific)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              r.cow?.isFemale == false ? Icons.male_rounded : Icons.female_rounded,
                              size: 15,
                              color: r.cow?.isFemale == false ? Colors.blue : Colors.pinkAccent,
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  r.cow?.tagId ?? 'N/A',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                if (r.cow?.calfName != null && r.cow!.calfName!.isNotEmpty)
                                  Text(
                                    r.cow!.calfName!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // 4. From Shed
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFEFF2F0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFDCE2DD),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsRegular.warehouse, size: 13, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 5),
                            Text(
                              r.fromShed?.display ?? 'Initial Shed',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5. Arrow
                    const DataCell(
                      Icon(PhosphorIconsRegular.arrowRight, size: 14, color: AppColors.primary),
                    ),

                    // 6. To Shed
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsRegular.warehouse, size: 13, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              r.toShed?.display ?? 'Target Shed',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 7. Reason
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.reason.isNotEmpty ? r.reason : 'Relocation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ),

                    // 8. Transferred By
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                            child: Text(
                              (r.transferredBy?.name.isNotEmpty == true)
                                  ? r.transferredBy!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                r.transferredBy?.name ?? 'Admin',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              if (r.transferredBy?.emailId != null)
                                Text(
                                  r.transferredBy!.emailId!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ),
  );
}

  // -------------------------------------------------------------------
  // 4B. TIMELINE VIEW (VERTICAL AUDIT TRAIL)
  // -------------------------------------------------------------------
  Widget _buildTimelineView(
    List<ShedTransferRecord> records,
    bool isDark,
    bool isMobile,
  ) {
    return ListView.builder(
      controller: _timelineScrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 16,
      ),
      itemCount: records.length,
      itemBuilder: (context, idx) {
        final r = records[idx];
        final isLast = idx == records.length - 1;
        final dateStr = r.transferDate != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(r.transferDate!)
            : 'Date unavailable';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline connector column
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${records.length - idx}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 90,
                    color: isDark ? AppColors.borderDark : const Color(0xFFD6E3D8),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Card content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFFAFCFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2EBE2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Date + Staff
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(PhosphorIconsRegular.calendarBlank, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (r.transferredBy != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'By: ${r.transferredBy!.name}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Middle: Cattle info (if Gaushala mode)
                    if (!_isCowSpecific && r.cow != null) ...[
                      Row(
                        children: [
                          Icon(
                            r.cow!.isFemale ? Icons.female_rounded : Icons.male_rounded,
                            size: 14,
                            color: r.cow!.isFemale ? Colors.pinkAccent : Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cattle: ${r.cow!.displayName}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          if (r.cow?.breedName != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${r.cow!.breedName}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Relocation route: From Shed -> To Shed
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE8EFE8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.warehouse, size: 14, color: AppColors.textMutedLight),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    r.fromShed?.display ?? 'Initial Shed',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(PhosphorIconsRegular.arrowRight, size: 14, color: AppColors.primary),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.warehouse, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    r.toShed?.display ?? 'Target Shed',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Reason badge
                    if (r.reason.isNotEmpty)
                      Row(
                        children: [
                          Text(
                            'Reason: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              r.reason,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // 5. FOOTER & PAGINATION
  // -------------------------------------------------------------------
  Widget _buildFooter(BuildContext context, bool isDark, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pagination stats
          Text(
            'Showing ${_filteredRecords.length} of $_totalRecords records (Page $_currentPage of $_totalPages)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),

          // Pagination buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                tooltip: 'Previous Page',
                onPressed: _currentPage > 1
                    ? () => _fetchHistory(page: _currentPage - 1)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF0F4F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                tooltip: 'Next Page',
                onPressed: _currentPage < _totalPages
                    ? () => _fetchHistory(page: _currentPage + 1)
                    : null,
              ),
              const SizedBox(width: 8),
              // Rows per page selector
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rows: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: const [5, 10, 20, 50].contains(_rowsPerPage) ? _rowsPerPage : 5,
                        isDense: true,
                        dropdownColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        items: const [5, 10, 20, 50].map((opt) {
                          return DropdownMenuItem<int>(
                            value: opt,
                            child: Text(
                              '$opt',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _rowsPerPage) {
                            setState(() {
                              _rowsPerPage = val;
                            });
                            _fetchHistory(page: 1, limit: val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Close',
                width: 80,
                height: 34,
                variant: ButtonVariant.outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
