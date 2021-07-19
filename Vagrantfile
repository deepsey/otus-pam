# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :"otus-pam" => {
        :box_name => "centos/7",
        :ip_addr => '192.168.100.60',
        :ssh_port => '2212'     
  }
}



Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s
          box.vm.network "forwarded_port", id: "ssh", guest: 22, host: boxconfig[:ssh_port]

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "200"]
          end
          
          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
          SHELL
          
          box.vm.provision "ansible" do |ansible|
            ansible.playbook = "playbooks/pam.yml"
          end

      end
  end
end