import 'package:flutter/material.dart';

import '../../models/mitra_retur.dart';
import '../../services/mitra_retur_service.dart';
import '../../theme/app_colors.dart';
import 'detail_refund_mitra_page.dart';

class DetailReturMitraPage extends StatefulWidget {
  final int idRetur;

  const DetailReturMitraPage({super.key, required this.idRetur});

  @override
  State<DetailReturMitraPage> createState() => _DetailReturMitraPageState();
}

class _DetailReturMitraPageState extends State<DetailReturMitraPage> {
  late Future<MitraRetur> _future;
  bool _isSubmittingDecision = false;
  bool _isSubmittingInstruction = false;
  bool _isConfirmingReceipt = false;
  bool _isInspectingGoods = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = MitraReturService.fetchDetail(widget.idRetur);
  }

  String _rupiah(dynamic value) {
    final number = int.tryParse(value?.toString() ?? '') ?? 0;
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _line(String label, dynamic value) {
    final text = value?.toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(text == null || text.isEmpty ? '-' : text)),
        ],
      ),
    );
  }

  Future<void> _openDecisionDialog({
    required MitraRetur retur,
    required bool approve,
  }) async {
    final catatanController = TextEditingController();
    final alasanController = TextEditingController();

    final quantityControllers = retur.detailRetur.map((item) {
      final jumlah =
          int.tryParse(
            (item['jumlah_diminta'] ?? item['jumlah_diretur'])?.toString() ??
                '',
          ) ??
          0;

      return TextEditingController(text: jumlah.toString());
    }).toList();

    String? validationError;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  approve ? 'Setujui Pengajuan Retur' : 'Tolak Pengajuan Retur',
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (approve) ...[
                          const Text(
                            'Tentukan jumlah barang yang disetujui '
                            'untuk setiap item.',
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(retur.detailRetur.length, (index) {
                            final item = retur.detailRetur[index];
                            final detail = item['detail_pesanan'];
                            final detailMap = detail is Map
                                ? Map<String, dynamic>.from(detail)
                                : <String, dynamic>{};

                            final nama =
                                detailMap['nama_produk_saat_pesan']
                                    ?.toString() ??
                                detailMap['nama_produk']?.toString() ??
                                'Produk';

                            final diminta =
                                int.tryParse(
                                  (item['jumlah_diminta'] ??
                                              item['jumlah_diretur'])
                                          ?.toString() ??
                                      '',
                                ) ??
                                0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text('Jumlah diminta: $diminta'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: quantityControllers[index],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Jumlah disetujui',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ] else ...[
                          const Text(
                            'Tuliskan alasan penolakan pengajuan retur.',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: alasanController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Alasan penolakan *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: catatanController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Catatan Mitra (opsional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (validationError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            validationError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!approve && alasanController.text.trim().length < 5) {
                        setDialogState(() {
                          validationError =
                              'Alasan penolakan minimal 5 karakter.';
                        });
                        return;
                      }

                      if (approve) {
                        var totalDisetujui = 0;
                        var valid = true;

                        for (var i = 0; i < retur.detailRetur.length; i++) {
                          final item = retur.detailRetur[i];
                          final diminta =
                              int.tryParse(
                                (item['jumlah_diminta'] ??
                                            item['jumlah_diretur'])
                                        ?.toString() ??
                                    '',
                              ) ??
                              0;
                          final jumlah = int.tryParse(
                            quantityControllers[i].text.trim(),
                          );

                          if (jumlah == null ||
                              jumlah < 0 ||
                              jumlah > diminta) {
                            valid = false;
                            break;
                          }

                          totalDisetujui += jumlah;
                        }

                        if (!valid) {
                          setDialogState(() {
                            validationError = 'Jumlah harus berupa angka 0 sampai jumlah diminta.';
                          });
                          return;
                        }

                        if (totalDisetujui < 1) {
                          setDialogState(() {
                            validationError =
                                'Minimal satu barang harus disetujui.';
                          });
                          return;
                        }
                      }

                      Navigator.pop(dialogContext, true);
                    },
                    child: Text(approve ? 'Setujui' : 'Tolak Retur'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() {
        _isSubmittingDecision = true;
      });

      final detailRetur = approve
          ? List.generate(retur.detailRetur.length, (index) {
              return {
                'id_detail_retur': retur.detailRetur[index]['id_detail_retur'],
                'jumlah_disetujui': int.parse(
                  quantityControllers[index].text.trim(),
                ),
              };
            })
          : null;

      await MitraReturService.submitDecision(
        idRetur: retur.idRetur,
        keputusan: approve ? 'disetujui' : 'ditolak',
        catatanMitra: catatanController.text.trim().isEmpty
            ? null
            : catatanController.text.trim(),
        alasanPenolakan: approve ? null : alasanController.text.trim(),
        detailRetur: detailRetur,
      );

      if (!mounted) return;

      setState(_load);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Pengajuan retur berhasil disetujui.'
                : 'Pengajuan retur berhasil ditolak.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      catatanController.dispose();
      alasanController.dispose();

      for (final controller in quantityControllers) {
        controller.dispose();
      }

      if (mounted) {
        setState(() {
          _isSubmittingDecision = false;
        });
      }
    }
  }

  Widget _decisionSection(MitraRetur retur) {
    if (retur.statusRetur != 'menunggu_persetujuan') {
      return const SizedBox.shrink();
    }

    return _section('Keputusan Pengajuan', [
      const Text(
        'Periksa alasan dan rincian barang sebelum menentukan keputusan.',
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmittingDecision
                  ? null
                  : () => _openDecisionDialog(retur: retur, approve: false),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Tolak'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmittingDecision
                  ? null
                  : () => _openDecisionDialog(retur: retur, approve: true),
              child: _isSubmittingDecision
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Setujui'),
            ),
          ),
        ],
      ),
    ]);
  }

  Future<void> _openInstructionDialog(MitraRetur retur) async {
    final controller = TextEditingController();
    String metodePengembalian = 'outlet';
    String? validationError;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Instruksi Pengembalian Barang'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pilih metode pengembalian barang.'),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: metodePengembalian,
                        decoration: const InputDecoration(
                          labelText: 'Metode Pengembalian',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'outlet',
                            child: Text('Diantar ke Outlet'),
                          ),
                          DropdownMenuItem(
                            value: 'kurir',
                            child: Text('Melalui Kurir'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              metodePengembalian = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 3000,
                        decoration: const InputDecoration(
                          labelText: 'Instruksi Pengembalian *',
                          hintText: 'Tuliskan petunjuk pengembalian barang...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          validationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().length < 5) {
                        setDialogState(() {
                          validationError = 'Instruksi minimal 5 karakter.';
                        });
                        return;
                      }

                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Kirim Instruksi'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() {
        _isSubmittingInstruction = true;
      });

      await MitraReturService.submitReturnInstruction(
        idRetur: retur.idRetur,
        metodePengembalian: metodePengembalian,
        instruksiPengembalian: controller.text.trim(),
      );

      if (!mounted) return;

      setState(_load);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instruksi pengembalian berhasil dikirim.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      controller.dispose();

      if (mounted) {
        setState(() {
          _isSubmittingInstruction = false;
        });
      }
    }
  }

  Widget _instructionSection(MitraRetur retur) {
    if (retur.statusRetur != 'disetujui') {
      return const SizedBox.shrink();
    }

    return _section('Instruksi Pengembalian Barang', [
      const Text(
        'Pengajuan retur telah disetujui. '
        'Tentukan cara dan petunjuk pengembalian barang kepada pelanggan.',
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSubmittingInstruction
              ? null
              : () => _openInstructionDialog(retur),
          icon: _isSubmittingInstruction
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.local_shipping_outlined),
          label: Text(
            _isSubmittingInstruction
                ? 'Mengirim...'
                : 'Kirim Instruksi Pengembalian',
          ),
        ),
      ),
    ]);
  }

  Future<void> _confirmReceipt(MitraRetur retur) async {
    final controller = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Konfirmasi Barang Diterima'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pastikan barang retur sudah diterima secara fisik '
                    'sebelum melakukan konfirmasi.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Penerimaan (opsional)',
                      hintText: 'Contoh: Barang diterima dalam kondisi baik.',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Konfirmasi Diterima'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() {
        _isConfirmingReceipt = true;
      });

      await MitraReturService.confirmReturnReceived(
        idRetur: retur.idRetur,
        catatanPenerimaan: controller.text.trim().isEmpty
            ? null
            : controller.text.trim(),
      );

      if (!mounted) return;

      setState(_load);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penerimaan barang retur berhasil dikonfirmasi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      controller.dispose();

      if (mounted) {
        setState(() {
          _isConfirmingReceipt = false;
        });
      }
    }
  }

  Widget _receiptSection(MitraRetur retur) {
    if (retur.statusRetur != 'menunggu_pengembalian_barang') {
      return const SizedBox.shrink();
    }

    return _section('Konfirmasi Penerimaan Barang', [
      const Text(
        'Konfirmasikan setelah barang retur benar-benar diterima. '
        'Barang selanjutnya akan memasuki tahap pemeriksaan kondisi.',
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isConfirmingReceipt ? null : () => _confirmReceipt(retur),
          icon: _isConfirmingReceipt
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.inventory_2_outlined),
          label: Text(
            _isConfirmingReceipt
                ? 'Mengonfirmasi...'
                : 'Konfirmasi Barang Diterima',
          ),
        ),
      ),
    ]);
  }


  Future<void> _openInspectionDialog(MitraRetur retur) async {
    final catatanController = TextEditingController();
    final quantityControllers = retur.detailRetur.map((item) {
      return TextEditingController(text: '0');
    }).toList();
    String? validationError;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Pemeriksaan Barang Retur'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Periksa kondisi setiap barang. Masukkan jumlah '
                          'yang masih layak dijual untuk masing-masing item. '
                          'Nilai awal 0 agar barang tidak otomatis dianggap layak.',
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(retur.detailRetur.length, (index) {
                          final item = retur.detailRetur[index];
                          final detail = item['detail_pesanan'];
                          final detailMap = detail is Map
                              ? Map<String, dynamic>.from(detail)
                              : <String, dynamic>{};
                          final nama =
                              detailMap['nama_produk_saat_pesan']?.toString() ??
                                detailMap['nama_produk']?.toString() ??
                              'Produk';
                          final jumlahDisetujui = int.tryParse(
                                item['jumlah_disetujui']?.toString() ?? '',
                              ) ??
                              0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text('Jumlah disetujui: $jumlahDisetujui'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: quantityControllers[index],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah layak dijual (0–$jumlahDisetujui)',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        TextField(
                          controller: catatanController,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            labelText: 'Catatan pemeriksaan (opsional)',
                            hintText: 'Tuliskan kondisi barang hasil pemeriksaan...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (validationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            validationError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      for (var i = 0; i < retur.detailRetur.length; i++) {
                        final item = retur.detailRetur[i];
                        final maxQty = int.tryParse(
                              item['jumlah_disetujui']?.toString() ?? '',
                            ) ??
                            0;
                        final qty = int.tryParse(
                          quantityControllers[i].text.trim(),
                        );
                        if (qty == null || qty < 0 || qty > maxQty) {
                          setDialogState(() {
                            validationError =
                                'Jumlah layak dijual harus berupa angka 0 sampai jumlah disetujui.';
                          });
                          return;
                        }
                        if (int.tryParse(
                              item['id_detail_retur']?.toString() ?? '',
                            ) ==
                            null) {
                          setDialogState(() {
                            validationError =
                                'ID rincian retur tidak valid. Muat ulang detail retur.';
                          });
                          return;
                        }
                      }
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Simpan Pemeriksaan'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() {
        _isInspectingGoods = true;
      });

      final detailInspeksi = List.generate(retur.detailRetur.length, (index) {
        return {
          'id_detail_retur': int.parse(
            retur.detailRetur[index]['id_detail_retur'].toString(),
          ),
          'jumlah_layak_dijual': int.parse(
            quantityControllers[index].text.trim(),
          ),
        };
      });

      await MitraReturService.inspectReturnedGoods(
        idRetur: retur.idRetur,
        catatanPemeriksaan: catatanController.text.trim().isEmpty
            ? null
            : catatanController.text.trim(),
        detailInspeksi: detailInspeksi,
      );

      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasil pemeriksaan barang berhasil disimpan.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      catatanController.dispose();
      for (final controller in quantityControllers) {
        controller.dispose();
      }
      if (mounted) {
        setState(() {
          _isInspectingGoods = false;
        });
      }
    }
  }

  Widget _inspectionSection(MitraRetur retur) {
    if (retur.statusRetur != 'barang_diterima') {
      return const SizedBox.shrink();
    }

    return _section('Pemeriksaan Kondisi Barang', [
      const Text(
        'Periksa setiap item dan tentukan jumlah yang masih layak dijual. '
        'Laravel akan menambahkan jumlah layak jual ke stok dan menghitung refund.',
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isInspectingGoods ? null : () => _openInspectionDialog(retur),
          icon: _isInspectingGoods
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fact_check_outlined),
          label: Text(
            _isInspectingGoods ? 'Menyimpan...' : 'Periksa Kondisi Barang',
          ),
        ),
      ),
    ]);
  }

  Widget _buildDetail(MitraRetur retur) {
    final order = retur.pesanan;
    final customer = order['pengguna'];
    final customerName = customer is Map
        ? customer['nama']?.toString() ?? '-'
        : '-';
    final orderNumber = order['nomor_pesanan']?.toString() ?? '-';

    return RefreshIndicator(
      onRefresh: () async {
        setState(_load);
        await _future;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _section('Informasi Retur', [
            _line('Nomor retur', retur.nomorRetur),
            _line('Status', MitraRetur.statusLabel(retur.statusRetur)),
            _line('Nomor pesanan', orderNumber),
            _line('Pelanggan', customerName),
            _line('Tanggal pengajuan', retur.diajukanPada),
            _line('Alasan', retur.alasanRetur),
            _line('Catatan Mitra', retur.catatanMitra),
          ]),

          if (retur.statusRetur == 'menunggu_persetujuan') ...[
            const SizedBox(height: 12),
            _decisionSection(retur),
          ],
          if (retur.statusRetur == 'disetujui') ...[
            const SizedBox(height: 12),
            _instructionSection(retur),
          ],
          if (retur.statusRetur == 'menunggu_pengembalian_barang') ...[
            const SizedBox(height: 12),
            _receiptSection(retur),
          ],
          if (retur.statusRetur == 'barang_diterima') ...[
            const SizedBox(height: 12),
            _inspectionSection(retur),
          ],
          const SizedBox(height: 12),
          _section('Rincian Barang', [
            if (retur.detailRetur.isEmpty)
              const Text('Tidak ada rincian barang.')
            else
              ...retur.detailRetur.map((item) {
                final detail = item['detail_pesanan'];
                final detailMap = detail is Map
                    ? Map<String, dynamic>.from(detail)
                    : {};
                final nama =
                    detailMap['nama_produk_saat_pesan']?.toString() ??
                    detailMap['nama_produk']?.toString() ??
                    'Produk';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      _line(
                        'Jumlah diminta',
                        item['jumlah_diminta'] ?? item['jumlah_diretur'],
                      ),
                      _line('Jumlah disetujui', item['jumlah_disetujui']),
                      if (item['jumlah_layak_dijual'] != null)
                        _line('Jumlah layak dijual', item['jumlah_layak_dijual']),
                      _line('Alasan item', item['alasan_item']),
                      _line('Nominal refund', _rupiah(item['nominal_refund'])),
                    ],
                  ),
                );
              }),
          ]),
          const SizedBox(height: 12),
          _section('Bukti Retur', [
            if (retur.buktiRetur.isEmpty)
              const Text('Tidak ada bukti yang dilampirkan.')
            else
              ...retur.buktiRetur.map(
                (bukti) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    bukti['jenis_media'] == 'video'
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    color: AppColors.secondary,
                  ),
                  title: Text(
                    bukti['jenis_media']?.toString() == 'video'
                        ? 'Bukti video'
                        : 'Bukti foto',
                  ),
                  subtitle: const Text(
                    'Berkas tersimpan secara privat di server.',
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          _section('Informasi Pengembalian Dana', [
            _line('Status refund', retur.statusPengembalianDana),
            _line('Nominal refund', _rupiah(retur.nominalPengembalian)),
            if (retur.refund.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Divider(),
              const Text(
                'Rincian proses refund',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...retur.refund.map((item) {
                final idRefund =
                    int.tryParse(item['id_refund']?.toString() ?? '') ?? 0;
                final nominal = item['nominal_refund'];
                final status =
                    item['status_refund']?.toString() ?? 'belum_diajukan';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line('Refund #$idRefund', _rupiah(nominal)),
                      _line('Status', status.replaceAll('_', ' ')),
                      if (idRefund > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailRefundMitraPage(
                                    idRefund: idRefund,
                                  ),
                                ),
                              );
                              if (mounted) setState(_load);
                            },
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            label: const Text('Buka proses refund'),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Rincian refund belum tersedia. Periksa kembali setelah inspeksi barang selesai.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Retur')),
      body: FutureBuilder<MitraRetur>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildDetail(snapshot.data!);
        },
      ),
    );
  }
}
