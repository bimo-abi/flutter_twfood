class Address {
  final int idAlamat;
  final int idPengguna;
  final String label;
  final String namaPenerima;
  final String nomorTelepon;
  final String alamatLengkap;
  final String kota;
  final String provinsi;
  final String kodePos;
  final double? latitude;
  final double? longitude;
  final bool alamatUtama;

  const Address({
    required this.idAlamat,
    required this.idPengguna,
    required this.label,
    required this.namaPenerima,
    required this.nomorTelepon,
    required this.alamatLengkap,
    required this.kota,
    required this.provinsi,
    required this.kodePos,
    this.latitude,
    this.longitude,
    required this.alamatUtama,
  });

  factory Address.fromJson(
    Map<String, dynamic> json,
  ) {
    return Address(
      idAlamat: int.tryParse(
            json['id_alamat'].toString(),
          ) ??
          0,
      idPengguna: int.tryParse(
            json['id_pengguna'].toString(),
          ) ??
          0,
      label:
          json['label']?.toString() ?? '',
      namaPenerima:
          json['nama_penerima']?.toString() ?? '',
      nomorTelepon:
          json['nomor_telepon']?.toString() ?? '',
      alamatLengkap:
          json['alamat_lengkap']?.toString() ?? '',
      kota:
          json['kota']?.toString() ?? '',
      provinsi:
          json['provinsi']?.toString() ?? '',
      kodePos:
          json['kode_pos']?.toString() ?? '',
      latitude:
          _parseNullableDouble(json['latitude']),
      longitude:
          _parseNullableDouble(json['longitude']),
      alamatUtama:
          json['alamat_utama'] == true,
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