# Bitzlato WebSocket API

[Bitzlato WebSocket API](https://github.com/bitzlato/peatio/blob/master/docs/api/websocket_api.md) connections are handled by [rango](https://github.com/bitzlato/rango) service.

## API

There are two types of channels:

- Public: accessible by anyone
- Private: accessible only by given member

GET request parameters:

| Field    | Description                         | Multiple allowed |
| -------- | ----------------------------------- | ---------------- |
| `stream` | List of streams to be subscribed on | Yes              |

List of supported public streams:

- [`<market>.ob-inc`](#order-book) market order-book update
- [`<market>.trades` ](#trades)
- [`<market>.kline-PERIOD` ](#kline-point) (available periods are "1m", "5m", "15m", "30m", "1h", "2h", "4h", "6h", "12h", "1d", "3d", "1w")
- [`global.tickers`](#tickers)

List of supported private streams (requires authentication):

- [`order`](#order)
- [`trade`](#trade)

You can find a format of these events below in the doc.

## Connection

Example of connection to public channel using the [wscat](https://github.com/websockets/wscat):

```bash
$ wscat -n -c 'wss://market.bitzlato.com/api/v2/ranger/public?stream=usdeth'
```

Connection to the private channel requires creating the [API key](https://github.com/bitzlato/peatio/blob/master/docs/api/trading_api.md#how-to-create-api-key). Example of connection on nodejs:

```js
const websocket = require("ws");
const crypto = require("crypto");

const nonce = Date.now();
const apiKey = "changeme";
const secretKey = "changeme";
const signature = crypto
  .createHmac("sha256", secretKey)
  .update(nonce + apiKey)
  .digest("hex");

const client = new websocket(
  "wss://market.bitzlato.com/api/v2/ranger/private?cancel_on_close=1",
  {
    headers: {
      "X-Auth-Nonce": nonce,
      "X-Auth-Apikey": apiKey,
      "X-Auth-Signature": signature,
    },
  }
);
```

## Streams subscription

### Using parameters

You can specify streams to subscribe to by passing the `stream` GET parameter in the connection URL. The parameter can be specified multiple times for subscribing to multiple streams.

example:

```
wss://demo.openware.com/api/v2/ranger/public/?stream=global.tickers&stream=ethusd.trades
```

This will subscribe you to _tickers_ and _trades_ events from _ethusd_ market once the connection is established.

### Subscribe and unsubscribe events

You can manage the connection subscriptions by send the following events after the connection is established:

Subscribe event will subscribe you to the list of streams provided:

```json
{ "event": "subscribe", "streams": ["ethusd.trades", "ethusd.ob-inc"] }
```

The server confirms the subscription with the following message and provides the new list of your current subscrictions:

```json
{
  "success": {
    "message": "subscribed",
    "streams": ["global.tickers", "ethusd.trades", "ethusd.ob-inc"]
  }
}
```

Unsubscribe event will unsubscribe you to the list of streams provided:

```json
{ "event": "unsubscribe", "streams": ["ethusd.trades", "ethusd.ob-inc"] }
```

The server confirms the unsubscription with the following message and provides the new list of your current subscrictions:

```json
{
  "success": {
    "message": "unsubscribed",
    "streams": ["global.tickers", "ethusd.kline-15m"]
  }
}
```

## Public streams

### Order-Book

This stream sends a snapshot of the order-book at the subscription time, then it sends increments. Volumes information in increments replace the previous values. If the volume is zero the price point should be removed from the order-book.

Register to stream `<market>.ob-inc` to receive snapshot and increments messages.

Example of order-book snapshot:

```json
{
  "eurusd.ob-snap": {
    "asks": [
      ["15.0", "21.7068"],
      ["20.0", "100.2068"],
      ["20.5", "30.2068"],
      ["30.0", "21.2068"]
    ],
    "bids": [
      ["10.95", "21.7068"],
      ["10.90", "65.2068"],
      ["10.85", "55.2068"],
      ["10.70", "30.2068"]
    ]
  }
}
```

Example of order-book increment message:

```json
{
  "eurusd.ob-inc": {
    "asks": [["15.0", "22.1257"]]
  }
}
```

### Trades

Here is structure of `<market>.trades` event expose as array with trades:

| Field        | Description                                  |
| ------------ | -------------------------------------------- |
| `tid`        | Unique trade tid.                            |
| `taker_type` | Taker type of trade, either `buy` or `sell`. |
| `price`      | Price for the trade.                         |
| `amount`     | The amount of trade.                         |
| `created_at` | Trade create time.                           |

### Kline point

Kline point as array of numbers:

1. Timestamp.
2. Open price.
3. Max price.
4. Min price.
5. Last price.
6. Period volume

Example:

```ruby
[1537370580, 0.0839, 0.0921, 0.0781, 0.0845, 0.5895]
```

### Tickers

Here is structure of `global.tickers` event expose as array with all markets pairs:

| Field                  | Description                      |
| ---------------------- | -------------------------------- |
| `at`                   | Date of current ticker.          |
| `name`                 | Market pair name.                |
| `base_unit`            | Base currency.                   |
| `quote_unit`           | Quote currency.                  |
| `low`                  | Lowest price in 24 hours.        |
| `high`                 | Highest price in 24 hours.       |
| `last`                 | Last trade price.                |
| `open`                 | Last trade from last timestamp.  |
| `close`                | Last trade price.                |
| `volume`               | Volume in 24 hours.              |
| `sell`                 | Best price per unit.             |
| `buy`                  | Best price per unit.             |
| `avg_price`            | Average price for last 24 hours. |
| `price_change_percent` | Average price change in percent. |

## Private streams

### Order

Here is structure of `Order` event:

| Field              | Description                                                      |
| ------------------ | ---------------------------------------------------------------- |
| `id`               | Unique order id.                                                 |
| `market`           | The market in which the order is placed. (In peatio `market_id`) |
| `order_type`       | Order type, either `limit` or `market`.                          |
| `price`            | Order price.                                                     |
| `avg_price`        | Order average price.                                             |
| `state`            | One of `wait`, `done`, `reject` or `cancel`.                     |
| `origin_volume`    | The amount user want to sell/buy.                                |
| `remaining_volume` | Remaining amount user want to sell/buy.                          |
| `executed_volume`  | Executed amount for current order.                               |
| `created_at`       | Order create time.                                               |
| `updated_at`       | Order create time.                                               |
| `trades_count`     | Trades with this order.                                          |
| `kind`             | Type of order, either `bid` or `ask`. (Deprecated)               |
| `at`               | Order create time. (Deprecated) (In peatio `created_at`)         |

### Trade

Here is structure of `Trade` event:

| Field        | Description                                                          |
| ------------ | -------------------------------------------------------------------- |
| `id`         | Unique trade identifier.                                             |
| `price`      | Price for each unit.                                                 |
| `amount`     | The amount of trade.                                                 |
| `total`      | The total of trade (volume \* price).                                |
| `market`     | The market in which the trade is placed. (In peatio market_id)       |
| `side`       | Type of order in trade that related to current user `sell` or `buy`. |
| `taker_type` | Order side of the taker for the trade, either `buy` or `sell`.       |
| `created_at` | Trade create time.                                                   |
| `order_id`   | User order identifier in trade.                                      |

## Working with orders

While connecting to the private channel allowed to add GET request parameters:

| Field             | Description                                       | Value |
| ----------------- | ------------------------------------------------- | ----- |
| `cancel_on_close` | Cancel all created orders when closing the socket | 1     |

To create a Sell/Buy order need to send the following message:

```json
{
  "event": "order",
  "data": {
    "market": "btcusd",
    "side": "sell",
    "volume": "1",
    "ord_type": "limit",
    "price": "3000"
  }
}
```

Structure of `Order`:

| Field      | Description                                                                                |
| ---------- | ------------------------------------------------------------------------------------------ |
| `market`   | The market in which the order is placed.                                                   |
| `side`     | Either 'sell' or 'buy'.                                                                    |
| `volume`   | The amount user want to sell/buy.                                                          |
| `ord_type` | Type of order, either 'limit' or 'market'.                                                 |
| `price`    | Price for each unit. e.g. If you want to sell/buy 1 btc at 3000 usd, the price is '3000.0' |
