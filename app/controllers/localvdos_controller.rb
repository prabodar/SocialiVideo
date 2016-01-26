require 'open-uri'


class LocalvdosController < ApplicationController
  before_action :set_localvdo, only: [:show, :edit, :update, :destroy]

  # GET /localvdos
  # GET /localvdos.json
  def index
    @localvdos = Localvdo.all
  end

  # GET /localvdos/1
  # GET /localvdos/1.json
  def show
    
  end

  # GET /localvdos/new
  def new
    @localvdo = Localvdo.new
  end

  # GET /localvdos/1/edit
  def edit
  end

  # POST /localvdos
  # POST /localvdos.json
  def create
    @localvdo = Localvdo.new(localvdo_params)
    puts "Creatingggggg localvdoooo"
    puts localvdo_params

    uploaded_file = params[:localvdo][:video]
    puts uploaded_file.original_filename
   # system ("bash /var/www/html/copylocalfiles.sh '#{uploaded_file.original_filename}'")

    hostname = session[:user_ip]
    port = 2000

    s = TCPSocket.open(hostname, port)
    s.puts("local_video_filename~"+uploaded_file.original_filename) # Send the time to the client
    while line = s.gets # Read lines from the socket
      puts line.chop # And print with platform line terminator
    end

    @localvdo.user_id = session[:user_id]
    puts @localvdo
   # system ("bash ~/Dropbox-Uploader/dropbox_uploader.sh delete /Public/'#{name_of_video}'")
    respond_to do |format|
      if @localvdo.save
        @user = User.find(@localvdo.user_id )
        format.html { redirect_to @user, notice: 'Localvdo was successfully uploaded.' }
        format.json { render action: 'show', status: :created, location: @localvdo }
      else
        format.html { render action: 'new' }
        format.json { render json: @localvdo.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH/PUT /localvdos/1
  # PATCH/PUT /localvdos/1.json
  def update
    respond_to do |format|
      @user = User.find(session[:user_id])
      if @localvdo.update(localvdo_params)
        format.html { redirect_to @user, notice: 'Localvdo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @localvdo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /localvdos/1
  # DELETE /localvdos/1.json
  def destroy
    deleted_url = @localvdo.video.url
    puts "Distroying video name " +@localvdo.name
    vdo_obj = Video.where(local_link: deleted_url).all
    vdo_obj.each do |vdo|
      vdo.inLocal = false
      vdo.local_link = ""
      vdo.save!
    end
    @localvdo.destroy
    @user = User.find(session[:user_id])
    respond_to do |format|
      format.html { redirect_to @user }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_localvdo
      @localvdo = Localvdo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def localvdo_params
      params.require(:localvdo).permit(:url)
      params.require(:localvdo).permit(:video)
    end
end
