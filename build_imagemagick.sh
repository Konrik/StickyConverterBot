#!/bin/bash

set -e

# Define versions and environment variables
UBUNTU_VERSION="22.04"
LIBDE265_VERSION="1.0.15"
LIBHEIF_VERSION="1.17.6"
IMAGEMAGICK_VERSION="7.1.1-33"
IMAGEMAGICK_EPOCH="8:"

# Create a directory for binaries
mkdir -p binaries

# Update and install build dependencies
apt update && apt -y install \
  autoconf \
  build-essential \
  checkinstall \
  cmake \
  curl \
  git \
  libtool \
  pkg-config \
  software-properties-common \
  wget

# Install libheif dependencies
LIBHEIF_DEPENDENCIES='libaom-dev,libx265-dev'
apt satisfy -y "$LIBHEIF_DEPENDENCIES"

# Install ImageMagick dependencies
IMAGEMAGICK_DEPENDENCIES='fonts-urw-base35,libbz2-dev,libfontconfig1-dev,libfreetype-dev,libglib2.0-dev,libgs-dev,libjpeg-turbo8-dev,liblcms2-dev,liblqr-1-0-dev,libltdl7,liblzma-dev,libopenexr-dev,libopenjp2-7-dev,libpng-dev,libraw-dev,libtiff-dev,libwebp-dev,libx11-dev,libxml2-dev,zlib1g'
apt satisfy -y "$IMAGEMAGICK_DEPENDENCIES"

# Build libde265 from source
git clone --depth 1 --branch v$LIBDE265_VERSION https://github.com/strukturag/libde265.git
cd libde265
./autogen.sh
./configure
make -j$(nproc)
checkinstall --pkgversion="$LIBDE265_VERSION" --fstrans=no
mv libde265_*.deb ../binaries/
pkg-config --exists --print-errors "libde265 = $LIBDE265_VERSION"
cd ..

# Build libheif from source
git clone --depth 1 --branch v$LIBHEIF_VERSION https://github.com/strukturag/libheif.git
cd libheif
mkdir build
cd build
cmake --preset=release ..
make -j$(nproc)
checkinstall --pkgname="libheif" --pkgversion="$LIBHEIF_VERSION" --requires="'$LIBHEIF_DEPENDENCIES, libde265 (>= $LIBDE265_VERSION)'" --fstrans=no
mv libheif_*.deb ../../binaries/
pkg-config --exists --print-errors "libheif = $LIBHEIF_VERSION"
cd ../..

# Set and validate ImageMagick epoch
if ! apt-cache show imagemagick | grep -q "Version: $IMAGEMAGICK_EPOCH"; then
  echo "ImageMagick epoch version mismatch."
  exit 1
fi

# Build ImageMagick from source
git clone --depth 1 --branch $IMAGEMAGICK_VERSION https://github.com/ImageMagick/ImageMagick.git imagemagick
cd imagemagick
./configure --disable-opencl --disable-silent-rules --enable-openmp --enable-shared --enable-static --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=no --with-heic=yes --with-lqr=yes --with-modules --with-openexr=yes --with-openjp2 --with-raw=yes --with-webp=yes --with-xml=yes --without-djvu --without-fftw --without-pango --without-wmf
make -j$(nproc)
checkinstall --pkgversion=$IMAGEMAGICK_EPOCH$(echo "$IMAGEMAGICK_VERSION" | cut -d- -f1) --pkgrelease=$(echo "$IMAGEMAGICK_VERSION" | cut -d- -f2) --requires="'$IMAGEMAGICK_DEPENDENCIES, libde265 (>= $LIBDE265_VERSION), libheif (>= $LIBHEIF_VERSION)'" --fstrans=no
ldconfig
mv imagemagick_*.deb ../binaries/
if [[ $(dpkg-query -W -f='${Version}' imagemagick) != $IMAGEMAGICK_EPOCH$IMAGEMAGICK_VERSION ]]; then
  echo "ImageMagick version mismatch."
  exit 1
fi
cd ..

# Add Ubuntu codename to the filenames
cd binaries
CODENAME=$( . /etc/os-release ; echo $UBUNTU_CODENAME)
for f in *; do mv -i -- "$f" "${f//_amd64/~${CODENAME}_amd64}"; done
cd ..

# Test package install
apt update && apt install -y software-properties-common
LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php
apt update && apt install -y imagemagick libmagickwand-dev php-pear php8.2 php8.2-cli php8.2-common php8.2-dev php8.2-xml
if ! php -v | grep -q "PHP 8.2"; then
  echo "PHP 8.2 installation failed."
  exit 1
fi
curl -o imagick.tgz https://pecl.php.net/get/imagick
printf "\n" | MAKEFLAGS="-j $(nproc)" pecl install ./imagick.tgz
echo extension=imagick.so > /etc/php/8.2/mods-available/imagick.ini
phpenmod imagick

# Installed ImageMagick version should not match built ImageMagick version
if [[ $(dpkg-query -W -f='${Version}' imagemagick) == $(dpkg-deb -f ./binaries/imagemagick_*.deb Version) ]]; then
  echo "Installed ImageMagick version should not match built ImageMagick version."
  exit 1
fi

# ImageMagick version imagick was compiled with and is using should match installed ImageMagick version
if ! php -i | grep "Imagick compiled with ImageMagick version" | grep -q "$(identify --version | sed -e "s/Version: ImageMagick //" -e "s/ .*//" | head -1)"; then
  echo "Imagick compiled version mismatch."
  exit 1
fi
if ! php -i | grep "Imagick using ImageMagick library version" | grep -q "$(identify --version | sed -e "s/Version: ImageMagick //" -e "s/ .*//" | head -1)"; then
  echo "Imagick using version mismatch."
  exit 1
fi

# Test that imagemagick cannot be installed without libde265 and libheif
if apt install -y ./binaries/imagemagick_*.deb; then
  echo "ImageMagick installation should have failed."
  exit 1
fi

# Test that libheif cannot be installed without libde265
if apt install -y ./binaries/libheif_*.deb; then
  echo "libheif installation should have failed."
  exit 1
fi

# Install built libde265
apt install -y ./binaries/libde265_*.deb

# Test that imagemagick cannot be installed without libheif, even with libde265 installed
if apt install -y ./binaries/imagemagick_*.deb; then
  echo "ImageMagick installation should have failed."
  exit 1
fi

# Install built libheif and imagemagick
apt install -y ./binaries/libheif_*.deb
apt install -y ./binaries/imagemagick_*.deb
ldconfig

# Installed ImageMagick version should match built ImageMagick version
if [[ $(dpkg-query -W -f='${Version}' imagemagick) != $(dpkg-deb -f ./binaries/imagemagick_*.deb Version) ]]; then
  echo "Installed ImageMagick version mismatch."
  exit 1
fi

# ImageMagick version string should not contain `(Beta)`
if magick -version | grep -q "(Beta)"; then
  echo "ImageMagick version should not contain (Beta)."
  exit 1
fi

# Check feature and delegate support
for feature in Modules freetype heic jpeg png raw tiff; do
  if ! magick -version | grep -q $feature; then
    echo "Feature $feature not supported."
    exit 1
  fi
done

# Check image format support
if ! magick -list format | grep -q "ARW  DNG       r--"; then
  echo "ARW format not supported."
  exit 1
fi
if ! magick -list format | grep -q "DNG  DNG       r--"; then
  echo "DNG format not supported."
  exit 1
fi
if ! magick -list format | grep -q "AVIF  HEIC      rw+"; then
  echo "AVIF format not supported."
  exit 1
fi

# Check font support
if ! magick -list font | grep -q "Nimbus Sans"; then
  echo "Nimbus Sans font not supported."
  exit 1
fi

# Upgrade imagick php extension
printf "\n" | MAKEFLAGS="-j $(nproc)" pecl upgrade --force ./imagick.tgz

# ImageMagick version imagick was compiled with and is using should match built ImageMagick version
if ! php -i | grep "Imagick compiled with ImageMagick version" | grep -q "$(dpkg-deb -f ./binaries/imagemagick_*.deb Version | cut -d: -f2)"; then
  echo "Imagick compiled version mismatch after upgrade."
  exit 1
fi
if ! php -i | grep "Imagick using ImageMagick library version" | grep -q "$(dpkg-deb -f ./binaries/imagemagick_*.deb Version | cut -d: -f2)"; then
  echo "Imagick using version mismatch after upgrade."
  exit 1
fi

# Test imagick php extension by creating an avif image
php -r '$image = new \Imagick(); $image->newImage(1, 1, new \ImagickPixel("red")); $image->writeImage("avif:test.avif");'

# Check if the avif image is created successfully
if [ ! -f test.avif ]; then
  echo "Failed to create avif image using imagick php extension."
  exit 1
fi

# Final clean up
rm -rf /libde265 /libheif /imagemagick /binaries /squashfs-root /test.avif /imagick.tgz

echo "All steps completed successfully."