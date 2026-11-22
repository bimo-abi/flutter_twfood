class User {
  final int idPengguna;
  final String nama;
  final String email;
  final String nomorTelepon;
  final String peran;
  final String jenisPelanggan;
  final bool? statusAktif;
  final String? statusVerifikasi;
  final String? fotoProfil;

  const User({
    required this.idPengguna,
    required this.nama,
    required this.email,
    required this.nomorTelepon,
    required this.peran,
    required this.jenisPelanggan,
    this.statusAktif,
    this.statusVerifikasi,
    this.fotoProfil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idPengguna: (json['id_pengguna'] as num).toInt(),
      nama: json['nama']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nomorTelepon: json['nomor_telepon']?.toString() ?? '',
      peran: json['peran']?.toString() ?? '',
      jenisPelanggan: json['jenis_pelanggan']?.toString() ?? '',
      statusAktif: json['status_aktif'] as bool?,
      statusVerifikasi: json['status_verifikasi'] as String?,
      fotoProfil: json['foto_profil'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_pengguna': idPengguna,
    'nama': nama,
    'email': email,
    'nomor_telepon': nomorTelepon,
    'peran': peran,
    'jenis_pelanggan': jenisPelanggan,
    'status_aktif': statusAktif,
    'status_verifikasi': statusVerifikasi,
    'foto_profil': fotoProfil,
  };
}
