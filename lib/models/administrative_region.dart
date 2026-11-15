class AdministrativeRegion {
  final String id;
  final String name;
  final String? postalCode;

  const AdministrativeRegion({
    required this.id,
    required this.name,
    this.postalCode,
  });

  factory AdministrativeRegion.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final name = json['name']?.toString();

    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      throw const FormatException(
        'Data wilayah tidak memiliki id atau name yang valid.',
      );
    }

    return AdministrativeRegion(
      id: id,
      name: name,
      postalCode: json['postal_code']?.toString(),
    );
  }
}
