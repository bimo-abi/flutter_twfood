class Notifikasi {
  final int idNotifikasi;
  final String judul;
  final String pesan;
  final String jenis;
  final int? idReferensi;
  final String? jenisReferensi;
  final bool sudahDibaca;
  final DateTime? createdAt;

  const Notifikasi({
    required this.idNotifikasi,
    required this.judul,
    required this.pesan,
    required this.jenis,
    this.idReferensi,
    this.jenisReferensi,
    required this.sudahDibaca,
    this.createdAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      idNotifikasi: int.parse(json['id_notifikasi'].toString()),
      judul: json['judul']?.toString() ?? '',
      pesan: json['pesan']?.toString() ?? '',
      jenis: json['jenis']?.toString() ?? '',
      idReferensi: json['id_referensi'] == null
          ? null
          : int.tryParse(json['id_referensi'].toString()),
      jenisReferensi: json['jenis_referensi']?.toString(),
      sudahDibaca:
          json['sudah_dibaca'] == true ||
          json['sudah_dibaca'].toString() == '1',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
