#!/usr/bin/env ruby

def augment_dataframe_with_id(df, start=0)
    sz=df.nrows
    numbers=start...start+sz
    v=Daru::Vector.new(numbers.to_a)
    df["Id"]=v
    return df
end