# Author: Max Miller
# Created: June 5th, 2019
# Last Updated: June 5th, 2019
=begin
    Description: File transfer package for moving a temporary directory over an SFTP connection. Can be placed
    on host and "slave" machines for remote file upload/download and temp directory creation
    SFTP Docs: http://net-ssh.github.io/net-sftp/
=end
require 'fileutils'
require 'net/sftp'

class SFTPFileTransfer
    @@tmp_file_identifier = "tmp"   # What will be appended at the end of the temp directory
    
    def initialize(project)
        #Create new directory
        @project = project
        @tmp_file_path = "#{project}_#{@@tmp_file_identifier}/"
        if File.exists?(@tmp_file_path)
            puts "Old directory found. Deleting..."
            FileUtils.remove_dir(@tmp_file_path)
        end
        puts "Creating new temp directory for project #{@project}"
        FileUtils.mkdir(@tmp_file_path)
    end

    def set_file_identifier(identifier)
        @@tmp_file_identifier = identifier
    end

=begin
    BEGIN SSH Protocal Section
=end

    def set_ssh_user(username, password)
        # Sets the credentials for a the remote SSH user
        @username = username
        @password = password
    end

    def download_directory(host, remote_path)
        # downloads temp directory from remote host 
        if @username.exist? or @password.exist?
            Net::SFTP.start(host, @username, :password => @password) do |sftp|
                # grab data off the remote host directly to a buffer
                data = sftp.download!(remote_path)
            end
        else
            puts "SSH username or password not set"
        end 
    end

    def upload_directory(host, remote_path) 
        # uploads temp directory from remote host
        if @username.exist? or @password.exist?
            Net::SFTP.start(host, @username, :password => @password) do |sftp|
                sftp.upload!(@tmp_file_path, remote_path)
                # list the entries in a directory
                sftp.dir.foreach(@tmp_file_path) do |entry|
                    puts entry.longname
                end
            end
        else
            puts "SSH username or password not set"
        end 
    end

=begin
    END SSH Protocal Section
=end

=begin 
    BEGIN Temp File Section
=end

    # https://stackoverflow.com/questions/12617152/how-do-i-create-directory-if-none-exists-using-file-class-in-ruby
    def create_temp_file(file_name)
        if file_name.rindex("/") != nil 
            directory = file_name[0, file_name.rindex("/")+1] # ASSUMING ONLY UNIX!
            if !File.exists?(directory)
                FileUtils.mkdir_p("#{@tmp_file_path}#{directory}")
            end
        end
        tmp_file = File.new("#{@tmp_file_path}#{file_name}", "w")
        tmp_file.close()
    end

    def load_temp_file(file_name, data)
        #loads a file into memory and returns it
        tmp_file = File.open("#{@tmp_file_path}#{file_name}", "w")
        create_temp_file(tmp_file)
        write_temp_file(tmp_file, data)
    end

    def read_temp_file(file_name)
        tmp_file = File.open("#{@tmp_file_path}#{file_name}", "w")
        puts tmp_file.read
        tmp_file.close
    end

    def write_temp_file(file_name, data)
        # Writes data to a temporary file
        tmp_file = File.open(@tmp_file_path + file_name, "w")
        tmp_file << data
        tmp_file.close()
    end

    def get_all_files()
        #Lists all files in current project directory
        return Dir.glob("#{@tmp_file_path}**/*")
    end

    def remove_file(file_name) 
        #Removes file from directory
        tmp_path_to_file = "#{@tmp_file_path}#{file_name}"
        File.delete(tmp_path_to_file) if File.exist?(tmp_path_to_file)
        puts "Removed file at #{tmp_path_to_file}"
    end

    def clear()
        # Clears the temp file system
        if File.exists?(@tmp_file_path)
            puts "Clearing temporary file system..."
            FileUtils.remove_dir(@tmp_file_path)
            puts "Temporary file system cleared"
        end
    end

    def self.test()
        test = SFTPFileTransfer.new("tmp")
        test.create_temp_file("hello/world/hello_world.rb")
        test.write_temp_file("hello/world/hello_world.rb", 'hello = "World"')
        test.create_temp_file("hello/hello_world_2.rb")
        puts test.get_all_files()
        test.clear
    end

=begin
    END Temp File Section
=end
end

SFTPFileTransfer.test