#!/usr/bin/env bash
# Gün 1 (L0-Ü1-D1) ders fixture'ı.
# Gün 1'in lab'ı FHS turu + seedli /var/log/auth.log üzerinedir; ikisi de taban
# imajda (provision-base.sh) zaten hazır. Bu yüzden Gün 1 EK FIXTURE İSTEMEZ.
# (İleriki dersler -- bozuk servis, çökmüş LVM, patlayan CI -- burada gerçek
#  dosyalar üretecek. Bu boş dosya, o desenin yerini tutuyor ve zinciri gösteriyor.)
echo "Gün 1 için ek fixture gerekmiyor; taban ortam yeterli."
exit 0
