import 'administrative_region.dart';

class RegionSelection {
  final AdministrativeRegion province;
  final AdministrativeRegion regency;
  final AdministrativeRegion district;
  final AdministrativeRegion village;

  const RegionSelection({
    required this.province,
    required this.regency,
    required this.district,
    required this.village,
  });
}
