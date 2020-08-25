#!/usr/bin/env ruby

require "./development/yf.rb"

def main()
    acc=YF.new("AAPL", "2020-08-20", "2020-08-25", "1d")
    acc.get_prices_short()
end

main()