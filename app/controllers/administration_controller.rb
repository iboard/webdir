class AdministrationController < ApplicationController
  
  before_filter :authenticate, :except => 'set_user_path'
  
  def index
    redirect_to passwords_path if @change_password
    path = set_path(params['path'])
    
    @files = []
    @folders = []    

    Dir.new(path).each do |f|
      if File::directory?(path +  "/" + f )
        if @user == 'admin' || f == 'public' || @user == f || File::basename(path) == @user
          @folders << path + "/" + f
        end
      else
        @files << path + "/" + f unless f[0] == ".".ord
      end
    end
    pre = ""
    @pathtrack = [] 
    path.gsub("#{session['user_path']}",'Top').split('/').each { |back|
      if ! back.empty?
        @pathtrack << [back, "#{pre}#{back}"]
        pre += "#{back}/"
      end
    }

  end
  
  def file_action
    redirect_to passwords_path if @change_password
    path = set_path(params['path'])
      
    # NEW DIRECORY
    if params['new_directory'] && !params['new_directory'].blank?
      begin
        Dir::mkdir( "#{path}/#{params['new_directory']}")
      rescue Exception => e
        flash[:error] = "Verzeichnis <b>#{params['new_directory']}</b> kann nicht erstellt werden - #{e.to_s}"
      end
    end
    
    # RENAME A FILE
    if params['rename']
      params['rename'].each do |r|
         if  !r[1][0].blank?
           begin
             File::rename( r[0], path + "/#{File::basename(r[1][0])}")
           rescue Exception => e
             flash[:error] ||= ""
             flash[:error] += "Umbenennen der Datei <b>#{r[0]}</b> in <b>#{r[1]}</b> fehlgeschlagen. #{e}<br/>"
           end
         end
      end
    end
    
    # REMOVE DIRECTORY
    if params['rmdir']
      params['rmdir'].each do |r|
        begin
           Dir::rmdir( r )
         rescue Exception => e
           flash[:error] ||= ""
           flash[:error] += "Verzeichnis  <b>#{r}</b> kann nicht gelöscht werden. #{e}<br/>"
         end
      end
    end
    
    # DELETE FILE
    if params['delete']
      params['delete'].each do |d|
        begin
          File::unlink(d)
        rescue Exeption => e
          flash[:error] ||= ""
          flash[:error] += "#{e}"
        end
      end
    end
    
    # UPLOAD FILE
    if not params['new_file'].blank?
      begin
        f = File::open(path + "/"+ params['new_file'].original_filename,'w')
        f.write(params['new_file'].read)
        f.close
      rescue
        flash[:error] = 'Datei konnte nicht geöffnet werden.'
      end
    end
    redirect_to :action => 'index', :path => Base64::encode64(@path).gsub(/\r|\n| /,"")
  end

  def download
    if !params['file']
      flash[:error] = 'File not found'
    else
      path = set_path(params['path'])
      begin
        full_path = Base64::decode64(params['file'])
        filename = File::basename(full_path)
        attachment = File::open(full_path,"r")
        flash.now[:notice] =  "Datei #{full_path}/#{filename} wurde gespeichert" 
        send_file(attachment.path, :filename => filename, 
            :type => 'application/binary', :disposition => 'download')
        return false
      rescue Exception => e
        flash[:error] = "Error: #{e}"
      end
    end
    redirect_to :action => 'index', :path => Base64::encode64(File::dirname(full_path))
  end
  
  def passwords
    if @user != 'admin'
      flash[:error] = "Passwörter können nur vom Benutzer 'admin' bearbeitet werden."
      redirect_to root_path
    end
    if params[:commit] == 'Speichern'
      @new_users = []
      params['user'].each do |usr|
        if (!params[:delete]) || (params[:delete][usr[0]] != '1')
          if params[:password][usr[0]] && !params[:password][usr[0]].blank?
            pass = params[:password][usr[0]].crypt('cG')
          else
            pass = params[:old_password][usr[0]]
          end
          @new_users << { :user => usr[0], :password => pass }          
        end
      end
      if params[:new_user] && !params[:new_user].empty?
        @new_users << { :user => params[:new_user], :password => params[:new_password].crypt('nW') }
      end
      f = File.open(session['user_path'] + '/.webdirusers', "w")
        @new_users.each do |usr|
          f << "#{usr[:user]}:#{usr[:password]}\n"
        end
      f.close
    end   
    @users = read_users
  end
   
  def set_user_path
    session['user_path'] = USER_HOMES + "/" + params[:path] + "/" + USER_HTML_DIR + "/webdirfiles"
    if File::directory? session['user_path']
      redirect_to root_path
    else
      render :text => "Das Verzeichnis #{File::dirname(request.env['REQUEST_URI'])} existiert nicht.", :layout => false
    end
  end 

private
  def authenticate
    if !session['user_path']
      redirect_to set_user_path_url
      return false
    end
     user =  authenticate_or_request_with_http_basic { |username, password|
        rc = read_users
        rc.detect { |c| 
          c[:user] == username and check_password(username,c[:password],password)
        }           
     }
     @user = user[:user]
  end

  def set_path(new_path)
    myroot = session['user_path']
    if ! File::directory?(myroot)
      Dir::mkdir(myroot)
    end
    newpath = Base64::decode64(params['path']||myroot)
    if File::directory?(newpath)
      @path = newpath
    else
      @path = myroot
    end
    return @path
  end

  def read_users
    users = []
    if File::exist? session['user_path'] + '/.webdirusers'
      f = File::open( session['user_path'] + '/.webdirusers')
      f.each do |u|
        usr = u.split(':')
        users << { :user => usr[0].chomp, :password => usr[1].chomp }
      end
      f.close()
    else
      users = [ {:user => 'admin', :password => 'admin'.crypt("kd")} ]
    end
    return users
  end

  def check_password(username,check,plain)
    salt = check[0..1]
    @change_password = (username=='admin' && username == plain)
    return (plain.crypt(salt) == check)
  end

end


