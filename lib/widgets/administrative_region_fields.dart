import 'package:flutter/material.dart';

import '../models/administrative_region.dart';
import '../models/region_selection.dart';
import '../services/region_service.dart';

/// Dropdown wilayah bertingkat:
/// Provinsi -> Kabupaten/Kota -> Kecamatan -> Desa/Kelurahan.
class AdministrativeRegionFields extends StatefulWidget {
  final ValueChanged<RegionSelection?> onChanged;
  final String? initialProvinceId;
  final String? initialRegencyId;
  final String? initialDistrictId;
  final String? initialVillageId;

  const AdministrativeRegionFields({
    super.key,
    required this.onChanged,
    this.initialProvinceId,
    this.initialRegencyId,
    this.initialDistrictId,
    this.initialVillageId,
  });

  @override
  State<AdministrativeRegionFields> createState() =>
      _AdministrativeRegionFieldsState();
}

class _AdministrativeRegionFieldsState
    extends State<AdministrativeRegionFields> {
  late final RegionService _service;

  List<AdministrativeRegion> _provinces = [];
  List<AdministrativeRegion> _regencies = [];
  List<AdministrativeRegion> _districts = [];
  List<AdministrativeRegion> _villages = [];

  AdministrativeRegion? _province;
  AdministrativeRegion? _regency;
  AdministrativeRegion? _district;
  AdministrativeRegion? _village;

  bool _loadingProvinces = false;
  bool _loadingRegencies = false;
  bool _loadingDistricts = false;
  bool _loadingVillages = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = RegionService();
    _loadInitialRegions();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _loadInitialRegions() async {
    await _loadProvinces();

    if (!mounted || widget.initialProvinceId == null) return;

    final provinceMatches = _provinces.where(
      (item) => item.id == widget.initialProvinceId,
    );
    if (provinceMatches.isEmpty) return;

    setState(() => _province = provinceMatches.first);
    await _loadRegencies(_province!.id, notify: false);

    if (!mounted || widget.initialRegencyId == null) return;
    final regencyMatches = _regencies.where(
      (item) => item.id == widget.initialRegencyId,
    );
    if (regencyMatches.isEmpty) return;

    setState(() => _regency = regencyMatches.first);
    await _loadDistricts(_regency!.id, notify: false);

    if (!mounted || widget.initialDistrictId == null) return;
    final districtMatches = _districts.where(
      (item) => item.id == widget.initialDistrictId,
    );
    if (districtMatches.isEmpty) return;

    setState(() => _district = districtMatches.first);
    await _loadVillages(_district!.id, notify: false);

    if (!mounted || widget.initialVillageId == null) return;
    final villageMatches = _villages.where(
      (item) => item.id == widget.initialVillageId,
    );
    if (villageMatches.isNotEmpty) {
      setState(() => _village = villageMatches.first);
      _notifySelection();
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _error = null;
    });
    try {
      final result = await _service.getProvinces();
      if (!mounted) return;
      setState(() => _provinces = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadRegencies(String provinceId, {bool notify = true}) async {
    setState(() {
      _loadingRegencies = true;
      _regencies = [];
      _regency = null;
      _districts = [];
      _district = null;
      _villages = [];
      _village = null;
      _error = null;
    });
    if (notify) _notifySelection();

    try {
      final result = await _service.getRegencies(provinceId);
      if (!mounted) return;
      setState(() => _regencies = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _loadingRegencies = false);
    }
  }

  Future<void> _loadDistricts(String regencyId, {bool notify = true}) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _district = null;
      _villages = [];
      _village = null;
      _error = null;
    });
    if (notify) _notifySelection();

    try {
      final result = await _service.getDistricts(regencyId);
      if (!mounted) return;
      setState(() => _districts = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadVillages(String districtId, {bool notify = true}) async {
    setState(() {
      _loadingVillages = true;
      _villages = [];
      _village = null;
      _error = null;
    });
    if (notify) _notifySelection();

    try {
      final result = await _service.getVillages(districtId);
      if (!mounted) return;
      setState(() => _villages = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _loadingVillages = false);
    }
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _notifySelection() {
    final selection =
        _province != null &&
            _regency != null &&
            _district != null &&
            _village != null
        ? RegionSelection(
            province: _province!,
            regency: _regency!,
            district: _district!,
            village: _village!,
          )
        : null;
    widget.onChanged(selection);
  }

  Widget _dropdown({
    required String label,
    required AdministrativeRegion? value,
    required List<AdministrativeRegion> items,
    required bool loading,
    required bool enabled,
    required ValueChanged<AdministrativeRegion?>? onChanged,
  }) {
    return DropdownButtonFormField<AdministrativeRegion>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: Text('Pilih $label'),
      items: items
          .map(
            (region) => DropdownMenuItem<AdministrativeRegion>(
              value: region,
              child: Text(region.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled && !loading ? onChanged : null,
      validator: (selected) => selected == null ? '$label wajib dipilih' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Wilayah Administratif',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Provinsi',
          value: _province,
          items: _provinces,
          loading: _loadingProvinces,
          enabled: true,
          onChanged: (selected) {
            if (selected == null) return;
            setState(() => _province = selected);
            _loadRegencies(selected.id);
          },
        ),
        const SizedBox(height: 16),
        _dropdown(
          label: 'Kabupaten/Kota',
          value: _regency,
          items: _regencies,
          loading: _loadingRegencies,
          enabled: _province != null,
          onChanged: (selected) {
            if (selected == null) return;
            setState(() => _regency = selected);
            _loadDistricts(selected.id);
          },
        ),
        const SizedBox(height: 16),
        _dropdown(
          label: 'Kecamatan',
          value: _district,
          items: _districts,
          loading: _loadingDistricts,
          enabled: _regency != null,
          onChanged: (selected) {
            if (selected == null) return;
            setState(() => _district = selected);
            _loadVillages(selected.id);
          },
        ),
        const SizedBox(height: 16),
        _dropdown(
          label: 'Desa/Kelurahan',
          value: _village,
          items: _villages,
          loading: _loadingVillages,
          enabled: _district != null,
          onChanged: (selected) {
            if (selected == null) return;
            setState(() => _village = selected);
            _notifySelection();
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadingProvinces ? null : _loadProvinces,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba muat ulang provinsi'),
            ),
          ),
        ],
      ],
    );
  }
}
