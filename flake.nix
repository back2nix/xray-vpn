{
  description = "Xray service flake with client and server configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Function to generate Xray configuration
        generateXrayConfig = pkgs.writeShellScriptBin "generate-xray-config" ''
          set -e

          # Generate UUID
          USER_ID=$(${pkgs.xray}/bin/xray uuid)

          # Generate key pair
          KEY_PAIR=$(${pkgs.xray}/bin/xray x25519)
          PRIVATE_KEY=$(${pkgs.coreutils}/bin/echo "$KEY_PAIR" | ${pkgs.gnugrep}/bin/grep "Private key:" | ${pkgs.gawk}/bin/awk '{print $3}')
          PUBLIC_KEY=$(${pkgs.coreutils}/bin/echo "$KEY_PAIR" | ${pkgs.gnugrep}/bin/grep "Public key:" | ${pkgs.gawk}/bin/awk '{print $3}')

          echo "# Add the following to your xrayConfig: in flake.nix"
          echo ""
          echo "xrayConfig = {"
          echo "  serverAddress = \"127.0.0.1\"; # yor external ip server. example '133.33.33.33'"
          echo "  serverPort = 1090; # change port"
          echo "  userId = \"$USER_ID\";"
          echo "  publicKey = \"$PUBLIC_KEY\";"
          echo "  privateKey = \"$PRIVATE_KEY\";"
          echo "  socksPort = 1091; # change port"
          echo "  httpPort = 1092; # change port"
          echo "};"
        '';

        # Configuration variables
        # REPLACE ME. This is fake data for example
        xrayConfig = {
          serverAddress = "127.0.0.1"; # CHANGE ME!!! Yor external ip server. example '133.333.33.33'"
          serverPort = 1090; # change port
          userId = "ec209473-9f70-474f-a686-cc69496118fa"; # CHANGE ME!!!! nix run .#generate-config
          publicKey = "VsuXH2iP8dUzJbsKO9BxLOmYwS_jyIjxPrQtfC_S-A0"; # CHANGE ME!!!! nix run .#generate-config
          privateKey = "WGU9hz1U8VohgC2JI_MGyVl74KnGiu2-2jIgOCXNxB0"; # CHANGE ME!!!! nix run .#generate-config
          socksPort = 1091; # Extracted SOCKS port for reuse
          httpPort = 1092; # HTTP port (if needed)
        };

        clientConfig = pkgs.writeText "xray-client-config.json" (builtins.toJSON {
          log = {loglevel = "warning";};
          routing = {
            domainStrategy = "IPOnDemand";
            rules = [
              {
                type = "field";
                ip = ["geoip:private"];
                outboundTag = "direct";
              }
            ];
          };
          inbounds = [
            {
              port = xrayConfig.socksPort;
              listen = "127.0.0.1";
              protocol = "socks";
              settings = {udp = true;};
            }
            {
              port = xrayConfig.httpPort;
              listen = "127.0.0.1";
              protocol = "http";
            }
          ];
          outbounds = [
            {
              protocol = "vless";
              settings = {
                vnext = [
                  {
                    address = xrayConfig.serverAddress;
                    port = xrayConfig.serverPort;
                    users = [
                      {
                        id = xrayConfig.userId;
                        flow = "xtls-rprx-vision";
                        encryption = "none";
                      }
                    ];
                  }
                ];
              };
              streamSettings = {
                network = "tcp";
                security = "reality";
                realitySettings = {
                  serverName = "www.google.com";
                  fingerprint = "firefox";
                  shortId = "114514";
                  publicKey = xrayConfig.publicKey;
                  spiderX = "/";
                };
              };
            }
            {
              protocol = "freedom";
              tag = "direct";
            }
          ];
        });

        serverConfig = pkgs.writeText "xray-server-config.json" (builtins.toJSON {
          log = {
            loglevel = "warning";
            # access = "/tmp/access.log";
            # error = "/tmp/error.log";
          };
          routing = {
            domainStrategy = "IPIfNonMatch";
            rules = [
              {
                type = "field";
                outboundTag = "block";
                ip = ["geoip:private"];
              }
              {
                type = "field";
                outboundTag = "block";
                domain = ["geosite:category-ads-all"];
              }
            ];
          };
          inbounds = [
            {
              port = xrayConfig.serverPort;
              listen = "0.0.0.0";
              protocol = "vless";
              settings = {
                clients = [
                  {
                    id = xrayConfig.userId;
                    flow = "xtls-rprx-vision";
                  }
                ];
                decryption = "none";
              };
              streamSettings = {
                network = "tcp";
                security = "reality";
                realitySettings = {
                  show = false;
                  dest = "www.microsoft.com:443";
                  serverNames = [
                    "www.google.com"
                    "www.microsoft.com"
                    "www.bing.com"
                  ];
                  privateKey = xrayConfig.privateKey;
                  shortIds = [
                    ""
                    "114514"
                  ];
                  maxTimeDiff = 0;
                  fingerprint = "chrome";
                };
              };
              sniffing = {
                enabled = true;
                destOverride = ["http" "tls"];
              };
            }
          ];
          outbounds = [
            {
              protocol = "freedom";
              tag = "direct";
              settings = {
                domainStrategy = "UseIPv4";
              };
            }
            {
              protocol = "blackhole";
              tag = "block";
            }
          ];
          policy = {
            levels = {
              "0" = {
                handshake = 1;
                connIdle = 120;
                uplinkOnly = 1;
                downlinkOnly = 1;
                statsUserUplink = true;
                statsUserDownlink = true;
                bufferSize = 32;
              };
            };
            system = {
              statsInboundUplink = true;
              statsInboundDownlink = true;
              statsOutboundUplink = true;
              statsOutboundDownlink = true;
            };
          };
          stats = {};
          buffer = {
            size = 16;
          };
        });

        # New function to run command through proxy
        runThroughProxy = pkgs.writeShellScriptBin "run-through-proxy" ''
          # Create a temporary proxychains config file
          TEMP_CONFIG=$(mktemp)
          cat << EOF > $TEMP_CONFIG
          strict_chain
          proxy_dns
          remote_dns_subnet 224
          tcp_read_time_out 15000
          tcp_connect_time_out 8000
          [ProxyList]
          socks5 127.0.0.1 ${toString xrayConfig.socksPort}
          EOF

          # Run the command through proxychains4
          ${pkgs.proxychains}/bin/proxychains4 -f $TEMP_CONFIG ${pkgs.curl}/bin/curl https://ifconfig.me

          # Clean up the temporary config file
          rm $TEMP_CONFIG
        '';
      in rec {
        packages = rec {
          xray-client = pkgs.writeShellScriptBin "run-xray-client" ''
            ${pkgs.xray}/bin/xray run -config ${clientConfig}
          '';

          xray-server = pkgs.writeShellScriptBin "run-xray-server" ''
            ${pkgs.xray}/bin/xray run -config ${serverConfig}
          '';

          xray-generate-config = generateXrayConfig;

          xray-run-through-proxy = runThroughProxy;

          default = xray-client;
        };

        apps = rec {
          client = flake-utils.lib.mkApp {
            drv = packages.xray-client;
          };

          server = flake-utils.lib.mkApp {
            drv = packages.xray-server;
          };

          generate-config = flake-utils.lib.mkApp {
            drv = packages.xray-generate-config;
          };

          run-through-proxy = flake-utils.lib.mkApp {
            drv = packages.xray-run-through-proxy;
          };

          default = client;
        };
      }
    );
}
