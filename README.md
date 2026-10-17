# Chargly

Chargly; pil ömrü tahmini ve pil kullanımı hakkında AI asistanı sunan Türkçe bir
Flutter web uygulamasıdır. Pil yüzdesi ve tüketim değerleri örnek hesaplamalardır;
uygulama cihazın gerçek pil seviyesini okumaz.

## Yerelde çalıştırma

Flutter kurulu proje klasöründe:

```sh
flutter pub get
flutter run -d chrome
```

Bu komut arayüzü tek başına açar. AI isteklerini yerelde denemek için proje
kökündeki `.env` dosyasına `KEDY_API_KEY=anahtarınız` ekleyin (bu dosyayı Git'e
göndermeyin) ve ikinci bir terminalde AI sunucusunu başlatın:

```sh
python -m uvicorn server:app --reload --port 8000
```

Yerelde `localhost` üzerinden açılan web uygulaması otomatik olarak bu API'yi
kullanır. Yayındaki web sitesi Cloudflare Pages Function'ı kullanmaya devam eder.
Yerel test boyunca Flutter ve AI sunucusu terminallerini açık tutun.

## Cloudflare Pages'e dağıtım

GitHub deposunu Cloudflare Pages'e bağlayıp şu ayarları kullanın:

- Build command:
  `git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter" && "$HOME/flutter/bin/flutter" build web --release`
- Build output directory: `build/web`
- Root directory: `/`
- **Settings > Variables and Secrets** bölümünde `KEDY_API_KEY` adlı bir secret
  tanımlayın.

Cloudflare Pages, depo kökündeki `functions/api/suggest.js` dosyasını otomatik
algılar ve `/api/suggest` olarak yayınlar. Önizleme ortamlarında da AI
kullanılacaksa aynı secret'ı preview ortamına da ekleyin.

## Kontroller

```sh
flutter analyze
flutter test
```
