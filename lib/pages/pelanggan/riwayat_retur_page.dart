import 'package:flutter/material.dart';

import '../../models/retur.dart';
import '../../services/retur_service.dart';
import 'detail_retur_page.dart';

class RiwayatReturPage extends StatefulWidget {
  const RiwayatReturPage({super.key});

  @override
  State<RiwayatReturPage> createState() => _RiwayatReturPageState();
}

class _RiwayatReturPageState extends State<RiwayatReturPage> {
  List<ReturnRequest> _returns = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loadingMore) return;
    if (refresh) {
      setState(() { _loading = true; _error = null; });
    }
    try {
      final result = await ReturnService.getHistory(page: refresh ? 1 : _page);
      if (!mounted) return;
      setState(() {
        _returns = result.returns;
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final result = await ReturnService.getHistory(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _returns.addAll(result.returns);
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Retur'), actions: [IconButton(onPressed: () => _load(refresh: true), icon: const Icon(Icons.refresh), tooltip: 'Muat ulang')]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _returns.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: () => _load(refresh: true), child: const Text('Coba lagi'))])))
              : _returns.isEmpty
                  ? RefreshIndicator(onRefresh: () => _load(refresh: true), child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 140), Icon(Icons.assignment_outlined, size: 60, color: Colors.grey), SizedBox(height: 12), Center(child: Text('Belum ada pengajuan retur.'))]))
                  : RefreshIndicator(
                      onRefresh: () => _load(refresh: true),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _returns.length + (_page < _lastPage ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _returns.length) {
                            return Center(
                              child: OutlinedButton(
                                onPressed: _loadingMore ? null : _loadMore,
                                child: _loadingMore
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Muat lainnya'),
                              ),
                            );
                          }
                          final item = _returns[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(item.nomorRetur, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text('Pesanan: ${item.nomorPesanan ?? item.idPesanan}\nStatus: ${_status(item.statusRetur)}\nBukti: ${item.proofs.length} file')),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailReturPage(idRetur: item.idRetur))),
                            ),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: !_loading && _returns.isNotEmpty ? Padding(padding: const EdgeInsets.all(12), child: Text('Menampilkan ${_returns.length} dari $_total pengajuan', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))) : null,
    );
  }
}

String _status(String value) => value.replaceAll('_', ' ');
