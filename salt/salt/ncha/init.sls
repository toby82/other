ncha_conf:
  file.managed:
    - name: /etc/nova/ncha/ncha.conf
    - source: salt://ncha/template/ncha.conf
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
