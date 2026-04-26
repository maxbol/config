{...}: final: prev: {
  xwayland-satellite = prev.xwayland-satellite.overrideAttrs {
    version = "git";

    src = final.fetchFromGitHub {
      owner = "Supreeeme";
      repo = "xwayland-satellite";
      rev = "04816e2a3634087db3de39043fcc9db2afcb0c44";
      hash = "sha256-ph61jGpaonY04jdfQxkBYRgw7ptlNHo7K0W+5kCV/+0=";
    };

    cargoHash = "";
  };
}
