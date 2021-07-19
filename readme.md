# Домашнее задание по теме "Рользователи и группы"

Настройку системы осуществляем через ansible. Структура проекта следующая:

**data** - каталог с необходимыми файлами для настройки системы (admin_login.sh, 01-systemd.rules)  
**inventories** - каталог с инвентори файлом (hosts.yml)  
**playbooks** - каталог с плейбуком (pam.yml)  
**ansible.cfg** - файл с настройками ansible  
**Vagrantfile**  
**readme.md**  

Далее идет описание плэйбука **pam.yml**, который настраивает поднятую вагрантом систему.  


## Задание 1. Запрещаем всем пользователям, кроме группы admin, login по выходным дням.

    - name: PAM | Permit login for admin group  
      hosts: otus-pam  
      become: true  
    
      tasks:

#### 1. Создаем группу admin.

    - name: Create admin group  
      group:  
      name: admin 
      

#### 2. Создаем пользователей admin1, admin2, user1, добавляем admin1, admin2 в группу admin

    - name: Create user admin1
      user:
        name: admin1
        groups: admin
               
    - name: Create user admin2
      user:
        name: admin2
        groups: admin
        
        
    - name: Create user user1
      user:
        name: user1
      
      
#### 3. Устанавливаем пароли для пользователей

    - name: SET PASSWORDS
      shell: echo "admin1" | passwd --stdin admin1 && echo "admin2" | passwd --stdin admin2 && echo "user1" | passwd --stdin user1

#### 4. Добавляем пользователя vagrant в группу admin  

    - name: Add vagrant to admin group
      user:
        name: vagrant
        groups: admin


#### 4. Для ограничения login используем модуль pam_exec.

Добавляем в файл **/etc/pam.d/login** строку  

    account required pam.exec.so /user/local/bin/admin_login.sh


    - name: Insert string in /etc/pam.d/login file    
      lineinfile: 
        path: /etc/pam.d/login  
        insertafter: account    required     pam_nologin.so  
        line: account    required     pam_exec.so   /usr/local/bin/admin_login.sh  
        state: present  
        
        

**admin_login.sh** - скрипт, выполняющий следующее:

    #!/bin/bash

Проверяем, является ли текущий день недели 6 или 7, т.е выходным:

    if [ $(date +%u) -eq 6 -o $(date +%u) -eq 7 ]; then

Если да, то проверяем через переменную окружения $PAM_USER, входит ли пользователь в группу admin  
и присваиваем переменной $return_code код возврата операции сравнения  

    id -nG "$PAM_USER" | grep -qw admin
     return_code=$?
  
Если код возрата 0, то пользователь входит в группу admin, login ему разрешен и скрипт возвращает 0.  
В противном случае возващается 1 и login не происходит.

    if [ return_code -eq 0 ]; then
      exit 0
    else
      exit 1
    fi
  
Если день недели - будни, то просто разрешаем login  

    else
     exit 0
    fi

#### 4. Копируем наш скрипт в /user/local/bin/

    - name: Copy admin_login.sh  
      copy:  
        src: ../data/admin_login.sh  
        dest: /usr/local/bin/    
        
    - name: SET CHMOD FOR  /usr/local/bin/admin_login.sh  
      command: chmod u+x /usr/local/bin/admin_login.sh  
  
  
  
## Задание 2. Разрешаем пользователю vagrant запуск docker и рестарт сервиса systemd docker.

    - name: PAM | PERMIT START DOCKER FOR VAGRANT
      hosts: otus-pam
      become: true
  
    tasks:

#### 1. Устанавливаем docker, активируем с стартуем сервис.

    - name: INSTALL DOCKER  
      shell: curl -sSL https://get.docker.com | sh  
   
        
    - name: STARTING AND ENABLING DOCKER  
      systemd:  
        name: docker  
        state: started  
        enabled: yes    

#### 2. Добавляем пользователя vagrant в группу docker 

    - name: ADDING vagrant TO DOCKER GROUP
      user:
        name: vagrant
        groups: docker        
        
#### 3. Рестартим сервис docker

    - name: RESTARTING DOCKER SERVICE 
      systemd:
        name: docker
        state: restarted
        
#### 4. Создаем файл polkit 01-systemd.rules

Разрешаем пользователю vagrant работу с сервисами systemd


    polkit.addRule(function(action, subject) {  
     if (action.id.match("org.freedesktop.systemd1.manage-units") &&  
     subject.user === "vagrant") {  
    return polkit.Result.YES;  
    }    
    });  
        

#### 5. Копируем созданный файл в /etc/polkit-1/rules.d/ 

    - name: COPY 01-systemd.rules  
      copy:  
        src: ../data/01-systemd.rules  
        dest: /etc/polkit-1/rules.d/   
          
                

  
## После прогона плэйбука проверяем работу системы.


Изменяем дату на сервере и убеждаемся, что в субботу и воскресенье мы можем  
логиниться только как члены группы admin, а в остальные дни и как пользователь user1.  


    [vagrant@otus-pam ~]$ sudo date 071800002021  
    Sun Jul 18 00:00:00 UTC 2021  

  
Запускаем docker от пользователя vagrant:  

    [vagrant@otus-pam ~]$ docker run hello-world  

    Hello from Docker!  
    This message shows that your installation appears to be working correctly.  
  
    To generate this message, Docker took the following steps:  
    1. The Docker client contacted the Docker daemon.  
    2. The Docker daemon pulled the "hello-world" image from the Docker Hub.  
    (amd64)  
    3. The Docker daemon created a new container from that image which runs the  
    executable that produces the output you are currently reading.  
    4. The Docker daemon streamed that output to the Docker client, which sent it  
    to your terminal.  
  
    To try something more ambitious, you can run an Ubuntu container with:  
    $ docker run -it ubuntu bash  
  
    Share images, automate workflows, and more with a free Docker ID:  
    https://hub.docker.com/  
  
    For more examples and ideas, visit:  
    https://docs.docker.com/get-started/  
   
   
Рестартим сервис docker от пользователя vagrant:   

    [vagrant@otus-pam ~]$ systemctl restart docker
