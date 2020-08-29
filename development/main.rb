#!/usr/bin/env ruby

$VERBOSE=nil

require "./development/yf.rb"
require "./development/database.rb"

def main()
    acc=YF.new("AAPL", "2020-08-20", "2020-08-29", "1d")
    df=acc.get_prices_short()
    puts(df.inspect())
    db=DataBase.new("./GeneratedDBs", "historical_data.db")
    sql=df.create_sql("aapl_daily")
    db.create_table(sql)
    db.initialize_table(df, "aapl_daily")
    df1=db.get_rows("aapl_daily", 3)
    puts(df1.inspect())
    db.close()
end

main()