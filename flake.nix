{
  description = "Ephemeral Burst Cache – pure Redis + Ruby, and a camera";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          redis
          ruby_3_3
          docker-compose
          imagemagick   # draws the poets into your photo, assembles the GIF
        ];

        shellHook = ''
          echo "EBC shell ready"
          echo "  redis-server --save \"\" --appendonly no"
          echo "  ruby bin/burst"
        '';
      };
    };
}
