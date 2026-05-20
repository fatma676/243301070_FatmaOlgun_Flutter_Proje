import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'urun_detay.dart';

class KategoriUrunleriSayfasi extends StatefulWidget {
  final String kategoriAdi;

  const KategoriUrunleriSayfasi({super.key, required this.kategoriAdi});

  @override
  State<KategoriUrunleriSayfasi> createState() => _KategoriUrunleriSayfasiState();
}

class _KategoriUrunleriSayfasiState extends State<KategoriUrunleriSayfasi> {
  bool _yukleniyor = true;
  List<dynamic> _urunler = [];
  final List<int> _favoriUrunIdleri = [];

  @override
  void initState() {
    super.initState();
    _urunleriGetir();
    _favoriListesiniGetir();
  }

  Future<void> _favoriListesiniGetir() async {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    if (email == null) return;

    try {
      final favoriData = await Supabase.instance.client
          .from('favoriler')
          .select('urunid')
          .eq('kullanici_mail', email);

      if (favoriData is List) {
        setState(() {
          _favoriUrunIdleri.clear();
          _favoriUrunIdleri.addAll(favoriData
              .where((item) =>
                  item is Map<String, dynamic> && item['urunid'] != null)
              .map<int>((item) => item['urunid'] as int));
        });
      }
    } catch (e) {
      debugPrint('Favori listesi alınamadı: $e');
    }
  }

  Future<void> _favoriToggle(int urunId, String urunAdi) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final supabase = Supabase.instance.client;
    final zatenFavori = _favoriUrunIdleri.contains(urunId);

    try {
      if (zatenFavori) {
        await supabase
            .from('favoriler')
            .delete()
            .eq('kullanici_mail', user.email!)
            .eq('urunid', urunId);

        await supabase.from('logs').insert({
          'islem': 'Favoriden kaldırıldı: $urunAdi',
          'kullanici_mail': user.email!,
        });

        if (mounted) {
          setState(() => _favoriUrunIdleri.remove(urunId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ürün favorilerden kaldırıldı!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        await supabase.from('favoriler').insert({
          'kullanici_mail': user.email,
          'urunid': urunId,
        });

        await supabase.from('logs').insert({
          'islem': 'Favoriye eklendi: $urunAdi',
          'kullanici_mail': user.email!,
        });

        if (mounted) {
          setState(() => _favoriUrunIdleri.add(urunId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ürün favorilere eklendi!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("İşlem sırasında hata oluştu: $e"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _urunleriGetir() async {
    try {
      final supabase = Supabase.instance.client;

      final kategoriData = await supabase
          .from('kategori')
          .select('kategoriid')
          .eq('kategoriadi', widget.kategoriAdi)
          .single();

      final int kategoriId = kategoriData['kategoriid'];

      final urunlerData = await supabase
          .from('urun')
          .select('*')
          .eq('kategoriid', kategoriId)
          .order('urunadi', ascending: true);

      setState(() {
        _urunler = urunlerData;
        _yukleniyor = false;
      });
    } catch (e) {
      debugPrint("Hata oluştu: $e");
      setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.kategoriAdi,
          style: const TextStyle(
              color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
        ),
      ),
      body: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _urunler.isEmpty
              ? const Center(
                  child: Text("Bu kategoride henüz ürün bulunmuyor."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _urunler.length,
                  itemBuilder: (context, index) {
                    final urun = _urunler[index];
                    final String durum = urun['durum'];
                    final String urunAdi = urun['urunadi'] ?? '';

                    Color durumRengi = Colors.grey;
                    if (durum == 'Helal') durumRengi = Colors.green;
                    if (durum == 'Şüpheli') durumRengi = Colors.orange;
                    if (durum == 'Haram') durumRengi = Colors.red;

                    final bool favori =
                        _favoriUrunIdleri.contains(urun['urunid']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UrunDetaySayfasi(
                                urun: Map<String, dynamic>.from(urun),
                              ),
                            ),
                          );
                        },
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: durumRengi.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.inventory_2, color: durumRengi),
                        ),
                        title: Text(
                          urunAdi,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Barkod: ${urun['barkod']}"),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: durumRengi,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                durum,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            favori ? Icons.favorite : Icons.favorite_border,
                            color: Colors.green,
                          ),
                          onPressed: () => _favoriToggle(urun['urunid'], urunAdi),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}