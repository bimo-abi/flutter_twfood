class User {
  final int idPengguna;
  final String nama;
  final String email;
  final String nomorTelepon;
  final String peran;
  final String jenisPelanggan;
  final bool? statusAktif;

  const User({
    required this.idPengguna,
    required this.nama,
    required this.email,
    required this.nomorTelepon,
    required this.peran,
    required this.jenisPelanggan,
    this.statusAktif,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idPengguna: json['id_pengguna'],
      nama: json['nama'],
      email: json['email'],
      nomorTelepon: json['nomor_telepon'],
      peran: json['peran'],
      jenisPelanggan: json['jenis_pelanggan'],
      statusAktif: json['status_aktif'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pengguna': idPengguna,
      'nama': nama,
      'email': email,
      'nomor_telepon': nomorTelepon,
      'peran': peran,
      'jenis_pelanggan': jenisPelanggan,
      'status_aktif': statusAktif,
    };
  }
}