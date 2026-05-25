{ dockerTools, fakeNss }:
dockerTools.buildLayeredImage {
  name = "copilot-cli-sandbox";
  # tag = null derives the tag from the image's store-path hash, so every
  # content change produces a new tag and triggers a reload on activation.

  contents = [ fakeNss ];

  extraCommands = ''
    mkdir -p tmp work home/user
    chmod 1777 tmp
  '';

  config = {
    WorkingDir = "/work";
    Env = [ "HOME=/home/user" ];
  };
}
