import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/cow_model.dart';
import '../../../data/models/shed_model.dart';
import '../../../data/services/api_service.dart';
import '../cow_controller.dart';
import 'shed_transfer_history_dialog.dart';

/// Enterprise Modal Dialog for transferring cattle between housing sheds.
/// Supports both single cattle transfer and batch transfer for multiple cattle.
class ShedTransferDialog extends StatefulWidget {
  final CowModel? cow;
  final List<CowModel>? preselectedCows;
  final CowController controller;

  const ShedTransferDialog({
    super.key,
    this.cow,
    this.preselectedCows,
    required this.controller,
  });

  /// Displays the Shed Transfer Dialog modal.
  static Future<bool?> show({
    required BuildContext context,
    CowModel? cow,
    List<CowModel>? preselectedCows,
    required CowController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShedTransferDialog(
        cow: cow,
        preselectedCows: preselectedCows,
        controller: controller,
      ),
    );
  }

  @override
  State<ShedTransferDialog> createState() => _ShedTransferDialogState();
}

class _ShedTransferDialogState extends State<ShedTransferDialog> {
  final ApiService _apiService = Get.find<ApiService>();

  late String _gaushalaId;
  String _gaushalaName = '';

  final Set<String> _selectedCowIds = <String>{};
  final Map<String, CowModel> _cowsMap = <String, CowModel>{};

  final List<ShedModel> _availableSheds = [];
  ShedModel? _targetShed;
  bool _isLoadingSheds = true;

  late final TextEditingController _reasonController;
  late DateTime _selectedDate;
  String _cowSearchQuery = '';
  bool _showAddMoreCows = false;
  bool _isSubmitting = false;

  final List<String> _quickReasons = const [
    'Moved to milking shed',
    'Dry period segregation',
    'Medical quarantine',
    'Calving pen',
    'Routine relocation',
    'Post-treatment recovery',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _reasonController = TextEditingController(text: 'Moved to milking shed');

    // 1. Resolve active Gaushala
    if (widget.cow?.gaushala?.id != null && widget.cow!.gaushala!.id.isNotEmpty) {
      _gaushalaId = widget.cow!.gaushala!.id;
      _gaushalaName = widget.cow!.gaushala!.gaushalaName;
    } else if (widget.preselectedCows != null && widget.preselectedCows!.isNotEmpty) {
      final first = widget.preselectedCows!.first;
      _gaushalaId = first.gaushala?.id ?? widget.controller.selectedGaushalaId.value ?? '';
      _gaushalaName = first.gaushala?.gaushalaName ?? widget.controller.selectedGaushalaName;
    } else {
      _gaushalaId = widget.controller.selectedGaushalaId.value ?? widget.controller.globalGaushalaId;
      _gaushalaName = widget.controller.selectedGaushalaName;
    }

    // 2. Index available cows from the controller (Only Active, Non-Deleted, Non-Died)
    for (final c in widget.controller.cows) {
      if (c.canTransferShed) {
        if (_gaushalaId.isEmpty ||
            c.gaushala?.id == null ||
            c.gaushala!.id.isEmpty ||
            c.gaushala!.id == _gaushalaId) {
          _cowsMap[c.id] = c;
        }
      }
    }

    // 3. Populate preselected cattle
    if (widget.cow != null) {
      if (widget.cow!.canTransferShed) {
        _selectedCowIds.add(widget.cow!.id);
        _cowsMap[widget.cow!.id] = widget.cow!;
      }
    } else if (widget.preselectedCows != null) {
      for (final c in widget.preselectedCows!) {
        if (c.canTransferShed) {
          _selectedCowIds.add(c.id);
          _cowsMap[c.id] = c;
        }
      }
    }

    // 4. Fetch sheds for the gaushala
    _fetchSheds();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSheds() async {
    setState(() => _isLoadingSheds = true);
    try {
      final sheds = await _apiService.getSheds(gaushalaId: _gaushalaId);
      if (mounted) {
        setState(() {
          _availableSheds.clear();
          _availableSheds.addAll(sheds);
          _isLoadingSheds = false;

          // Auto-select first non-current shed if only 1 alternative exists
          if (_targetShed == null && _availableSheds.isNotEmpty) {
            final currentShedId = widget.cow?.shed?.id;
            final candidate = _availableSheds.firstWhereOrNull(
              (s) => s.id != currentShedId,
            );
            if (candidate != null) {
              _targetShed = candidate;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSheds = false);
      }
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    } else if (mounted) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _submitTransfer() async {
    if (_selectedCowIds.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'Cattle Required',
        message: 'Please select at least one cattle to transfer.',
      );
      return;
    }

    if (_targetShed == null) {
      CustomSnackbar.showWarning(
        title: 'Target Shed Required',
        message: 'Please select a destination shed.',
      );
      return;
    }

    // Check if any selected cow is already in the target shed
    final alreadyInTarget = _selectedCowIds.where((id) {
      final c = _cowsMap[id];
      return c?.shed?.id == _targetShed!.id;
    }).toList();

    if (alreadyInTarget.length == _selectedCowIds.length) {
      CustomSnackbar.showWarning(
        title: 'Invalid Destination',
        message: 'The selected cattle are already in ${_targetShed!.shedName} (${_targetShed!.shedNumber}). Please choose a different shed.',
      );
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'Reason Required',
        message: 'Please enter or select a reason for the transfer.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.controller.executeShedTransfer(
      gaushalaId: _gaushalaId,
      cowIds: _selectedCowIds.toList(),
      toShedId: _targetShed!.id,
      reason: reason,
      transferDate: _selectedDate,
      targetShed: _targetShed,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    } else if (success && (Get.isDialogOpen ?? false)) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = (screenWidth - (isMobile ? 24 : 48)).clamp(260.0, 580.0);

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------------------------------------------------
            // HEADER
            // ---------------------------------------------------------
            _buildHeader(context, isDark),
            const Divider(height: 1),

            // ---------------------------------------------------------
            // SCROLLABLE FORM BODY
            // ---------------------------------------------------------
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gaushala Info Strip
                    _buildGaushalaInfoStrip(isDark),
                    const SizedBox(height: 18),

                    // Section 1: Selected Cattle
                    _buildCattleSelectionSection(isDark),
                    const SizedBox(height: 20),

                    // Section 2: Destination Shed
                    _buildTargetShedSection(isDark),
                    const SizedBox(height: 20),

                    // Section 3: Transfer Reason
                    _buildReasonSection(isDark),
                    const SizedBox(height: 20),

                    // Section 4: Transfer Date & Time
                    _buildDateTimeSection(isDark),
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------------
            // FOOTER ACTION BUTTONS
            // ---------------------------------------------------------
            const Divider(height: 1),
            _buildFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // 1. DIALOG HEADER
  // -------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              PhosphorIconsRegular.arrowsLeftRight,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transfer Cattle to Shed',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Relocate selected cattle to a different housing shed',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ShedTransferHistoryDialog.show(
                context: context,
                gaushalaId: _gaushalaId,
                gaushalaName: _gaushalaName,
                cow: widget.cow,
                cowId: widget.cow?.id,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsRegular.clockCounterClockwise,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'History',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // GAUSHALA INFO STRIP
  // -------------------------------------------------------------------
  Widget _buildGaushalaInfoStrip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : const Color(0xFFF3F6F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2EBE0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.buildings,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            'Active Gaushala:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _gaushalaName.isNotEmpty ? _gaushalaName : 'Primary Gaushala',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // 2. CATTLE SELECTION SECTION
  // -------------------------------------------------------------------
  Widget _buildCattleSelectionSection(bool isDark) {
    final count = _selectedCowIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'CATTLE TO TRANSFER *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count == 1 ? '1 Selected' : '$count Selected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: count > 0 ? AppColors.primary : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                setState(() => _showAddMoreCows = !_showAddMoreCows);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAddMoreCows ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAddMoreCows ? 'Hide Picker' : 'Select More Cattle',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Display Selected Cattle Chips / Cards
        if (_selectedCowIds.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedCowIds.map((id) {
              final cow = _cowsMap[id];
              final tag = cow?.tagId ?? id;
              final shedName = cow?.shed?.shedName;
              final shedNo = cow?.shed?.shedNumber;
              final shedInfo = (shedName != null && shedName.isNotEmpty)
                  ? '$shedName${(shedNo != null && shedNo.isNotEmpty) ? " ($shedNo)" : ""}'
                  : 'Unassigned';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cow?.isFemale == false ? Icons.male_rounded : Icons.female_rounded,
                      size: 15,
                      color: cow?.isFemale == false ? Colors.blue : Colors.pinkAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Current: $shedInfo',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedCowIds.remove(id);
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close_rounded, size: 14, color: AppColors.textMutedLight),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No cattle selected. Choose cattle below to transfer.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Collapsible Cattle Selector Table/List
        if (_showAddMoreCows || _selectedCowIds.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter search box
                CustomTextField(
                  hint: 'Search by Tag ID, Alias, or Breed...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  onChanged: (val) {
                    setState(() => _cowSearchQuery = val.trim().toLowerCase());
                  },
                ),
                const SizedBox(height: 10),

                // Cattle list with checkboxes
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Builder(
                    builder: (context) {
                      final filtered = _cowsMap.values.where((c) {
                        if (!c.canTransferShed) return false;
                        if (_cowSearchQuery.isEmpty) return true;
                        final tagMatch = c.tagId.toLowerCase().contains(_cowSearchQuery);
                        final aliasMatch = c.calfName?.toLowerCase().contains(_cowSearchQuery) ?? false;
                        final breedMatch = c.breed?.breedName.toLowerCase().contains(_cowSearchQuery) ?? false;
                        return tagMatch || aliasMatch || breedMatch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No matching cattle found in this gaushala.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        primary: false,
                        itemCount: filtered.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final cow = filtered[idx];
                          final isChecked = _selectedCowIds.contains(cow.id);
                          final shedLabel = cow.shed != null
                              ? '${cow.shed!.shedName} (${cow.shed!.shedNumber})'
                              : 'Unassigned';

                          return _HoverableCowTransferItem(
                            cow: cow,
                            isChecked: isChecked,
                            shedLabel: shedLabel,
                            isDark: isDark,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedCowIds.add(cow.id);
                                } else {
                                  _selectedCowIds.remove(cow.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------
  // 3. DESTINATION SHED SECTION
  // -------------------------------------------------------------------
  Widget _buildTargetShedSection(bool isDark) {
    if (_isLoadingSheds) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomInlineLoader(size: 18),
            SizedBox(width: 12),
            Text('Loading available sheds...', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    if (_availableSheds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No sheds registered under this Gaushala. Please create sheds first in the Sheds master menu.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DESTINATION SHED *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        DropdownSearch<ShedModel>(
          items: (filter, infiniteScrollProps) {
            if (filter.isEmpty) return _availableSheds;
            return _availableSheds
                .where((s) =>
                    s.shedName.toLowerCase().contains(filter.toLowerCase()) ||
                    s.shedNumber.toLowerCase().contains(filter.toLowerCase()))
                .toList();
          },
          selectedItem: _targetShed,
          compareFn: (i1, i2) => i1.id == i2.id,
          onSelected: (val) {
            setState(() => _targetShed = val);
          },
          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
            constraints: const BoxConstraints(maxHeight: 280),
            showSearchBox: _availableSheds.length > 2,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search destination shed...',
                hintStyle: TextStyle(
                  fontSize: 13,
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
            itemBuilder: (ctx, shed, isDisabled, isSelected) {
              final isCurrentForAny = _selectedCowIds.any((id) {
                final c = _cowsMap[id];
                return c?.shed?.id == shed.id;
              });
              final isCurrent = _targetShed?.id == shed.id;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.warehouse, size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${shed.shedName} (${shed.shedNumber})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentForAny) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Current Shed',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
              );
            },
          ),
          dropdownBuilder: (context, selectedItem) {
            if (selectedItem != null) {
              return Text(
                '${selectedItem.shedName} (${selectedItem.shedNumber})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              );
            }
            return Text(
              'Select Target Shed',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            );
          },
          suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              iconOpened: const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10, right: 8),
                child: Icon(PhosphorIconsRegular.warehouse, size: 16, color: AppColors.primary),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 20),
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
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // 4. TRANSFER REASON SECTION
  // -------------------------------------------------------------------
  Widget _buildReasonSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRANSFER REASON *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        CustomTextField(
          controller: _reasonController,
          hint: 'e.g., Moved to milking shed',
          prefixIcon: const Icon(PhosphorIconsRegular.notePencil, size: 18),
        ),
        const SizedBox(height: 8),

        // Quick suggestions wrap
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _quickReasons.map((reason) {
            final isSelected = _reasonController.text.trim() == reason;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _reasonController.text = reason;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F3F5)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // 5. TRANSFER DATE & TIME SECTION
  // -------------------------------------------------------------------
  Widget _buildDateTimeSection(bool isDark) {
    final formatted = DateFormat('yyyy-MM-dd • hh:mm a').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRANSFER DATE & TIME',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _pickDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatted,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedDate = DateTime.now());
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Set Now', style: TextStyle(fontSize: 11.5)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_calendar_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // 6. DIALOG FOOTER
  // -------------------------------------------------------------------
  Widget _buildFooter(BuildContext context, bool isDark) {
    final count = _selectedCowIds.length;
    final isEnabled = count > 0 && _targetShed != null && !_isSubmitting;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 450;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isCompact) ...[
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: count > 1 ? 'Transfer $count Cattle' : 'Transfer Cattle',
                icon: PhosphorIconsRegular.arrowsLeftRight,
                isLoading: _isSubmitting,
                height: 40,
                onPressed: isEnabled ? _submitTransfer : null,
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: count > 1 ? 'Transfer $count Cattle' : 'Transfer Cattle',
              icon: PhosphorIconsRegular.arrowsLeftRight,
              isLoading: _isSubmitting,
              width: count > 1 ? 190 : 165,
              height: 40,
              onPressed: isEnabled ? _submitTransfer : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _HoverableCowTransferItem extends StatefulWidget {
  final CowModel cow;
  final bool isChecked;
  final String shedLabel;
  final bool isDark;
  final ValueChanged<bool?> onChanged;

  const _HoverableCowTransferItem({
    required this.cow,
    required this.isChecked,
    required this.shedLabel,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_HoverableCowTransferItem> createState() => _HoverableCowTransferItemState();
}

class _HoverableCowTransferItemState extends State<_HoverableCowTransferItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : AppColors.primary.withValues(alpha: 0.045))
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: _isHovered
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          value: widget.isChecked,
          activeColor: AppColors.primary,
          title: Text(
            widget.cow.tagId,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${widget.cow.isFemale ? "Cow" : "Bull"} • Current: ${widget.shedLabel}',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
