// // What does this script do? 
// // 1. Sells TSLA on alpaca for USD 
// // 2. Buys USDC -> with USD
// // 3. Sends USDC -> contract for withdrawl

// // Return 0 on unsuccessful sell 

const ASSET_TICKER = "TSLA"
const CRYPTO_TICKER = "USDCUSD"
// TODO
const RWA_CONTRACT = "0x7358D4CDF1c468aA018ec41ddD98b44879a10962"
const SLEEP_TIME = 5000 // 5 seconds


async function main() {
    const amountTsla = args[0]
    const amountUsdc = args[1]
    _checkKeys()

    /*//////////////////////////////////////////////////////////////
                           SELL TSLA FOR USD
    //////////////////////////////////////////////////////////////*/
    let side = "sell"
    let [client_order_id, orderStatus, responseStatus] = await placeOrder(ASSET_TICKER, amountTsla, side)
    if (responseStatus !== 200) {
        return Functions.encodeUint256(0)
    }
    if (orderStatus !== "accepted") {
        return Functions.encodeUint256(0)
    }

    let filled = await waitForOrderToFill(client_order_id)
    if (!filled) {
        // @audit, if this fails... That's probably an issue
        await cancelOrder(client_order_id)
        return Functions.encodeUint256(0)
    }

    /*//////////////////////////////////////////////////////////////
                           BUY USDC WITH USD
    //////////////////////////////////////////////////////////////*/
    side = "buy"
    [client_order_id, orderStatus, responseStatus] = await placeOrder(CRYPTO_TICKER, amountTsla, side)
    if (responseStatus !== 200) {
        return Functions.encodeUint256(0)
    }
    if (orderStatus !== "accepted") {
        return Functions.encodeUint256(0)
    }
    filled = await waitForOrderToFill(client_order_id)
    if (!filled) {
        // @audit, if this fails... That's probably an issue
        await cancelOrder(client_order_id)
        return Functions.encodeUint256(0)
    }
  
    /*//////////////////////////////////////////////////////////////
                         SEND USDC TO CONTRACT
    //////////////////////////////////////////////////////////////*/
    const transferId = await sendUsdcToContract(amountUsdc)
    if (transferId === null) {
        return Functions.encodeUint256(0)
    }

    const completed = await waitForCryptoTransferToComplete(transferId)
    if (!completed) {
        return Functions.encodeUint256(0)
    }
    return Functions.encodeUint256(amountUsdc)
}


// returns string: client_order_id, string: orderStatus, int: responseStatus
async function placeOrder(symbol, qty, side) {
    // TODO, something is wrong with this request, need to fix
    const alpacaSellRequest = Functions.makeHttpRequest({
        method: 'POST',
        url: "https://paper-api.alpaca.markets/v2/orders",
        headers: {
            'accept': 'application/json',
            'content-type': 'application/json',
            'APCA-API-KEY-ID': secrets.alpacaKey,
            'APCA-API-SECRET-KEY': secrets.alpacaSecret
        },
        data: {
            side: side,
            type: "market",
            time_in_force: "gtc",
            symbol: symbol,
            qty: qty
        }
    })

    const [response] = await Promise.all([
        alpacaSellRequest,
    ])
    const responseStatus = response.status
    console.log(`\nResponse status: ${responseStatus}\n`)
    console.log(response)
    console.log(`\n`)

    const { client_order_id, status: orderStatus } = response.data
    return client_order_id, orderStatus, responseStatus
}

// returns int: responseStatus
async function cancelOrder(client_order_id) {
    const alpacaCancelRequest = Functions.makeHttpRequest({
        method: 'DELETE',
        url: `https://paper-api.alpaca.markets/v2/orders/${client_order_id}`,
        headers: {
            'accept': 'application/json',
            'APCA-API-KEY-ID': secrets.alpacaKey,
            'APCA-API-SECRET-KEY': secrets.alpacaSecret
        }
    })

    const [response] = await Promise.all([
        alpacaCancelRequest,
    ])

    const responseStatus = response.status
    return responseStatus
}

// @returns bool
async function waitForOrderToFill(client_order_id) {
    let numberOfSleeps = 0
    const capNumberOfSleeps = 10
    let filled = false

    while (numberOfSleeps < capNumberOfSleeps) {
        const alpacaOrderStatusRequest = Functions.makeHttpRequest({
            method: 'GET',
            url: `https://paper-api.alpaca.markets/v2/orders/${client_order_id}`,
            headers: {
                'accept': 'application/json',
                'APCA-API-KEY-ID': secrets.alpacaKey,
                'APCA-API-SECRET-KEY': secrets.alpacaSecret
            }
        })

        const [response] = await Promise.all([
            alpacaOrderStatusRequest,
        ])

        const responseStatus = response.status
        const { status: orderStatus } = response.data
        if (responseStatus !== 200) {
            return false
        }
        if (orderStatus === "filled") {
            filled = true
            break
        }
        numberOfSleeps++
        await sleep(SLEEP_TIME)
    }
    return filled
}

// returns string: transferId
async function sendUsdcToContract(usdcAmount) {
    const transferRequest = Functions.makeHttpRequest({
        method: 'POST',
        url: "https://paper-api.alpaca.markets/v2/wallets/transfers",
        headers: {
            'accept': 'application/json',
            'content-type': 'application/json',
            'APCA-API-KEY-ID': secrets.alpacaKey,
            'APCA-API-SECRET-KEY': secrets.alpacaSecret
        },
        data: {
            "amount": usdcAmount,
            "address": RWA_CONTRACT,
            "asset": CRYPTO_TICKER
        }
    })

    const [response] = await Promise.all([
        transferRequest,
    ])
    if (response.status !== 200) {
        return null
    }
    return response.data.id
}

async function waitForCryptoTransferToComplete(transferId) {
    let numberOfSleeps = 0
    const capNumberOfSleeps = 120 // 120 * 5 seconds = 10 minutes
    let completed = false

    while (numberOfSleeps < capNumberOfSleeps) {
        const alpacaTransferStatusRequest = Functions.makeHttpRequest({
            method: 'GET',
            url: `https://paper-api.alpaca.markets/v2/wallets/transfers/${transferId}`,
            headers: {
                'accept': 'application/json',
                'APCA-API-KEY-ID': secrets.alpacaKey,
                'APCA-API-SECRET-KEY': secrets.alpacaSecret
            }
        })

        const [response] = await Promise.all([
            alpacaTransferStatusRequest,
        ])

        const responseStatus = response.status
        // @audit, the transfer could complete, but the response could be 400
        const { status: transferStatus } = response.data
        if (responseStatus !== 200) {
            return false
        }
        if (transferStatus === "completed") {
            completed = true
            break
        }
        numberOfSleeps++
        await sleep(SLEEP_TIME)
    }
    return completed

}

function _checkKeys() {
    if (
        secrets.alpacaKey == "" ||
        secrets.alpacaSecret === ""
    ) {
        throw Error(
            "need alpaca keys"
        )
    }
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

const result = await main()
return result