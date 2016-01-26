require 'nokogiri'
require 'open-uri'

require 'viddl-rb'
require 'socket' # Sockets are in standard library
class VideosController < ApplicationController
  before_action :set_video, only: [:show, :edit, :update, :destroy]

  # GET /videos
  # GET /videos.json
  def index

    if current_user
      token = current_user.oauth_token
      #  puts token
      Koala.config.api_version = "v2.2"
      Koala.config.api_version = "v2.2"

      @graph = Koala::Facebook::API.new(token)
      friends = @graph.get_connections("me", "friends")
      @frilist = Array.new

      friends.each do |hash|
        @frilist.push(hash['id'])
        puts hash['id']

      end
    end

    @same_network = is_same_network(session[:user_id])
    @Nvideos = Video.all
    # @Nvideos = @videolist
    @videos = @Nvideos.order(:created_at).reverse
    # sorted = @records.sort_by &:created_at
    @locals = Localvdo.all
    @local_videos = @locals.order(:created_at).reverse

    # @friends = friendlistreturn
  end

  # GET /videos/1
  # GET /videos/1.json
  def show
    @sessionId = session[:user_id]
    @same_network = is_same_network(session[:user_id])
    @id = @video.user_id
  end

  # GET /videos/1
  def stream
    @same_network = is_same_network(session[:user_id])
  end

  # GET /videos/new
  def new
    @video = Video.new
  end

  # GET /videos/1/edit
  def edit
    @localvdo_for_given_user = Localvdo.where(user_id: session[:user_id])
  end

  # POST /videos
  # POST /videos.json
  def create
    @video = Video.new(video_params)

    respond_to do |format|
      if @video.save
        format.html { redirect_to @video, notice: 'Video was successfully created.' }
        format.json { render action: 'show', status: :created, location: @video }
      else
        format.html { render action: 'new' }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /videos/1
  # PATCH/PUT /videos/1.json
  def update
    puts "call update Video info"
    puts video_params

    respond_to do |format|
      if @video.update(video_params)
        if @video.local_link.length > 0
          @video.inLocal = true
        end
        @video.save!
        @user = User.find(session[:user_id])
        format.html { redirect_to @user, notice: 'Video was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.json
  def destroy
    @user = User.find(session[:user_id])
    @video.destroy
    respond_to do |format|
      format.html { redirect_to @user }
      format.json { head :no_content }
    end
  end

  def timelinevdo
    vdo_list = []
    user_id = session[:user_id]
    puts user_id
    user_obj = User.find(user_id)
    url = 'https://graph.facebook.com/v2.0/' + user_obj.uid + '?fields=posts&access_token=' + user_obj.oauth_token
    puts url
    raw_data = open(url).read
    #  puts raw_data
    json_data = JSON.parse(raw_data)
    puts json_data
    json_data['posts']['data'].each do |obj|

      if obj['type'] == "swf" || obj['type']== "video" || obj['type']== "link"

        puts obj['id']
        # puts obj['application']['name']


        if obj['link'].include? "www.youtube.com"

          vdo_list.append(youtube_embed(obj['link'], obj['id']))

        elsif obj['source'].include? "www.youtube.com"
          #puts obj

          vdo_list.append(youtube_embed(obj['source'], obj['id']))

        elsif obj['source'].include? "vimeo.com"
          #  puts "NOT youtube"
          #  puts obj['source']
          vdo_list.append(vimeo_embed(obj['source'], obj['id']))
        else
          vdo_list.append(facebook_embed(obj['source'], obj['id']))
        end

      end

    end


    #  listOne= Localvdo.pluck(:post_id)
    listOne = Array.new
    listTwo = Array.new
    #Detection of deleted videos
    json_data['posts']['data'].each do |obj|
      if obj['type'] == "swf" || obj['type']== "video"|| obj['type'] == "link"

        if obj['link'].include? "www.youtube.com"
          listTwo.append(obj['id'])
          puts obj['id']
        elsif obj['source'].include? "www.youtube.com"
          listTwo.append(obj['id'])
          puts obj['id']
        end

      end
    end
    deleteVideo = listOne - listTwo
    puts "Deleted Videoooooooooooooooo"
    puts deleteVideo
    if deleteVideo
      deleteVideo.each do |obj|
        name_of_video = Localvdo.find_by_post_id(obj).video_file_name

        # puts "Destroying Video from dropbox"
        #  system ("bash ~/Dropbox-Uploader/dropbox_uploader.sh delete /Public/'#{name_of_video}'")
        puts "Destroying video from Active record"
        dVideo = Localvdo.find_by_post_id(obj).destroy
        puts dVideo
        #  @client = Dropbox::API::Client.new(:token  => "pa8g47kzltdus4a1", :secret => "fwno07n27l1f6ii")
        #  client.destroy "#{name_of_video}"
      end
    end
    @contents = vdo_list
  end

  #YouTube Detection
  def youtube_embed(youtube_url, post_id)

    if youtube_url[/youtu\.be\/([^\?]*)/]
      youtube_id = $1

    else
      ## Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
      youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
      youtube_id = $5
    end

    #   puts youtube_id
    url = "https://www.youtube.com/watch?v=#{youtube_id}"

    downloadvdo(url, youtube_id, post_id)
    %Q{<iframe width="500" height="250" src="http://www.youtube.com/embed/#{ youtube_id}" frameborder="0" allowfullscreen></iframe>}
  end


  #Vimeo Detection
  def vimeo_embed(vimeo_url, post_id)

    vimeo_url["autoplay=1"]= "autoplay=0"
    #  puts vimeo_url
    %Q{<iframe width="400" height="300" name="autoplay" value="0" src="#{vimeo_url}" frameborder="0" allowfullscreen controls></iframe>}
  end

  def facebook_embed(facebook_url, post_id)
    %Q{<video width="400" height="300" name="autoplay" value="false" src="#{facebook_url}" frameborder="0" allowfullscreen controls></video>}
  end


  def downloadvdo(url, youtube_id, fbpost_id)
    uid = session[:user_id]
    name = ViddlRb.get_names(url)
    video_name = name.first.split.join('_')
    if Localvdo.exists?(:user_id => uid, :video_file_name => video_name)
      puts "#{video_name} already available in the local .... Errorrrrrrrrr"
    else
      puts "Downloading video----------------------------check name"
      puts video_name
      #puts name.first

      hostname = session[:user_ip]
      port = 2000

      s = TCPSocket.open(hostname, port)
      s.puts(url) # Send the time to the client
      while line = s.gets # Read lines from the socket
        puts line.chop # And print with platform line terminator
      end

      #Creating local video for local list
      @localvdo = Localvdo.new
      @localvdo.user_id =uid
      @localvdo.video_file_name = video_name
      #@localvdo.post_id = fbpost_id
      @localvdo.url = "https://www.youtube.com/embed/#{ youtube_id}"

      @localvdo.save

      puts "Download finished #{video_name} #{session[:user_ip]}"
    end
  end


  def fetch
    user_id = session[:user_id]
    user_obj = User.find(user_id)
    options = {:access_token => user_obj.oauth_token}
    query = 'SELECT owner, vid, title, thumbnail_link, embed_html
             FROM video WHERE owner=me()'

    begin
      @parsed_json = Fql.execute(query, options)
      @parsed_json.each do |obj|
        if Video.where(:uid => user_obj.uid, :facebook_vid => obj['vid'].to_s).blank?
          #puts "current obj['vid'] = " + obj['vid'].to_s

          vdo = Video.new()
          if obj['title'].length == 0
            vdo.name = "untitled"
          else
            vdo.name = obj['title']
          end
          vdo.thumbnail_link = obj['thumbnail_link']
          vdo.link = obj['embed_html']
          vdo.local_link = ""
          vdo.facebook_vid = obj['vid']
          vdo.uid = user_obj.uid
          vdo.user_id = user_id
          vdo.inLocal = false
          vdo.save!
        end
      end
      redirect_to user_obj
    rescue Exception
      redirect_to "/auth/facebook"
    end
  end

  def is_same_network(id)
    result = true
    if current_user
      loginUser_city = User.find(id).city
      puts loginUser_city
      # videoOwner_id = @video.user_id
      # videoOwner_city = User.find(videoOwner_id).city
      # puts videoOwner_city
      if loginUser_city == "Évry"
        result = true
      else
        result= false
      end
      result
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_video
    @video = Video.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def video_params
    params.require(:video).permit(:name, :uid, :link, :inLocal, :local_link)
  end

end