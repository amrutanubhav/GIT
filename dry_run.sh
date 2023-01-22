# Creates server , adding the ip to inv , run the role, delete itself.
- name: Creating EC2 for DryRun
  hosts: localhost
  gather_facts: False
  vars:
    instance_type: "t3.micro"
    security_group_id: "sg-051319f5b5c658b9d"  # Update as per your security group id
    image: "ami-0fa1ba08307b907ac"             # Update this with the AMI ID in your account which has ansible installed.
    region: "us-east-1"
  tasks:
    - name: Launching instance
      amazon.aws.ec2:
         count: 1
         group_id: "{{ security_group_id }}"
         instance_type: "{{ instance_type }}"
         image: "{{ image }}"
         wait: true
         region: "{{ region }}"
         instance_tags:
          Name: ansible-drurun
      register: ec2

    - name: Adding instance to the host group
      add_host:
        hostname: "{{ item.public_ip }}"
        groupname: launched
      loop: "{{ ec2.instances }}"

    - name: Waiting for SSH to come up
      delegate_to: "{{ item.public_ip }}"
      wait_for_connection:
        delay: 40
        timeout: 80
      loop: "{{ ec2.instances }}"
    - name: Set a Instance_ID Variable
      set_fact:
        INSTANCE_ID: "{{ ec2.instance_ids }}"

- name: Run Role to Test
  hosts: launched
  become: True
  gather_facts: Yes
  tasks:
    - name: set the facts per host
      set_fact:
        INSTANCE_ID: "{{hostvars['localhost']['INSTANCE_ID']}}"
    - name: Import the role and Terminate the instance
      block:
        - name: Import a role
          import_role:
            name: "{{COMPONENT}}"
      always:
        - name: Terminate instances that were previously launched
          delegate_to: 127.0.0.1
          amazon.aws.ec2:
            state: 'absent'
            instance_ids: '{{ INSTANCE_ID }}'
            region: us-east-1

	    ### adding file to show use of git push to origin remote branch
