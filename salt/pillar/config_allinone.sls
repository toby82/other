################################
# 配置 "管理网络"的各服务器的主机名
################################
mg_nw:
  hosts:
    present:
      # 列出所有在线主机节点名
      # 格式：
      #   控制节点：cc{数字}.域名.域名
      #   计算节点：nc{数字}.域名.域名
      #   网络节点：nn{数字}.域名.域名
      #   自动化部署节点：autodeploy.域名.域名
      cc.chinacloud.com: 172.16.70.24

################################
# 配置 Openstack 角色和服务器的关系
################################
iaas_role:
  # 控制节点角色的主机名
  cc: cc.chinacloud.com

  # 计算节点主机名(正则表达式，勿修改)
  #   规则为：
  #     [可有前缀]nc<数字>.各级域名
  #     例如：nc12.chinacloud.com
  #           iaas-nc01.chinacloud.com
  # 包含 计算节点 + 控制节点 的主机名表达式：
  nc: '.*nc|cc\S*\..*'

  # 网络节点角色的主机名
  nn: cc.chinacloud.com

  # 部署服务器角色的主机名
  autodeploy: cc.chinacloud.com

  # VMware代理节点角色的主机名
  #vm_agent: nc3.chinacloud.com
  
  
################################
# 配置 每台服务器的存储网络
################################


################################
# 配置 Neutron
################################
neutron_info:
  # 数据网络
  pri_if: eth1
  # 外网（被配置用于浮动IP，外网映射）
  pub_if: eth3


################################
# 配置 Cinder
################################
cinder_info:
  ## 配置使用gluster ##
  backend: gluster
  # 使用存储网段IP地址（没有的情况下可使用管理网段）
  gluster_mounts: 172.16.70.24:/cinder-vol

  ## lvm卷的配置
  lvm_volumes_size: "50G"

################################
# 配置 Ironic
################################
ironic_info:
  # y表示安装，n表示不安装
  # 如果选择了y，则控制节点上 nova_compute服务的driver，将使用 ironic 驱动。
  install: n

################################
# 配置 对接 Vmware Center
################################
vmware_vcenter_info:
  vmware_host:
  vmware_user:
  vmware_password:
  vmware_cluster:


################################
# 配置 到存储设备LUN的连接
################################
lun_info:
  # 是否激活
  enable: False
  # 配置逻辑单元号
  lun_number:
    glance_lun: 1
    nova_lun: 1
    cinder_lun: 2
  nodes:



################################
# 配置 OCFS2 集群
################################
ocfs2_cluster:
  # 是否激活
  enable: False
  # 集群名字
  name: ocfs2
  service_port: 7777
  #需挂载ocfs2文件夹的节点（包括控制节点和所有计算节点）
  nodes:

################################
# 配置 Glusterfs 集群  服务端/客户端
################################
glusterfs:
  # 是否激活
  enable: True
  # 副本数
  #  replica: 0 表示数据冗余为0，仅有一份数据保存在集群中
  #  replica: 2 表示数据冗余为1，共有两份相同的数据保存在集群中
  replica: 0

  # 承载共享存储的网络（通常使用存储网络，无存储网络的情况下，请选择管理网络。）
  # 管理网络配置项为 mg_nw
  network: mg_nw
  nodes:
    - cc.chinacloud.com:
        # 角色分为 server, client。 server将作为集群的一个节点，同时也部署了client；而client仅作为客户端访问集群。
        role: server
  cgconfig_params:
    cpuset_mems: 0

    # Gluster仅用于安装和演示，以下两个值需设置为
    #   memory_limit_in_bytes: 268435456
    #   cpuset_cpus:0
    #
    # 在生成环境中，须设置为：
    #   memory_limit_in_bytes: 17179869184
    #   cpuset_cpus: 0-7
    memory_limit_in_bytes: 268435456
    cpuset_cpus: 0

include:
  - others.glusterfs
  - others.yum_repos
  - others.nebula4j
  - others.others
  - others.keystone
  - others.glance
  - others.nova
  - others.db_info
