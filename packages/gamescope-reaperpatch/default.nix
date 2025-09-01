{
  fetchFromGitHub,
  gamescope,
  ...
}:
gamescope.overrideAttrs {
  src = fetchFromGitHub {
    owner = "zlice";
    repo = "gamescope";
    rev = "fa900b0694ffc8b835b91ef47a96ed90ac94823b";
    fetchSubmodules = true;
    hash = "sha256-8KT/YEDFOyUiCAqPxuCc0SzJuwquyo/mxYMx0LBiyHM=";
  };
}
