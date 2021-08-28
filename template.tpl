IP_address: {{hostvars[inventory_hostname]['ansible_facts']['default_ipv4']['address']}}
Distribution: {{hostvars[inventory_hostname]['ansible_facts']['distribution']}} {{hostvars[inventory_hostname]['ansible_facts']['distribution_version']}}
Kernel: {{hostvars[inventory_hostname]['ansible_facts']['kernel']}}
vCPUs: {{hostvars[inventory_hostname]['ansible_facts']['processor_vcpus']}}
RAM_MB: {{hostvars[inventory_hostname]['ansible_facts']['memory_mb']['real']['total']}}
Boot_image: {{hostvars[inventory_hostname]['ansible_facts']['cmdline']['BOOT_IMAGE']}}
Python3: {{hostvars[inventory_hostname]['ansible_facts']['python_version']}}
