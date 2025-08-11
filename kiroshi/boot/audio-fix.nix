{
  stdenv,
  lib,
  fetchgit,
  kernel,
  version ? "259cc39e243daef170f145ba87ad134239b5967f",
}:
stdenv.mkDerivation {
  inherit version;
  name = "sna-hda-codec-cirrus-${version}-module-${kernel.modDirVersion}";

  src = fetchgit {
    url = "https://github.com/davidjo/snd_hda_macbookpro";
    rev = version;
    sha256 = "sha256-M1dE4QC7mYFGFU3n4mrkelqU/ZfCA4ycwIcYVsrA4MY=";
  };

  hardeningDisable = ["pic"];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  NIX_CFLAGS_COMPILE = ["-g" "-Wall" "-Wno-unused-variable" "-Wno-unused-function"];

  makeFlags =
    kernel.makeFlags
    ++ [
      "INSTALL_MOD_PATH=$(out)"
      "KERNELRELEASE=${kernel.modDirVersion}"
      "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    ];
  postPatch = ''
    printf '
    snd-hda-codec-cs8409-objs := patch_cs8409.o patch_cs8409-tables.o
    obj-$(CONFIG_SND_HDA_CODEC_CS8409) += snd-hda-codec-cs8409.o

    KBUILD_EXTRA_CFLAGS = "-DAPPLE_PINSENSE_FIXUP -DAPPLE_CODECS -DCONFIG_SND_HDA_RECONFIG=1"

    PWD := $(shell pwd)/build/hda

    default:
    	make -C $(KERNEL_DIR) M=$(PWD) CFLAGS_MODULE=$(KBUILD_EXTRA_CFLAGS)

    install:
    	make -C $(KERNEL_DIR) M=$(PWD) modules_install
    ' \
    > Makefile

    mkdir build
    tar -xf ${kernel.src} -C ./build --strip-components=3 "linux-${kernel.modDirVersion}/sound/pci/hda"
    cp patch_cirrus/Makefile patch_cirrus/patch_cirrus_* build/hda

    cd build/hda
    patch -b -p2 <../../patch_patch_cs8409.c.diff
    patch -b -p2 <../../patch_patch_cs8409.h.diff
    patch -b -p2 <../../patch_patch_cirrus_apple.h.diff
    cd -
  '';

  meta = {platforms = lib.platforms.linux;};
}
