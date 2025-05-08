{
  description = "A flake that packages a simple OpenCV script";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    jetpack.url = "github:anduril/jetpack-nixos";
    jetpack.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, jetpack, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
    overlay = final: prev:
      {
        inherit (final.nvidia-jetpack) cudaPackages;
        opencv4 = prev.opencv4.override {inherit (final) cudaPackages;};
      };
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
            cudaCapabilities = [ "7.2" ];
          };
          overlays = [ overlay jetpack.overlays.default ];
        };
        pythonEnv = pkgs.python3.withPackages (ps:
          with ps; [
            (ps.opencv4.override {
              enableGtk2 = true;
              enableGtk3 = true;
              enableUnfree = true;
		      enableCuda = true;
            })
            numpy
          ]);
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "simple-cv";
          version = "1.0";
          src = ./.;

          buildInputs = [ pythonEnv ];

          installPhase = ''
            mkdir -p $out/bin
            cp $src/simple_cv.py $out/bin/simple-cv
            chmod +x $out/bin/simple-cv
          '';
        };
        devShell = pkgs.mkShell { 
		name = "opencv-fun-devshell";
		shellHook = ''
		echo "system = ${system}, yeet"
		'';
        buildInputs = [ 
        pythonEnv 
		pkgs.cudaPackages.cudatoolkit
        pkgs.nvidia-jetpack.l4t-cuda
        pkgs.nvidia-jetpack.l4t-gstreamer
        pkgs.nvidia-jetpack.l4t-multimedia
        pkgs.nvidia-jetpack.l4t-camera
        pkgs.linuxPackages.nvidia_x11
        pkgs.libGLU pkgs.libGL
        pkgs.xorg.libXi pkgs.xorg.libXmu pkgs.freeglut
        pkgs.xorg.libXext pkgs.xorg.libX11 pkgs.xorg.libXv pkgs.xorg.libXrandr pkgs.zlib 
        pkgs.ncurses5
        pkgs.stdenv.cc
        pkgs.binutils
          ];
         };
         nativeBuildInputs = [ ];
        # Allow `nix run` usage
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/simple-cv";
        };
      });
}
