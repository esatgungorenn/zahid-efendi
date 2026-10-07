# LGS Deneme Takip — Spec v1.0

## Problem
Babam her haftaki LGS deneme sonuçlarını Excel'de takip ediyor. Amaç: veriyi kolay giren, ilerlemeyi grafiklerle gösteren ve son denemeye göre girilebilecek liseleri listeleyen bir Android uygulaması.

## Kullanıcı
- Tek kullanıcı: baba (teknik değil), tek telefon. Büyük yazı, az buton, Türkçe, hatalı giriş engellenir.

## Kararlar
- Flutter → Android APK. GitHub Actions ile derlenir, Releases'tan indirilir.
- Tamamen çevrimdışı: deneme verisi cihazda tek JSON dosyası (az kayıt; SQLite gereksiz); lise tablosu APK içinde gömülü (assets). İnternet izni yok.
- Yedek: JSON dışa/içe aktarma (paylaş menüsü).
- Uygulama boş başlar; geçmiş denemeleri baba kendisi girer.
- Dersler: Türkçe 20, Matematik 20, Fen 20, İnkılap 10, Din 10, İngilizce 10 (90 soru).
- Net = D − Y/3. Boş = soru − D − Y.
- Yüzdelik = sıralama / katılım × 100. Tek LGS puanı, tek genel sıralama.
- Trend okları: önceki denemeye göre. Yüzdelikte azalma = iyileşme (▲ yeşil).
- Palet C: koyu mor #3C3489, ana mor #534AB7, sarı vurgu #EF9F27, açık zemin #F6F5FC, artış #2E9E5B, düşüş #E24B4A, sabit #BA7517.

## Veri modeli
- Exam: id, ad, tarih, katılım, sıralama, lgsPuanı, dersler[6] {doğru, yanlış}
- Türetilen (saklanmaz): ders netleri, toplam net, yüzdelik
- School (gömülü, salt-okunur): ad, il, ilçe, tür, tabanPuan, tabanYüzdelik, (kontenjan)
- Settings: seçili iller, seçili okul türleri, liseler modu (yüzdelik/puan)

## Ekranlar (onaylı)
- [x] 1. Palet C
- [x] 2. Ana sayfa: son deneme başlık, 4 kart (LGS puanı, yüzdelik + sıra/katılım, toplam net, girebildiği lise sayısı → Liseler), ders net çubukları (<%75 sarı) + oklar, "Yeni deneme ekle" butonu; alt 4 sekme
- [x] 3. Deneme ekle/düzenle: sınav bilgisi (ad önerisi, tarih=bugün, katılım, sıra, puan, otomatik yüzdelik), ders başına D/Y −/+ (dokununca klavye), boş otomatik, canlı net, sınır kontrolü, Kaydet
- [x] 4. Denemeler: yeniden eskiye kartlar, kapalı: puan/yüzdelik/net + oklar + sıra; açık: D/Y/B/Net tablo, Düzenle/Sil (onaylı silme)
- [x] 5. Grafikler: sekmeler LGS puanı / Yüzdelik (ters eksen) / Toplam net / Dersler (ders seçimi, y=soru sayısı); altında tek cümle özet; dokununca değer
- [x] 6. Liseler:
  - Kaynak: son deneme
  - En üstte toggle: Yüzdeliğe göre ↔ Puana göre
    - Yüzdelik modu: tabanYüzdelik ≥ öğrenci yüzdeliği → girebilir; sıralama tabanYüzdelik artan
    - Puan modu: tabanPuan ≤ öğrenci puanı → girebilir; sıralama tabanPuan azalan
  - İl filtresi: çoklu seçim, 81 il aranabilir, seçim kalıcı
  - Okul türü filtresi: Fen / Anadolu / İmam Hatip / Mesleki (varsayılan hepsi)
  - "Biraz daha çalışırsa": yüzdelik modunda tabanı öğrencinin ≤%20 daha iyisi; puan modunda ≤15 puan üstü. Fark metni ("%x daha iyi olmalı" / "x puan daha")
  - Etiket: Sınırda (yüzdelik farkı <2 veya puan farkı <5) / Rahat

- Okul türlerine Sosyal Bilimler eklendi (gerçek LGS kategorisi).
- Veri: puan modu = 2026 resmi MEB taban puanları; yüzdelik modu = 2025 resmi yüzdelikler (2026 resmi yayımlanınca güncellenir). Ekranda yıl yazılır.
- Ad: Zahit Efendi; ikon: aile fotoğrafından.

## Uygulama adımları
- [x] Flutter iskeleti, tema, veri katmanı
- [x] Hesap modülü + birim testleri yazıldı (CI'da koşacak)
- [x] Ekranlar 2→6 + widget testleri yazıldı (CI'da koşacak)
- [x] Yedekleme (dışa/içe aktarma)
- [x] GitHub Actions: analyze + test + imzalı APK + Release
- [x] CI yeşil: analyze temiz, tüm testler geçiyor, APK derleniyor
- [x] Lise tablosu: 81 il, 3149 sınavlı program (tabanpuanlari.net; 2026 puan, 2025 yüzdelik)
- [ ] İmza secret'ları (kullanıcı ekleyecek) → imzalı Release
- [ ] Telefonda duman testi

## Notlar
- Bu ortamda Flutter SDK / pub.dev erişimi yok → tüm testler CI'da.
- android/ klasörünün yalnızca build.gradle.kts ve AndroidManifest.xml'i repoda; geri kalanı CI'da `flutter create` ile üretilir.
- İmza anahtarı repo dışında; GitHub secret olarak tutulur (ZE_KEYSTORE_BASE64, ZE_KEYSTORE_PASSWORD, ZE_KEY_ALIAS, ZE_KEY_PASSWORD).

## Review (07.10.2026)
- Testler iki gerçek taşma hatası yakaladı (ana sayfa kart ızgarası, liseler grup başlığı); düzeltildi, widget testleri 360dp genişlikte koşuyor.
- 144 programın 2025 yüzdeliği yok (yeni program); yalnızca puan modunda görünürler.
- Kaynak bazı aynı görünen programları ayrı listeliyor; isimlerine (2) eklendi.
