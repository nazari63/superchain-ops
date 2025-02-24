set dotenv-load

export rpcUrl := env_var_or_default('ETH_RPC_URL', 'https://ethereum.publicnode.com')
export signatures := env_var_or_default('SIGNATURES', '')
export taskPath := invocation_directory()
export scriptPath := justfile_directory()
export scriptName := env_var('SCRIPT_NAME')

# Accounts
export councilSafe := env_var("COUNCIL_SAFE")
export foundationSafe := env_var("FOUNDATION_SAFE")
export chainGovernorSafe := env_var_or_default('CHAIN_GOVERNOR_SAFE', '')
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"

simulate whichSafe hdPath='0':
  #!/usr/bin/env bash
  config=${taskPath}/config.toml
  script=${scriptPath}/template/${scriptName}.sol

  echo "Using script ${script}"
  echo "getting signer address for {{whichSafe}}..."

  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi
  signer=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)

  echo "safe: $safe"
  echo "Simulating call to {{whichSafe}} at ${safe}"
  if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    echo "Simulating with ledger account: ${signer}"
  else
      echo "Simulating without ledger using the first owner account: ${signer}"
  fi
  echo ""

  forge build
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sender ${signer} \
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    ${safe}

sign whichSafe hdPath='0':
  #!/usr/bin/env bash
  config=${taskPath}/config.toml
  script=${scriptPath}/template/${scriptName}.sol

  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    "${safe}"

approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  config=${taskPath}/config.toml
  script=${scriptPath}/template/${scriptName}.sol

  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "approveFromChildMultisig(string,address,bytes)" \
    ${config} \
    ${safe} \
    ${signatures}

simulate-approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  config=${taskPath}/config.toml
  script=${scriptPath}/template/${scriptName}.sol

  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    sender=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)
  else
    sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${sender} \
    --sig "approveFromChildMultisig(string,address,bytes)" \
    ${config} \
    ${safe} \
    ${signatures}

execute hdPath='0':
  #!/usr/bin/env bash
  config=${taskPath}/config.toml
  script=${scriptPath}/template/${scriptName}.sol

  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "executeRun(string,bytes)" \
    ${config} \
    "0x"

simulated-run hdPath='0':
  #!/usr/bin/env bash
  config=${taskPath}/config.toml
  script=${scriptPath}/template/${scriptName}.sol

  echo "Using script ${script}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${randomPersonEoa} \
    --sig "executeRun(string,bytes)" \
    ${config} \
    "0x"
