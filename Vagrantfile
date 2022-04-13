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
    config.vm.network "forwarded_port", guest: 32400, host: 32400
    config.vm.network "forwarded_port", guest: 7878, host: 7878
    config.vm.network "forwarded_port", guest: 8989, host: 8989
    config.vm.network "forwarded_port", guest: 9117, host: 9117
    config.vm.network "forwarded_port", guest: 8181, host: 8181
    config.vm.network "forwarded_port", guest: 8080, host: 8082

    config.ssh.forward_agent = true

#     config.vm.provision :shell, path: "install.sh", :run => 'once', keep_color: true
    config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "www-data", mount_options: ["dmode=777", "fmode=777"]
end