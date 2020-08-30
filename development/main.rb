#!/usr/bin/env ruby

$VERBOSE=nil

require 'slop'
require 'set'


require "./development/yf.rb"
require "./development/database.rb"
require "./development/utilities.rb"

#Constants
Text_file_path="./Collateral"
DB_path="./GeneratedDBs"
Data_path="./GeneratedData"

def main()

    list1=Set.new

    options = Slop.parse do |opts|
        opts.string '-a', '--read_text_file', 'Parse a list of symbols in a text file'
        opts.string '-b', '--timeframe', 'Provide a timeframe [1d, 1wk, 1mo]'
        opts.bool '-h', '--help', 'Print this help message'
    end

    if options[:help]
        puts(options)
        exit()
    end

    if options[:read_text_file]
        read_text_file(Text_file_path+"/"+options[:read_text_file], list1)
        puts(list1)
    end
    puts(options)

=begin    
    acc1=YF.new("AAPL", "2020-08-17", "2020-08-22", "1d")
    df1=acc1.get_prices_short()
    puts(df1.inspect())
    acc2=YF.new("AAPL", "2020-08-24", "2020-08-29", "1d")
    df2=acc2.get_prices_short()
    puts(df2.inspect())
    df11=augment_dataframe_with_id(df1)
    db=DataBase.new("./GeneratedDBs", "historical_data.db")
    sql=df11.create_sql("aapl_daily")
    db.create_table(sql)
    db.initialize_table(df11, "aapl_daily")
 #   df2=db.get_rows("aapl_daily", 3)
 #   puts(df2.inspect())
    db.update_table(df2,"aapl_daily")
    db.close()
=end    
end

main()