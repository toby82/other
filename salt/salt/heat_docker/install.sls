oslo.log:
  pip.installed:
    - name: oslo.log
    - find_links: file:///opt/software/pip_heat
    - no_index: true
/usr/lib/heat:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - file_mode: 744
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
cp_file:
  cmd.run:
    - name: /usr/bin/cp -fr /opt/software/heat/contrib/heat_docker/heat_docker /usr/lib/heat/
heat_engine:
  cmd.run:
    - name: systemctl restart openstack-heat-engine
	- require:
	  - file: /usr/lib/heat
	  - cmd: cp_file

