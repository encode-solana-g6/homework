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
          CACHE_DIR = "${env.WD}/.cache";
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
          pkgs.nodePackages_latest.ts-node
          pkgs.yarn
          pkgs.pnpm
          pkgs.zellij
        ];


        # cmdPane = cmdStr:
        #   let
        #     parts = (lib.strings.splitString " " cmdStr);
        #     args = tail parts;
        #   in
        #   ''pane command="${head parts}" {
        #           ${lib.optionalString (args != []) ''
        #               args ${concatStringsSep " " (map (arg: '' "${arg}" '') args)}
        #           ''}
        #         }'';
        mkDev = buildrun_cmd:
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
            cmdPane = { cmd, paneCfg ? "" }: ''pane command="bash" ${paneCfg} {
                args "-c" "${cmd}"
              }'';
            layout = pkgs.writeText "layout.kdl" ''
              layout {
                default_tab_template { 
                  pane size=1 borderless=true { plugin location="zellij:tab-bar"; };
                  children
                }
                tab name="foreground" {
                  pane split_direction="vertical" {
                    ${cmdPane {cmd = buildrun_cmd; }}
                    ${cmdPane {cmd = "logs"; }}
                    pane
                  }
                }
                tab name="background" {
                  ${cmdPane {cmd = "localnet"; }}
                }
              }
            '';
          in
          '' zellij --config ${zellijConfig} --new-session-with-layout ${layout} '';

        wd = "$(git rev-parse --show-toplevel)";
        scripts = mapAttrs (name: txt: pkgs.writeScriptBin name txt) rec {
          # bare = ''cd ${wd}/examples_baremetal; npm i; npm run build'';
          localnet = ''solana-test-validator --reset'';
          # await_net = ''until sol ping -c 1 | grep -q "✅"; do sleep 1; echo "Waitiing for validator..."; done && echo "Validator is ready"'';
          await_net = ''until sol balance 2>&1 | grep -q "SOL"; do sleep 1; echo "Waitiing for validator..."; done && echo "Validator is ready"'';
          logs = ''await_net; sol logs'';
          # validator = ''solana-test-validator'';
          mkKeys = ''if [ ! -f "${env.PAYER}" ]; then  solana-keygen new --no-bip39-passphrase --outfile "${env.PAYER}"; fi '';
          # configure = ''mkKeys; solana config set --config "$CONFIG_PATH" --keypair "$PAYER" --url devnet '';
          sol = ''set -x; mkKeys; solana --config "${env.CONFIG_PATH}" $@ '';
          token = ''set -x; mkKeys; spl-token --config "${env.CONFIG_PATH}" $@ '';

          pkg_name = '''';
          # prog_keypair = ''solana-keygen new -o ./target/deploy/your_program-keypair.json'';
          mk_prog_keys-1 = ''if [ ! -f "${env.PROGRAM_1_KEYS}" ]; then  solana-keygen new --no-bip39-passphrase --outfile "${env.PROGRAM_1_KEYS}"; fi '';
          mk_prog_keys = ''set -x; 
            export PKG="''${1-''${PKG}}"; echo $PKG
            PROG_KEYS=${env.PROGRAMS_PATH}/$PKG-keypair.json
            if [ ! -f "$PROG_KEYS" ]; then  solana-keygen new --no-bip39-passphrase --outfile "$PROG_KEYS"; fi 
          '';
          progKeysOf = ''set -x; PKG="''${1-''${PKG}}"; echo ${env.PROGRAMS_PATH}/$PKG-keypair.json'';
          build-all = ''cargo-build-sbf --workspace --no-rustup-override --skip-tools-install --manifest-path=${wd}/examples_baremetal/Cargo.toml'';
          # deploy1-old = ''set -x; pnpm deploy:$1'';
          # call-old = ''set -x; pnpm call:$1'';
          setenv = ''set -x; sol config set --url "$1" '';
          # net = ''sol config get | grep "RPC URL" | cut -d'.' -f2'';
          net = ''sol config get | grep -oP 'RPC URL: \K.*' '';
          setdevnet = ''set -x; if [[ "$(net)" != *"devnet"* ]]; then setenv devnet; fi'';
          setlocal = ''set -x; if [[ "$(net)" != *"local"* ]]; then setenv localhost; fi'';

          # FOR ALL PROGRAMS
          prog_dir = ''find ${wd}/examples_baremetal ${wd}/examples_anchor -maxdepth 2 -type d -name "*$1*" '';
          exports = ''set -x; export PKG="''${1-''${PKG}}"; export PROG_DIR="$(prog_dir $PKG)"; echo "PKG=$PKG" "PROG_DIR=$PROG_DIR" '';
          build = ''set -x; ${exports};
            if [[ "$PROG_DIR" == *baremetal* ]]; 
              then cargo-build-sbf --manifest-path=${wd}/examples_baremetal/Cargo.toml --no-rustup-override --skip-tools-install -- --package "$PKG" 
            fi
            if [[ "$PROG_DIR" == *anchor* ]]; 
              then cd "$PROG_DIR"; yarn install; anchor build
            fi
          '';
          deploy = ''set -x; ${exports}; airdrop; mk_prog_keys; await_net;
            sol program-v4 deploy --program-keypair "$(progKeysOf $PKG)" "${env.PROGRAMS_PATH}/$PKG.so"; 
          '';
          show = ''set -x; ${exports};
            sol program-v4 show "$(addrOfKeys "$(progKeysOf $PKG)")"
          '';
          call = ''set -x; ${exports};
            cd "${wd}"; npm i
            ts-node "$PROG_DIR/client/main.ts"
          '';
          buildrun = ''set -x; export ${exports};
            build $PKG; deploy $PKG; call $PKG;
          '';

          # PER PROGRAM
          # build1 = ''cargo-build-sbf --manifest-path=${wd}/examples_baremetal/Cargo.toml --no-rustup-override --skip-tools-install -- --package "helloworld" '';
          run1 = ''set -x; build helloworld; airdrop; mk_prog_keys; await_net; 
            PROG_NAME="helloworld"
            deploy helloworld
            call helloworld;
          '';
          show1 = ''sol program-v4 show "$(addrOfKeys "${env.PROGRAM_1_KEYS}")" '';


          # HOMEWORK_8
          addrOfKeys = ''solana address --keypair "$1" '';
          myAddr = ''solana address --keypair "${env.PAYER}"'';
          myBal = ''set -x; sol balance --lamports --no-address-labels | awk '{print $1}' '';
          airdrop = ''set -x; mkKeys; await_net; if [ "$(${bin.myBal})" -lt 5000000000 ]; then mkKeys; sol airdrop 5; fi'';

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

          cleanup = ''set -x; 
            rm -r "${wd}/test-ledger"
            rm -r "${wd}/node_modules"
            rm -r "${wd}/examples_baremetal/target"
            # rm -r "${wd}/.cache"
          '';


          hw = mkDev "buildrun helloworld";
          ct = mkDev "buildrun counter";
          cpi = mkDev ''build helloworld; deploy helloworld;
            buildrun cpi
          '';
          compute = mkDev "buildrun compute";
          pda = mkDev "buildrun pda";
          lottery = mkDev "build lottery";
          rps = mkDev "buildrun rps";
          consortium = mkDev "buildrun consortium";
          hw2 = ''set -x; setenv devnet; airdrop;
            export PKG="hello-world"; ${exports}; 
            cd $PROG_DIR; echo "Building $PKG program";
            if [ ! -d "node_modules" ]; then yarn install; fi
            # anchor keys list;
            anchor build --no-idl --program-name "$PKG" -- --no-rustup-override --skip-tools-install 
            mkdir -p "${env.CACHE_DIR}/$PKG"
            ANCHOR_LOG=true anchor idl build --program-name "$PKG" --out ${env.CACHE_DIR}/hello-world/idl.json --out-ts ${env.CACHE_DIR}/hello-world/idl-ts.ts
            anchor deploy --program-name "$PKG" --provider.cluster devnet --provider.wallet "${env.PAYER}"
            anchor test --program-name "$PKG" --skip-deploy --provider.wallet "${env.PAYER}" --provider.cluster devnet
          '';

          # dev1 =
          #   let
          #     zellijConfig = pkgs.writeText "config.kdl" ''
          #       show_startup_tips false
          #       show_release_notes false
          #       keybinds {
          #         shared { 
          #           bind "Ctrl Esc" { Quit; }
          #           bind "Ctrl k" {
          #             Run "bash" "-c" "zellij ka -y && zellij da -yf"
          #           }
          #         }
          #       }
          #     '';
          #     cmdPane = cmdStr:
          #       let
          #         parts = (lib.strings.splitString " " cmdStr);
          #         args = tail parts;
          #       in
          #       ''pane command="${head parts}" {
          #         ${lib.optionalString (args != []) ''
          #             args ${concatStringsSep " " (map (arg: '' "${arg}" '') args)}
          #         ''}
          #       }'';
          #     cmdPane2 = { cmd, paneCfg ? "" }: ''pane command="bash" ${paneCfg} {
          #       args "-c" "${cmd}"
          #     }'';
          #     # pane command="bash" {
          #     #     args "-c"  "while true; do echo \"1 Waiting...\"; sleep 5; done " 
          #     # }
          #     # pane command="echo" { args "hello world"; }
          #     # pane size=2 borderless=true {
          #     #     plugin location="zellij:status-bar"
          #     # }
          #     # ${cmdPane "localnet"}
          #   in
          #   ''
          #     zellij --config ${zellijConfig} --new-session-with-layout ${pkgs.writeText "layout.kdl" ''
          #       layout {
          #         default_tab_template { 
          #           pane size=1 borderless=true { plugin location="zellij:tab-bar"; };
          #           children
          #         }
          #         tab name="foreground" {
          #           pane split_direction="vertical" {
          #             ${cmdPane "buildrun helloworld"}
          #             ${cmdPane "logs"}
          #             pane
          #           }
          #         }
          #         tab name="background" {
          #           ${cmdPane2 {cmd = "localnet"; }}
          #         }
          #       }
          #     ''}
          #   '';
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
