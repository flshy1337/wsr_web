## Базовый пример репозитория

Данный репозиторий является базовым примером для решения конкурсного задания по сценарию «Автоматизация развертывания приложения и базового аудита».
В данном примере используется базовая структура для управления конфигурациями с использованием Ansible, однако использование Ansible не является обязательным, т. к. проверка будет осуществляться по функциональным критериям.

### Структура репозитория
`run.sh` — является точкой входа для конвейера автоматической проверки задания и реализует сценарий автоматического развертывания конфигурации и сбора информации по аудиту:

```
# Указание используемого интерпретатора для исполняемого файла
#!/bin/bash

# Вывод inventory включающий необходимую отладочную информацию
ansible-inventory --graph --yaml --vars

# Проверка доступности всех устройств
ansible -m ping all 

# Запуск Ansible playbook для развертывания конфигурации
ansible-playbook deploy.yaml

# Запуск Ansible playbook для сбора информации по аудиту
ansible-playbook audit.yaml
```
`inventory.yaml` — содержит перечисление хостов, на которых производится управление конфигурацией. В данном примере в рамках группы `all` указан один единственный хост `platform_region_01`

```
all: 
  hosts:
    platform_region_01:
```

`group_vars` — директория, содержащая файлы переменных для групп устройств, указанных в рамках `inventory`.

`group_vars/all.yaml` — файл переменных для группы `all`. В данном примере описываются переменные подключения для ОС Linux. Обратите внимание, что учетная запись задается переменными среды `adminuser` и `password`. 

```
####  CONNECTION SPECIFIC ####
ansible_connection: ssh
ansible_become: no
ansible_network_os: linux

ansible_user: "{{ lookup('env','adminuser') }}"
ansible_ssh_pass: "{{ lookup('env','password') }}"
ansible_port: 22

####  CONFIGURATION SPECIFIC ####
```

`host_vars` — директория, содержащая файлы переменных для каждого хоста, указанного в рамках `inventory`

`host_vars\platform_region_01.yaml` — файл уникальных переменных для хоста `platform_region_01`. В данном примере указывается единственная уникальная переменная — `ansible_host`, содержащая IP-адрес (или FQDN) для подключения к хосту. Обратите внимание, что IP-адрес задается переменной среды `platform_01_public_ip`. 


```
####  CONNECTION SPECIFIC ####
ansible_host: "{{ lookup('env','platform_01_public_ip') }}"
```

`deploy.yaml` — содержит пример сценария Ansible playbook для управления конфигурацией. В данном примере на каждый хост, состоящий в группе `all` копируется файл `kickstart.sh`, а затем на выполняется удаленно.

```
- name: Execute kickstart script
  hosts: all
  gather_facts: false
  tasks:
    - name: Copy script
      ansible.builtin.copy:
        src: ./kickstart.sh
        dest: /home/azadmin/kickstart.sh
        mode: u=rwx,g=r,o=r
    - name: Run script
      ansible.builtin.shell: /home/azadmin/kickstart.sh
```

`kickstart.sh` — пример сценария, для удаленного выполнения на целевых хостах. 

```
#!/bin/bash
sudo echo 'Hello World!' > /home/azadmin/hello.txt
```

`audit.yaml` — содержит пример сценария Ansible playbook по сбору информации для базового аудита целевых хостов. В данном примере для всех хостов, состоящих в группе `all`, происходит следующее:
 - `gather_facts: true` — производится сбор базовой информации 
 - `Render report template` — на каждый хост копируется jinja2-шаблон в формате YAML, в который подставляется информация из ansible-facts
 - `Fetch rendered reports` — создается локальная папка `output`, в которую копируется отчет с каждого хоста
 
```
- name: Get audit information
  hosts: all
  gather_facts: true
  tasks:
    - name: Render report template
      ansible.builtin.template:
        src: template.tpl
        dest: "{{inventory_hostname}}.yaml"
    - name: Fetch rendered reports
      ansible.builtin.fetch:
        src: "{{inventory_hostname}}.yaml"
        dest: "./output/"
        flat: yes
```

`template.tpl` — jinja2-шаблон для сбора базовой информации о целевых хостах. В данном примере в шаблон подставляется IPv4-адрес целевого хоста.

```
IP_address: {{hostvars[inventory_hostname]['ansible_facts']['default_ipv4']['address']}}
```

`requirements.txt` — содержит все зависимости, которые необходимы для успешного выполнения сценария. По умолчанию содержит минимально необходимый набор pip3 пакетов, для работы Ansible и проверки отчетов с помощью PyYAML

`ansible.cfg` — локальный файл конфигурации Ansible, в котором можно переопределить параметры конфигурации Ansible при необходимости.

## Пример подготовки среды выполнения для конвейера автоматической проверки

```
# Репозиторий скачивается на локальную машину по ссылке, зарегистрированной кандидатом
- git clone {CloneURL} repo-{prefix}
- cd repo-{prefix}

# Создается виртуальная среда python3 с установкой всех зависимостей, указанных кандидатом в файле requirements.txt
- python3 -m venv venv-{prefix}          
- source venv-{prefix}/bin/activate
- pip3 install -r requirements.txt

# Удаляется директория output (при наличии)
- rm -rf output

# Назначаются всех необходимые переменные среды
- export adminuser={adminuser}
- export password={password}
- export prefix={prefix}
- export platform_01_public_ip={platform-01-public-ip}
...

# Производится запуск сценария run.sh
- ./run.sh > run.log
- cat run.log
```

После окончания выполнения сценария `run.sh` производится ряд функциональных проверок на доступность и отказоустойчивость веб-приложения в соответствии с требованиями технического задания, а также проверка результатов аудита каждой платформы на соответствие эталонным значениям.

## Обратите внимание 
**Доступ ко всем хостам производится с помощью динамических переменных, генерируемых случайным образом при развертывании базового экземпляра инфраструктуры. Перед проверкой данного задания, инфраструктура, предоставленная кандидатам для тестирования своего решения, БУДЕТ УНИЧТОЖЕНА и создана заново, соответственно все динамические переменные будут изменены — не используйте в своем сценарии значения динамических переменных, выданных перед началом выполнения задания — используйте переменные среды, согласно примерам, описанным выше.**

## Формат файлов отчетов для базового аудита

После окончания работы сценария `run.sh` в локальной директории должна быть создана директория `output`, в которой должны находиться файлы отчетов для каждого целевого хоста. Имя каждого файла должно быть в формате `hostname_XX.yaml`, например `platform_region_01.yaml`.

Каждый файл отчета должен содержать следующую информацию:

- Distribution: навзвание и версия дистрибутива ОС
- Kernel: версия ядра ОС
- vCPUs: количество виртуальных процессоров
- RAM_MB: количество оперативной памяти в мегабайтах
- Boot_image: путь к файлу загрузки ОС
- Python3: версия интерпретатора python3

Пример файла отчета по аудиту для каждого хоста имеет следующий вид:

```
Distribution: Ubuntu 16.04
Kernel: 3.1.4-88-repack-by-canonical
vCPUs: 1
RAM_MB: 666
Boot_image: /boot/vmlinus-torvalds-3.1.4-88-repack-by-canonical
Python3: 3.2.28
```
# wsr_web
