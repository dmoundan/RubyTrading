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

#    def create_and_populate_table(df, tbl)
#        df.write_sql(@dbh,tbl)
#    end

    def close()
        @db.close if @db
    end

end
