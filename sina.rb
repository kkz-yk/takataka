# encoding: utf-8
require 'sinatra'
require 'sqlite3'
require 'twitter'
require 'oauth'
require 'date'

require './pattern'

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

set :port,8080

configure do
	use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest(rand.to_s)

	$callback_url = "http://133.13.58.132:8080/get_token"

	CONSUMER_KEY = "BEtwuhgXzHl4klvUq7m37g"
	CONSUMER_SECRET = "Gc3Iw8wBml7xTqCGHqiM3TPoA5qpaywvtbOhkaw"

	begin 
		$db = SQLite3::Database.new("data.db")
	rescue
		$db = SQLite3::Database.open("data.db")
	end

	sql = <<SQL
CREATE TABLE taka (
	twitter_name text,
	access_token text,
	access_token_secret text,
	submit_date text,
	lap text,
	lap_num integer,
	gesture text
);
SQL
begin
	$db.execute(sql)
rescue
end
end

def oauth_consumer
	OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com")
end

get '/hoge.html' do
	content_type :html
	send_file "hoge.html"
end

get '/takker_list/:takker/bgm/clap.wav' do
	content_type :wav
	send_file "bgm/clap.wav"
end

get '/' do
	erb %{
		<a href="/takker_list">takker_list</a>
	}
end

post '/receives' do
	p params
	temp_lap = ""
	temp_ges = ""

	takker = params[:twitter_name]
	access_token = params[:access_token]
	access_token_secret = params[:access_token_secret]
	len = params[:arraylen].to_i

	if len > 3000
		len = 3000
	end

	for j in 1..len-1
		val = "value#{j}"
		temp_lap << params[val] + ","
		#val_ = "gesture#{j}"
		#temp_ges << params[val_] + ","
	end

	temp_lap[temp_lap.length - 1, 1] = ""
	now_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

	begin 
		$db.execute("insert into taka values (?,?,?,?,?,?,?)", takker, access_token, access_token_secret, now_time, temp_lap, len, temp_ges)
	rescue
	end

	old_times = $db.execute("select submit_date from taka where twitter_name = ? and submit_date <> ?", takker, now_time)
	old_times = old_times.flatten
	p old_times
	old_times.each{|old_time|
		pattern_analysis(takker, now_time, old_time)
	}

	text = ""
	Twitter.configure do |config|
		config.consumer_key = CONSUMER_KEY
		config.consumer_secret = CONSUMER_SECRET
		config.oauth_token = access_token
		config.oauth_token_secret = access_token_secret
	end
	begin
		@twitter_client = Twitter::Client.new
	rescue 
		p "client failed"
	else
		text << @twitter_client.user.screen_name
		text << "さんは今日" + len.to_s + "回タカタカしました"
	end

	begin
		@twitter_client.update(text)
	rescue
		p "post failed"
	else
		p "post successed"
	end
end

post '/get_takker' do
	p params
	case params.length 
	when 0
		names = ""
		$db.execute("select distinct access_token from taka").each{|token|
			$db.execute("select distinct twitter_name from taka where access_token = '#{token[0]}'").each{|name|
				names << name[0] + ","
			}
		}
		return names
	when 1
		links = ""
		$db.execute("select submit_date from taka where twitter_name = '#{params[:twitter_name]}'").each{|link|
			links << link[0] + ","
		}
		return links
	when 2
		laps = ""
		$db.execute("select lap from taka where twitter_name = '#{params[:twitter_name]}' and submit_date = '#{params[:submit_date]}'").each{|lap|
			laps = lap[0]
		}
		p "send " + laps
		return laps
	else
	end
end

get '/request_token' do
	request_token = oauth_consumer.get_request_token(:oauth_callback => $callback_url)
	session[:request_token] = request_token.token
	session[:request_token_secret] = request_token.secret
	redirect request_token.authorize_url
end

get '/get_token' do
	redirect "/point?oauth_token=#{params[:oauth_token]}&oauth_verifier=#{params[:oauth_verifier]}&request_token=#{session[:request_token]}&request_token_secret=#{session[:request_token_secret]}"
end

get '/point' do
	erb %{
		下の認証ボタンを押してください<br>
		その後, Doneを押してください
	}
end

post '/access_token' do
	begin
		request_token = OAuth::RequestToken.new(oauth_consumer, params[:request_token], params[:request_token_secret])
	rescue
		p "failed"
	else
		p "request_token ok"
	end

	begin
		@access_token = request_token.get_access_token(
			{},
			:oauth_token => params[:oauth_token],
			:oauth_verifier => params[:oauth_verifier])
	rescue OAuth::Unauthorized => @exception
		p "oauth failed: #{@exception.message}"
	else
		p "get access_token"
	end
	p @access_token
	p @access_token.token
	p @access_token.secret
	access = @access_token.token + "," + @access_token.secret + "," + @access_token.params[:screen_name]
end


get '/takker_list' do
	erb %{
	<% $db.execute("select distinct access_token from taka").each{|token| %>
		<% name = $db.execute("select distinct twitter_name from taka where access_token = ?", token[0]) %>
		<a href="/takker_list/<%= name[0][0] %>"><%= name[0][0] %></a><br>
	<% } %>
	}
end

get '/takker_list/:takker' do
	p "get_list from #{params[:takker]}"
	erb %{
	<% $db.execute("select submit_date from taka where twitter_name = '#{params[:takker]}'").each{|link| %>
		<a href="/takker_list/#{params[:takker]}/<%= link[0] %>"><%= link[0] %></a><br>
	<% } %>
	}
end

get '/takker_list/:takker/:date' do
	p "get_lap from #{params[:date]}"
	erb %{


		<% rhythm = $db.execute("select lap from taka where twitter_name = '#{params[:takker]}' and submit_date = '#{params[:date]}'") %>
		<% rhythm = rhythm[0][0].split(/\s*,\s*/) %>
		<% len = $db.execute("select lap_num from taka where twitter_name = '#{params[:takker]}' and submit_date = '#{params[:date]}'") %>
		<% len = len[0][0] %>

		<% p len %>
		<% p rhythm[0].to_f %>

		<audio id="clap" preload="auto">
			<source src="bgm/clap.wav" type="audio/wav">
		</audio>
		<script type="text/javascript">
		<!--
			var i = 0;
			lap_num = <%= len %>;
			lap = new Array(lap_num);
			<% for j in 0..len %>
				<% rhythm[j] = rhythm[j].to_f * 1000 %>
				<% rhythm[j] = rhythm[j].round %>
				lap[i] = <%= rhythm[j].to_f %>;
				i += 1;
			<% end %>

			function play(){
				for(i = 0; i < lap_num; i++){
					setTimeout(function(){ document.getElementById("clap").play() }, lap[i]);
				}
			}
		//-->
		</script>
		<input type="button" onClick="play()" value="play">
	}
end

post '/get_data' do
	params
end

get '/mendo' do
	$db.execute("insert into taka values ('nanasi', 'access_token', 'access_token_secret', '2012-10-01-04-00', '1.11111,2.22222,3.33333,4.44444,5.55555', 5, 'ges0,ges1')")
end

get '/pattern' do
	pdb = SQLite3::Database.open("pattern.db")
	pattern = pdb.execute("select distinct pattern from pattern_t")
	pdb.close
	p pattern[0]
end
