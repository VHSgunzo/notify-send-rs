#!/usr/bin/env bash

###-----------------------------------------------------###
### Setups ENV, Install Deps & Builds Binaries (+ upx)  ###
### This Script must be run as `root` (passwordless)    ###
### Assumptions: OS (Ubuntu) | Arch ($(uname -m) | aarch64)  ###
### Can also run in chroot | Docker (nix may not work)  ###
###-----------------------------------------------------###


##-------------------------------------------------------#
##Install CoreUtils & Deps
export DEBIAN_FRONTEND="noninteractive"
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
sudo apt update -y -qq
sudo apt install 7zip b3sum bc binutils binutils-aarch64-linux-gnu coreutils curl dos2unix fdupes jq moreutils wget -y -qq
sudo apt-get install apt-transport-https apt-utils b3sum bc binutils binutils-aarch64-linux-gnu ca-certificates coreutils dos2unix fdupes gnupg2 jq moreutils p7zip-full rename rsync software-properties-common texinfo tmux upx util-linux wget -y -qq 2>/dev/null ; sudo apt-get update -y 2>/dev/null
#Do again, sometimes fails
sudo apt install 7zip b3sum bc binutils binutils-aarch64-linux-gnu coreutils curl dos2unix fdupes jq moreutils wget -y -qq
sudo apt-get install apt-transport-https apt-utils b3sum bc binutils binutils-aarch64-linux-gnu ca-certificates coreutils dos2unix fdupes gnupg2 jq moreutils p7zip-full rename rsync software-properties-common texinfo tmux upx util-linux wget -y -qq2>/dev/null ; sudo apt-get update -y 2>/dev/null
##More Deps
sudo apt-get update -y -qq
sudo apt-get install autoconf automake autopoint binutils bison build-essential byacc ca-certificates ccache clang diffutils dos2unix gawk flex file imagemagick jq liblz-dev librust-lzma-sys-dev libsqlite3-dev libtool libtool-bin lzip lzma lzma-dev make musl musl-dev musl-tools p7zip-full patch patchelf pkg-config qemu-user-static rsync scons sqlite3 sqlite3-pcre sqlite3-tools texinfo wget -y -qq 2>/dev/null
#Re
sudo apt-get install autoconf automake autopoint binutils bison build-essential byacc ca-certificates ccache clang diffutils dos2unix gawk flex file imagemagick jq liblz-dev librust-lzma-sys-dev libsqlite3-dev libtool libtool-bin lzip lzma lzma-dev make musl musl-dev musl-tools p7zip-full patch patchelf pkg-config qemu-user-static rsync scons sqlite3 sqlite3-pcre sqlite3-tools texinfo wget -y -qq 2>/dev/null
sudo apt install python3-pip python3-venv -y -qq 2>/dev/null
pip install --break-system-packages --upgrade pip || pip install --upgrade pip
sudo apt install lm-sensors pciutils procps python3-distro python3-netifaces sysfsutils virt-what -y -qq 2>/dev/null
pip install build ansi2txt cffi pipx scons scuba py2static pytest typer --upgrade --force 2>/dev/null 
pip install build ansi2txt cffi pipx scons scuba py2static pytest typer --break-system-packages --upgrade --force 2>/dev/null
##-------------------------------------------------------#

##-------------------------------------------------------#
##ENV
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}" ; mkdir -p "${SYSTMP}/nix_builder"
TMPDIRS="mktemp -d --tmpdir=${SYSTMP}/nix_builder XXXXXXX_linux_$(uname -m)-$(uname -s)" && export TMPDIRS="${TMPDIRS}"
##Artifacts
ARTIFACTS="${SYSTMP}/ARTIFACTS-$(uname -m)-$(uname -s)" && export "ARTIFACTS=${ARTIFACTS}"
rm -rf "${ARTIFACTS}" 2>/dev/null ; mkdir -p "${ARTIFACTS}"
##User-Agent
USER_AGENT="$(curl -qfsSL 'https://pub.ajam.dev/repos/Azathothas/Wordlists/Misc/User-Agents/ua_chrome_macos_latest.txt')" && export USER_AGENT="${USER_AGENT}"
##-------------------------------------------------------#

##-------------------------------------------------------#
##Install Nix
##Official Installers break
#curl -qfsSL "https://nixos.org/nix/install" | bash -s -- --no-daemon
#source "$HOME/.bash_profile" ; source "$HOME/.nix-profile/etc/profile.d/nix.sh" ; . "$HOME/.nix-profile/etc/profile.d/nix.sh"
##https://github.com/DeterminateSystems/nix-installer
"/nix/nix-installer" uninstall --no-confirm 2>/dev/null
curl -qfsSL "https://install.determinate.systems/nix" | bash -s -- install linux --init none --no-confirm
source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
sudo chown --recursive "$(whoami)" "/nix"
echo "root    ALL=(ALL:ALL) ALL" | sudo tee -a "/etc/sudoers"
nix --version && nix-channel --list && nix-channel --update --cores "$(($(nproc)+1))" --quiet
##-------------------------------------------------------#

##-------------------------------------------------------#
##Install 7z
pushd "$($TMPDIRS)" >/dev/null 2>&1 && curl -A "${USER_AGENT}" -qfsSLJO "https://www.7-zip.org/$(curl -A "${USER_AGENT}" -qfsSL "https://www.7-zip.org/download.html" | grep -o 'href="[^"]*"' | sed 's/href="//' | grep -i "$(uname -s)-$(uname -m | sed 's/$(uname -m)/x64\\|$(uname -m)/;s/aarch64/arm64\\|aarch64/')" | sed 's/"$//' | sort -n -r | head -n 1)" 2>/dev/null
find "." -type f -name '*.xz' -exec tar -xf {} \; 2>/dev/null
sudo find "." -type f -name '7zzs' ! -name '*.xz' -exec mv {} "/usr/bin/7z" \; 2>/dev/null
sudo cp "/usr/bin/7z" "/usr/local/bin/7z" 2>/dev/null
sudo chmod +x "/usr/bin/7z" "/usr/local/bin/7z" 2>/dev/null ; 7z
popd >/dev/null 2>&1
##-------------------------------------------------------#

##-------------------------------------------------------#
##Install upX
pushd "$($TMPDIRS)" >/dev/null 2>&1
curl -qfLJO "$(curl -qfsSL https://api.github.com/repos/upx/upx/releases/latest | jq -r '.assets[].browser_download_url' | grep -i "$(uname -m | sed 's/$(uname -m)/amd64\\|$(uname -m)/;s/aarch64/arm64\\|aarch64/')_$(uname -s)")" 2>/dev/null
find "." -type f -name '*tar*' -exec tar -xvf {} \; 2>/dev/null
sudo find "." -type f -name 'upx' -exec mv {} "$(which upx)" \; 2>/dev/null
sudo chmod +x "$(which upx)" 2>/dev/null
popd >/dev/null 2>&1
##-------------------------------------------------------#

##-------------------------------------------------------#
##Setup Alpine Chroot
pushd "$($TMPDIRS)" >/dev/null 2>&1
BASE_DIR="$(realpath .)"
ALPINE_CHROOT="${BASE_DIR}/alpine" && mkdir -p "${ALPINE_CHROOT}"
BUILD_DIR="${BASE_DIR}/build" && mkdir -p "${BUILD_DIR}"
MISC_DIR="${BASE_DIR}/misc" && mkdir -p "${MISC_DIR}"
OUT_DIR="${BASE_DIR}/out" && mkdir -p "${OUT_DIR}"
ALPINE_DEPS="
  acl-static argp-standalone attr-static autoconf automake \
  b3sum bash bc bcc-static bind-tools binutils bison brotli-static build-base bzip2-static bzip3-static \
  clang clang-static cmake coreutils curl curl-dev curl-static \
  device-mapper-static diffutils dos2unix \
  elfutils execline execline-static expat-static expect ethtool\
  flex fontconfig-static fuse fuse-static fuse3-dev fuse3-static \
  gawk gcc gettext gettext-dev gettext-static git go glib-static gmp-dev gperf grep \
  imagemagick imagemagick-static iperf iputils itstool \
  jq json-c-dev json-glib-dev \
  keyutils \
  libarchive-static libcaca-static libc-dev libcap-static libcap-ng-static libcurl libelf-static libffi-dev libssh-dev libtasn1-dev libtool libtpms libtpms-dev linux-headers linux-tools lvm2-dev lvm2-static lz4 lz4-dev lz4-libs lz4-static \
  make mariadb-static mesa mesa-dev mesa-gbm meson mlocate mold moreutils musl musl-dev musl-fts musl-obstack-dev musl-utils \
  nano nasm ncurses ncurses-static nettle-static nghttp2-static ninja-build \
  openssl openssl-dev openssl-libs-static \
  patchelf pcre2 perl perl-xml-parser pkgconf pkgconfig popt-dev popt-static procps protobuf protobuf-c protobuf-c-compiler protobuf-dev python3 \
  readline readline-dev readline-static rsync \
  tar texinfo txt2man tzdata \
  unzip upx util-linux util-linux-dev util-linux-static \
  wget wolfssl wolfssl-dev wpa_supplicant \
  xxd xxhash xz xz-dev xz-libs xz-static \
  yaml yaml-dev yaml-static \
  zig zlib zlib-dev zlib-static zstd zstd-static"
curl -qfsSL "https://raw.githubusercontent.com/alpinelinux/alpine-chroot-install/master/alpine-chroot-install" -o "${ALPINE_CHROOT}/alpine-chroot-install" && chmod +x "${ALPINE_CHROOT}/alpine-chroot-install"
sudo "${ALPINE_CHROOT}/alpine-chroot-install" -d "${ALPINE_CHROOT}"
sudo "${ALPINE_CHROOT}/enter-chroot" apk update && apk upgrade --no-interactive 2>/dev/null
echo "$ALPINE_DEPS" | xargs sudo "${ALPINE_CHROOT}/enter-chroot" apk add --latest --upgrade --no-interactive
#Rust
sudo "${ALPINE_CHROOT}/enter-chroot" bash -c '
 pushd "$(mktemp -d)" >/dev/null 2>&1
 curl -qfsSL "https://sh.rustup.rs" -o "./rustup.sh"
 chmod +x "./rustup.sh"
 "./rustup.sh" -y
 source "$HOME/.cargo/env"
 cargo version'
popd >/dev/null 2>&1
##-------------------------------------------------------#


##-------------------------------------------------------#
##Build
#https://github.com/VHSgunzo/notify-send-rs/blob/main/.github/workflows/ci.yml
pushd "$($TMPDIRS)" >/dev/null 2>&1
sudo "${ALPINE_CHROOT}/enter-chroot" bash -c '
 #Setup ENV
  rm -rf  "/build-bins" 2>/dev/null ; mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
  source "$HOME/.cargo/env"
  export RUST_TARGET="$(uname -m)-unknown-linux-musl"
  rustup target add "$RUST_TARGET"
  export RUSTFLAGS="-C target-feature=+crt-static -C default-linker-libraries=yes -C link-self-contained=yes -C prefer-dynamic=no -C embed-bitcode=yes -C lto=yes -C opt-level=3 -C debuginfo=none -C strip=symbols -C linker=clang -C link-arg=-fuse-ld=$(which mold) -C link-arg=-Wl,--Bstatic -C link-arg=-Wl,--static -C link-arg=-Wl,-S -C link-arg=-Wl,--build-id=none"
 #Build
  git clone --filter "blob:none" --quiet "https://github.com/VHSgunzo/notify-send-rs" && cd "./notify-send-rs"
  echo -e "\n[+] Target: $RUST_TARGET\n"
  echo -e "\n[+] Flags: $RUSTFLAGS\n"
  sed "/^\[profile\.release\]/,/^$/d" -i "./Cargo.toml" ; echo -e "\n[profile.release]\nstrip = true\nopt-level = 3\nlto = true" >> "./Cargo.toml"
  rm rust-toolchain* 2>/dev/null
  cargo build --target "$RUST_TARGET" --release --jobs="$(($(nproc)+1))" --keep-going
  find "./target/$RUST_TARGET/release" -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath | xargs -I {} cp --force {} /build-bins/
  popd >/dev/null 2>&1
'
sudo rsync -av --copy-links --exclude="*/" "${ALPINE_CHROOT}/build-bins/." "${ARTIFACTS}"
#dbus
sudo "${ALPINE_CHROOT}/enter-chroot" bash -c '
 #Setup ENV
  rm -rf  "/build-bins" 2>/dev/null ; mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
  source "$HOME/.cargo/env"
  export RUST_TARGET="$(uname -m)-unknown-linux-musl"
  rustup target add "$RUST_TARGET"
  export RUSTFLAGS="-C target-feature=+crt-static -C default-linker-libraries=yes -C link-self-contained=yes -C prefer-dynamic=no -C embed-bitcode=yes -C lto=yes -C opt-level=3 -C debuginfo=none -C strip=symbols -C linker=clang -C link-arg=-fuse-ld=$(which mold) -C link-arg=-Wl,--Bstatic -C link-arg=-Wl,--static -C link-arg=-Wl,-S -C link-arg=-Wl,--build-id=none"
 #Build
  git clone --filter "blob:none" --quiet "https://github.com/VHSgunzo/notify-send-rs" && cd "./notify-send-rs"
  git tag --sort="-v:refname" | head -n 1 > "/build-bins/VERSION.txt"
  echo -e "\n[+] Target: $RUST_TARGET\n"
  echo -e "\n[+] Flags: $RUSTFLAGS\n"
  echo -e "\n[dependencies.dbus]\nversion = \"*\"\nfeatures = [\"vendored\"]" >> "./Cargo.toml"
  sed "/^\[profile\.release\]/,/^$/d" -i "./Cargo.toml" ; echo -e "\n[profile.release]\nstrip = true\nopt-level = 3\nlto = true" >> "./Cargo.toml"
  rm rust-toolchain* 2>/dev/null
  cargo build --target "$RUST_TARGET" --features d --no-default-features --release --jobs="$(($(nproc)+1))" --keep-going
  cp --force "./target/$RUST_TARGET/release/notify-send-rs" "/build-bins/notify-send-rs-dbus"
  popd >/dev/null 2>&1
'
sudo rsync -av --copy-links --exclude="*/" "${ALPINE_CHROOT}/build-bins/." "${ARTIFACTS}"
PKG_VERSION="$(cat "${ARTIFACTS}/VERSION.txt")" && export PKG_VERSION="${PKG_VERSION}"
sudo chown -R "$(whoami):$(whoami)" "${ARTIFACTS}" && chmod -R 755 "${ARTIFACTS}"
find "${ARTIFACTS}" -type f -name '*.sh' -delete 2>/dev/null
find "${ARTIFACTS}" -type f ! -name '*.txt' -exec bash -c 'mv "$0" "${0}-$(uname -m)-$(uname -s)"' {} \; 2>/dev/null
#Strip
find "${ARTIFACTS}" -type f -exec strip --strip-debug --strip-dwo --strip-unneeded -R ".comment" -R ".gnu.version" --preserve-dates "{}" \; 2>/dev/null
#upx
find "${ARTIFACTS}" -type f | xargs realpath | xargs -I {} upx --best "{}" -f --force-overwrite -o"{}.upx" -qq 2>/dev/null
#End
popd >/dev/null 2>&1
##-------------------------------------------------------#

##-------------------------------------------------------#
#Generate METADATA & Release Notes
pushd "${ARTIFACTS}" >/dev/null 2>&1
find "./" -maxdepth 1 -type f | sort | grep -v -E '\.txt$' | xargs file > "${ARTIFACTS}/FILE.txt"
find "./" -maxdepth 1 -type f | sort | grep -v -E '\.txt$' | xargs sha256sum > "${ARTIFACTS}/SHA256SUM.txt"
echo "${PKG_VERSION}" > "${ARTIFACTS}/VERSION.txt"
popd >/dev/null 2>&1
echo -e "\n[+] Built in $(realpath ${ARTIFACTS})\n"
ls "${ARTIFACTS}" -lah && echo -e "\n"
##-------------------------------------------------------#