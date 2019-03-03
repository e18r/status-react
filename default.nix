let
  pkgs = import ((import <nixpkgs> { }).fetchFromGitHub {
    owner = "status-im";
    repo = "nixpkgs";
    rev = "5922f168965214ffdbc1404c081dca95b714840b";
    sha256 = "1jrvbf0903bs6a74x1nwxa6bx0q78a420mkw5104p2p5967lxkvg";
  }) { config = { }; };

in with pkgs;
  let
    _stdenv = stdenvNoCC; # TODO: Try to use stdenv for Darwin
    statusDesktop = callPackage ./scripts/lib/setup/nix/desktop { stdenv = _stdenv; };
    statusMobile = callPackage ./scripts/lib/setup/nix/mobile { stdenv = _stdenv; };
    nodeInputs = import ./scripts/lib/setup/nix/global-node-packages/output {
      # The remaining dependencies come from Nixpkgs
      inherit pkgs;
      inherit nodejs;
    };
    nodePkgs = [
      nodejs
      python27 # for e.g. gyp
      yarn
    ] ++ (map (x: nodeInputs."${x}") (builtins.attrNames nodeInputs));

  in _stdenv.mkDerivation rec {
    name = "env";
    env = buildEnv { name = name; paths = buildInputs; };
    buildInputs = with _stdenv; [
      clojure
      curl
      jq
      leiningen
      lsof # used in scripts/start-react-native.sh
      maven
      statusDesktop.buildInputs
      statusMobile.buildInputs
      watchman
      unzip
      wget
    ] ++ nodePkgs
      ++ lib.optional isDarwin cocoapods
      ++ lib.optional isLinux gcc7;
    shellHook = ''
        ${statusDesktop.shellHook}
        ${statusMobile.shellHook}

        [ -d "$ANDROID_SDK_ROOT" ] || ./scripts/setup # we assume that if the Android SDK dir does not exist, make setup needs to be run
    '';
  }
