#!/usr/bin/env ruby

$VERBOSE=nil

require "./development/yf.rb"
require "./development/database.rb"

def main()
    acc=YF.new("AAPL", "2020-08-20", "2020-08-26", "1d")
    df=acc.get_prices_short()
    puts(df.inspect())
    db=DataBase.new("./GeneratedDBs", "historical_data.db")
    sql=df.create_sql("aapl_daily")
    puts(sql)
    db.execute(sql)
    db.close()
end

main()