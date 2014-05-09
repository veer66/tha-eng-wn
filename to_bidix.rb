# Copyright (C) 2014 Vee Satayamas
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE X CONSORTIUM BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'sqlite3'
require 'pp'

class ThaWnReader
  def initialize
    
  end

  def proc_id_pos(raw) 
    if raw =~ /^(\d+)-(\w)$/
      pos = case $2 
            when "n"
              1
            when "v"
              2
            when "a"
              3
            when "r"
              4
            when "s"
              5
            else
              raise "invalid pos"
            end      
      [$1.to_i + pos * 100000000, $2]
    else
      nil
    end
  end

  def read 
    File.open("wn-data-tha.tab", "r:UTF-8") do |file|
      while file.gets
        line = $_.chomp
        if line =~ /^#/
          next
        end        
        toks = line.split(/\s+/)
        lemma = toks[2]
        id, pos = proc_id_pos(toks[0])
        entry = {"id" => id, "pos" => pos, "lemma" => lemma}
        yield(entry)
      end
    end
  end
end

class EngWn 
  def initialize 
    @db = SQLite3::Database.new("wn_30_sqlite.db")
    @stmt = @db.prepare("SELECT lemma FROM wordsXsenses WHERE synsetid = ?")
  end

  def lookup(id) 
    lemmas = []
    @stmt.execute(id) do |result|
      result.each do |row|
        lemmas << row[0]
      end
    end
    lemmas
  end
    
end

def toApertiumPos(pos)
  # This is not always correct
  case pos
  when "n"
    "n"
  when "v"
    "vblex" 
  when "a"
    "adj"
  when "r"
    "adv"
  when "s"
    raise "Undefined pos s"
  else
    raise "Invalid pos"
  end
end

engWn = EngWn.new
ThaWnReader.new.read do |entry|
  tha_lemma = entry["lemma"]
  pos = toApertiumPos(entry["pos"])
  eng_lemmas = engWn.lookup(entry["id"])
  tha = tha_lemma.encode(:xml => :text)
  s = "<s n=\"#{pos}\"/>"
  eng_lemmas.each do |eng|
    eng = eng.encode(:xml => :text).gsub(" ", "<b/>")
    puts "<e><p><r>#{tha}#{s}</r><l>#{eng}#{s}</l></p></e>"
  end
end
