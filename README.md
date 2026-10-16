# claude-switch

Claude Code içinde birden fazla hesap arasında `!cs` ile geçiş yapmak için küçük bir araç.
Linux, WSL ve Windows (Git Bash) üzerinde çalışır.

```
!cs status          aktif hesap + tüm hesapların token durumu
!cs add <ad>        şu an giriş yapılı hesabı <ad> adıyla kaydet
!cs use <ad>        <ad> hesabına geç
!cs sync            aktif credentials'ı kendi slotuna geri yaz
!cs rm <ad>         hesabı sil
!cs restore         son yedeği geri yükle
!cs prune           !cs izlerini geçmişten temizle (--apply ile)
!cs help            tüm komutlar
```

## Kurulum

Gereksinimler: `git`, `bash`, `python3`. Windows'ta [Git for Windows](https://git-scm.com/download/win) (Git Bash) ve Python.

```bash
git clone <repo-adresi> ~/claude-switch      # Windows'ta Git Bash içinde çalıştır
~/claude-switch/install.sh
```

Kurulum şunları yapar:

1. `~/.local/bin/cs` → bu repodaki `bin/cs`'i çağıran küçük bir shim kurar
   (Windows'ta ayrıca PowerShell/cmd için `cs.cmd`).
2. `~/.claude/settings.json` içine ekler (diğer ayarlara dokunmaz, önce `.bak-*` yedeği alır):
   - `"respondToBashCommands": false` → `!cs` çalışınca model cevap vermez
   - Hook'lar: oturum başı/sonu ve her cevaptan sonra `cs autosync`
     (yenilenen token'ları hesabın slotuna yazar), açılışta `cs prune --apply`.

Tekrar çalıştırmak güvenlidir; hook'lar çiftlenmez. Sonra açık Claude oturumlarını yeniden başlat.

## Yeni bir bilgisayarda hesapları eklemek

Credentials bu repoda **yoktur** ve olmamalıdır. Her bilgisayarda hesapları bir kez ekle:

```
/login              # 1. hesapla giriş
!cs add is
/login              # 2. hesapla giriş
!cs add kisisel
!cs use is
```

`~/.claude/accounts/` klasörünü bilgisayarlar arasında **kopyalama**: refresh token'lar her
yenilemede değişir, iki makine aynı slotu paylaşırsa biri diğerinin oturumunu düşürür.

## Güncelleme

```bash
cd ~/claude-switch && git pull
```

Shim doğrudan repodaki script'i çağırdığı için yeniden kurmaya gerek yok.
Repoyu başka bir klasöre taşırsan `install.sh`'ı tekrar çalıştır.

## Kaldırma

```bash
rm ~/.local/bin/cs ~/.local/bin/cs.cmd
```

Ardından `~/.claude/settings.json` içinden `respondToBashCommands` satırını ve `cs` içeren hook'ları sil.
