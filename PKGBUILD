# Maintainer: VHSgunzo <vhsgunzo.github.io>
pkgname='notify-send-rs'
pkgver='0.0.1'
pkgrel='1'
pkgdesc='Rust version of notify-send for display notifications on the linux desktop using notify-rust'
arch=("aarch64" "x86_64")
url="https://github.com/VHSgunzo/${pkgname}"
provides=("${pkgname}")
conflicts=("${pkgname}")
source=("https://github.com/VHSgunzo/${pkgname}/releases/download/v${pkgver}/${pkgname}-${CARCH}-Linux")
sha256sums=('SKIP')

package() {
    install -Dm755 "${pkgname}-${CARCH}-Linux" "$pkgdir/usr/bin/${pkgname}"
}