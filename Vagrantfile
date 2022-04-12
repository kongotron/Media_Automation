Vagrant.configure("2") do |config|
    box_name = "mediamanager"
    config.vm.define box_name
    config.vm.hostname = box_name
    config.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.name = box_name
    end
    config.vm.box = "ubuntu/focal64"

    config.vm.network "forwarded_port", guest: 80, host: 8081
    config.vm.network "forwarded_port", guest: 443, host: 443
    config.vm.network "forwarded_port", guest: 3306, host: 3306

    config.ssh.forward_agent = true

#     config.vm.provision :shell, path: "install.sh", :run => 'once', keep_color: true
    config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "www-data", mount_options: ["dmode=777", "fmode=777"]
end