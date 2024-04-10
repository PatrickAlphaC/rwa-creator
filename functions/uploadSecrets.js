const {
    SecretsManager,
} = require("@chainlink/functions-toolkit")
const ethers = require("ethers")


const uploadSecrets = async () => {
    // hardcoded for Sepolia
    const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0"
    const donId = "fun-ethereum-sepolia-1"
    const gatewayUrls = [
        "https://01.functions-gateway.testnet.chain.link/",
        "https://02.functions-gateway.testnet.chain.link/",
    ]

    // Initialize ethers signer and provider to interact with the contracts onchain
    const privateKey = process.env.PRIVATE_KEY // fetch PRIVATE_KEY
    if (!privateKey)
        throw new Error(
            "private key not provided - check your environment variables"
        )

    const rpcUrl = process.env.SEPOLIA_RPC_URL

    if (!rpcUrl)
        throw new Error(`rpcUrl not provided  - check your environment variables`)

    const secrets = { alpacaKey: process.env.ALPACA_KEY ?? "", alpacaSecret: process.env.ALPACA_SECRET ?? "" }
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl)
    const wallet = new ethers.Wallet(privateKey)
    const signer = wallet.connect(provider) // create ethers signer for signing transactions

    // First encrypt secrets and upload the encrypted secrets to the DON
    const secretsManager = new SecretsManager({
        signer: signer,
        functionsRouterAddress: routerAddress,
        donId: donId,
    })
    await secretsManager.initialize()

    // Encrypt secrets and upload to DON
    const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets)
    const slotIdNumber = 0 // slot ID where to upload the secrets
    const expirationTimeMinutes = 1440 // expiration time in minutes of the secrets, 1440 is 1 day


    console.log(
        `Upload encrypted secret to gateways ${gatewayUrls}. slotId ${slotIdNumber}. Expiration in minutes: ${expirationTimeMinutes}`
    )
    // Upload secrets
    const uploadResult = await secretsManager.uploadEncryptedSecretsToDON({
        encryptedSecretsHexstring: encryptedSecretsObj.encryptedSecrets,
        gatewayUrls: gatewayUrls,
        slotId: slotIdNumber,
        minutesUntilExpiration: expirationTimeMinutes,
    })

    if (!uploadResult.success)
        throw new Error(`Encrypted secrets not uploaded to ${gatewayUrls}`)

    console.log(
        `\n✅ Secrets uploaded properly to gateways ${gatewayUrls}! Gateways response: `,
        uploadResult
    )

    const donHostedSecretsVersion = parseInt(uploadResult.version) // fetch the reference of the encrypted secrets
    console.log(`\n✅ Secrets version: ${donHostedSecretsVersion}`)

}

uploadSecrets().catch((e) => {
    console.error(e)
    process.exit(1)
})