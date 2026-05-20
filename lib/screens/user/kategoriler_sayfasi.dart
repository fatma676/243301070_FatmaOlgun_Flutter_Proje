import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'barkod_tarama.dart';
import 'components.dart';
import 'kategori_urunleri.dart';
import 'urun_detay.dart';

class KategorilerSayfasi extends StatefulWidget {
  const KategorilerSayfasi({super.key});

  @override
  State<KategorilerSayfasi> createState() => _KategorilerSayfasiState();
}

class _KategorilerSayfasiState extends State<KategorilerSayfasi> {
  final List<Map<String, dynamic>> kategoriler = [
    {'ad': 'Et Ürünleri', 'ikon': Icons.kebab_dining},
    {'ad': 'Süt Ürünleri', 'ikon': Icons.water_drop},
    {'ad': 'Atıştırmalık', 'ikon': Icons.cookie},
    {'ad': 'İçecek', 'ikon': Icons.local_drink},
    {'ad': 'Dondurulmuş Ürünler', 'ikon': Icons.icecream},
    {'ad': 'Baharat', 'ikon': Icons.eco},
    {'ad': 'Bakliyat', 'ikon': Icons.grain},
    {'ad': 'Soslar', 'ikon': Icons.soup_kitchen},
    {'ad': 'Unlu Mamuller', 'ikon': Icons.bakery_dining},
    {'ad': 'Yağlar', 'ikon': Icons.oil_barrel},
    {'ad': 'Konserve', 'ikon': Icons.inventory_2},
    {'ad': 'Tatlılar', 'ikon': Icons.cake},
    {'ad': 'Kahvaltılık', 'ikon': Icons.breakfast_dining},
    {'ad': 'Bebek Maması', 'ikon': Icons.child_care},
    {'ad': 'Hazır Yemek', 'ikon': Icons.fastfood},
  ];

  final TextEditingController _aramaController = TextEditingController();
  List<dynamic> _aramaSonuclari = [];
  bool _aramaYapiliyor = false;
  final List<int> _favoriUrunIdleri = [];

  @override
  void initState() {
    super.initState();
    _favoriListesiniGetir();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _barkodTara() async {
    final String? barkod = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarkodTaramaSayfasi()),
    );

    if (barkod != null && barkod.isNotEmpty) {
      _aramaController.text = barkod;
      _urunAra(barkod);
    }
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

      if (favoriData is List && mounted) {
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

    final zatenFavori = _favoriUrunIdleri.contains(urunId);
    final supabase = Supabase.instance.client;

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

  Future<void> _urunAra(String aramaMetni) async {
    if (aramaMetni.isEmpty) {
      setState(() => _aramaSonuclari = []);
      return;
    }
    setState(() => _aramaYapiliyor = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      final data = await supabase
          .from('urun')
          .select('*')
          .or('urunadi.ilike.$aramaMetni%,barkod.ilike.$aramaMetni%')
          .limit(10);

      // Arama logunu kaydet (sonuç varsa)
      if (user != null && (data as List).isNotEmpty) {
        await supabase.from('logs').insert({
          'islem': 'Ürün arandı: $aramaMetni',
          'kullanici_mail': user.email!,
        });
      }

      setState(() {
        _aramaSonuclari = data;
        _aramaYapiliyor = false;
      });
    } catch (e) {
      debugPrint("Arama hatası: $e");
      setState(() => _aramaYapiliyor = false);
    }
  }

  Widget _aramaSonucListesi() {
    if (_aramaYapiliyor) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (_aramaSonuclari.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            "Sonuç bulunamadı.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _aramaSonuclari.length,
      itemBuilder: (context, index) {
        final urun = _aramaSonuclari[index];
        final String durum = urun['durum'] ?? '';
        final int urunId = urun['urunid'];
        final String urunAdi = urun['urunadi'] ?? '';
        final bool favori = _favoriUrunIdleri.contains(urunId);

        Color durumRengi = Colors.grey;
        if (durum == 'Helal') durumRengi = Colors.green;
        if (durum == 'Şüpheli') durumRengi = Colors.orange;
        if (durum == 'Haram') durumRengi = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Text("Barkod: ${urun['barkod'] ?? ''}"),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: durumRengi,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    durum,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                favori ? Icons.favorite : Icons.favorite_border,
                color: Colors.green,
              ),
              onPressed: () => _favoriToggle(urunId, urunAdi),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool aramaAktif = _aramaController.text.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 14),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  width: 46,
                  child: CustomPaint(painter: CrescentPainter()),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Helal Gıda Sorgulama",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: TextField(
                            controller: _aramaController,
                            onChanged: _urunAra,
                            decoration: InputDecoration(
                              hintText: "Ürün adı veya barkod yazın...",
                              prefixIcon: const Icon(Icons.search, color: Colors.green),
                              suffixIcon: aramaAktif
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _aramaController.clear();
                                        setState(() => _aramaSonuclari = []);
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _barkodTara,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Okut"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      aramaAktif ? "Arama Sonuçları" : "Kategoriler",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (aramaAktif) _aramaSonucListesi(),
              ],
            ),
          ),
        ),
        if (!aramaAktif)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KategoriUrunleriSayfasi(
                            kategoriAdi: kategoriler[index]['ad'],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            kategoriler[index]['ikon'],
                            color: const Color(0xFF2E7D32),
                            size: 35,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kategoriler[index]['ad'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: kategoriler.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}