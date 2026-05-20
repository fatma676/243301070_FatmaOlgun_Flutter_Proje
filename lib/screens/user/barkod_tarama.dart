import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase paketini ekledik

class BarkodTaramaSayfasi extends StatefulWidget {
  const BarkodTaramaSayfasi({super.key});

  @override
  State<BarkodTaramaSayfasi> createState() => _BarkodTaramaSayfasiState();
}

class _BarkodTaramaSayfasiState extends State<BarkodTaramaSayfasi> {
  bool _tarandiMi = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Barkod Tara"),
      ),
      body: Stack(
        children: [
          MobileScanner(
           
            onDetect: (capture) async {
              if (_tarandiMi) return;
              final barkod = capture.barcodes.firstOrNull?.rawValue;
              
              if (barkod != null) {
                setState(() => _tarandiMi = true);

                
                try {
                  final supabase = Supabase.instance.client;
                  await supabase.from('logs').insert({
                    'islem': 'Barkod tarandı: $barkod',
                    'kullanici_mail': supabase.auth.currentUser?.email ?? 'Bilinmeyen Kullanıcı',
                  });
                } catch (e) {
                  // Log tablosunda bir hata oluşursa tarama akışını bozmasın diye debug print 
                  debugPrint("Log yazma hatası: $e");
                }
                // ────────────────────────────────────────────────

                if (!mounted) return;
                Navigator.pop(context, barkod);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Icon(Icons.qr_code_scanner, color: Colors.white, size: 36),
                SizedBox(height: 12),
                Text(
                  "Barkodu çerçeve içine getirin",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}