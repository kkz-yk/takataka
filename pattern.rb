# encoding: utf-8
def pattern_analysis(takker, now_time, old_time)
  p "pattern_analysis"
  # 準備
  # rhythmAを追加したデータに, rhythmBを既存のデータに
  db = SQLite3::Database.open("data.db")

  $rhythmA = []
  rhythm = db.execute("select lap from taka where twitter_name = ? and submit_date = ?", takker, now_time)
  rhythm[0][0].split(/\s*,\s*/).each{|temp|
    $rhythmA << temp.to_f
  }

  $rhythmB = []
  rhythm = db.execute("select lap from taka where twitter_name = ? and submit_date = ?", takker, old_time)
  rhythm[0][0].split(/\s*,\s*/).each{|temp|
    $rhythmB << temp.to_f
  }

  db.close
  check_interval(takker, now_time)

  $rhythmA.clear
  $rhythmB.clear
end

def check_interval(takker, now_time)
  puts "check_interval"
  intervalA = []
  intervalB = []
  temp_pattern = []

  p $rhythmA
  for a in 0..$rhythmA.length-2
    intervalA[a] = (($rhythmA[a + 1]*1000000 - $rhythmA[a]*1000000).ceil).to_i
  end

  for b in 0..$rhythmB.length-2
    intervalB[b] = (($rhythmB[b + 1]*1000000 - $rhythmB[b]*1000000).ceil).to_i
  end

  if intervalA.length >= intervalB.length
                for head in 0..intervalB.length-1
                        a = 0
                        for b in head..intervalB.length-1
                                if intervalA[a] % intervalB[b] <= 100000
                                        temp_pattern << b
                                end
                                a += 1
                        end
                        temp_pattern.clear
                        check_pattern(temp_pattern, takker, now_time)
                end
        else
                for head in 0..intervalB.length-intervalA.length
                        a = 0
                        for b in head..intervalA.length-1+head
                                if intervalA[a] % intervalB[b] <= 100000
                                        temp_pattern << b
                                end
                                a += 1
                        end
                        check_pattern(temp_pattern, takker, now_time)
                        temp_pattern.clear
                end
        end
end

def check_pattern(temp_pattern, takker, now_time)
        p "check_pattern"
        pattern_flg = 0
        cont = 0
        for i in 0..temp_pattern.length-2
                if (temp_pattern[i] - temp_pattern[i + 1]).abs == 1
                        pattern_flg = 1
                        cont += 1
                        next
                end

                if pattern_flg == 0
                else
                        pattern_flg = 0
                        if cont < 3
                                cnt = 0
                        else
                                # temp_pattern[i-cont..i]がパターン これをDBに保存
                                write_db(takker, now_time, temp_pattern[i-cont..i])
                        end
                end
        end
end

def write_db(takker, now_time, *pattern_num)
CREATE TABLE pattern_t (
        takker text,
        pattern text,
        submit_date text,
        number_of_time int
);
SQL
db.execute(sql)
        rescue
                db = SQLite3::Database.open("pattern.db")
        end

        pattern_list = ""
        pattern_num[0].each{|num|
                pattern_list << $rhythmB[num].to_s + ","
        }
        pattern_list << $rhythmB[pattern_num[0].pop + 1].to_s

        # 同じリズムパターンでもinsertになってるのをなおす
        date_time = db.execute("select submit_date, number_time from pattern_t where takker = ? and pattern = ?", takker, pattern_list)
        date_time.flatten
        if date_time[1] != 0
                # 同じリズムパターンがある
                date_time[0] << "," + now_time
                date_time[1] += 1
                db.execute("update pattern_t set submit_date = ?, number_of_time = ? where takker = ? and pattern = ?", date_time[0], date_time[1], takker, pattern_list)
                p "update db"
        else
                # 同じリズムパターンが無い
                number_time = 1
                db.execute("insert into pattern_t values (?, ?, ?, ?)", takker, pattern_list, now_time, number_time)
                p "insert db"
        end
        db.close
end
