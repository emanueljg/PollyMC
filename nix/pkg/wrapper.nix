{
  lib,
  stdenv,
  symlinkJoin,
  pollymc-unwrapped,
  wrapQtAppsHook,
  qtbase, # needed for wrapQtAppsHook
  qtsvg,
  qtwayland,
  xorg,
  libpulseaudio,
  libGL,
  glfw,
  openal,
  jdk8,
  jdk17,
  gamemode,
  flite,
  mesa-demos,
  udev,
  msaClientID ? null,
  gamemodeSupport ? stdenv.isLinux,
  textToSpeechSupport ? stdenv.isLinux,
  jdks ? [jdk17 jdk8],
  additionalLibs ? [],
  additionalPrograms ? [],
}: let
  pollymcFinal = pollymc-unwrapped.override {
    inherit msaClientID gamemodeSupport;
  };
in
  symlinkJoin {
    name = "pollymc-${pollymcFinal.version}";

    paths = [pollymcFinal];

    nativeBuildInputs = [
      wrapQtAppsHook
    ];

    buildInputs =
      [
        qtbase
        qtsvg
      ]
      ++ lib.optional (lib.versionAtLeast qtbase.version "6" && stdenv.isLinux) qtwayland;

    postBuild = ''
      wrapQtAppsHook
    '';

    qtWrapperArgs = let
      runtimeLibs =
        (with xorg; [
          libX11
          libXext
          libXcursor
          libXrandr
          libXxf86vm
        ])
        ++ [
          # lwjgl
          libpulseaudio
          libGL
          glfw
          openal
          stdenv.cc.cc.lib

          # oshi
          udev
        ]
        ++ lib.optional gamemodeSupport gamemode.lib
        ++ lib.optional textToSpeechSupport flite
        ++ additionalLibs;

      runtimePrograms =
        [
          xorg.xrandr
          mesa-demos # need glxinfo
        ]
        ++ additionalPrograms;
    in
      ["--prefix POLLYMC_JAVA_PATHS : ${lib.makeSearchPath "bin/java" jdks}"]
      ++ lib.optionals stdenv.isLinux [
        "--set LD_LIBRARY_PATH /run/opengl-driver/lib:${lib.makeLibraryPath runtimeLibs}"
        # xorg.xrandr needed for LWJGL [2.9.2, 3) https://github.com/LWJGL/lwjgl/issues/128
        "--prefix PATH : ${lib.makeBinPath runtimePrograms}"
      ];

    inherit (pollymcFinal) meta;
  }
