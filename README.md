# Zahit Efendi

LGS deneme sonuçlarını takip eden Android uygulaması (Flutter). Tamamen çevrimdışı çalışır.

- **Ana sayfa:** son deneme özeti, ders netleri, önceki denemeye göre değişim
- **Denemeler:** tüm denemeler, düzenle/sil, yedekle/geri yükle
- **Grafikler:** LGS puanı, yüzdelik, toplam net, ders bazlı net
- **Liseler:** son denemeye göre girilebilecek liseler (yüzdeliğe veya puana göre, il ve tür filtresi)

## APK

Her `main` push'unda GitHub Actions testleri çalıştırır, imzalı APK'yı derler ve **Releases** sayfasına koyar.

## Geliştirme

```
flutter create --project-name zahit_efendi --org com.esatgungoren --platforms android --no-pub .
flutter pub get
dart run flutter_launcher_icons
flutter test
```

Lise verisi: `assets/schools.json` (`scoreYear`, `percentileYear`, `schools[]`).
