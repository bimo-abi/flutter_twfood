import 'product.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  final ProductPrice price;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    required this.price,
    this.quantity = 1,
  });
  // Estimasi Campaign hanya untuk harga ecer; nominal final tetap dihitung Laravel.
  bool get memakaiCampaign {
    final campaign = variant.campaignAktif;
    if (price.jenisHarga != 'ecer' || campaign == null) return false;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final mulai = campaign.tanggalMulai == null ? null : DateTime(campaign.tanggalMulai!.year, campaign.tanggalMulai!.month, campaign.tanggalMulai!.day);
    final selesai = campaign.tanggalSelesai == null ? null : DateTime(campaign.tanggalSelesai!.year, campaign.tanggalSelesai!.month, campaign.tanggalSelesai!.day);
    return (mulai == null || !day.isBefore(mulai)) && (selesai == null || !day.isAfter(selesai));
  }
  int get diskonPerUnit => memakaiCampaign
      ? (price.harga * variant.campaignAktif!.nilaiPersen / 100 + 0.5).floor()
      : 0;
  int get diskonItem => diskonPerUnit * quantity;
  int get subtotal => price.harga * quantity;
  int get subtotalSetelahDiskon => subtotal - diskonItem;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      variant: variant,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}
