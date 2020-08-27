#!/usr/bin/env ruby

$VERBOSE=nil

require "./development/yf.rb"
require "./development/database.rb"

def main()
    acc=YF.new("AAPL", "2020-08-20", "2020-08-27", "1d")
    df=acc.get_prices_short()
    puts(df.inspect())
    db=DataBase.new("./GeneratedDBs", "historical_data.db")
    sql=df.create_sql("aapl_daily")
    puts(sql)
    db.create_table(sql)
    #db.create_and_populate_table(df, "aapl_daily")
    db.close()

    df.each(:row) do |row|
        puts(row["Date"])    
    end


end

main()