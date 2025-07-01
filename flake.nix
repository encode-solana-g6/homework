{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    solana = { url = "github:nmrshll-templates/solana"; inputs.nixpkgs.follows = "nixpkgs"; };
    rust-overlay = { url = "github:oxalica/rust-overlay"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs@{ nixpkgs, flake-parts, solana, rust-overlay, ... }: with builtins; flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-darwin" ];

    perSystem = { pkgs, system, lib, ... }:
      let
        dbg = obj: trace (toJSON obj) obj;
        ownPkgs = {
          rust = pkgs.rust-bin.stable."1.87.0".default.override {
            extensions = [ "rust-src" "rust-analyzer" ];
            targets = [ ];
          };
        };
        env = {
          XDG_RUNTIME_DIR = "/tmp";
          ZELLIJ_SESSION_NAME = "default-session";
          WD = getEnv "PWD";
          PAYER = "${env.WD}/.cache/keys/id.json";
          CONFIG_PATH = "${env.WD}/.cache/config.yml";
          TOKEN_ADDR = "D6RTpDQRggiZ5sr75oG3TzNH13L8E19p1BJoGdMe8GgF"; # Decimals: 9
          MY_TOKEN_ACCOUNT = "GTFLxPQWDraeXrRetyZbVwkUx9TLWDRR2wsrWUz4Ho9x";
          NFT_ID = "FSALK4zSNyuSFuRRZSjZ6rJx7pqa9ysFqoq98xpS4BHY";
          MY_NFT_ACCOUNT = "9WtUdj6Hwv6qNaoSvwxQUT42d4HvwC1bg8B43Ta1ZrRT";
          PROGRAMS_PATH = "${env.WD}/examples_baremetal/target/deploy";
          PROGRAM_1_KEYS = "${env.PROGRAMS_PATH}/helloworld-keypair.json";
        };
        buildInputs = [ ];
        devInputs = [
          ownPkgs.rust
          solana.packages.${system}.solana-cli
          solana.packages.${system}.anchor-cli
          solana.packages.${system}.spl-token
          solana.packages.${system}.cargo-build-sbf
          pkgs.nodejs_24
          pkgs.yarn
          pkgs.pnpm
          pkgs.zellij
        ];

        wd = "$(git rev-parse --show-toplevel)";
        cmdPane = with builtins; cmdStr:
          let
            parts = (lib.strings.splitString " " cmdStr);
            args = tail parts;
          in
          ''pane command="${head parts}" {
            ${lib.optionalString (args != []) ''
                args ${concatStringsSep " " (map (arg: '' "${arg}" '') args)}
            ''}
          }'';
        scripts = mapAttrs (name: txt: pkgs.writeScriptBin name txt) {
          # bare = ''cd ${wd}/examples_baremetal; npm i; npm run build'';
          localnet = ''solana-test-validator --reset'';
          # await_net = ''until sol ping -c 1 | grep -q "✅"; do sleep 1; echo "Waitiing for validator..."; done && echo "Validator is ready"'';
          await_net = ''until sol balance 2>&1 | grep -q "SOL"; do sleep 1; echo "Waitiing for validator..."; done && echo "Validator is ready"'';
          logs = ''solana logs'';
          # validator = ''solana-test-validator'';
          mkKeys = ''if [ ! -f "${env.PAYER}" ]; then  solana-keygen new --no-bip39-passphrase --outfile "${env.PAYER}"; fi '';
          # configure = ''mkKeys; solana config set --config "$CONFIG_PATH" --keypair "$PAYER" --url devnet '';
          sol = ''set -x; mkKeys; solana --config "${env.CONFIG_PATH}" $@ '';
          token = ''set -x; mkKeys; spl-token --config "${env.CONFIG_PATH}" $@ '';

          pkg_name = '''';
          # prog_keypair = ''solana-keygen new -o ./target/deploy/your_program-keypair.json'';
          mk_prog_keys = ''if [ ! -f "${env.PROGRAM_1_KEYS}" ]; then  solana-keygen new --no-bip39-passphrase --outfile "${env.PROGRAM_1_KEYS}"; fi '';
          build = ''cargo build-sbf --workspace --manifest-path=${wd}/examples_baremetal/Cargo.toml'';
          deploy = ''set -x; pnpm deploy:$1'';
          call = ''set -x; pnpm call:$1'';
          setenv = ''set -x; sol config set --url "$1" '';
          # net = ''sol config get | grep "RPC URL" | cut -d'.' -f2'';
          net = ''sol config get | grep -oP 'RPC URL: \K.*' '';
          setdevnet = ''set -x; if [[ "$(net)" != *"devnet"* ]]; then setenv devnet; fi'';
          setlocal = ''set -x; if [[ "$(net)" != *"local"* ]]; then setenv localhost; fi'';

          build1 = ''cargo-build-sbf --manifest-path=${wd}/examples_baremetal/Cargo.toml --no-rustup-override --skip-tools-install -- --package "helloworld" '';
          run1 = ''set -x; build1; airdrop; mk_prog_keys; await_net; 
            PROG_NAME="helloworld"
            sol program-v4 deploy --program-keypair "${env.PROGRAM_1_KEYS}" "${env.PROGRAMS_PATH}/$PROG_NAME.so";
            call 1;
          '';

          # homework_8
          addr = ''solana address --keypair "${env.PAYER}"'';
          bal = ''set -x; sol balance --lamports --no-address-labels | awk '{print $1}' '';
          airdrop = ''set -x; mkKeys; await_net; if [ "$(${bin.bal})" -lt 2000000 ]; then mkKeys; sol airdrop 2; fi'';

          new-token = ''set -x; setenv devnet; mkKeys; airdrop;
            TOKEN_ID=''${TOKEN_ADDR-"$(${bin.token} create-token --config "${env.CONFIG_PATH}")"}
            echo $TOKEN_ID
             MY_TOKEN_ACCOUNT=''${MY_TOKEN_ACCOUNT-"$(${bin.token} create-account "$TOKEN_ID")"}
            if [ "$(${bin.token} balance "${env.TOKEN_ADDR}")" -lt 2 ]; then
              ${bin.token} mint $TOKEN_ID 2 $MY_TOKEN_ACCOUNT
            fi
            ${bin.token} balance "${env.TOKEN_ADDR}"
          '';
          token-bal = ''${bin.token} balance "${env.TOKEN_ADDR}" '';
          new-nft = ''set -x; setenv devnet; mkKeys; airdrop;
            NFT_ID=''${NFT_ID-"$(${bin.token} create-token --decimals 0 | grep -oP '(?<=Creating token )\S+')"}
            echo $NFT_ID
            MY_NFT_ACCOUNT=''${MY_NFT_ACCOUNT-"$(${bin.token} create-account "$NFT_ID" | grep -oP '(?<=Creating token )\S+')"}
            ${bin.token} mint "$NFT_ID" 1 "$MY_NFT_ACCOUNT"
            ${bin.token} authorize "$NFT_ID" mint --disable
            ${bin.token} balance "${env.NFT_ID}"
          '';


          # zellij -s "$ZELLIJ_SESSION_NAME"
          # zellij run --direction right -- "while true; do echo "1 Waiting..."; sleep 1; done"
          # zellij run --direction right -- "while true; do echo "2 Waiting..."; sleep 1; done"
          # zellij attach --session "$ZELLIJ_SESSION_NAME"
          # bind "Ctrl k" { Quit; };
          dev =
            let
              zellijConfig = pkgs.writeText "config.kdl" ''
                show_startup_tips false
                show_release_notes false
                keybinds {
                  shared { 
                    bind "Ctrl Esc" { Quit; }
                    bind "Ctrl k" {
                      Run "bash" "-c" "zellij ka -y && zellij da -yf"
                    }
                  }
                }
              '';
              # pane command="bash" {
              #     args "-c"  "while true; do echo \"1 Waiting...\"; sleep 5; done " 
              # }
              # pane command="echo" { args "hello world"; }
              # pane size=2 borderless=true {
              #     plugin location="zellij:status-bar"
              # }
            in
            ''
              zellij --config ${zellijConfig} --new-session-with-layout ${pkgs.writeText "layout.kdl" ''
                layout { 
                  pane split_direction="vertical" {
                    ${cmdPane "localnet"}
                    ${cmdPane "run1"}
                  }
                }
              ''}
            '';
        };
        bin = mapAttrs (k: _: "${scripts.${k}}/bin/${k}") scripts;

      in
      {
        devShells.default = pkgs.mkShellNoCC {
          inherit env;
          buildInputs = buildInputs ++ devInputs ++ (attrValues scripts);
          shellHook = ''
            # $\{my-utils.binaries.$\{system}.configure-vscode};
            dotenv
          '';
        };
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
          config = { };
        };
      };
  };
}
