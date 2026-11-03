{
  stdenv,
  lib,
  fetchgit,
  kernel,
  version ? "89b22ff90b86468b186706861dd18663562defa7",
  hash ? "sha256-5iDybAlRG5HldUA24L9+rSlgEiUPZg50K8IYC+Lie4U=",
}:
stdenv.mkDerivation {
  inherit version;
  name = "sna-hda-codec-cirrus-${version}-module-${kernel.modDirVersion}";

  src = fetchgit {
    url = "https://github.com/davidjo/snd_hda_macbookpro";
    rev = version;
    inherit hash;
  };

  hardeningDisable = ["pic"];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  NIX_CFLAGS_COMPILE = ["-g" "-Wall" "-Wno-unused-variable" "-Wno-unused-function"];

  makeFlags =
    kernel.commonMakeFlags
    ++ [
      "INSTALL_MOD_PATH=$(out)"
      "KERNELRELEASE=${kernel.modDirVersion}"
      "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    ];
  postPatch = ''
    printf '
    KBUILD_EXTRA_CFLAGS = "-DAPPLE_PINSENSE_FIXUP -DAPPLE_CODECS -DCONFIG_SND_HDA_RECONFIG=1"

    PWD := $(shell pwd)/build/hda

    default:
    	make -C $(KERNEL_DIR) M=$(PWD) CFLAGS_MODULE=$(KBUILD_EXTRA_CFLAGS)

    install:
    	make -C $(KERNEL_DIR) M=$(PWD) modules_install
    ' \
    > Makefile

    # kernel 6.17+ moved the HDA codec drivers from sound/pci/hda to sound/hda/codecs
    # (see snd_hda_macbookpro install.cirrus.driver.sh for the reference build flow)
    mkdir build
    tar -xf ${kernel.src} -C ./build --strip-components=2 "linux-${kernel.modDirVersion}/sound/hda"

    # swap in out-of-tree kbuild makefiles that only build the cirrus codec modules
    mv build/hda/Makefile build/hda/Makefile.orig
    mv build/hda/common/Makefile build/hda/common/Makefile.orig
    mv build/hda/codecs/Makefile build/hda/codecs/Makefile.orig
    mv build/hda/codecs/cirrus/Makefile build/hda/codecs/cirrus/Makefile.orig
    cp makefiles/Makefile build/hda
    cp makefiles/Makefile_common build/hda/common/Makefile
    cp makefiles/Makefile_codecs build/hda/codecs/Makefile
    cp makefiles/Makefile_cirrus build/hda/codecs/cirrus/Makefile

    # apple codec fixup headers used by the cs8409.apple patches
    cp patch_cirrus/cirrus_apple.h \
       patch_cirrus/patch_cirrus_boot84.h \
       patch_cirrus/patch_cirrus_new84.h \
       patch_cirrus/patch_cirrus_real84.h \
       patch_cirrus/patch_cirrus_real84_i2c.h \
       patch_cirrus/patch_cirrus_hda_generic_copy.h \
       build/hda/codecs/cirrus

    # kernel-auto-detected apple machine fixes on top of the in-tree cs8409 driver
    cd build/hda
    patch -b -p1 <../../patch_cs8409.c.diff
    patch -b -p1 <../../patch_cs8409.h.diff
    cd -
  '';

  meta = {platforms = lib.platforms.linux;};
}
