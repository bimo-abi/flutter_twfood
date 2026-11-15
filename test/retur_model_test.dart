import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/models/retur.dart';

void main() {
  group('ReturnRequest.fromJson', () {
    test('membaca instruksi pengembalian dan bukti privat', () {
      final retur = ReturnRequest.fromJson({
        'id_retur': 12,
        'id_pesanan': 34,
        'nomor_retur': 'RTR-001',
        'alasan_retur': 'Produk rusak',
        'status_retur': 'menunggu_pengembalian_barang',
        'status_pengembalian_dana': 'belum_diproses',
        'nominal_pengembalian': 150000,
        'metode_pengembalian': 'kurir',
        'instruksi_pengembalian': 'Kirim kembali melalui kurir.',
        'pesanan': {'id_pesanan': 34, 'nomor_pesanan': 'ORD-001'},
        'detail_retur': [
          {
            'id_detail_pesanan': 5,
            'jumlah_diminta': 2,
            'jumlah_disetujui': 2,
            'jumlah_diretur': 2,
            'detail_pesanan': {
              'nama_produk_saat_pesan': 'Keripik',
              'nama_varian_saat_pesan': 'Pedas',
            },
          },
        ],
        'bukti_retur': [
          {
            'id_bukti_retur': 9,
            'jenis_media': 'foto',
            'url_bukti': 'http://localhost/api/retur/bukti/9',
          },
        ],
      });

      expect(retur.metodePengembalian, 'kurir');
      expect(retur.instruksiPengembalian, 'Kirim kembali melalui kurir.');
      expect(retur.items, hasLength(1));
      expect(retur.proofs, hasLength(1));
      expect(retur.proofs.first.urlBukti,
          'http://localhost/api/retur/bukti/9');
    });
  });
}
