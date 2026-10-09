class Outlet {
  final int idOutlet;
  final String namaOutlet;
  final String? alamat;
  final String? nomorTelepon;
  final double? latitude;
  final double? longitude;
  final String? deskripsi;
  final String? foto;
  final List<OutletOperatingHour> jamOperasional;

  const Outlet({
    required this.idOutlet,
    required this.namaOutlet,
    this.alamat,
    this.nomorTelepon,
    this.latitude,
    this.longitude,
    this.deskripsi,
    this.foto,
    required this.jamOperasional,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    final rawJamOperasional = json['jam_operasional'];

    final List<OutletOperatingHour> jamOperasional = [];

    if (rawJamOperasional is List) {
      for (final item in rawJamOperasional) {
        if (item is Map<String, dynamic>) {
          jamOperasional.add(
            OutletOperatingHour.fromJson(item),
          );
        }
      }
    }

    return Outlet(
      idOutlet: int.tryParse(
            json['id_outlet'].toString(),
          ) ??
          0,
      namaOutlet:
          json['nama_outlet']?.toString() ?? '',
      alamat:
          json['alamat']?.toString(),
      nomorTelepon:
          json['nomor_telepon']?.toString(),
      latitude:
          _parseNullableDouble(json['latitude']),
      longitude:
          _parseNullableDouble(json['longitude']),
      deskripsi:
          json['deskripsi']?.toString(),
      foto:
          json['foto']?.toString(),
      jamOperasional: jamOperasional,
    );
  }

  static double? _parseNullableDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return double.tryParse(
      value.toString(),
    );
  }
}

class OutletOperatingHour {
  final int idJamOperasional;
  final int idOutlet;
  final String hari;
  final String? jamBuka;
  final String? jamTutup;
  final bool tutup;

  const OutletOperatingHour({
    required this.idJamOperasional,
    required this.idOutlet,
    required this.hari,
    this.jamBuka,
    this.jamTutup,
    required this.tutup,
  });

  factory OutletOperatingHour.fromJson(
    Map<String, dynamic> json,
  ) {
    return OutletOperatingHour(
      idJamOperasional: int.tryParse(
            json['id_jam_operasional'].toString(),
          ) ??
          0,
      idOutlet: int.tryParse(
            json['id_outlet'].toString(),
          ) ??
          0,
      hari:
          json['hari']?.toString() ?? '',
      jamBuka:
          json['jam_buka']?.toString(),
      jamTutup:
          json['jam_tutup']?.toString(),
      tutup:
          json['tutup'] == true,
    );
  }
}