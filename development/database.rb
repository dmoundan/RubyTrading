#!/usr/bin/env ruby


require 'sqlite3'
#require 'java'
#require 'dbi'
#require 'dbd/jdbc'
#require 'jdbc/sqlite3'

class DataBase

    def initialize(location, name)  
        @location=location
        @name=name
        databasefile=@location+"/"+name
        @db = SQLite3::Database.open(databasefile)
        @db.results_as_hash = true
 #       @dbh = DBI.connect(
 #                           "DBI:jdbc:sqlite:#{databasefile}",  # connection string
 #                           '',                                 # no username for sqlite3
 #                           '',                                 # no password for sqlite3
 #                           'driver' => 'org.sqlite.JDBC')      # need to set the driver
    end

    def create_table(sql)
        sql1=sql.gsub("CREATE TABLE", "CREATE TABLE IF NOT EXISTS")
        sql2=sql1.gsub("CHARACTER SET=UTF8;", "")
        @db.execute(sql2)
    end

   def initialize_table(df, tbl)
#        df.write_sql(@dbh,tbl)
       insert_into_table(df,tbl)
   end

   def update_table(df,tbl)
#find out the id of the last row in the table
        results=@db.execute("SELECT * FROM #{tbl} ORDER BY ID DESC LIMIT 1")
        df1=augment_dataframe_with_id(df,results[0]["Id"]+1)
        insert_into_table(df1,tbl)
   end

   def get_rows(tbl, how_many=0) 
        if how_many == 0
            results=@db.execute("SELECT * FROM #{tbl}")
        else
            results=@db.execute("SELECT * FROM (SELECT * FROM #{tbl} ORDER BY id  DESC LIMIT #{how_many}) var1 ORDER BY id ASC")
        end
        df=Daru::DataFrame.new(results)
        return df
   end

   def get_db_table_names()
        results=@db.execute("SELECT tbl_name FROM sqlite_master WHERE type = \'table\'")
        df=Daru::DataFrame.new(results)
        return df
   end

   def close()
        @db.close if @db
   end

   private

   def insert_into_table(df,tbl)
        keys_arr=df.to_h.keys
        str1="?,"*keys_arr.count
        str1.chop!
        df.each(:row) do |row|
            val_array=Array.new
            keys_arr.each do |value|
                val_array << row[value]
            end
            @db.execute("INSERT INTO #{tbl} (#{keys_arr.join(',')}) VALUES (#{str1})", val_array)
        end
   end
end
