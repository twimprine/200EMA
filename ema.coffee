###
  The script engine is based on CoffeeScript (http://coffeescript.org)
  The Cryptotrader API documentation is available at https://cryptotrader.org/api
  
  EMA CROSSOVER TRADING ALGORITHM
  
  The strategy enters buy orders when the short-term EMA crosses above the long-term EMA 
  or enters sell orders when the short-term EMA crosses below the long-term EMA.

  
###

trading = require 'trading' # import core trading module
talib = require 'talib' # import technical indicators library (https://cryptotrader.org/talib)

# Initialization method called before the script starts. 
# Context object holds script data and will be passed to 'handle' method. 
init: ->
    @context.buy_treshold = 0.25
    @context.sell_treshold = 0.25

# This method is called for each tick
handle: ->
    # data object provides access to market data
    instrument = @data.instruments[0]
     # calculate EMA value using ta-lib function
    short = instrument.ema(10)
    long = instrument.ema(21)       
    # plot chart data
    plot
        short: short
        long: long
    diff = 100 * (short - long) / ((short + long) / 2)
    # Uncomment next line for some debugging
    #debug 'EMA difference: '+diff.toFixed(3)+' price: '+instrument.price.toFixed(2)+' at '+new Date(data.at)
 
    if diff > @context.buy_treshold
        # The portfolio object gives access to information about funds 
        # instrument.base() returns base asset id e.g cny
        if @portfolio.positions[instrument.base()].amount > 0
            # open long position
            trading.buy instrument  
    else
        if diff < -@context.sell_treshold
            # instrument.asset() returns traded asset id, for example: "btc"
            if @portfolio.positions[instrument.asset()].amount > 0
                # close long position
                trading.sell instrument

