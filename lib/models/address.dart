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
  final String? kodeProvinsi;
  final String? kodeKabupatenKota;
  final String? kodeKecamatan;
  final String? kodeDesaKelurahan;
  final String? kabupatenKota;
  final String? kecamatan;
  final String? desaKelurahan;
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
    this.kodeProvinsi,
    this.kodeKabupatenKota,
    this.kodeKecamatan,
    this.kodeDesaKelurahan,
    this.kabupatenKota,
    this.kecamatan,
    this.desaKelurahan,
    this.latitude,
    this.longitude,
    required this.alamatUtama,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      idAlamat: int.tryParse(json['id_alamat'].toString()) ?? 0,
      idPengguna: int.tryParse(json['id_pengguna'].toString()) ?? 0,
      label: json['label']?.toString() ?? '',
      namaPenerima: json['nama_penerima']?.toString() ?? '',
      nomorTelepon: json['nomor_telepon']?.toString() ?? '',
      alamatLengkap: json['alamat_lengkap']?.toString() ?? '',
      kota: json['kota']?.toString() ?? '',
      provinsi: json['provinsi']?.toString() ?? '',
      kodePos: json['kode_pos']?.toString() ?? '',
      kodeProvinsi: _nullableString(json['kode_provinsi']),
      kodeKabupatenKota: _nullableString(json['kode_kabupaten_kota']),
      kodeKecamatan: _nullableString(json['kode_kecamatan']),
      kodeDesaKelurahan: _nullableString(json['kode_desa_kelurahan']),
      kabupatenKota: _nullableString(json['kabupaten_kota']),
      kecamatan: _nullableString(json['kecamatan']),
      desaKelurahan: _nullableString(json['desa_kelurahan']),
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
      alamatUtama: _parseBool(json['alamat_utama']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return value.toString();
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
