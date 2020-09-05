#!/usr/bin/env ruby

$VERBOSE=nil

require 'slop'
require 'set'
require 'progress_bar'


require "./development/yf.rb"
require "./development/database.rb"
require "./development/utilities.rb"
require './development/finviz.rb'

#Constants
Text_file_path="./Collateral"
DB_path="./GeneratedDBs"
Data_path="./GeneratedData"
Historical_data_DB="historical_data.db"
Timeframes = ["daily", "weekly", "monthly"]

def main()

    list1=Set.new
    start_date=""
    end_date=""
    method=""

    options = Slop.parse do |opts|
        opts.string '-a', '--read_text_file', 'Parse a list of symbols in a text file'
        opts.string '-b', '--timeframe', 'Provide a timeframe [1d, 1wk, 1mo all]'
        opts.string '-c', '--earnings', 'Discover earnings for [this_week, next_week, this_month]'
        opts.string '-d', '--intersect_with', 'Intersect earnings names with [text_file]'
        opts.string '-f', '--start_date', 'Start Date yyyy-mm-dd'
        opts.string '-g', '--end_date', 'End  Date yyyy-mm-dd'
        opts.bool   '-e', '--create_historical_data_db', 'Create the DB with historical prices'
        opts.bool   '-i', '--update_historical_data_db', 'Update the DB with historical prices'
        opts.string '-j', '--method', 'Use one of three methods [scrape, json, csv] to get the prices frpm YF'
        opts.bool   '-h', '--help', 'Print this help message'
    end

    if options[:help]
        puts(options)
        exit()
    end

    if options[:method]
        method = options[:method]
    end


    if options[:read_text_file]
        read_text_file(Text_file_path+"/"+options[:read_text_file], list1)
        #sputs(list1)
    end

    if options[:start_date]
        start_date=options[:start_date]
    end

    if options[:end_date]
        end_date=options[:end_date]
    end

    if options[:create_historical_data_db]
        if !options[:read_text_file]
            puts("We need a way to come up with a list of tickers to create the db for. Exiting.")
            exit(1)
        end
        filename=DB_path+"/"+Historical_data_DB
        if File.exists? filename
            File.delete(filename)
        end
        db=DataBase.new(DB_path, Historical_data_DB)
        Timeframes.each do |tf|
            puts("Creating the DB tables for the #{tf} timeframe ...")
            tf1=""
            case tf
                when "daily"
                    tf1="1d"
                when "weekly"
                    tf1="1wk"
                when "monthly"
                    tf1="1mo"
                else
                    puts("Not supported timeframe. Exiting.")
                    exit(1)
            end
            bar=ProgressBar.new(list1.count)
            list1.each do |ticker|
                #puts(ticker)
                tbl=ticker.downcase+"_"+tf
                acc=YF.new(ticker, start_date, end_date, tf1)
                case method
                    when "json" 
                        df=acc.get_prices_long()
                    when "scrape"
                        df=acc.get_prices_short()
                    when "cvs"
                        puts("This is not implemented yet, reverting to the json method")
                        df=acc.get_prices_long()
                    else
                        puts("Not supported method. Exiting.")
                        exit(1)
                end
                #puts(df.inspect())
                df1=augment_dataframe_with_id(df)
                sql=df1.create_sql(tbl)
                #puts(sql)
                db.create_table(sql)
                db.initialize_table(df1, tbl)
                #puts(df11.inspect())
                bar.increment!
            end
        end
        db.close()
    end

    if options[:intersect_with]
        read_text_file(Text_file_path+"/"+options[:intersect_with], list1)
    end

    if options[:earnings]
        if !options[:intersect_with]
            puts("-E- --intersect_with option required. Exiting.")
            exit(1)
        end
        fv=Finviz.new
        fv.weeklyEarnings(list1, options[:earnings])
    end
    #puts(options)

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