#!/usr/bin/env ruby

require 'time'
require 'httparty'
require 'nokogiri'
require 'daru'

class YF

    Base_URL="https://finance.yahoo.com"
    attr_accessor :ticker, :start_date, :end_date, :timeframe

    def initialize(ticker, start_date, end_date, timeframe, filter="history")
        @ticker=ticker
        @start_date=start_date
        @end_date=end_date
        @timeframe=timeframe
        @filter=filter
    end

    def get_prices_short()
        parsed_page=Nokogiri::HTML(get_prices_helper())
        results=Hash.new
        keys_arr=Array.new
        list_of_tables=parsed_page.search('table')
        table=list_of_tables[0]
        count=0
        count1=0
        table.search('tr').each do |tr|
            count1=0
            collection=tr.search('th, td')
            collection.each do |cell|
                if count == 0
                    str1=cell.text.strip
                    if str1.include? "*"
                        str1.delete! '*'
                    end
                    keys_arr << str1
                    results[str1]=Array.new
                else
                    if collection.count == keys_arr.count
                        results[keys_arr[count1]] << cell.text.strip
                    else
                        break
                    end
                end    
                count1+=1
            end
            count+=1
        end   
        puts(results) 
    end

    def get_prices_long()
        unparsed_page=get_prices_helper()
        /HistoricalPriceStore":{"prices":(.*?\])/.match(unparsed_page)
        my_data=JSON.parse($1)
        my_data.each do |hash|
            hash.each do |key, value|
                if key == "date"
                    value1=Time.at(value).to_date.to_s 
                    hash[key]=value1
                end
            end
        end    
        puts(my_data) 
    end

    private

    def break_down_time_points()
        arr1=start_date.split("-")
        arr2=end_date.split("-")
        return [arr1,arr2]
    end

    def get_prices_helper()
        arr=break_down_time_points()
        period1=Time.new(arr[0][0],arr[0][1],arr[0][2]).to_i.to_s
        period2=Time.new(arr[1][0],arr[1][1],arr[1][2]).to_i.to_s
        subdomain="/quote/#{@ticker}/history?period1=#{period1}&period2=#{period2}&interval=#{@timeframe}&filter=#{@filter}&frequency=#{@timeframe}"
        final_url=Base_URL+subdomain
        unparsed_page=HTTParty.get(final_url)
        return unparsed_page
    end

end
