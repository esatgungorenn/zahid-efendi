# Lessons

- Kart/ızgara düzenlerinde sabit en-boy oranı kullanma; dar ekranda ve büyük yazı boyutunda taşar. Widget testlerini 360dp genişlikte koş.
- Bu ortamda CI log'ları okunamıyor: başarısızlıkta log `ci-logs` dalına yayınlanıyor (`git fetch origin ci-logs:refs/remotes/origin/ci-logs`).
- Shell'den dış sitelere erişim yok; toplu veri gerekiyorsa GitHub Actions'ta çek, sonucu dala commit et.
