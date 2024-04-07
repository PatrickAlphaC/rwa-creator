// Sample script to show creating an order works

const axios = require('axios')
require('dotenv').config()

// returns string: client_order_id, string: orderStatus, int: responseStatus
async function placeOrder(symbol, qty, side) {
    const response = await axios({
        method: 'POST',
        url: "https://paper-api.alpaca.markets/v2/orders",
        headers: {
            'accept': 'application/json',
            'content-type': 'application/json',
            'APCA-API-KEY-ID': process.env.ALPACA_KEY,
            'APCA-API-SECRET-KEY': process.env.ALPACA_SECRET
        },
        data: {
            side: side,
            type: "market",
            time_in_force: "gtc",
            symbol: symbol,
            qty: qty
        }
    })

    const responseStatus = response.status
    console.log(`\nResponse status: ${responseStatus}\n`)
    console.log(response.data)
    console.log(`\n`)

    const { client_order_id, status: orderStatus } = response.data
    return { client_order_id, orderStatus, responseStatus }
}

placeOrder("AAPL", 1, "sell")
