{
  description = "Ephemeral Burst Cache – pure Redis + Ruby environment";

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
        ];

        shellHook = ''
          echo "EBC shell ready"
          echo "  redis-server --save \"\" --appendonly no"
          echo "  ruby bin/burst"
        '';
      };
    };
}
