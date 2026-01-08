# **Midnight-node 起動パラメター一覧**

=== "English"

    ```
    ./midnight-node --help
    The `run` command used to run a node

    Usage: midnight-node [OPTIONS]

    --validator
        Enable validator mode.
        
        The node will be started with the authority role and actively participate in any consensus task that it can (e.g. depending on availability of local keys).

    --no-grandpa
        Disable GRANDPA.
        
        Disables voter when running in validator mode, otherwise disable the GRANDPA observer.

    --rpc-external
        Listen to all RPC interfaces (default: local).
        
        Not all RPC methods are safe to be exposed publicly.
        
        Use an RPC proxy server to filter out dangerous methods. More details: <https://docs.substrate.io/build/remote-procedure-calls/#public-rpc-interfaces>.
        
        Use `--unsafe-rpc-external` to suppress the warning if you understand the risks.

    --unsafe-rpc-external
        Listen to all RPC interfaces.
        
        Same as `--rpc-external`.

    --rpc-methods <METHOD SET>
        RPC methods to expose.
        
        [default: auto]

        Possible values:
        - auto:   Expose every RPC method only when RPC is listening on `localhost`, otherwise serve only safe RPC methods
        - safe:   Allow only a safe subset of RPC methods
        - unsafe: Expose every RPC method (even potentially unsafe ones)

    --rpc-rate-limit <RPC_RATE_LIMIT>
        RPC rate limiting (calls/minute) for each connection.
        
        This is disabled by default.
        
        For example `--rpc-rate-limit 10` will maximum allow 10 calls per minute per connection.

    --rpc-rate-limit-whitelisted-ips <RPC_RATE_LIMIT_WHITELISTED_IPS>...
        Disable RPC rate limiting for certain ip addresses.
        
        Each IP address must be in CIDR notation such as `1.2.3.4/24`.

    --rpc-rate-limit-trust-proxy-headers
        Trust proxy headers for disable rate limiting.
        
        By default the rpc server will not trust headers such `X-Real-IP`, `X-Forwarded-For` and `Forwarded` and this option will make the rpc server to trust these headers.
        
        For instance this may be secure if the rpc server is behind a reverse proxy and that the proxy always sets these headers.

    --rpc-max-request-size <RPC_MAX_REQUEST_SIZE>
        Set the maximum RPC request payload size for both HTTP and WS in megabytes
        
        [default: 15]

    --rpc-max-response-size <RPC_MAX_RESPONSE_SIZE>
        Set the maximum RPC response payload size for both HTTP and WS in megabytes
        
        [default: 15]

    --rpc-max-subscriptions-per-connection <RPC_MAX_SUBSCRIPTIONS_PER_CONNECTION>
        Set the maximum concurrent subscriptions per connection
        
        [default: 1024]

    --rpc-port <PORT>
        Specify JSON-RPC server TCP port

    --experimental-rpc-endpoint <EXPERIMENTAL_RPC_ENDPOINT>...
        EXPERIMENTAL: Specify the JSON-RPC server interface and this option which can be enabled
        several times if you want expose several RPC interfaces with different configurations.
        
        The format for this option is:
        `--experimental-rpc-endpoint" listen-addr=<ip:port>,<key=value>,..."` where each option is
        separated by a comma and `listen-addr` is the only required param.
        
        The following options are available:
        • listen-addr: The socket address (ip:port) to listen on. Be careful to not expose the
            server to the public internet unless you know what you're doing. (required)
        • disable-batch-requests: Disable batch requests (optional)
        • max-connections: The maximum number of concurrent connections that the server will
            accept (optional)
        • max-request-size: The maximum size of a request body in megabytes (optional)
        • max-response-size: The maximum size of a response body in megabytes (optional)
        • max-subscriptions-per-connection: The maximum number of subscriptions per connection
            (optional)
        • max-buffer-capacity-per-connection: The maximum buffer capacity per connection
            (optional)
        • max-batch-request-len: The maximum number of requests in a batch (optional)
        • cors: The CORS allowed origins, this can enabled more than once (optional)
        • methods: Which RPC methods to allow, valid values are "safe", "unsafe" and "auto"
            (optional)
        • optional: If the listen address is optional i.e the interface is not required to be
            available For example this may be useful if some platforms doesn't support ipv6
            (optional)
        • rate-limit: The rate limit in calls per minute for each connection (optional)
        • rate-limit-trust-proxy-headers: Trust proxy headers for disable rate limiting (optional)
        • rate-limit-whitelisted-ips: Disable rate limiting for certain ip addresses, this can be
        enabled more than once (optional)  • retry-random-port: If the port is already in use,
        retry with a random port (optional)
        
        Use with care, this flag is unstable and subject to change.

    --rpc-max-connections <COUNT>
        Maximum number of RPC server connections
        
        [default: 100]

    --rpc-message-buffer-capacity-per-connection <RPC_MESSAGE_BUFFER_CAPACITY_PER_CONNECTION>
        The number of messages the RPC server is allowed to keep in memory.
        
        If the buffer becomes full then the server will not process new messages until the connected client start reading the underlying messages.
        
        This applies per connection which includes both JSON-RPC methods calls and subscriptions.
        
        [default: 64]

    --rpc-disable-batch-requests
        Disable RPC batch requests

    --rpc-max-batch-request-len <LEN>
        Limit the max length per RPC batch request

    --rpc-cors <ORIGINS>
        Specify browser *origins* allowed to access the HTTP & WS RPC servers.
        
        A comma-separated list of origins (protocol://domain or special `null` value). Value of `all` will disable origin validation. Default is to allow localhost and <https://polkadot.js.org> origins.
        When running in `--dev` mode the default is to allow all origins.

    --name <NAME>
        The human-readable name for this node.
        
        It's used as network node name.

    --no-telemetry
        Disable connecting to the Substrate telemetry server.
        
        Telemetry is on by default on global chains.

    --telemetry-url <URL VERBOSITY>
        The URL of the telemetry server to connect to.
        
        This flag can be passed multiple times as a means to specify multiple telemetry endpoints. Verbosity levels range from 0-9, with 0 denoting the least verbosity.
        
        Expected format is 'URL VERBOSITY', e.g. `--telemetry-url 'wss://foo/bar 0'`.

    --prometheus-port <PORT>
        Specify Prometheus exporter TCP Port

    --prometheus-external
        Expose Prometheus exporter on all interfaces.
        
        Default is local.

    --no-prometheus
        Do not expose a Prometheus exporter endpoint.
        
        Prometheus metric endpoint is enabled by default.

    --max-runtime-instances <MAX_RUNTIME_INSTANCES>
        The size of the instances cache for each runtime [max: 32].
        
        Values higher than 32 are illegal.
        
        [default: 8]

    --runtime-cache-size <RUNTIME_CACHE_SIZE>
        Maximum number of different runtimes that can be cached
        
        [default: 2]

    --offchain-worker <ENABLED>
        Execute offchain workers on every block
        
        [default: when-authority]

        Possible values:
        - always:         Always have offchain worker enabled
        - never:          Never enable the offchain worker
        - when-authority: Only enable the offchain worker when running as a validator (or collator, if this is a parachain node)

    --enable-offchain-indexing <ENABLE_OFFCHAIN_INDEXING>
        Enable offchain indexing API.
        
        Allows the runtime to write directly to offchain workers DB during block import.
        
        [default: false]
        [possible values: true, false]

    --chain <CHAIN_SPEC>
        Specify the chain specification.
        
        It can be one of the predefined ones (dev, local, or staging) or it can be a path to a file with the chainspec (such as one exported by the `build-spec` subcommand).

    --dev
        Specify the development chain.
        
        This flag sets `--chain=dev`, `--force-authoring`, `--rpc-cors=all`, `--alice`, and `--tmp` flags, unless explicitly overridden. It also disables local peer discovery (see --no-mdns and
        --discover-local)

    -d, --base-path <PATH>
            Specify custom base path

    -l, --log <LOG_PATTERN>...
        Sets a custom logging filter (syntax: `<target>=<level>`).
        
        Log levels (least to most verbose) are `error`, `warn`, `info`, `debug`, and `trace`.
        
        By default, all targets log `info`. The global log level can be set with `-l<level>`.
        
        Multiple `<target>=<level>` entries can be specified and separated by a comma.
        
        *Example*: `--log error,sync=debug,grandpa=warn`. Sets Global log level to `error`, sets `sync` target to debug and grandpa target to `warn`.

    --detailed-log-output
        Enable detailed log output.
        
        Includes displaying the log target, log level and thread name.
        
        This is automatically enabled when something is logged with any higher level than `info`.

    --disable-log-color
        Disable log color output

    --enable-log-reloading
        Enable feature to dynamically update and reload the log filter.
        
        Be aware that enabling this feature can lead to a performance decrease up to factor six or more. Depending on the global logging level the performance decrease changes.
        
        The `system_addLogFilter` and `system_resetLogFilter` RPCs will have no effect with this option not being set.

    --tracing-targets <TARGETS>
        Sets a custom profiling filter.
        
        Syntax is the same as for logging (`--log`).

    --tracing-receiver <RECEIVER>
        Receiver to process tracing messages
        
        [default: log]

        Possible values:
        - log: Output the tracing records using the log

    --state-pruning <PRUNING_MODE>
        Specify the state pruning mode.
        
        This mode specifies when the block's state (ie, storage) should be pruned (ie, removed) from the database. This setting can only be set on the first creation of the database. Every subsequent run
        will load the pruning mode from the database and will error if the stored mode doesn't match this CLI value. It is fine to drop this CLI flag for subsequent runs. The only exception is that
        `NUMBER` can change between subsequent runs (increasing it will not lead to restoring pruned state).
        
        Possible values:
        
        - archive: Keep the data of all blocks.
        
        - archive-canonical: Keep only the data of finalized blocks.
        
        - NUMBER: Keep the data of the last NUMBER of finalized blocks.
        
        [default: 256]

    --blocks-pruning <PRUNING_MODE>
        Specify the blocks pruning mode.
        
        This mode specifies when the block's body (including justifications) should be pruned (ie, removed) from the database.
        
        Possible values:
        
        - archive: Keep the data of all blocks.
        
        - archive-canonical: Keep only the data of finalized blocks.
        
        - NUMBER: Keep the data of the last NUMBER of finalized blocks.
        
        [default: archive-canonical]

    --database <DB>
        Select database backend to use

        Possible values:
        - paritydb:              ParityDb. <https://github.com/paritytech/parity-db/>
        - auto:                  Detect whether there is an existing database. Use it, if there is, if not, create new instance of ParityDb
        - paritydb-experimental: ParityDb. <https://github.com/paritytech/parity-db/>

    --db-cache <MiB>
        Limit the memory the database cache can use

    --wasm-execution <METHOD>
        Method for executing Wasm runtime code
        
        [default: compiled]

        Possible values:
        - interpreted-i-know-what-i-do: Uses an interpreter which now is deprecated
        - compiled:                     Uses a compiled runtime

    --wasmtime-instantiation-strategy <STRATEGY>
        The WASM instantiation method to use.
        
        Only has an effect when `wasm-execution` is set to `compiled`. The copy-on-write strategies are only supported on Linux. If the copy-on-write variant of a strategy is unsupported the executor will
        fall back to the non-CoW equivalent. The fastest (and the default) strategy available is `pooling-copy-on-write`. The `legacy-instance-reuse` strategy is deprecated and will be removed in the
        future. It should only be used in case of issues with the default instantiation strategy.
        
        [default: pooling-copy-on-write]

        Possible values:
        - pooling-copy-on-write:           Pool the instances to avoid initializing everything from scratch on each instantiation. Use copy-on-write memory when possible
        - recreate-instance-copy-on-write: Recreate the instance from scratch on every instantiation. Use copy-on-write memory when possible
        - pooling:                         Pool the instances to avoid initializing everything from scratch on each instantiation
        - recreate-instance:               Recreate the instance from scratch on every instantiation. Very slow

    --wasm-runtime-overrides <PATH>
        Specify the path where local WASM runtimes are stored.
        
        These runtimes will override on-chain runtimes when the version matches.

    --execution-syncing <STRATEGY>
        Runtime execution strategy for importing blocks during initial sync

        Possible values:
        - native:           Execute with native build (if available, WebAssembly otherwise)
        - wasm:             Only execute with the WebAssembly build
        - both:             Execute with both native (where available) and WebAssembly builds
        - native-else-wasm: Execute with the native build if possible; if it fails, then execute with WebAssembly

    --execution-import-block <STRATEGY>
        Runtime execution strategy for general block import (including locally authored blocks)

        Possible values:
        - native:           Execute with native build (if available, WebAssembly otherwise)
        - wasm:             Only execute with the WebAssembly build
        - both:             Execute with both native (where available) and WebAssembly builds
        - native-else-wasm: Execute with the native build if possible; if it fails, then execute with WebAssembly

    --execution-block-construction <STRATEGY>
        Runtime execution strategy for constructing blocks

        Possible values:
        - native:           Execute with native build (if available, WebAssembly otherwise)
        - wasm:             Only execute with the WebAssembly build
        - both:             Execute with both native (where available) and WebAssembly builds
        - native-else-wasm: Execute with the native build if possible; if it fails, then execute with WebAssembly

    --execution-offchain-worker <STRATEGY>
        Runtime execution strategy for offchain workers

        Possible values:
        - native:           Execute with native build (if available, WebAssembly otherwise)
        - wasm:             Only execute with the WebAssembly build
        - both:             Execute with both native (where available) and WebAssembly builds
        - native-else-wasm: Execute with the native build if possible; if it fails, then execute with WebAssembly

    --execution-other <STRATEGY>
        Runtime execution strategy when not syncing, importing or constructing blocks

        Possible values:
        - native:           Execute with native build (if available, WebAssembly otherwise)
        - wasm:             Only execute with the WebAssembly build
        - both:             Execute with both native (where available) and WebAssembly builds
        - native-else-wasm: Execute with the native build if possible; if it fails, then execute with WebAssembly

    --execution <STRATEGY>
        The execution strategy that should be used by all execution contexts

        Possible values:
        - native:           Execute with native build (if available, WebAssembly otherwise)
        - wasm:             Only execute with the WebAssembly build
        - both:             Execute with both native (where available) and WebAssembly builds
        - native-else-wasm: Execute with the native build if possible; if it fails, then execute with WebAssembly

    --trie-cache-size <Bytes>
        Specify the state cache size.
        
        Providing `0` will disable the cache.
        
        [default: 67108864]

    --state-cache-size <STATE_CACHE_SIZE>
        DEPRECATED: switch to `--trie-cache-size`

    --bootnodes <ADDR>...
        Specify a list of bootnodes

    --reserved-nodes <ADDR>...
        Specify a list of reserved node addresses

    --reserved-only
        Whether to only synchronize the chain with reserved nodes.
        
        Also disables automatic peer discovery. TCP connections might still be established with non-reserved nodes. In particular, if you are a validator your node might still connect to other validator
        nodes and collator nodes regardless of whether they are defined as reserved nodes.

    --public-addr <PUBLIC_ADDR>...
        Public address that other nodes will use to connect to this node.
        
        This can be used if there's a proxy in front of this node.

    --listen-addr <LISTEN_ADDR>...
        Listen on this multiaddress.
        
        By default: If `--validator` is passed: `/ip4/0.0.0.0/tcp/<port>` and `/ip6/[::]/tcp/<port>`. Otherwise: `/ip4/0.0.0.0/tcp/<port>/ws` and `/ip6/[::]/tcp/<port>/ws`.

    --port <PORT>
        Specify p2p protocol TCP port

    --no-private-ip
        Always forbid connecting to private IPv4/IPv6 addresses.
        
        The option doesn't apply to addresses passed with `--reserved-nodes` or `--bootnodes`. Enabled by default for chains marked as "live" in their chain specifications.
        
        Address allocation for private networks is specified by [RFC1918](https://tools.ietf.org/html/rfc1918)).

    --allow-private-ip
        Always accept connecting to private IPv4/IPv6 addresses.
        
        Enabled by default for chains marked as "local" in their chain specifications, or when `--dev` is passed.
        
        Address allocation for private networks is specified by [RFC1918](https://tools.ietf.org/html/rfc1918)).

    --out-peers <COUNT>
        Number of outgoing connections we're trying to maintain
        
        [default: 8]

    --in-peers <COUNT>
        Maximum number of inbound full nodes peers
        
        [default: 32]

    --in-peers-light <COUNT>
        Maximum number of inbound light nodes peers
        
        [default: 100]

    --no-mdns
        Disable mDNS discovery (default: true).
        
        By default, the network will use mDNS to discover other nodes on the local network. This disables it. Automatically implied when using --dev.

    --max-parallel-downloads <COUNT>
        Maximum number of peers from which to ask for the same blocks in parallel.
        
        This allows downloading announced blocks from multiple peers. Decrease to save traffic and risk increased latency.
        
        [default: 5]

    --node-key <KEY>
        Secret key to use for p2p networking.
        
        The value is a string that is parsed according to the choice of `--node-key-type` as follows:
        
        - `ed25519`: the value is parsed as a hex-encoded Ed25519 32 byte secret key (64 hex chars)
        
        The value of this option takes precedence over `--node-key-file`.
        
        WARNING: Secrets provided as command-line arguments are easily exposed. Use of this option should be limited to development and testing. To use an externally managed secret key, use
        `--node-key-file` instead.

    --node-key-type <TYPE>
        Crypto primitive to use for p2p networking.
        
        The secret key of the node is obtained as follows:
        
        - If the `--node-key` option is given, the value is parsed as a secret key according to the type. See the documentation for `--node-key`.
        
        - If the `--node-key-file` option is given, the secret key is read from the specified file. See the documentation for `--node-key-file`.
        
        - Otherwise, the secret key is read from a file with a predetermined, type-specific name from the chain-specific network config directory inside the base directory specified by `--base-dir`. If
        this file does not exist, it is created with a newly generated secret key of the chosen type.
        
        The node's secret key determines the corresponding public key and hence the node's peer ID in the context of libp2p.
        
        [default: ed25519]

        Possible values:
        - ed25519: Use ed25519

    --node-key-file <FILE>
        File from which to read the node's secret key to use for p2p networking.
        
        The contents of the file are parsed according to the choice of `--node-key-type` as follows:
        
        - `ed25519`: the file must contain an unencoded 32 byte or hex encoded Ed25519 secret key.
        
        If the file does not exist, it is created with a newly generated secret key of the chosen type.

    --unsafe-force-node-key-generation
        Forces key generation if node-key-file file does not exist.
        
        This is an unsafe feature for production networks, because as an active authority other authorities may depend on your node having a stable identity and they might not being able to reach you if
        your identity changes after entering the active set.
        
        For minimal node downtime if no custom `node-key-file` argument is provided the network-key is usually persisted accross nodes restarts, in the `network` folder from directory provided in
        `--base-path`
        
        Warning!! If you ever run the node with this argument, make sure you remove it for the subsequent restarts.

    --discover-local
        Enable peer discovery on local networks.
        
        By default this option is `true` for `--dev` or when the chain type is `Local`/`Development` and false otherwise.

    --kademlia-disjoint-query-paths
        Require iterative Kademlia DHT queries to use disjoint paths.
        
        Disjoint paths increase resiliency in the presence of potentially adversarial nodes.
        
        See the S/Kademlia paper for more information on the high level design as well as its security improvements.

    --kademlia-replication-factor <KADEMLIA_REPLICATION_FACTOR>
        Kademlia replication factor.
        
        Determines to how many closest peers a record is replicated to.
        
        Discovery mechanism requires successful replication to all `kademlia_replication_factor` peers to consider record successfully put.
        
        [default: 20]

    --ipfs-server
        Join the IPFS network and serve transactions over bitswap protocol

    --sync <SYNC_MODE>
        Blockchain syncing mode.
        
        [default: full]

        Possible values:
        - full:        Full sync. Download and verify all blocks
        - fast:        Download blocks without executing them. Download latest state with proofs
        - fast-unsafe: Download blocks without executing them. Download latest state without proofs
        - warp:        Prove finality and download the latest state

    --max-blocks-per-request <COUNT>
        Maximum number of blocks per request.
        
        Try reducing this number from the default value if you have a slow network connection and observe block requests timing out.
        
        [default: 64]

    --network-backend <NETWORK_BACKEND>
        Network backend used for P2P networking.
        
        litep2p network backend is considered experimental and isn't as stable as the libp2p
        network backend.
        
        [default: libp2p]

        Possible values:
        - libp2p:  Use libp2p for P2P networking
        - litep2p: Use litep2p for P2P networking

    --pool-limit <COUNT>
        Maximum number of transactions in the transaction pool
        
        [default: 8192]

    --pool-kbytes <COUNT>
        Maximum number of kilobytes of all transactions stored in the pool
        
        [default: 20480]

    --tx-ban-seconds <SECONDS>
        How long a transaction is banned for.
        
        If it is considered invalid. Defaults to 1800s.

    --keystore-path <PATH>
        Specify custom keystore path

    --password-interactive
        Use interactive shell for entering the password used by the keystore

    --password <PASSWORD>
        Password used by the keystore.
        
        This allows appending an extra user-defined secret to the seed.

    --password-filename <PATH>
        File that contains the password used by the keystore

    --alice
        Shortcut for `--name Alice --validator`.
        
        Session keys for `Alice` are added to keystore.

    --bob
        Shortcut for `--name Bob --validator`.
        
        Session keys for `Bob` are added to keystore.

    --charlie
        Shortcut for `--name Charlie --validator`.
        
        Session keys for `Charlie` are added to keystore.

    --dave
        Shortcut for `--name Dave --validator`.
        
        Session keys for `Dave` are added to keystore.

    --eve
        Shortcut for `--name Eve --validator`.
        
        Session keys for `Eve` are added to keystore.

    --ferdie
        Shortcut for `--name Ferdie --validator`.
        
        Session keys for `Ferdie` are added to keystore.

    --one
        Shortcut for `--name One --validator`.
        
        Session keys for `One` are added to keystore.

    --two
        Shortcut for `--name Two --validator`.
        
        Session keys for `Two` are added to keystore.

    --force-authoring
        Enable authoring even when offline

    --tmp
        Run a temporary node.
        
        A temporary directory will be created to store the configuration and will be deleted at the end of the process.
        
        Note: the directory is random per process execution. This directory is used as base path which includes: database, node key and keystore.
        
        When `--dev` is given and no explicit `--base-path`, this option is implied.

    -h, --help
            Print help (see a summary with '-h')

    ================================================================================
    ChainSpecCfg
    ================================================================================

    NAME:          genesis_utxo
    HELP:          chain-spec generation: partner chain parameter for genesis_utxo
    TYPE:          Option < UtxoId >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          addresses_json
    HELP:          This file is an output of the partner-chains-cli provided by partnerchains.
                It's required to provide configuration at runtime for the node.
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    ================================================================================
    MetaCfg
    ================================================================================

    NAME:          cfg_preset
    HELP:          Use a preset of default config values
    TYPE:          Option < CfgPreset >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          show_config
    HELP:          Show configuration on startup
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          show_secrets
    HELP:          Show secrets in configuration
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    ================================================================================
    MidnightCfg
    ================================================================================

    NAME:          wipe_chain_state
    HELP:          On start-up, wipe the chain
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          seed_phrase
    HELP:          Seed for key to be inserted to the keystore for this node's authoring functions.
                This automatically generates the required key triple of (`aura`, `grandpa`, `cross_chain`).
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          use_main_chain_follower_mock
    HELP:          Mock ariadne parameters
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          main_chain_follower_mock_registrations_file
    HELP:          Required if use_main_chain_follower_mock is true
                Used in the sidechains library
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          mc__first_epoch_timestamp_millis
    HELP:          see partner-chains EpochConfig
    TYPE:          u64
    DEFAULT:       1666656000000
    SOURCES:       default
    CURRENT_VALUE: 1666656000000

    NAME:          mc__first_epoch_number
    HELP:          see partner-chains EpochConfig
    TYPE:          u32
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    NAME:          mc__epoch_duration_millis
    HELP:          see partner-chains EpochConfig
    TYPE:          u64
    DEFAULT:       86400000
    SOURCES:       default
    CURRENT_VALUE: 86400000

    NAME:          mc__first_slot_number
    HELP:          see partner-chains EpochConfig
    TYPE:          u64
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    NAME:          db_sync_postgres_connection_string
    HELP:          see partner-chains ConnectionConfig
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          cardano_security_parameter
    HELP:          see partner-chains CandidateDataSourceCacheConfig and DbSyncBlockDataSourceConfig
    TYPE:          Option < u32 >
    DEFAULT:       432
    SOURCES:       default
    CURRENT_VALUE: 432

    NAME:          cardano_active_slots_coeff
    HELP:          see partner-chains DbSyncBlockDataSourceConfig
    TYPE:          Option < f64 >
    DEFAULT:       0.05
    SOURCES:       default
    CURRENT_VALUE: 0.05

    NAME:          block_stability_margin
    HELP:          see partner-chains DbSyncBlockDataSourceConfig
    TYPE:          Option < u32 >
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    NAME:          proposed_wasm_file
    HELP:          An optional proposal of a new runtime file for the Midnight runtime.
                The spec version and code hash will be extracted from this file, otherwise, the default path will be used.
                If not in the default path, the node will not vote in favor of a WASM to promote for a runtime upgrade
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          storage_cache_size
    HELP:          Size of ledger storage cache (number of nodes)
    TYPE:          usize
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    ================================================================================
    StorageMonitorParamsCfg
    ================================================================================

    NAME:          threshold
    HELP:          Required available space on database storage
    TYPE:          u64
    DEFAULT:       512
    SOURCES:       default
    CURRENT_VALUE: 512

    NAME:          polling_period
    HELP:          How often available space is polled
    TYPE:          u32
    DEFAULT:       5
    SOURCES:       default
    CURRENT_VALUE: 5

    ================================================================================
    SubstrateCfg
    ================================================================================

    NAME:          argv
    HELP:          REMOVED: USE "args" INSTEAD
                The arguments passed to the node, including the binary
    TYPE:          Vec < String >
    DEFAULT:       
    SOURCES:       default
    CURRENT_VALUE: ""

    NAME:          args
    HELP:          The arguments passed to the node
    TYPE:          Vec < String >
    DEFAULT:       
    SOURCES:       cli
    CURRENT_VALUE: "--help, "

    NAME:          append_args
    HELP:          Extra arguments to append to args
    TYPE:          Vec < String >
    DEFAULT:       
    SOURCES:       default
    CURRENT_VALUE: ""

    NAME:          base_path
    HELP:          Optional override for base_path. --base-path in argv takes precedence
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          node_key
    HELP:          Optional override for node_key. --node-key in argv takes precedence
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          chain
    HELP:          Optional override for chain. --chain in argv takes precedence
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          validator
    HELP:          Override for --validator in argv
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          bootnodes
    HELP:          Appends to the list of bootnodes
    TYPE:          Vec < MultiaddrWithPeerId >
    DEFAULT:       
    SOURCES:       default
    CURRENT_VALUE: ""

    NAME:          trie_cache_size
    HELP:          Override for --trie_cache_size. --trie-cache-size in argv takes precedence (unless set to default value).
    TYPE:          Option < usize >
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    CONFIG PRESET: None
    VALIDATION RESULT: Configuration failed to validate: config error: {"errors":["db_sync_postgres_connection_string must be defined if ariadne is enabled (i.e. if use_main_chain_follower_mock is false)"],"properties":{}}
    *note:* To show secret values, set SHOW_SECRETS=1

    Midnight blockchain node. Run without <COMMAND> to start the node. To see full config options, run with no args with env-var SHOW_CONFIG=TRUE or run --help

    Usage: midnight-node <COMMAND>

    Commands:
    key                      Key management cli utilities
    sidechain-params         Returns sidechain parameters
    registration-status      Returns registration status for a given mainchain public key and epoch number. If registration has been included in Cardano block in epoch N, then it should be returned by this
                            command if epoch greater than N+1 is provided. If this command won't show your registration after a few minutes after it has been included in a cardano block, you can start
                            debugging for unsuccessful registration
    ariadne-parameters       Returns ariadne parameters effective at given mainchain epoch number. Parameters are effective two epochs after the block their change is included in
    registration-signatures  Generates registration signatures for partner chains committee candidates
    smart-contracts          Commands for interacting with Partner Chain smart contracts on Cardano
    wizards                  Partner Chains text "wizards" for setting up chain
    build-spec               Build a chain specification
    check-block              Validate blocks
    export-blocks            Export blocks
    export-state             Export the state of a given block into a chain spec
    import-blocks            Import blocks
    purge-chain              Remove the whole chain
    revert                   Revert the chain to a previous state
    benchmark                Sub-commands concerned with benchmarking
    chain-info               Db meta columns information
    help                     Print this message or the help of the given subcommand(s)

    Options:
    -h, --help     Print help
    -V, --version  Print version
    ```

=== "日本語"

    ```
    ./midnight-node --help
    ノードを起動するために使う `run` コマンド

    使用法: midnight-node [OPTIONS]

    --validator
        バリデーターモードを有効にする。
        
        ノードはオーソリティロールで起動し、可能な限り（例: ローカルキーの可用性に応じて）合意タスクに積極的に参加する。

    --no-grandpa
        GRANDPA を無効化する。
        
        バリデーターモードでは投票者を無効化し、そうでない場合は GRANDPA オブザーバーを無効化する。

    --rpc-external
        すべての RPC インターフェースで待ち受ける（デフォルト: ローカル）。
        
        すべての RPC メソッドが安全に公開できるわけではない。
        
        危険なメソッドを除外するために RPC プロキシサーバーを使用する。詳細: <https://docs.substrate.io/build/remote-procedure-calls/#public-rpc-interfaces>。
        
        リスクを理解している場合は `--unsafe-rpc-external` で警告を抑制できる。

    --unsafe-rpc-external
        すべての RPC インターフェースで待ち受ける。
        
        `--rpc-external` と同じ。

    --rpc-methods <METHOD SET>
        公開する RPC メソッド。
        
        [default: auto]

        可能な値:
        - auto:   RPC が `localhost` で待ち受ける場合のみすべての RPC メソッドを公開し、それ以外は安全な RPC メソッドのみ提供する
        - safe:   安全な RPC メソッドのサブセットのみ許可する
        - unsafe: すべての RPC メソッド（潜在的に安全でないものも含む）を公開する

    --rpc-rate-limit <RPC_RATE_LIMIT>
        各接続ごとの RPC レート制限（呼び出し/分）。
        
        これはデフォルトで無効。
        
        例: `--rpc-rate-limit 10` は接続あたり 1 分に最大 10 回の呼び出しのみ許可する。

    --rpc-rate-limit-whitelisted-ips <RPC_RATE_LIMIT_WHITELISTED_IPS>...
        特定の IP アドレスに対する RPC レート制限を無効化する。
        
        各 IP アドレスは `1.2.3.4/24` のような CIDR 表記である必要がある。

    --rpc-rate-limit-trust-proxy-headers
        レート制限の無効化のためにプロキシヘッダーを信頼する。
        
        デフォルトでは RPC サーバーは `X-Real-IP`、`X-Forwarded-For`、`Forwarded` などのヘッダーを信頼せず、このオプションを指定すると信頼するようになる。
        
        例えば、RPC サーバーがリバースプロキシの背後にあり、プロキシが常にこれらのヘッダーを設定する場合に安全である可能性がある。

    --rpc-max-request-size <RPC_MAX_REQUEST_SIZE>
        HTTP と WS の両方で RPC リクエストのペイロード最大サイズをメガバイト単位で設定する
        
        [default: 15]

    --rpc-max-response-size <RPC_MAX_RESPONSE_SIZE>
        HTTP と WS の両方で RPC レスポンスのペイロード最大サイズをメガバイト単位で設定する
        
        [default: 15]

    --rpc-max-subscriptions-per-connection <RPC_MAX_SUBSCRIPTIONS_PER_CONNECTION>
        接続あたりの最大同時サブスクリプション数を設定する
        
        [default: 1024]

    --rpc-port <PORT>
        JSON-RPC サーバーの TCP ポートを指定する

    --experimental-rpc-endpoint <EXPERIMENTAL_RPC_ENDPOINT>...
        実験的: JSON-RPC サーバーのインターフェースを指定する。このオプションは複数回指定でき、異なる設定で複数の RPC インターフェースを公開できる。
        
        このオプションの形式:
        `--experimental-rpc-endpoint" listen-addr=<ip:port>,<key=value>,..."`。各オプションはカンマで区切られ、`listen-addr` が唯一の必須パラメータ。
        
        利用可能なオプション:
        • listen-addr: 待ち受けるソケットアドレス（ip:port）。よほど理解していない限り、公開インターネットへの公開は避けること。（必須）
        • disable-batch-requests: バッチリクエストを無効化（任意）
        • max-connections: サーバーが受け入れる同時接続の最大数（任意）
        • max-request-size: リクエスト本文の最大サイズ（メガバイト）（任意）
        • max-response-size: レスポンス本文の最大サイズ（メガバイト）（任意）
        • max-subscriptions-per-connection: 接続あたりの最大サブスクリプション数（任意）
        • max-buffer-capacity-per-connection: 接続あたりの最大バッファ容量（任意）
        • max-batch-request-len: バッチ内のリクエスト最大件数（任意）
        • cors: 許可する CORS オリジン。この項目は複数回有効化できる（任意）
        • methods: 許可する RPC メソッド。`safe`、`unsafe`、`auto` が有効（任意）
        • optional: 待ち受けアドレスが任意、つまりインターフェースが利用できなくてもよい。例: 一部プラットフォームで ipv6 をサポートしない場合に有用（任意）
        • rate-limit: 各接続の呼び出し/分のレート制限（任意）
        • rate-limit-trust-proxy-headers: レート制限の無効化のためにプロキシヘッダーを信頼する（任意）
        • rate-limit-whitelisted-ips: 特定の IP アドレスに対するレート制限を無効化。この項目は複数回有効化できる（任意）
        • retry-random-port: ポートが既に使用中の場合、ランダムなポートで再試行（任意）
        
        注意して使用すること。このフラグは不安定で、変更される可能性がある。

    --rpc-max-connections <COUNT>
        RPC サーバー接続の最大数
        
        [default: 100]

    --rpc-message-buffer-capacity-per-connection <RPC_MESSAGE_BUFFER_CAPACITY_PER_CONNECTION>
        RPC サーバーがメモリ内に保持できるメッセージ数。
        
        バッファが満杯になると、接続しているクライアントが基盤メッセージを読み始めるまで、新しいメッセージは処理されない。
        
        これは JSON-RPC のメソッド呼び出しとサブスクリプションの両方を含む接続単位で適用される。
        
        [default: 64]

    --rpc-disable-batch-requests
        RPC バッチリクエストを無効化する

    --rpc-max-batch-request-len <LEN>
        RPC バッチリクエストの最大長を制限する

    --rpc-cors <ORIGINS>
        HTTP & WS RPC サーバーへのアクセスを許可するブラウザの *origin* を指定する。
        
        オリジンのカンマ区切りリスト（protocol://domain または特別な `null` 値）。`all` はオリジン検証を無効化する。デフォルトは localhost と <https://polkadot.js.org> のオリジンを許可する。
        `--dev` モードではデフォルトで全オリジンを許可する。

    --name <NAME>
        このノードの人間が読める名前。
        
        ネットワーク上のノード名として使用される。

    --no-telemetry
        Substrate テレメトリーサーバーへの接続を無効化する。
        
        グローバルチェーンではデフォルトでテレメトリーが有効。

    --telemetry-url <URL VERBOSITY>
        接続先のテレメトリーサーバー URL。
        
        複数回指定して複数のテレメトリーエンドポイントを指定できる。冗長度は 0-9 で、0 が最も低い。
        
        期待される形式は 'URL VERBOSITY'、例: `--telemetry-url 'wss://foo/bar 0'`。

    --prometheus-port <PORT>
        Prometheus エクスポーターの TCP ポートを指定する

    --prometheus-external
        すべてのインターフェースで Prometheus エクスポーターを公開する。
        
        デフォルトはローカル。

    --no-prometheus
        Prometheus エクスポーターエンドポイントを公開しない。
        
        Prometheus のメトリクスエンドポイントはデフォルトで有効。

    --max-runtime-instances <MAX_RUNTIME_INSTANCES>
        各ランタイムのインスタンスキャッシュサイズ [max: 32]。
        
        32 を超える値は不正。
        
        [default: 8]

    --runtime-cache-size <RUNTIME_CACHE_SIZE>
        キャッシュ可能な異なるランタイムの最大数
        
        [default: 2]

    --offchain-worker <ENABLED>
        各ブロックでオフチェーンワーカーを実行する
        
        [default: when-authority]

        可能な値:
        - always:         常にオフチェーンワーカーを有効にする
        - never:          オフチェーンワーカーを有効にしない
        - when-authority: バリデーター（または、これはパラチェーンノードならコレーター）として実行している場合のみ有効にする

    --enable-offchain-indexing <ENABLE_OFFCHAIN_INDEXING>
        オフチェーンインデクシング API を有効化する。
        
        ブロック取り込み中にランタイムがオフチェーンワーカー DB へ直接書き込めるようにする。
        
        [default: false]
        [possible values: true, false]

    --chain <CHAIN_SPEC>
        チェーン仕様を指定する。
        
        事前定義済み（dev、local、staging）のいずれか、または chainspec を含むファイルへのパス（`build-spec` サブコマンドでエクスポートしたものなど）を指定できる。

    --dev
        開発用チェーンを指定する。
        
        このフラグは明示的に上書きされない限り、`--chain=dev`、`--force-authoring`、`--rpc-cors=all`、`--alice`、`--tmp` を設定する。またローカルピア探索を無効化する（--no-mdns および
        --discover-local を参照）。

    -d, --base-path <PATH>
            カスタムのベースパスを指定する

    -l, --log <LOG_PATTERN>...
            カスタムのログフィルターを設定する（構文: `<target>=<level>`）。
            
            ログレベル（低い→高い）は `error`、`warn`、`info`、`debug`、`trace`。
            
            デフォルトでは全ターゲットが `info`。グローバルログレベルは `-l<level>` で設定できる。
            
            複数の `<target>=<level>` を指定でき、カンマで区切る。
            
            *例*: `--log error,sync=debug,grandpa=warn`。グローバルログレベルを `error` にし、`sync` ターゲットを debug、grandpa ターゲットを warn にする。

    --detailed-log-output
        詳細なログ出力を有効化する。
        
        ログターゲット、ログレベル、スレッド名の表示を含む。
        
        何かが `info` より高いレベルでログされると自動的に有効になる。

    --disable-log-color
        ログの色出力を無効化する

    --enable-log-reloading
        ログフィルターを動的に更新・再読み込みする機能を有効化する。
        
        この機能を有効にすると、最大 6 倍以上の性能低下が起きる可能性がある。グローバルログレベルに応じて性能低下の度合いは変わる。
        
        このオプションが設定されていない場合、`system_addLogFilter` と `system_resetLogFilter` RPC は効果がない。

    --tracing-targets <TARGETS>
        カスタムのプロファイリングフィルターを設定する。
        
        構文はログ（`--log`）と同じ。

    --tracing-receiver <RECEIVER>
        トレーシングメッセージの受信先
        
        [default: log]

        可能な値:
        - log: ログを使ってトレーシングレコードを出力する

    --state-pruning <PRUNING_MODE>
        状態のプルーニングモードを指定する。
        
        このモードは、ブロックの状態（すなわちストレージ）をいつプルーニング（削除）するかを指定する。この設定はデータベース作成時のみ設定可能。その後の実行では DB に保存されたプルーニングモードが読み込まれ、CLI の値が一致しない場合はエラーになる。以降の実行でこの CLI フラグを外しても問題ない。唯一の例外として、`NUMBER` は後続の実行で変更できる（増やしてもプルーニング済み状態は復元されない）。
        
        可能な値:
        
        - archive: すべてのブロックのデータを保持する。
        
        - archive-canonical: 確定済みブロックのデータのみ保持する。
        
        - NUMBER: 直近 NUMBER 件の確定済みブロックのデータのみ保持する。
        
        [default: 256]

    --blocks-pruning <PRUNING_MODE>
        ブロックのプルーニングモードを指定する。
        
        このモードは、ブロックの本文（justifications を含む）をいつプルーニング（削除）するかを指定する。
        
        可能な値:
        
        - archive: すべてのブロックのデータを保持する。
        
        - archive-canonical: 確定済みブロックのデータのみ保持する。
        
        - NUMBER: 直近 NUMBER 件の確定済みブロックのデータのみ保持する。
        
        [default: archive-canonical]

    --database <DB>
        使用するデータベースバックエンドを選択する

        可能な値:
        - paritydb:              ParityDb。<https://github.com/paritytech/parity-db/>
        - auto:                  既存のデータベースがあるか検出し、あればそれを使い、なければ新しい ParityDb インスタンスを作成する
        - paritydb-experimental: ParityDb。<https://github.com/paritytech/parity-db/>

    --db-cache <MiB>
        データベースキャッシュが使用できるメモリを制限する

    --wasm-execution <METHOD>
        Wasm ランタイムコードの実行方法
        
        [default: compiled]

        可能な値:
        - interpreted-i-know-what-i-do: 現在は非推奨のインタープリターを使用する
        - compiled:                     コンパイル済みランタイムを使用する

    --wasmtime-instantiation-strategy <STRATEGY>
        WASM のインスタンス化方法。
        
        `wasm-execution` が `compiled` のときのみ有効。copy-on-write の戦略は Linux のみでサポートされる。copy-on-write 版の戦略が未サポートの場合、エグゼキューターは非 CoW 版にフォールバックする。利用可能な最速（かつデフォルト）の戦略は `pooling-copy-on-write`。`legacy-instance-reuse` は非推奨で将来削除される。デフォルト戦略に問題がある場合のみ使用すること。
        
        [default: pooling-copy-on-write]

        可能な値:
        - pooling-copy-on-write:           各インスタンス化での初期化を避けるためにインスタンスをプールする。可能なら copy-on-write メモリを使用する
        - recreate-instance-copy-on-write: 各インスタンス化のたびに最初からインスタンスを作成する。可能なら copy-on-write メモリを使用する
        - pooling:                         各インスタンス化での初期化を避けるためにインスタンスをプールする
        - recreate-instance:               各インスタンス化のたびに最初からインスタンスを作成する。非常に遅い

    --wasm-runtime-overrides <PATH>
        ローカルの WASM ランタイムを格納するパスを指定する。
        
        バージョンが一致する場合、これらのランタイムがオンチェーンのランタイムを上書きする。

    --execution-syncing <STRATEGY>
        初期同期時のブロック取り込みにおけるランタイム実行戦略

        可能な値:
        - native:           ネイティブビルドで実行（利用可能なら、そうでなければ WebAssembly）
        - wasm:             WebAssembly ビルドのみで実行
        - both:             ネイティブ（利用可能なら）と WebAssembly の両方で実行
        - native-else-wasm: 可能ならネイティブビルドで実行し、失敗したら WebAssembly で実行

    --execution-import-block <STRATEGY>
        一般的なブロック取り込み（ローカルで生成したブロックを含む）におけるランタイム実行戦略

        可能な値:
        - native:           ネイティブビルドで実行（利用可能なら、そうでなければ WebAssembly）
        - wasm:             WebAssembly ビルドのみで実行
        - both:             ネイティブ（利用可能なら）と WebAssembly の両方で実行
        - native-else-wasm: 可能ならネイティブビルドで実行し、失敗したら WebAssembly で実行

    --execution-block-construction <STRATEGY>
        ブロック構築におけるランタイム実行戦略

        可能な値:
        - native:           ネイティブビルドで実行（利用可能なら、そうでなければ WebAssembly）
        - wasm:             WebAssembly ビルドのみで実行
        - both:             ネイティブ（利用可能なら）と WebAssembly の両方で実行
        - native-else-wasm: 可能ならネイティブビルドで実行し、失敗したら WebAssembly で実行

    --execution-offchain-worker <STRATEGY>
        オフチェーンワーカーにおけるランタイム実行戦略

        可能な値:
        - native:           ネイティブビルドで実行（利用可能なら、そうでなければ WebAssembly）
        - wasm:             WebAssembly ビルドのみで実行
        - both:             ネイティブ（利用可能なら）と WebAssembly の両方で実行
        - native-else-wasm: 可能ならネイティブビルドで実行し、失敗したら WebAssembly で実行

    --execution-other <STRATEGY>
        同期・取り込み・構築以外でのランタイム実行戦略

        可能な値:
        - native:           ネイティブビルドで実行（利用可能なら、そうでなければ WebAssembly）
        - wasm:             WebAssembly ビルドのみで実行
        - both:             ネイティブ（利用可能なら）と WebAssembly の両方で実行
        - native-else-wasm: 可能ならネイティブビルドで実行し、失敗したら WebAssembly で実行

    --execution <STRATEGY>
        すべての実行コンテキストで使用する実行戦略

        可能な値:
        - native:           ネイティブビルドで実行（利用可能なら、そうでなければ WebAssembly）
        - wasm:             WebAssembly ビルドのみで実行
        - both:             ネイティブ（利用可能なら）と WebAssembly の両方で実行
        - native-else-wasm: 可能ならネイティブビルドで実行し、失敗したら WebAssembly で実行

    --trie-cache-size <Bytes>
        状態キャッシュのサイズを指定する。
        
        `0` を指定するとキャッシュを無効化する。
        
        [default: 67108864]

    --state-cache-size <STATE_CACHE_SIZE>
        非推奨: `--trie-cache-size` に切り替えること

    --bootnodes <ADDR>...
        ブートノードのリストを指定する

    --reserved-nodes <ADDR>...
        予約ノードアドレスのリストを指定する

    --reserved-only
        予約ノードのみとチェーンを同期するかどうか。
        
        自動ピア探索も無効化する。TCP 接続は非予約ノードとも確立されうる。特にバリデーターの場合、予約ノードとして定義されているかどうかに関わらず、他のバリデーターノードやコレーター
        ノードに接続する可能性がある。

    --public-addr <PUBLIC_ADDR>...
        他のノードがこのノードに接続する際に使う公開アドレス。
        
        このノードの前段にプロキシがある場合に使用できる。

    --listen-addr <LISTEN_ADDR>...
        このマルチアドレスで待ち受ける。
        
        デフォルト: `--validator` が渡された場合は `/ip4/0.0.0.0/tcp/<port>` と `/ip6/[::]/tcp/<port>`。それ以外は `/ip4/0.0.0.0/tcp/<port>/ws` と `/ip6/[::]/tcp/<port>/ws`。

    --port <PORT>
        p2p プロトコルの TCP ポートを指定する

    --no-private-ip
        常にプライベート IPv4/IPv6 アドレスへの接続を禁止する。
        
        `--reserved-nodes` または `--bootnodes` で渡されたアドレスには適用されない。チェーン仕様で "live" とマークされたチェーンではデフォルトで有効。
        
        プライベートネットワークのアドレス割り当ては [RFC1918](https://tools.ietf.org/html/rfc1918)) で規定される。

    --allow-private-ip
        常にプライベート IPv4/IPv6 アドレスへの接続を許可する。
        
        チェーン仕様で "local" とマークされたチェーン、または `--dev` が指定された場合にデフォルトで有効。
        
        プライベートネットワークのアドレス割り当ては [RFC1918](https://tools.ietf.org/html/rfc1918)) で規定される。

    --out-peers <COUNT>
        維持しようとする送信接続数
        
        [default: 8]

    --in-peers <COUNT>
        受信するフルノードピアの最大数
        
        [default: 32]

    --in-peers-light <COUNT>
        受信するライトノードピアの最大数
        
        [default: 100]

    --no-mdns
        mDNS 探索を無効化する（デフォルト: true）。
        
        デフォルトでは、ネットワークはローカルネットワーク上の他ノードを mDNS で探索する。これを無効化する。`--dev` 使用時は自動的に指定される。

    --max-parallel-downloads <COUNT>
        同じブロックを並列に要求するピアの最大数。
        
        複数ピアから通知されたブロックをダウンロードできる。トラフィックを節約し、遅延が増えるリスクを下げるには値を小さくする。
        
        [default: 5]

    --node-key <KEY>
        p2p ネットワーキングに使う秘密鍵。
        
        値は `--node-key-type` の選択に従って次のように解析される:
        
        - `ed25519`: 値は hex エンコードされた Ed25519 32 バイト秘密鍵（64 hex 文字）として解析される
        
        このオプションの値は `--node-key-file` より優先される。
        
        警告: コマンドライン引数として渡した秘密情報は容易に露出する。このオプションの使用は開発やテストに限定すること。外部で管理された秘密鍵を使うには `--node-key-file` を使う。

    --node-key-type <TYPE>
        p2p ネットワーキングに使う暗号プリミティブ。
        
        ノードの秘密鍵は以下の手順で取得される:
        
        - `--node-key` オプションが指定された場合、値はそのタイプに従って秘密鍵として解析される。`--node-key` のドキュメント参照。
        
        - `--node-key-file` オプションが指定された場合、秘密鍵は指定されたファイルから読み込まれる。`--node-key-file` のドキュメント参照。
        
        - それ以外は、`--base-dir` で指定されたベースディレクトリ内のチェーン固有のネットワーク設定ディレクトリにある、タイプ別の既定ファイル名から秘密鍵を読み込む。このファイルが存在しない場合、選択したタイプの新しい秘密鍵が生成される。
        
        ノードの秘密鍵は対応する公開鍵を決定し、libp2p の文脈におけるノードのピア ID を決定する。
        
        [default: ed25519]

        可能な値:
        - ed25519: ed25519 を使用する

    --node-key-file <FILE>
        p2p ネットワーキングに使うノードの秘密鍵を読み込むファイル。
        
        ファイルの内容は `--node-key-type` の選択に従って次のように解析される:
        
        - `ed25519`: ファイルには未エンコードの 32 バイト、または hex エンコードされた Ed25519 秘密鍵が含まれている必要がある。
        
        ファイルが存在しない場合、選択したタイプの新しい秘密鍵が生成される。

    --unsafe-force-node-key-generation
        node-key-file が存在しない場合に鍵生成を強制する。
        
        これは本番ネットワークには安全でない機能。アクティブなオーソリティとして、他のオーソリティは安定したアイデンティティに依存する可能性があり、アクティブセットに参加した後に ID が変わると到達できなくなることがある。
        
        カスタム `node-key-file` 引数が提供されない場合、ネットワークキーは通常、`--base-path` で指定されたディレクトリ内の `network` フォルダーにノード再起動間で保持される。
        
        警告!! この引数を指定してノードを実行した場合、次回以降の再起動では必ず削除すること。

    --discover-local
        ローカルネットワークでのピア探索を有効化する。
        
        デフォルトでは、`--dev` が指定された場合、またはチェーンタイプが `Local`/`Development` の場合は `true`、それ以外は false。

    --kademlia-disjoint-query-paths
        反復的な Kademlia DHT クエリで互いに交わらないパスの使用を要求する。
        
        互いに交わらないパスは、潜在的に敵対的なノードの存在下での回復力を高める。
        
        高レベル設計とそのセキュリティ改善については S/Kademlia 論文を参照。

    --kademlia-replication-factor <KADEMLIA_REPLICATION_FACTOR>
        Kademlia のレプリケーション係数。
        
        レコードが最も近いどのピアに複製されるかを決定する。
        
        Discovery メカニズムは、すべての `kademlia_replication_factor` ピアへの複製が成功した場合のみ、レコードが正常に投入されたとみなす。
        
        [default: 20]

    --ipfs-server
        IPFS ネットワークに参加し、bitswap プロトコルでトランザクションを提供する

    --sync <SYNC_MODE>
        ブロックチェーンの同期モード。
        
        [default: full]

        可能な値:
        - full:        フル同期。すべてのブロックをダウンロードし検証する
        - fast:        ブロックを実行せずにダウンロードする。証明付きで最新の状態をダウンロードする
        - fast-unsafe: ブロックを実行せずにダウンロードする。証明なしで最新の状態をダウンロードする
        - warp:        最終性を証明し、最新の状態をダウンロードする

    --max-blocks-per-request <COUNT>
        1 リクエストあたりの最大ブロック数。
        
        低速なネットワーク接続でブロックリクエストのタイムアウトが見られる場合、デフォルト値から減らすことを試す。
        
        [default: 64]

    --network-backend <NETWORK_BACKEND>
        P2P ネットワーキングに使うネットワークバックエンド。
        
        litep2p ネットワークバックエンドは実験的で、libp2p バックエンドほど安定していない。
        
        [default: libp2p]

        可能な値:
        - libp2p:  P2P ネットワーキングに libp2p を使う
        - litep2p: P2P ネットワーキングに litep2p を使う

    --pool-limit <COUNT>
        トランザクションプール内の最大トランザクション数
        
        [default: 8192]

    --pool-kbytes <COUNT>
        プールに保存される全トランザクションの最大キロバイト数
        
        [default: 20480]

    --tx-ban-seconds <SECONDS>
        トランザクションの禁止期間。
        
        無効と判断された場合。デフォルトは 1800 秒。

    --keystore-path <PATH>
        カスタムのキーストアパスを指定する

    --password-interactive
        キーストアで使うパスワード入力に対話シェルを使う

    --password <PASSWORD>
        キーストアに使うパスワード。
        
        これによりシードにユーザー定義の追加シークレットを付加できる。

    --password-filename <PATH>
        キーストアに使うパスワードが入ったファイル

    --alice
        `--name Alice --validator` のショートカット。
        
        `Alice` のセッションキーがキーストアに追加される。

    --bob
        `--name Bob --validator` のショートカット。
        
        `Bob` のセッションキーがキーストアに追加される。

    --charlie
        `--name Charlie --validator` のショートカット。
        
        `Charlie` のセッションキーがキーストアに追加される。

    --dave
        `--name Dave --validator` のショートカット。
        
        `Dave` のセッションキーがキーストアに追加される。

    --eve
        `--name Eve --validator` のショートカット。
        
        `Eve` のセッションキーがキーストアに追加される。

    --ferdie
        `--name Ferdie --validator` のショートカット。
        
        `Ferdie` のセッションキーがキーストアに追加される。

    --one
        `--name One --validator` のショートカット。
        
        `One` のセッションキーがキーストアに追加される。

    --two
        `--name Two --validator` のショートカット。
        
        `Two` のセッションキーがキーストアに追加される。

    --force-authoring
        オフライン時でもブロック生成を有効にする

    --tmp
        一時ノードとして実行する。
        
        設定の保存用に一時ディレクトリが作成され、プロセス終了時に削除される。
        
        注: ディレクトリはプロセス実行ごとにランダム。これはベースパスとして使用され、データベース、ノードキー、キーストアを含む。
        
        `--dev` が指定され、明示的な `--base-path` がない場合、このオプションが暗黙的に指定される。

    -h, --help
            ヘルプを表示する（'-h' で概要）

    ================================================================================
    ChainSpecCfg
    ================================================================================

    NAME:          genesis_utxo
    HELP:          chain-spec 生成: genesis_utxo のためのパートナーチェーンパラメータ
    TYPE:          Option < UtxoId >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          addresses_json
    HELP:          partnerchains が提供する partner-chains-cli の出力ファイル。
                実行時にノードへ設定を提供するために必要。
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    ================================================================================
    MetaCfg
    ================================================================================

    NAME:          cfg_preset
    HELP:          デフォルト設定値のプリセットを使用する
    TYPE:          Option < CfgPreset >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          show_config
    HELP:          起動時に設定を表示する
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          show_secrets
    HELP:          設定に含まれる秘密情報を表示する
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    ================================================================================
    MidnightCfg
    ================================================================================

    NAME:          wipe_chain_state
    HELP:          起動時にチェーンを消去する
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          seed_phrase
    HELP:          このノードのオーサリング機能で使うキーをキーストアに挿入するためのシード。
                これは必要なキー三つ組（`aura`、`grandpa`、`cross_chain`）を自動生成する。
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          use_main_chain_follower_mock
    HELP:          ariadne パラメータのモック
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          main_chain_follower_mock_registrations_file
    HELP:          use_main_chain_follower_mock が true の場合に必要
                sidechains ライブラリで使用される
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          mc__first_epoch_timestamp_millis
    HELP:          partner-chains の EpochConfig を参照
    TYPE:          u64
    DEFAULT:       1666656000000
    SOURCES:       default
    CURRENT_VALUE: 1666656000000

    NAME:          mc__first_epoch_number
    HELP:          partner-chains の EpochConfig を参照
    TYPE:          u32
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    NAME:          mc__epoch_duration_millis
    HELP:          partner-chains の EpochConfig を参照
    TYPE:          u64
    DEFAULT:       86400000
    SOURCES:       default
    CURRENT_VALUE: 86400000

    NAME:          mc__first_slot_number
    HELP:          partner-chains の EpochConfig を参照
    TYPE:          u64
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    NAME:          db_sync_postgres_connection_string
    HELP:          partner-chains の ConnectionConfig を参照
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          cardano_security_parameter
    HELP:          partner-chains の CandidateDataSourceCacheConfig と DbSyncBlockDataSourceConfig を参照
    TYPE:          Option < u32 >
    DEFAULT:       432
    SOURCES:       default
    CURRENT_VALUE: 432

    NAME:          cardano_active_slots_coeff
    HELP:          partner-chains の DbSyncBlockDataSourceConfig を参照
    TYPE:          Option < f64 >
    DEFAULT:       0.05
    SOURCES:       default
    CURRENT_VALUE: 0.05

    NAME:          block_stability_margin
    HELP:          partner-chains の DbSyncBlockDataSourceConfig を参照
    TYPE:          Option < u32 >
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    NAME:          proposed_wasm_file
    HELP:          Midnight ランタイムの新しいランタイムファイルの任意提案。
                スペックバージョンとコードハッシュがこのファイルから抽出され、そうでなければデフォルトパスが使用される。
                デフォルトパスにない場合、ノードはランタイムアップグレードのために昇格すべき WASM に賛成票を投じない
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          storage_cache_size
    HELP:          レジャーのストレージキャッシュサイズ（ノード数）
    TYPE:          usize
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    ================================================================================
    StorageMonitorParamsCfg
    ================================================================================

    NAME:          threshold
    HELP:          データベースストレージの必要な空き容量
    TYPE:          u64
    DEFAULT:       512
    SOURCES:       default
    CURRENT_VALUE: 512

    NAME:          polling_period
    HELP:          空き容量をポーリングする頻度
    TYPE:          u32
    DEFAULT:       5
    SOURCES:       default
    CURRENT_VALUE: 5

    ================================================================================
    SubstrateCfg
    ================================================================================

    NAME:          argv
    HELP:          削除済み: 代わりに "args" を使用
                バイナリを含む、ノードに渡される引数
    TYPE:          Vec < String >
    DEFAULT:       
    SOURCES:       default
    CURRENT_VALUE: ""

    NAME:          args
    HELP:          ノードに渡される引数
    TYPE:          Vec < String >
    DEFAULT:       
    SOURCES:       cli
    CURRENT_VALUE: "--help, "

    NAME:          append_args
    HELP:          args に追加する追加引数
    TYPE:          Vec < String >
    DEFAULT:       
    SOURCES:       default
    CURRENT_VALUE: ""

    NAME:          base_path
    HELP:          base_path の任意の上書き。argv の --base-path が優先される
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          node_key
    HELP:          node_key の任意の上書き。argv の --node-key が優先される
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          chain
    HELP:          chain の任意の上書き。argv の --chain が優先される
    TYPE:          Option < String >
    DEFAULT:       
    SOURCES:       
    CURRENT_VALUE: <unset>

    NAME:          validator
    HELP:          argv の --validator の上書き
    TYPE:          bool
    DEFAULT:       false
    SOURCES:       default
    CURRENT_VALUE: false

    NAME:          bootnodes
    HELP:          ブートノードのリストに追加する
    TYPE:          Vec < MultiaddrWithPeerId >
    DEFAULT:       
    SOURCES:       default
    CURRENT_VALUE: ""

    NAME:          trie_cache_size
    HELP:          --trie_cache_size の上書き。argv の --trie-cache-size が優先される（デフォルト値に設定されない限り）。
    TYPE:          Option < usize >
    DEFAULT:       0
    SOURCES:       default
    CURRENT_VALUE: 0

    CONFIG PRESET: None
    VALIDATION RESULT: 設定の検証に失敗: config error: {"errors":["ariadne が有効（use_main_chain_follower_mock が false）の場合は db_sync_postgres_connection_string を定義する必要があります"],"properties":{}}
    *note:* 秘密情報の値を表示するには、SHOW_SECRETS=1 を設定してください

    Midnight ブロックチェーンノード。<COMMAND> なしで実行するとノードが起動する。全設定オプションを見るには、引数なしで環境変数 SHOW_CONFIG=TRUE を指定するか --help を実行する

    使用法: midnight-node <COMMAND>

    コマンド:
    key                      鍵管理 CLI ユーティリティ
    sidechain-params         サイドチェーンのパラメータを返す
    registration-status      指定したメインチェーン公開鍵とエポック番号の登録状況を返す。登録がエポック N の Cardano ブロックに含まれている場合、N+1 より大きいエポックを指定すると返される。数分経っても
                            登録が表示されない場合は、登録失敗のデバッグを開始できる
    ariadne-parameters       指定したメインチェーンのエポック番号で有効な ariadne パラメータを返す。パラメータは変更が含まれたブロックの 2 エポック後に有効になる
    registration-signatures  パートナーチェーンの委員会候補向け登録署名を生成する
    smart-contracts          Cardano 上の Partner Chain スマートコントラクトとやり取りするためのコマンド
    wizards                  チェーン設定のための Partner Chains テキスト "wizards"
    build-spec               チェーン仕様をビルドする
    check-block              ブロックを検証する
    export-blocks            ブロックをエクスポートする
    export-state             指定したブロックの状態をチェーン仕様にエクスポートする
    import-blocks            ブロックをインポートする
    purge-chain              チェーン全体を削除する
    revert                   チェーンを以前の状態に戻す
    benchmark                ベンチマークに関するサブコマンド
    chain-info               DB メタカラム情報
    help                     このメッセージ、または指定したサブコマンドのヘルプを表示する

    オプション:
    -h, --help     ヘルプを表示
    -V, --version  バージョンを表示
    ```

---