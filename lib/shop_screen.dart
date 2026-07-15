import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SYSTEM SHOP',
          style: TextStyle(
            color: Colors.amber.shade400,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            shadows: [Shadow(color: Colors.amber.withOpacity(0.5), blurRadius: 15.0)],
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A00).withOpacity(0.3), // Nuansa emas gelap
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 30, spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.store, color: Colors.amber.withOpacity(0.2), size: 100),
                    const Icon(Icons.lock_outline, color: Colors.amber, size: 50),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'ACCESS DENIED',
                  style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4.0),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Fitur Penukaran Hadiah sedang dalam tahap pengembangan (Coming Soon).\n\nKumpulkan Gold Anda dari Misi Harian. System akan membuka kunci toko ini saat sumber daya di dunia nyata telah memadai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 14),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'STATUS: LOCKED',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}